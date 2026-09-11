"""Regression for final failures, Windows process ownership and interrupted leases."""
# 恢复回归覆盖后续失败、中断和 Windows 进程归属；执行时会创建受控子进程。
from project_context import PROJECT_ROOT
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest import mock
import uuid

import test_framework_evidence as fixtures
from evidence_fixture import make_run
from tools.lib.execution_attempts import attempt, journal_path, read_journal
from tools.lib.run_evidence import derive_test_evidence, manifest_reference


class ExecutionRecoveryTests(unittest.TestCase):
    setUp = fixtures.FrameworkEvidenceTests.setUp
    write = fixtures.FrameworkEvidenceTests.write
    write_json = fixtures.FrameworkEvidenceTests.write_json
    git = fixtures.FrameworkEvidenceTests.git

    def derive(self, plan, path):
        return derive_test_evidence(self.root, "F001", [manifest_reference(self.root, path)])

    def test_later_failed_full_cannot_hide_behind_old_green_or_new_narrow_green(self):
        plan, old_pass = make_run(self.root)
        self.derive(plan, old_pass)
        _, failed = make_run(self.root, exit_code=7)
        with self.assertRaisesRegex(ValueError, "newer failed or unfinished"):
            self.derive(plan, old_pass)
        _, narrow = make_run(self.root, scope="required")
        with self.assertRaisesRegex(ValueError, "newer failed or unfinished"):
            derive_test_evidence(self.root, "F001",
                                 [manifest_reference(self.root, old_pass), manifest_reference(self.root, narrow)])
        # A controlled recovery case, not a production retry to conceal a failure.
        _, repaired = make_run(self.root)
        self.derive(plan, repaired)
        self.assertTrue(failed.is_file())

    def test_baseline_failure_does_not_replace_final_obligations(self):
        plan, passed = make_run(self.root)
        make_run(self.root, phase="baseline", exit_code=7)
        self.derive(plan, passed)

    def test_broader_selection_failure_cannot_hide_behind_old_success(self):
        from tools.lib.test_selection import build_selection
        plan, passed = make_run(self.root)
        other_plan = build_selection(self.root, "F001")
        with attempt(self.root, "tests", self.root / "reports/run-other-plan", selection=other_plan, scope="full"):
            pass
        with self.assertRaisesRegex(ValueError, "newer failed or unfinished"):
            self.derive(plan, passed)

    def test_missing_selection_is_still_an_unresolved_attempt(self):
        plan, passed = make_run(self.root)
        with attempt(self.root, "tests", self.root / "reports/run-bad-plan", selection={"full_suite": None}, scope="full"):
            pass
        with self.assertRaisesRegex(ValueError, "newer failed or unfinished"):
            self.derive(plan, passed)

    def test_missing_executable_is_registered_before_preflight_and_blocks_old_pass(self):
        plan, passed = make_run(self.root)
        spec = importlib.util.spec_from_file_location("attempt_runner", PROJECT_ROOT / "tools/testing/run-gdunit-tests.py")
        runner = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = runner
        spec.loader.exec_module(runner)
        args = runner._parse_args(["--godot-binary", str(self.root / "missing.exe"),
                                   "--feature", "F001"])
        with mock.patch.object(runner, "REPO_ROOT", self.root):
            self.assertEqual(runner._run_tests(args), 2)
        with self.assertRaisesRegex(ValueError, "newer failed or unfinished"):
            self.derive(plan, passed)
        latest = read_journal(journal_path(self.root))[-1]
        self.assertTrue((self.root / latest["directory"] / "startup-failure.txt").is_file())

    def test_missing_report_after_interruption_and_journal_tamper_fail_closed(self):
        plan, passed = make_run(self.root)
        directory = self.root / "reports" / ("run-" + uuid.uuid4().hex)
        directory.mkdir()
        with attempt(self.root, "tests", directory, selection=plan, scope="full"):
            with self.assertRaisesRegex(ValueError, "newer failed or unfinished"):
                self.derive(plan, passed)
        path = journal_path(self.root)
        data = json.loads(path.read_text())
        data["records"][-1]["scope"] = "required"
        path.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError, "order/hash"):
            self.derive(plan, passed)

    def test_os_releases_hard_killed_owner_without_deleting_lock_or_failure(self):
        directory = self.root / "reports/run-interrupted"
        directory.mkdir(parents=True)
        program = (
            "import sys; from pathlib import Path; sys.path.insert(0,sys.argv[1]); "
            "from tools.lib.execution_attempts import attempt; "
            "lease=attempt(Path(sys.argv[2]),'static',Path(sys.argv[3])); "
            "lease.__enter__(); print('LOCKED',flush=True); sys.stdin.read()")
        child = subprocess.Popen([sys.executable, "-B", "-c", program, str(PROJECT_ROOT),
                                  str(self.root), str(directory)], stdin=subprocess.PIPE,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                                 creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            self.assertEqual(child.stdout.readline().strip(), "LOCKED")
            with self.assertRaisesRegex(ValueError, "holds the project lease"):
                with attempt(self.root, "static", self.root / "reports/run-competing"):
                    self.fail("Concurrent execution acquired an active lease")
            child.kill()
            child.communicate(timeout=5)
            with attempt(self.root, "static", self.root / "reports/run-recovery"):
                pass
            records = read_journal(journal_path(self.root))
            self.assertEqual([r["run_id"] for r in records], ["run-interrupted", "run-recovery"])
            self.assertTrue(journal_path(self.root).with_suffix(".lock").exists())
        finally:
            if child.poll() is None:
                child.kill()
            child.communicate(timeout=5)



if __name__ == "__main__":
    unittest.main()
