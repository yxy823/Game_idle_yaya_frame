"""Preserve failed and unfinished runs without a second journal or lock."""
from project_context import PROJECT_ROOT
from contextlib import redirect_stderr
import importlib.util
import io
import json
import sys
import unittest
from unittest import mock

import test_feature_completion_evidence as fixtures
from gdunit_report_fixture import make_run
from tools.lib.feature_completion_evidence import EvidenceError
from tools.lib.test_run_evidence import derive_test_evidence, result_reference, start_run


class ExecutionRecoveryTests(unittest.TestCase):
    setUp = fixtures.FeatureCompletionEvidenceTests.setUp
    write = fixtures.FeatureCompletionEvidenceTests.write
    write_json = fixtures.FeatureCompletionEvidenceTests.write_json
    git = fixtures.FeatureCompletionEvidenceTests.git

    def derive(self, plan, path):
        return derive_test_evidence(self.root, "F001", [result_reference(self.root, path)])

    def test_later_failed_full_cannot_hide_behind_old_green_or_new_narrow_green(self):
        plan, old_pass = make_run(self.root)
        self.derive(plan, old_pass)
        _, failed = make_run(self.root, exit_code=7)
        with self.assertRaisesRegex(ValueError, "unresolved failed or unfinished"):
            self.derive(plan, old_pass)
        _, narrow = make_run(self.root, scope="required")
        with self.assertRaisesRegex(ValueError, "unresolved failed or unfinished"):
            derive_test_evidence(self.root, "F001",
                                 [result_reference(self.root, old_pass), result_reference(self.root, narrow)])
        # A controlled recovery case, not a production retry to conceal a failure.
        _, repaired = make_run(self.root)
        self.derive(plan, repaired)
        self.assertTrue(failed.is_file())

    def test_baseline_failure_does_not_replace_final_obligations(self):
        plan, passed = make_run(self.root)
        make_run(self.root, phase="baseline", exit_code=7)
        self.derive(plan, passed)


    def test_interruption_leaves_one_running_result_that_blocks_old_success(self):
        plan, passed = make_run(self.root)
        directory = self.root / "reports/gdunit-wrapper/run-interrupted"
        directory.mkdir()
        start_run(self.root, directory, "F001", "final", "full")
        with self.assertRaisesRegex(ValueError, "unresolved failed or unfinished"):
            self.derive(plan, passed)
        record = json.loads((directory / "result.json").read_text())
        self.assertEqual(record["status"], "running")
        self.assertEqual(list(directory.iterdir()), [directory / "result.json"])

    def test_missing_executable_is_recorded_before_preflight_and_blocks_old_pass(self):
        plan, passed = make_run(self.root)
        spec = importlib.util.spec_from_file_location("attempt_runner", PROJECT_ROOT / "tools/testing/run-gdunit-tests.py")
        runner = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = runner
        spec.loader.exec_module(runner)
        args = runner._parse_args(["--godot-binary", str(self.root / "missing.exe"),
                                   "--feature", "F001", "--scope", "full"])
        with mock.patch.object(runner, "REPO_ROOT", self.root):
            self.assertEqual(runner._run_tests(args), 1)
        with self.assertRaisesRegex(ValueError, "unresolved failed or unfinished"):
            self.derive(plan, passed)
        records = [json.loads(path.read_text()) for path in
                   (self.root / "reports/gdunit-wrapper").glob("run-*/result.json")]
        latest = max(records, key=lambda record: record["sequence"])
        self.assertEqual(latest["status"], "failed")
        self.assertTrue(any("executable not found" in error for error in latest["errors"]))

    def test_invalid_history_warns_without_blocking_launch_or_hiding_current_failure(self):
        self.write("tools/testing/gdunit_evidence_runner.gd", "extends SceneTree\n")
        plan, old_pass = make_run(self.root)
        old_bytes = old_pass.read_bytes()
        history = json.loads(old_bytes)
        history.update(run_id="run-damaged", sequence=2)
        damaged = self.write_json("reports/gdunit-wrapper/run-damaged/result.json", history)
        missing_sequence = {key: value for key, value in history.items() if key != "sequence"}
        payloads = ["{", "[]", json.dumps(missing_sequence),
                    json.dumps({**history, "schema_version": 99}),
                    json.dumps({**history, "run_id": "run-other"})]
        payloads.extend(json.dumps({**history, "sequence": value})
                        for value in (None, True, 0, -1, "2"))
        spec = importlib.util.spec_from_file_location("history_runner", PROJECT_ROOT / "tools/testing/run-gdunit-tests.py")
        runner = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = runner
        spec.loader.exec_module(runner)

        for payload in payloads:
            with self.subTest(payload=payload):
                damaged.write_text(payload, encoding="utf-8")
                previous = set((self.root / "reports/gdunit-wrapper").glob("run-*/result.json"))
                sequence = max(json.loads(path.read_text())["sequence"]
                               for path in previous if path != damaged) + 1
                args = runner._parse_args(["--godot-binary", sys.executable,
                                          "--feature", "F001", "--scope", "full"])
                warnings = io.StringIO()
                with redirect_stderr(warnings), mock.patch.object(runner, "REPO_ROOT", self.root), \
                        mock.patch.object(runner, "_run_process",
                                          side_effect=RuntimeError("current launch failed")) as launch:
                    self.assertEqual(runner._run_tests(args), 1)
                launch.assert_called_once()
                self.assertIn("WARNING: invalid run history", warnings.getvalue())
                self.assertIn(str(damaged), warnings.getvalue())
                created = set((self.root / "reports/gdunit-wrapper").glob("run-*/result.json")) - previous
                self.assertEqual(len(created), 1)
                result_path = created.pop()
                result = json.loads(result_path.read_text())
                self.assertEqual(result["status"], "failed")
                self.assertEqual(result["sequence"], sequence)
                self.assertEqual(result["run_id"], result_path.parent.name)
                self.assertIsNotNone(result["finished_at"])
                self.assertIsNone(result["process"])
                self.assertEqual(result["artifacts"], {})
                self.assertIn("current launch failed", result["errors"])
                self.assertFalse(any("invalid run history" in error for error in result["errors"]))
                self.assertEqual(damaged.read_text(encoding="utf-8"), payload)
                self.assertEqual(old_pass.read_bytes(), old_bytes)
                with self.assertRaises(ValueError) as failure:
                    self.derive(plan, old_pass)
                self.assertIn(str(damaged), str(failure.exception))

    def test_unreadable_history_allows_new_pass_but_not_completion(self):
        self.write("reports/gdunit-wrapper/run-damaged/result.json", "{")
        with redirect_stderr(io.StringIO()) as warnings:
            plan, passed = make_run(self.root)
        self.assertIn("invalid run history", warnings.getvalue())
        self.assertEqual(json.loads(passed.read_text())["status"], "passed")
        with self.assertRaisesRegex(ValueError, "invalid run history"):
            self.derive(plan, passed)
        self.assertEqual((self.root / "reports/gdunit-wrapper/run-damaged/result.json").read_text(), "{")

    def test_other_feature_bad_sequence_does_not_block_current_completion(self):
        plan, old_pass = make_run(self.root)
        record = json.loads(old_pass.read_text())
        record.update(run_id="run-other-feature", feature_id="F002", sequence=None)
        damaged = self.write_json("reports/gdunit-wrapper/run-other-feature/result.json", record)
        original = damaged.read_bytes()
        with redirect_stderr(io.StringIO()) as warnings:
            _, passed = make_run(self.root)
        self.assertIn("invalid run history", warnings.getvalue())
        self.derive(plan, passed)
        self.assertEqual(damaged.read_bytes(), original)
        with self.assertRaises(ValueError):
            derive_test_evidence(self.root, "F001", [result_reference(self.root, damaged)])
        for invalid in ({"schema_version": 99}, {"run_id": "run-wrong"}, {"feature_id": "unknown"}):
            with self.subTest(invalid=invalid):
                damaged.write_text(json.dumps({**record, **invalid}), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "invalid run history"):
                    self.derive(plan, passed)

    def test_snapshot_error_is_kept_in_the_current_failed_result(self):
        directory = self.root / "reports/gdunit-wrapper/run-snapshot-error"
        directory.mkdir(parents=True)
        with mock.patch("tools.lib.test_run_evidence.current_snapshot",
                        side_effect=EvidenceError("snapshot unavailable")):
            result = start_run(self.root, directory, "F001", "final", "full")
        self.assertEqual(result["status"], "failed")
        self.assertIsNone(result["snapshot"])
        self.assertEqual(result["errors"], ["snapshot unavailable"])
        self.assertEqual(json.loads((directory / "result.json").read_text()), result)

    def test_snapshot_error_stops_runner_before_launch(self):
        spec = importlib.util.spec_from_file_location("snapshot_runner", PROJECT_ROOT / "tools/testing/run-gdunit-tests.py")
        runner = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = runner
        spec.loader.exec_module(runner)
        args = runner._parse_args(["--godot-binary", sys.executable, "--feature", "F001"])
        with mock.patch.object(runner, "REPO_ROOT", self.root), \
                mock.patch.object(runner, "_run_process") as launch, \
                mock.patch("tools.lib.test_run_evidence.current_snapshot",
                           side_effect=EvidenceError("git read failed")):
            self.assertEqual(runner._run_tests(args), 1)
        launch.assert_not_called()
        paths = list((self.root / "reports/gdunit-wrapper").glob("run-*/result.json"))
        self.assertEqual(len(paths), 1)
        result = json.loads(paths[0].read_text())
        self.assertEqual(result["status"], "failed")
        self.assertEqual(result["errors"], ["git read failed"])
        self.assertIsNotNone(result["finished_at"])

    def test_finish_snapshot_error_finalizes_result_and_preserves_raw_reports(self):
        _, previous = make_run(self.root)
        snapshot = json.loads(previous.read_text())["snapshot"]
        with mock.patch("tools.lib.test_run_evidence.current_snapshot",
                        side_effect=[snapshot, EvidenceError("git read failed at finish")]):
            _, path = make_run(self.root)
        result = json.loads(path.read_text())
        self.assertEqual(result["status"], "failed")
        self.assertEqual(result["errors"], ["git read failed at finish"])
        self.assertIsNotNone(result["finished_at"])
        self.assertEqual(set(result["artifacts"]), {"junit", "discovery", "diagnostics", "engine_log"})
        for reference in result["artifacts"].values():
            artifact = path.parent / reference["path"]
            self.assertEqual(result_reference(path.parent, artifact), reference)
        self.assertEqual(result["process"]["returncode"], 0)

    def test_snapshot_failure_does_not_hide_result_write_failure(self):
        directory = self.root / "reports/gdunit-wrapper/run-write-error"
        with mock.patch("tools.lib.test_run_evidence.current_snapshot",
                        side_effect=EvidenceError("snapshot unavailable")), \
                mock.patch("tools.lib.test_run_evidence.write_evidence",
                           side_effect=OSError("report directory not writable")):
            with self.assertRaisesRegex(OSError, "report directory not writable"):
                start_run(self.root, directory, "F001", "final", "auto")

    def test_concurrent_sequence_tie_cannot_clear_an_unresolved_failure(self):
        plan, old_pass = make_run(self.root)
        _, failed = make_run(self.root, exit_code=7)
        _, candidate = make_run(self.root)
        failure = json.loads(failed.read_text())
        result = json.loads(candidate.read_text())
        result["sequence"] = failure["sequence"]
        candidate.write_text(json.dumps(result), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "unresolved failed or unfinished"):
            self.derive(plan, candidate)
        self.assertTrue(old_pass.is_file())
        self.assertTrue(failed.is_file())


if __name__ == "__main__":
    unittest.main()
