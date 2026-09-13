"""Preserve failed and unfinished runs without a second journal or lock."""
from project_context import PROJECT_ROOT
import importlib.util
import json
import sys
import unittest
from unittest import mock

import test_feature_completion_evidence as fixtures
from gdunit_report_fixture import make_run
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

    def test_invalid_history_leaves_a_failed_result_without_launching_or_hiding_the_error(self):
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
                with mock.patch.object(runner, "REPO_ROOT", self.root), \
                        mock.patch.object(runner, "_run_process") as launch:
                    self.assertEqual(runner._run_tests(args), 1)
                launch.assert_not_called()
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
                self.assertTrue(any(str(damaged) in error for error in result["errors"]))
                self.assertEqual(damaged.read_text(encoding="utf-8"), payload)
                self.assertEqual(old_pass.read_bytes(), old_bytes)
                with self.assertRaises(ValueError) as failure:
                    self.derive(plan, old_pass)
                self.assertIn(str(damaged), str(failure.exception))

    def test_snapshot_error_is_kept_in_the_current_failed_result(self):
        directory = self.root / "reports/gdunit-wrapper/run-snapshot-error"
        directory.mkdir(parents=True)
        with mock.patch("tools.lib.test_run_evidence.current_snapshot",
                        side_effect=ValueError("snapshot unavailable")):
            result = start_run(self.root, directory, "F001", "final", "full")
        self.assertEqual(result["status"], "failed")
        self.assertIsNone(result["snapshot"])
        self.assertEqual(result["errors"], ["snapshot unavailable"])
        self.assertEqual(json.loads((directory / "result.json").read_text()), result)

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
