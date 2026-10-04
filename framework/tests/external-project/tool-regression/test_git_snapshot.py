"""Project verification binds to a real commit and current source content."""
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import json
import os
import subprocess
import tempfile
import unittest

TOOLS = (PROJECT_ROOT / "tools")
sys.path.insert(0, str(PROJECT_ROOT))
from tools.lib import feature_completion_evidence, verification_snapshot
from tools.lib.atomic_json import write_json
from gdunit_report_fixture import make_run
from tools.lib.test_run_evidence import derive_test_evidence, result_reference
from tools.lib.test_run_evidence import RunEvidenceError


class GitSnapshotTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="yaya-git-snapshot-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.git("init", "--initial-branch=bootstrap")
        self.git("config", "user.name", "Git Snapshot Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "core.autocrlf", "false")
        self.write(".gitignore", "reports/\n")
        self.write("source.gd", "extends RefCounted\n")
        self.git("add", ".gitignore", "source.gd")
        self.git("commit", "-m", "Fixture baseline")

    def git(self, *arguments: str) -> str:
        result = subprocess.run(["git", "-C", str(self.root), *arguments],
                                capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(0, result.returncode, result.stderr)
        return result.stdout.strip()

    def write(self, name: str, value: str | dict) -> None:
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        text = value if isinstance(value, str) else json.dumps(value)
        path.write_text(text, encoding="utf-8", newline="\n")

    def plan_fixture(self) -> None:
        self.write("tests/unit/test_contract.gd",
                   "extends GdUnitTestSuite\nfunc test_contract():\n\tpass\n")
        self.write("docs/methodology-config.json", {"python_executable": sys.executable,
                   "engine_executable": sys.executable})
        self.write("docs/features/F001.json", {"id": "F001", "affected_components": ["contract"],
                   "acceptance_criteria": [{"id": "AC01", "text": "Preserve the contract",
                       "verification": {"automated_tests": [], "manual_checks": ["Review the contract"]}}],
                   "verification": {"acceptance_mode": "manual", "regression_tests": [], "manual_regression": None}})
        self.write("docs/feature-list.json", {"meta": {}, "features": [
                   {"id": "F001", "status": "in_progress", "depends_on": [], "completed_at": None}]})
        self.write("docs/test-registry.json", {"meta": {"schema_version": 3}, "components": [
                   {"id": "contract", "unit_test_paths": ["tests/unit"], "full_suite_on_change": True}],
                   "tests": []})

    def test_snapshot_tracks_commit_and_hashes_untracked_source(self) -> None:
        self.write("new.gd", "extends RefCounted\n")
        before = verification_snapshot.current_snapshot(self.root)
        self.assertEqual(self.git("rev-parse", "HEAD"), before["git_revision"])
        self.assertEqual(before, verification_snapshot.current_snapshot(self.root))
        self.git("add", "new.gd")
        self.assertEqual(before, verification_snapshot.current_snapshot(self.root))
        self.write("source.gd", "extends RefCounted\nvar changed = true\n")
        self.assertNotEqual(before["working_tree_fingerprint"],
                            verification_snapshot.current_snapshot(self.root)["working_tree_fingerprint"])

    def test_source_deletion_and_rename_change_content_only_once(self) -> None:
        for destination in (None, "renamed.gd"):
            with self.subTest(destination=destination):
                source = self.root / "source.gd"
                before = verification_snapshot.working_tree_fingerprint(self.root)
                if destination is None:
                    source.unlink()
                else:
                    source.rename(self.root / destination)
                changed = verification_snapshot.working_tree_fingerprint(self.root)
                self.assertNotEqual(before, changed)
                paths = ["source.gd"] + ([destination] if destination else [])
                self.git("add", *paths)
                self.assertEqual(changed, verification_snapshot.working_tree_fingerprint(self.root))
                self.git("commit", "-m", "Fixture source removal")
                self.assertEqual(changed, verification_snapshot.working_tree_fingerprint(self.root))
                self.write("source.gd", "extends RefCounted\n")
                self.git("add", "source.gd")
                self.git("commit", "-m", "Fixture restored source")

    def test_recorded_run_survives_staging_a_source_deletion(self) -> None:
        self.plan_fixture()
        before = verification_snapshot.working_tree_fingerprint(self.root)
        (self.root / "source.gd").unlink()
        self.assertNotEqual(before, verification_snapshot.working_tree_fingerprint(self.root))
        _plan, manifest = make_run(self.root)
        references = [result_reference(self.root, manifest)]
        verified = derive_test_evidence(self.root, "F001", references)
        self.git("add", "source.gd")
        self.assertEqual(verified, derive_test_evidence(self.root, "F001", references))
        self.git("commit", "-m", "Fixture verified deletion")
        after = derive_test_evidence(self.root, "F001", references)
        for scope, result in verified.items():
            self.assertEqual(result["working_tree_fingerprint"], after[scope]["working_tree_fingerprint"])
            self.assertEqual(result["run_ids"], after[scope]["run_ids"])
        self.write("source.gd", "extends RefCounted\n")
        with self.assertRaisesRegex(RunEvidenceError, "source changed"):
            derive_test_evidence(self.root, "F001", references)

    def test_run_survives_content_identical_commits_without_granting_acceptance(self) -> None:
        self.plan_fixture()
        plan, manifest = make_run(self.root)
        references = [result_reference(self.root, manifest)]
        verified = derive_test_evidence(self.root, "F001", references)
        evidence = feature_completion_evidence.empty_evidence("F001", verification_snapshot.current_snapshot(self.root))
        evidence.update(test_runs=references, **verified)
        write_json(self.root / feature_completion_evidence.evidence_relative_path("F001"), evidence)
        task_files = [".gitignore", "source.gd", "tests", "docs"]
        self.git("add", *task_files)
        self.git("commit", "-m", "Fixture verified changes")
        self.assertEqual(self.git("rev-parse", "HEAD"), verification_snapshot.git_revision(self.root))
        self.assertEqual(verified["required_test_set"]["total"],
                         derive_test_evidence(self.root, "F001", references)["required_test_set"]["total"])
        accepted, reason = feature_completion_evidence.validate_completion_evidence(self.root, "F001")
        self.assertFalse(accepted)
        self.assertIn("explicit human acceptance", reason)
        self.write("docs/progress/bootstrap.md", "Initial verification is archived here.\n")
        self.git("add", "docs/progress/bootstrap.md")
        self.git("commit", "-m", "Fixture process history only")
        after_commit = derive_test_evidence(self.root, "F001", references)
        for scope, result in verified.items():
            # 当前 Git 提交可变化；相同内容下，测试结论、用例与运行引用必须保持。
            self.assertEqual(after_commit[scope]["git_revision"], verification_snapshot.git_revision(self.root))
            self.assertEqual({key: value for key, value in result.items() if key != "git_revision"},
                             {key: value for key, value in after_commit[scope].items() if key != "git_revision"})
        self.write("source.gd", "extends RefCounted\nvar changed = true\n")
        with self.assertRaisesRegex(RunEvidenceError, "source changed"):
            derive_test_evidence(self.root, "F001", references)

    def test_missing_repository_or_initial_commit_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory(prefix="yaya-not-repo-") as unrelated:
            with self.assertRaises(verification_snapshot.EvidenceError):
                verification_snapshot.current_snapshot(Path(unrelated))
            subprocess.run(["git", "init", "--template=", unrelated], check=True, capture_output=True)
            with self.assertRaises(verification_snapshot.EvidenceError):
                verification_snapshot.current_snapshot(Path(unrelated))

    def test_corrupt_or_dangling_head_is_rejected(self) -> None:
        for content in ("invalid HEAD\n", "f" * 40 + "\n"):
            with self.subTest(content=content):
                self.write(".git/HEAD", content)
                with self.assertRaises(verification_snapshot.EvidenceError):
                    verification_snapshot.current_snapshot(self.root)

    def test_broken_branch_ref_is_rejected(self) -> None:
        for content in ("not-an-object-id\n", "f" * 40 + "\n"):
            with self.subTest(content=content):
                self.write(".git/refs/heads/bootstrap", content)
                with self.assertRaises(verification_snapshot.EvidenceError):
                    verification_snapshot.current_snapshot(self.root)


if __name__ == "__main__":
    unittest.main()
