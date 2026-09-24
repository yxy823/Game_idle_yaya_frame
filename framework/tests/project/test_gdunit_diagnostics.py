# 重放本次诊断与已消费记录，检查预期错误没有吞掉其他真实异常。
from __future__ import annotations
from project_context import PROJECT_ROOT

import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from unittest import mock


TOOLS = (PROJECT_ROOT / "tools")
SPEC = importlib.util.spec_from_file_location("gdunit_lifecycle_replay", TOOLS / "testing/run-gdunit-tests.py")
assert SPEC is not None and SPEC.loader is not None
runner = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = runner
with mock.patch.object(sys, "path", [str(PROJECT_ROOT), *sys.path]):
    SPEC.loader.exec_module(runner)
    from tools.lib.gdunit_diagnostics import DiagnosticEvidenceError, unexpected_diagnostics


NATIVE = "ERROR: lifecycle diagnostic\n   at: push_error (core/variant/variant_utility.cpp:1023)\n"
RECORD = {
    "event": "diagnostic", "id": 1, "kind": "error", "message": "lifecycle diagnostic",
    "file": "core/variant/variant_utility.cpp", "line": 1023, "function": "push_error",
}


class LifecycleEvidenceTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="gdunit-lifecycle-unit-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.report = self.root / "report_1/results.xml"
        self.report.parent.mkdir()
        self.evidence = self.report.parent / "diagnostics.jsonl"

    def _events(self, *events: dict) -> list[dict]:
        return [{"event": "session_start", "schema_version": 1,
                 "report_path": str(self.report.parent), "engine_pid": 123},
                *events, {"event": "session_end"}]

    def _write(self, events: list[dict]) -> None:
        self.evidence.write_text("".join(json.dumps(event) + "\n" for event in events), encoding="utf-8")

    def test_native_diagnostics_across_lifecycle_need_positive_scoped_evidence(self) -> None:
        self._write(self._events())
        for prefix in ("", "res://tests/example.gd > test_case STARTED\n",
                       "res://tests/example.gd > test_case PASSED\n", "Open XML Report at: current\n"):
            with self.subTest(prefix=prefix):
                self.assertEqual(len(unexpected_diagnostics(prefix + NATIVE, self.report)), 1)

    def test_only_the_individual_matched_occurrence_is_exempt(self) -> None:
        self._write(self._events(RECORD, {"event": "expected", "id": 1}))
        self.assertEqual(unexpected_diagnostics(NATIVE, self.report), [])
        self.assertEqual(len(unexpected_diagnostics(NATIVE + NATIVE, self.report)), 1)
        self._write(self._events(RECORD, dict(RECORD, id=2), {"event": "expected", "id": 1}))
        self.assertEqual(len(unexpected_diagnostics(NATIVE + NATIVE, self.report)), 1)

    def test_logger_only_unexpected_diagnostic_cannot_disappear(self) -> None:
        self._write(self._events(RECORD))
        self.assertEqual(len(unexpected_diagnostics("", self.report)), 1)

    def test_expected_evidence_requires_matching_native_source_and_type(self) -> None:
        self._write(self._events(RECORD, {"event": "expected", "id": 1}))
        for output in ("", NATIVE.replace("1023", "1024"), NATIVE.replace("ERROR:", "WARNING:")):
            with self.subTest(output=output), self.assertRaises(DiagnosticEvidenceError):
                unexpected_diagnostics(output, self.report)

    def test_missing_malformed_and_incomplete_evidence_fails_closed(self) -> None:
        with self.assertRaises(DiagnosticEvidenceError):
            unexpected_diagnostics("", self.report)
        for content in ("", "{broken", "[]\n", json.dumps(self._events()[0]) + "\n"):
            self.evidence.write_text(content, encoding="utf-8")
            with self.subTest(content=content), self.assertRaises(DiagnosticEvidenceError):
                unexpected_diagnostics("", self.report)

    def test_another_invocations_evidence_is_rejected(self) -> None:
        events = self._events()
        events[0]["report_path"] = str(self.root / "old/report_1")
        self._write(events)
        with self.assertRaisesRegex(DiagnosticEvidenceError, "another report"):
            unexpected_diagnostics("", self.report)

    def test_invalid_event_identity_and_order_are_rejected(self) -> None:
        variants = (
            self._events(dict(RECORD, id=2)),
            self._events({"event": "expected", "id": 1}, RECORD),
            self._events(RECORD, {"event": "expected", "id": 1}, {"event": "expected", "id": 1}),
            self._events(dict(RECORD, line=True)),
            self._events(dict(RECORD, kind="anything")),
            self._events({"event": "unknown"}),
            [*self._events(), RECORD],
        )
        for events in variants:
            self._write(events)
            with self.subTest(events=events), self.assertRaises(DiagnosticEvidenceError):
                unexpected_diagnostics("", self.report)

    def test_plain_error_words_and_test_summaries_are_not_native_records(self) -> None:
        self._write(self._events())
        output = "ERROR count: 0\nERROR: documentation example\nStatistics: 1 tests, 0 errors\n"
        self.assertEqual(unexpected_diagnostics(output, self.report), [])

    def _replay(self, output: str, *, scoped: bool = False, exit_code: int = 0,
                timed_out: bool = False) -> tuple[int, dict]:
        vendor_script = self.root / runner.RUNNER_SCRIPT.removeprefix("res://")
        vendor_script.parent.mkdir(parents=True, exist_ok=True)
        vendor_script.touch()
        suite = self.root / "tests/example.gd"
        suite.parent.mkdir(exist_ok=True)
        suite.write_text("extends GdUnitTestSuite\nfunc test_case():\n\tpass\n", encoding="utf-8")

        def process(command: list[str], log: Path, _timeout: float) -> runner.ProcessResult:
            directory = Path(command[command.index("-rd") + 1]) / "report_1"
            directory.mkdir()
            (directory / "results.xml").write_text(
                '<testsuites tests="1" failures="0" skipped="0" flaky="0">'
                '<testsuite name="example" package="tests" tests="1" errors="0" failures="0" skipped="0" flaky="0">'
                '<testcase name="test_case"/></testsuite></testsuites>', encoding="utf-8")
            (directory.parent / "discovery.json").write_text(json.dumps({
                "schema_version": 1, "run_id": directory.parent.name, "engine_pid": 123,
                "cases": [{"id": "tests/example.gd::test_case", "path": "tests/example.gd",
                           "case": "test_case", "method": "test_case"}]}), encoding="utf-8")
            self.report = directory / "results.xml"
            self.evidence = directory / "diagnostics.jsonl"
            events = self._events(RECORD, {"event": "expected", "id": 1}) if scoped else self._events()
            self._write(events)
            log.write_text(output, encoding="utf-8")
            return runner.ProcessResult(exit_code, timed_out, 123, output, (123,))

        args = runner._parse_args(["--godot-binary", sys.executable])
        with mock.patch.object(runner, "REPO_ROOT", self.root), mock.patch.object(
            runner, "_run_process", side_effect=process
        ), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = runner._run_tests(args)
        verdict_path = self.report.parent.parent / "result.json"
        return code, json.loads(verdict_path.read_text(encoding="utf-8"))

    def test_current_green_junit_does_not_hide_lifecycle_errors(self) -> None:
        for prefix in ("", "res://tests/example.gd > test_case STARTED\n",
                       "res://tests/example.gd > test_case PASSED\n", "Open XML Report at: current\n"):
            with self.subTest(prefix=prefix):
                code, verdict = self._replay(prefix + NATIVE)
                self.assertEqual(code, 1)
                self.assertEqual(ET.parse(self.report).find("testsuite").attrib["errors"], "0")
                self.assertTrue(verdict["errors"])

    def test_current_scoped_evidence_and_green_junit_pass(self) -> None:
        code, verdict = self._replay(NATIVE, scoped=True)
        self.assertEqual(code, 0)
        self.assertEqual(verdict["errors"], [])

    def test_green_junit_and_scoped_evidence_never_override_exit_or_timeout(self) -> None:
        for options in ({"exit_code": 7}, {"exit_code": 1, "timed_out": True}):
            with self.subTest(options=options):
                code, verdict = self._replay(NATIVE, scoped=True, **options)
                self.assertEqual(code, 1)
                self.assertTrue(verdict["errors"])


    def test_missing_discovery_preserves_actual_process_exit(self):
        script = self.root / runner.RUNNER_SCRIPT.removeprefix("res://")
        script.parent.mkdir(parents=True)
        script.touch()
        def failed_process(command, log, timeout):
            log.write_text("original startup failure", encoding="utf-8")
            return runner.ProcessResult(7, False, 123, "original startup failure", (123,))
        args = runner._parse_args(["--godot-binary", sys.executable])
        with mock.patch.object(runner, "REPO_ROOT", self.root), mock.patch.object(
                runner, "_run_process", side_effect=failed_process):
            self.assertEqual(runner._run_tests(args), 1)
        path = next((self.root / "reports/gdunit-wrapper/focused").glob("run-*/result.json"))
        result = json.loads(path.read_text())
        self.assertEqual(result["process"]["returncode"], 7)
        self.assertEqual(result["status"], "failed")
        self.assertEqual((path.parent / "engine.log").read_text(), "original startup failure")


if __name__ == "__main__":
    unittest.main()
