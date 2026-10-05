# 检查包装器命令、判定及进程控制边界；需要真实引擎的集成范围由验证入口另行执行。
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import argparse
import ctypes
import importlib.util
import io
import json
from contextlib import redirect_stdout
import os
import subprocess
import tempfile
import time
import unittest
from unittest import mock

SPEC = importlib.util.spec_from_file_location(
    "gdunit_runner_process_tests", (PROJECT_ROOT / "yaya/tools") / "testing/run-gdunit-tests.py"
)
assert SPEC is not None and SPEC.loader is not None
runner = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = runner
with mock.patch.object(sys, "path", [str(PROJECT_ROOT / "yaya"), *sys.path]):
    SPEC.loader.exec_module(runner)

STARTED = "res://tests/test_example.gd > test_case STARTED\n"
ERROR = "ERROR: injected startup failure\n   at: before (res://tests/test_example.gd:4)\n"


def _pid_is_running(pid: int) -> bool:
    api = ctypes.WinDLL("kernel32", use_last_error=True)
    api.OpenProcess.argtypes = [ctypes.c_ulong, ctypes.c_int, ctypes.c_ulong]
    api.OpenProcess.restype = ctypes.c_void_p
    api.GetExitCodeProcess.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ulong)]
    api.CloseHandle.argtypes = [ctypes.c_void_p]
    handle = api.OpenProcess(0x1000, False, pid)
    if not handle:
        if ctypes.get_last_error() == 87:
            return False
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        code = ctypes.c_ulong()
        if not api.GetExitCodeProcess(handle, ctypes.byref(code)):
            raise ctypes.WinError(ctypes.get_last_error())
        return code.value == 259
    finally:
        api.CloseHandle(handle)


class GdUnitRunnerTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="gdunit-wrapper-unit-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "tests").mkdir()
        patcher = mock.patch.object(runner, "REPO_ROOT", self.root)
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_direct_command_preserves_engine_and_gdunit_argument_boundaries(self) -> None:
        suite = self.root / "tests/with spaces/test_case.gd"
        suite.parent.mkdir(parents=True)
        suite.touch()
        args = runner._parse_args([
            "--godot-binary", sys.executable, "--target", "tests/with spaces/test_case.gd",
            "--require-test", "tests/with spaces/test_case.gd::test_case", "--continue",
        ])
        command = runner._build_command(args, self.root / "reports with spaces")
        self.assertEqual(command[:7], [
            str(Path(sys.executable).resolve()), "--path", str(self.root),
            "--debug", "--ignore-error-breaks", "--script", runner.RUNNER_SCRIPT,
        ])
        self.assertEqual(command[7:], [
            "-rd", str(self.root / "reports with spaces"), "-a", "tests/with spaces/test_case.gd", "-c",
        ])
        self.assertNotIn("--headless", command)
        self.assertNotIn("--remote-debug", command)
        self.assertEqual(args.require_test, "tests/with spaces/test_case.gd::test_case")

    def test_repeated_targets_all_run_in_order_without_duplicates(self) -> None:
        for name in ("a.gd", "b.gd"):
            (self.root / "tests" / name).touch()
        args = runner._parse_args(["--godot-binary", sys.executable, "--target", "tests/a.gd",
                                   "--target", "tests/b.gd", "--target", "tests/a.gd"])
        self.assertEqual(args.targets, ["tests/a.gd", "tests/b.gd"])
        command = runner._build_command(args, self.root / "reports")
        self.assertEqual(command[-4:], ["-a", "tests/a.gd", "-a", "tests/b.gd"])
        self.assertEqual(runner._parse_args(["--godot-binary", sys.executable]).targets, ["tests"])

    def test_overlapping_targets_execute_only_the_parent_directory(self) -> None:
        suite = self.root / "tests/features/F013/held_tween_clock_test.gd"
        suite.parent.mkdir(parents=True)
        suite.touch()
        targets = ["tests/features/F013", "tests/features/F013/held_tween_clock_test.gd",
                   "res://tests/features/F013", "tests\\features\\F013", "tests/features",
                   "res://tests/features", "tests/features"]
        args = runner._parse_args(["--godot-binary", sys.executable,
                                   *[argument for target in targets for argument in ("--target", target)]])
        self.assertEqual(args.targets, ["tests/features"])
        command = runner._build_command(args, self.root / "reports")
        self.assertEqual(command[-2:], ["-a", "tests/features"])
        self.assertEqual(command.count("-a"), 1)

    def test_console_summary_lists_failures_and_falls_back_to_output_tail(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            output = "\n".join(f"line {index}" for index in range(30))
            fallback = runner._summary(directory, output)
            self.assertIn("No single JUnit report", fallback)
            self.assertIn("line 29", fallback)
            self.assertNotIn("line 9\n", fallback)
            report = directory / "report_1/results.xml"
            report.parent.mkdir()
            report.write_text(
                '<testsuites><testsuite name="s">'
                '<testcase classname="probe_test" name="test_ok"/>'
                '<testcase classname="probe_test" name="test_bad">'
                '<failure message="FAILED: res://tests/probe_test.gd:5"><![CDATA[\nExpecting:\n 2\n but was\n 1\n'
                "\tat 'test_bad' in res://tests/probe_test.gd:5\n]]></failure></testcase>"
                '<testcase classname="probe_test" name="test_skip"><skipped/></testcase>'
                "</testsuite></testsuites>", encoding="utf-8")
            summary = runner._summary(directory, output)
        self.assertIn("Tests: 3 cases, 2 not passed", summary)
        self.assertIn("FAILED probe_test.test_bad", summary)
        self.assertIn("res://tests/probe_test.gd:5  Expecting: 2 but was 1", summary)
        self.assertIn("SKIPPED probe_test.test_skip", summary)
        self.assertNotIn("test_ok", summary)
        self.assertNotIn("line 29", summary)
        self.assertIn("engine.log", summary)

    def test_timeout_default_override_and_invalid_values(self) -> None:
        self.assertEqual(runner._parse_args(["--godot-binary", sys.executable]).timeout_seconds, 120)
        self.assertEqual(runner._positive_seconds("0.25"), 0.25)
        for invalid in ("0", "-1", "nan", "inf", "-inf"):
            with self.subTest(value=invalid), self.assertRaises(argparse.ArgumentTypeError):
                runner._positive_seconds(invalid)

    def test_invalid_feature_cannot_choose_a_report_directory(self) -> None:
        for feature in ("../outside", "F001/run-other", "focused", "", "F01"):
            with self.subTest(feature=feature), self.assertRaises(SystemExit):
                runner._parse_args(["--godot-binary", sys.executable, "--feature", feature])
        self.assertFalse((self.root / "reports").exists())

    def test_default_engine_reads_config_and_override_needs_no_config(self) -> None:
        config = self.root / "docs/methodology-config.json"
        config.parent.mkdir()
        config.write_text(
            '{"engine_executable":"engine folder/Godot.exe"}',
            encoding="utf-8",
        )
        args = runner._parse_args(["--feature", "F001"])
        self.assertEqual(runner._build_command(args, self.root / "reports")[0],
                         str((self.root / "engine folder/Godot.exe").resolve()))
        config.unlink()
        self.assertEqual(runner._parse_args(["--godot-binary", sys.executable]).godot_binary,
                         sys.executable)
        with self.assertRaises(ValueError):
            runner._build_command(runner._parse_args([]), self.root / "reports")

    def test_invalid_configured_engine_is_rejected_before_launch(self) -> None:
        for value in (None, [], {}, 7, "", "   "):
            with self.subTest(value=value), mock.patch.object(
                runner, "read_json", return_value={"engine_executable": value}
            ), self.assertRaises(ValueError):
                runner._build_command(runner._parse_args([]), self.root / "reports")

    def _manual_plan(self) -> dict:
        for command in (
            ["git", "init", "--quiet"],
            ["git", "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
             "commit", "--allow-empty", "--quiet", "-m", "Fixture"],
        ):
            subprocess.run(command, cwd=self.root, check=True, capture_output=True)
        detail = {"id": "F001", "affected_components": ["example"],
                  "acceptance_criteria": [{"id": "AC01", "text": "Inspect appearance",
                      "verification": {"automated_tests": [], "manual_checks": ["Inspect appearance"]}}],
                  "verification": {"acceptance_mode": "manual", "regression_tests": []}}
        path = self.root / "docs/features/F001.json"
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps(detail), encoding="utf-8")
        (self.root / "docs/test-registry.json").write_text(json.dumps({
            "meta": {"schema_version": 3},
            "components": [{"id": "example", "unit_test_paths": [], "full_suite_on_change": False}],
            "tests": [],
        }), encoding="utf-8")
        return detail

    def test_manual_empty_selection_needs_no_engine_or_reports(self) -> None:
        self._manual_plan()
        for scope in ("auto", "required", "affected"):
            output = io.StringIO()
            with self.subTest(scope=scope), redirect_stdout(output), mock.patch.object(runner, "_run_process") as engine:
                self.assertEqual(runner._run_tests(runner._parse_args(
                    ["--feature", "F001", "--scope", scope])), 0)
                engine.assert_not_called()
            self.assertEqual(json.loads(output.getvalue().splitlines()[-1])["status"], "not_required")
        self.assertFalse((self.root / "reports").exists())
        self.assertFalse((self.root / "docs/features/F001-evidence.json").exists())

    def test_empty_final_cannot_hide_failed_run(self) -> None:
        self._manual_plan()
        directory = self.root / "reports/gdunit-wrapper/F001/run-failed"
        directory.mkdir(parents=True)
        result = runner.start_run(self.root, directory, "F001", "final", "affected")
        runner.finish_run(self.root, directory, result, errors=["previous failure"])
        with mock.patch.object(runner, "_run_process") as engine:
            self.assertEqual(runner._run_tests(runner._parse_args(["--feature", "F001"])), 1)
            engine.assert_not_called()

    def test_empty_selection_cannot_skip_explicit_test_or_full_scope(self) -> None:
        self._manual_plan()
        for extra in (["--scope", "full"], ["--require-test", "tests/example.gd::test_case"]):
            with self.subTest(extra=extra), mock.patch.object(runner, "_run_process") as engine:
                self.assertEqual(runner._run_tests(runner._parse_args(["--feature", "F001", *extra])), 1)
                engine.assert_not_called()

    def test_missing_registered_path_is_not_an_empty_selection(self) -> None:
        self._manual_plan()
        path = self.root / "docs/test-registry.json"
        registry = json.loads(path.read_text(encoding="utf-8"))
        registry["components"][0]["unit_test_paths"] = ["tests/missing.gd"]
        path.write_text(json.dumps(registry), encoding="utf-8")
        with mock.patch.object(runner, "_run_process") as engine:
            self.assertEqual(runner._run_tests(runner._parse_args(["--feature", "F001"])), 1)
            engine.assert_not_called()

    def test_planned_automated_tests_can_have_empty_baseline_but_not_final(self) -> None:
        detail = self._manual_plan()
        detail["verification"]["acceptance_mode"] = "automated"
        detail["acceptance_criteria"][0]["verification"] = {
            "automated_tests": ["F001-AC01-01"], "manual_checks": []}
        (self.root / "docs/features/F001.json").write_text(json.dumps(detail), encoding="utf-8")
        path = self.root / "docs/test-registry.json"
        registry = json.loads(path.read_text(encoding="utf-8"))
        registry["tests"] = [{"id": "F001-AC01-01", "status": "planned",
                             "components": ["example"], "path": None, "case": None}]
        path.write_text(json.dumps(registry), encoding="utf-8")
        with mock.patch.object(runner, "_run_process") as engine:
            self.assertEqual(runner._run_tests(runner._parse_args(
                ["--feature", "F001", "--phase", "baseline"])), 0)
            self.assertFalse((self.root / "reports").exists())
            self.assertEqual(runner._run_tests(runner._parse_args(["--feature", "F001"])), 1)
            engine.assert_not_called()

    def test_project_relative_engine_path_preserves_spaces_and_unicode(self) -> None:
        executable = self.root / "engine folder" / "工具.exe"
        executable.parent.mkdir()
        executable.touch()
        args = runner._parse_args(["--godot-binary", executable.relative_to(self.root).as_posix()])
        command = runner._build_command(args, self.root / "reports")
        self.assertEqual(command[0], str(executable.resolve()))

    def test_stdin_is_closed_and_both_streams_are_collected(self) -> None:
        command = [sys.executable, "-c", (
            "import sys; print('stdout', flush=True); "
            "print('stderr', file=sys.stderr, flush=True); "
            "print('stdin_closed=' + str(sys.stdin.read() == ''), flush=True)"
        )]
        log = self.root / "engine.log"
        result = runner._run_process(command, log, 5)
        self.assertEqual(result.returncode, 0)
        self.assertFalse(result.timed_out)
        self.assertEqual(result.output.splitlines(), ["stdout", "stderr", "stdin_closed=True"])
        self.assertEqual(log.read_text(encoding="utf-8"), result.output)

    def test_timeout_reaps_only_the_owned_process_and_preserves_output(self) -> None:
        sentinel = subprocess.Popen(
            [sys.executable, "-c", "import time; time.sleep(30)"],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        try:
            start = time.monotonic()
            result = runner._run_process(
                [sys.executable, "-c", "import time; print('before hang', flush=True); time.sleep(30)"],
                self.root / "engine.log", 0.5,
            )
            self.assertTrue(result.timed_out)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("before hang", result.output)
            self.assertFalse(_pid_is_running(result.pid))
            self.assertLess(time.monotonic() - start, 6)
            self.assertIsNone(sentinel.poll(), "unrelated process must remain alive")
        finally:
            sentinel.kill()
            sentinel.wait(timeout=5)

    def test_timeout_reaps_a_real_child_process_as_well_as_its_launcher(self) -> None:
        program = (
            "import subprocess,sys,time; "
            "child=subprocess.Popen([sys.executable,'-c','import time; time.sleep(30)']); "
            "print('child=' + str(child.pid),flush=True); time.sleep(30)"
        )
        result = runner._run_process(
            [sys.executable, "-c", program], self.root / "tree.log", 1,
        )
        self.assertTrue(result.timed_out)
        self.assertFalse(_pid_is_running(result.pid))
        child_pid = int(result.output.strip().split("child=", 1)[1])
        self.assertFalse(_pid_is_running(child_pid), "owned child survived timeout")

    def test_nonzero_exit_is_collected_even_without_a_timeout(self) -> None:
        result = runner._run_process(
            [sys.executable, "-c", "raise SystemExit(7)"], self.root / "engine.log", 5,
        )
        self.assertEqual(result.returncode, 7)
        self.assertFalse(result.timed_out)

    def test_pre_monitor_error_is_not_hidden_by_runner_banner_or_suite_start(self) -> None:
        output = "GdUnit4 Comandline Tool\nRun Test Suite: res://tests/test_example.gd\n"
        diagnostics = runner._startup_diagnostics(output + ERROR + STARTED)
        self.assertEqual(len(diagnostics), 1)
        self.assertIn("injected startup failure", diagnostics[0])

    def test_started_is_not_evidence_of_a_scoped_diagnostic_match(self) -> None:
        self.assertEqual(len(runner._startup_diagnostics(STARTED + ERROR)), 1)

    def test_suite_and_case_banners_never_disable_native_diagnostics(self) -> None:
        output = STARTED + ERROR + "Run Test Suite: res://tests/test_second.gd\n"
        self.assertEqual(len(runner._startup_diagnostics(output + ERROR + STARTED + ERROR)), 3)

    def test_ansi_cursor_positioning_does_not_hide_diagnostics(self) -> None:
        marker = "\x1b[32mres://tests/test_example.gd > test_case\x1b[20GSTARTED\x1b[0m\n"
        self.assertEqual(len(runner._startup_diagnostics(marker + ERROR)), 1)

    def test_native_parse_error_without_test_start_is_captured(self) -> None:
        output = "SCRIPT ERROR: Parse Error: invalid syntax\n   at: reload (res://broken.gd:4)\n"
        self.assertEqual(len(runner._startup_diagnostics(output)), 1)

    def test_native_warning_before_monitor_is_captured(self) -> None:
        self.assertEqual(len(runner._startup_diagnostics(ERROR.replace("ERROR:", "WARNING:"))), 1)

    def test_multiline_native_diagnostic_keeps_its_source_location(self) -> None:
        output = "ERROR: startup failure\nadditional context\n\n   at: before (res://suite.gd:4)\n"
        self.assertEqual(len(runner._startup_diagnostics(output + STARTED)), 1)

    def test_plain_error_words_are_not_native_diagnostic_records(self) -> None:
        output = "ERROR count in example: 0\nERROR: documentation example\nordinary next line\n"
        self.assertEqual(runner._startup_diagnostics(output + STARTED), [])

    def test_old_junit_outside_the_current_directory_cannot_be_reused(self) -> None:
        old = self.root / "old/report_1"
        old.mkdir(parents=True)
        (old / "results.xml").write_text("<testsuites />", encoding="utf-8")
        current = self.root / "new"
        current.mkdir()
        result = runner.start_run(self.root, current, None, "final", "auto")
        runner.finish_run(self.root, current, result)
        self.assertEqual(result["status"], "failed")
        self.assertIn("expected one current JUnit report, found 0", result["errors"])

    def test_multiple_current_reports_are_rejected(self) -> None:
        for number in (1, 2):
            directory = self.root / f"report_{number}"
            directory.mkdir()
            (directory / "results.xml").write_text("<testsuites />", encoding="utf-8")
        result = runner.start_run(self.root, self.root, None, "final", "auto")
        runner.finish_run(self.root, self.root, result)
        self.assertEqual(result["status"], "failed")
        self.assertIn("expected one current JUnit report, found 2", result["errors"])

if __name__ == "__main__":
    unittest.main()
