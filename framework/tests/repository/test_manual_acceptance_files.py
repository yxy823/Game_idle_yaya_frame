import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[3] / "project-source"
sys.path.insert(0, str(SOURCE))
from tools.lib import feature_completion_evidence as evidence
from tools.lib import verification_snapshot
from tools.lib.manual_acceptance import prepare_checklist, read_checklist

CLI = SOURCE / "tools/features/record-feature-completion.py"


class ManualAcceptanceFileTests(unittest.TestCase):
    def setUp(self):
        area = tempfile.TemporaryDirectory(prefix="yaya-manual-files-")
        self.addCleanup(area.cleanup)
        self.root = Path(area.name)
        self.git("init", "--quiet")
        self.git("config", "user.name", "File contract test")
        self.git("config", "user.email", "test@example.invalid")
        (self.root / "implementation.txt").write_text("version one", encoding="utf-8")
        self.git("add", "implementation.txt")
        self.git("commit", "--quiet", "-m", "Fixture baseline")
        self.detail = {"id": "F001", "affected_components": ["example"], "notes": "",
                       "acceptance_criteria": [{"id": "AC01", "text": "Human judgment",
                           "verification": {"manual_checks": ["Observe appearance", "Listen"], "automated_tests": []}}],
                       "verification": {"acceptance_mode": "manual", "manual_regression": "Repeat the original failure",
                                        "regression_tests": []},
                       "base_revision": subprocess.run(["git", "-C", str(self.root), "rev-parse", "HEAD"], check=True,
                                                       capture_output=True, text=True).stdout.strip()}
        self.write("docs/features/F001.json", self.detail)
        self.write("docs/feature-list.json", {"meta": {}, "features": [
            {"id": "F001", "status": "in_progress", "depends_on": [], "completed_at": None}]})
        self.write("docs/test-registry.json", {"meta": {"schema_version": 4}, "tests": [],
                    "components": [{"id": "example", "unit_test_paths": [], "full_suite_on_change": False,
                                    "source_paths": ["*.gd"]}]})
        self.checklist = self.write_checklist("F001")
        self.evidence_path = self.root / evidence.evidence_relative_path("F001")

    def write_checklist(self, feature):
        return self.write(f"reports/manual-acceptance/{feature}/manual-acceptance-checklist.json", {
            "schema_version": 1, "feature_id": feature, "title": "人工验收", "snapshot": None,
            "tests": [{"id": f"{feature}-M{index:02d}", "source_ref": ref, "title": ref,
                       "steps": ["执行操作", "观察并重置"], "expected_result": "符合预期"}
                      for index, ref in enumerate(("AC01/1", "AC01/2", "manual_regression"), 1)]})

    def git(self, *args):
        result = subprocess.run(["git", "-C", str(self.root), *args], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def write(self, path, value):
        path = self.root / path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value, ensure_ascii=False), encoding="utf-8")
        return path

    def load(self, path):
        return json.loads(path.read_text(encoding="utf-8-sig"))

    def decide(self, status="passed", checklist=None):
        checklist = checklist or self.checklist
        prepare_checklist(self.root, self.load(checklist)["feature_id"], checklist)
        value = self.load(checklist)
        for test in value["tests"]:
            test.update(status=status, comment="来自对话：全部接受")
        self.write(checklist, value)
        return value

    def invoke(self, *args, expected=0):
        environment = os.environ.copy()
        environment["PYTHONPATH"] = str(SOURCE)
        result = subprocess.run([sys.executable, "-B", str(CLI), "--repo-root", str(self.root), *args],
                                capture_output=True, text=True, env=environment)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def record(self, *extra, feature="F001", checklist=None, expected=0):
        return self.invoke("record-acceptance", "--feature", feature, "--checklist", str(checklist or self.checklist),
                           *extra, expected=expected)

    def test_checklist_status_is_the_record_and_preserves_extensions_bom_and_order(self):
        original = verification_snapshot.current_snapshot(self.root)
        value = self.decide()
        value["unrelated_metadata"] = {"version": "custom", "text": "保留"}
        value["tests"][0]["extra"] = "opaque"
        value["tests"].reverse()
        self.checklist.write_text(json.dumps(value, ensure_ascii=False), encoding="utf-8-sig")
        decision = read_checklist(self.root, "F001", self.checklist)
        self.assertEqual(decision["status"], "accepted")
        self.assertEqual(verification_snapshot.current_snapshot(self.root), original)
        self.record()
        stored = self.load(self.evidence_path)
        self.assertEqual(stored["human_acceptance"]["source"],
                         {"checklist": "reports/manual-acceptance/F001/manual-acceptance-checklist.json"})
        self.assertNotIn("unrelated_changes", stored["human_acceptance"])
        self.assertEqual(verification_snapshot.current_snapshot(self.root), original)
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_pending_and_failed_do_not_complete(self):
        value = self.decide()
        for status, expected in (("pending", "pending"), ("failed", "rejected")):
            with self.subTest(status=status):
                value["tests"][0]["status"] = status
                self.write(self.checklist, value)
                self.record()
                self.assertEqual(self.load(self.evidence_path)["human_acceptance"]["status"], expected)
                self.assertFalse(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_definition_identity_and_binding_changes_are_rejected(self):
        original = self.decide()
        mutations = (
            lambda d: d.update(feature_id="F002"),
            lambda d: d.update(title="Different scope"),
            lambda d: d["tests"].pop(),
            lambda d: d["tests"].append({**copy.deepcopy(d["tests"][0]), "id": "F001-M09"}),
            lambda d: d["tests"][0].update(steps=["Different action"]),
            lambda d: d["tests"][0].update(expected_result="Easier outcome"),
            lambda d: d["tests"][0].update(source_ref="AC01/99"),
            lambda d: d["tests"][0].update(status="success"),
            lambda d: d["tests"][0].update(id="new-id"),
            lambda d: d.update(snapshot=None),
            lambda d: d["snapshot"].update(definition_sha256="sha256:other"),
            lambda d: d["snapshot"].pop("uncommitted_paths"),
            lambda d: d["snapshot"].update(uncommitted_paths="implementation.txt"),
        )
        for mutation in mutations:
            value = copy.deepcopy(original)
            mutation(value)
            self.write(self.checklist, value)
            with self.assertRaises((verification_snapshot.EvidenceError, ValueError)):
                read_checklist(self.root, "F001", self.checklist)

    def test_preparation_rejects_incomplete_coverage_and_rebinding(self):
        original = self.load(self.checklist)
        invalid = copy.deepcopy(original)
        invalid["tests"].pop()
        self.write(self.checklist, invalid)
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "missing manual obligations"):
            prepare_checklist(self.root, "F001", self.checklist)
        self.write(self.checklist, original)
        self.invoke("prepare-manual", "--feature", "F001", "--checklist", str(self.checklist))
        self.assertIn("definition_sha256", self.load(self.checklist)["snapshot"])
        before = self.checklist.read_bytes()
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "already bound"):
            prepare_checklist(self.root, "F001", self.checklist)
        self.assertEqual(self.checklist.read_bytes(), before)

    def test_changes_after_binding_need_explicit_confirmation_and_are_recorded(self):
        self.decide()
        (self.root / "other_feature.gd").write_text("extends Node", encoding="utf-8")
        result = self.record(expected=2)
        self.assertIn("other_feature.gd", result.stderr)
        self.assertFalse(self.evidence_path.exists())
        self.record("--confirm-unrelated-changes")
        acceptance = self.load(self.evidence_path)["human_acceptance"]
        self.assertEqual(acceptance["status"], "accepted")
        self.assertIn("other_feature.gd", acceptance["unrelated_changes"])
        self.assertNotEqual(acceptance["bound_fingerprint"], acceptance["working_tree_fingerprint"])
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])
        (self.root / "implementation.txt").write_text("version two", encoding="utf-8")
        self.assertFalse(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_reverted_uncommitted_input_needs_confirmation_and_is_recorded(self):
        implementation = self.root / "implementation.txt"
        implementation.write_text("version two", encoding="utf-8")
        value = self.decide()
        self.assertIn("implementation.txt", value["snapshot"]["uncommitted_paths"])
        implementation.write_text("version one", encoding="utf-8")
        result = self.record(expected=2)
        self.assertIn("implementation.txt", result.stderr)
        self.assertFalse(self.evidence_path.exists())
        self.record("--confirm-unrelated-changes")
        acceptance = self.load(self.evidence_path)["human_acceptance"]
        self.assertEqual(acceptance["status"], "accepted")
        self.assertIn("implementation.txt", acceptance["unrelated_changes"])

    def test_deleted_untracked_input_needs_confirmation_and_is_recorded(self):
        untracked = self.root / "other_feature.gd"
        untracked.write_text("extends Node", encoding="utf-8")
        value = self.decide()
        self.assertIn("other_feature.gd", value["snapshot"]["uncommitted_paths"])
        untracked.unlink()
        result = self.record(expected=2)
        self.assertIn("other_feature.gd", result.stderr)
        self.assertFalse(self.evidence_path.exists())
        self.record("--confirm-unrelated-changes")
        acceptance = self.load(self.evidence_path)["human_acceptance"]
        self.assertEqual(acceptance["status"], "accepted")
        self.assertIn("other_feature.gd", acceptance["unrelated_changes"])

    def test_content_identical_commit_and_usage_readme_preserve_acceptance(self):
        self.decide()
        (self.root / "README.md").write_text("Usage", encoding="utf-8")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "fixture")
        self.record()
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_acceptance_survives_staging_and_committing_source_deletion(self):
        implementation = self.root / "implementation.txt"
        implementation.unlink()
        self.decide()
        self.record()
        self.git("add", "implementation.txt")
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])
        self.git("commit", "--quiet", "-m", "Fixture accepted deletion")
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])
        implementation.write_text("restored source", encoding="utf-8")
        self.assertFalse(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_completion_rereads_checklist_and_blocks_later_failure_edit_or_missing_file(self):
        value = self.decide()
        self.record()
        for mutate in (lambda d: d["tests"][0].update(status="failed"),
                       lambda d: d["tests"][0].update(steps=["Changed after acceptance"])):
            changed = copy.deepcopy(value)
            mutate(changed)
            self.write(self.checklist, changed)
            self.assertFalse(evidence.validate_completion_evidence(self.root, "F001")[0])
        self.write(self.checklist, value)
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])
        self.checklist.unlink()
        self.assertFalse(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_repeated_recording_warns_without_failing(self):
        self.decide()
        self.record()
        self.assertIn("already recorded", self.record().stderr)

    def test_invalid_existing_evidence_is_not_reset_by_recording(self):
        self.decide()
        valid = evidence.empty_evidence("F001", verification_snapshot.current_snapshot(self.root))
        self.evidence_path.parent.mkdir(parents=True, exist_ok=True)
        for content in ("{broken", "[]", json.dumps({**valid, "schema_version": 0}),
                        json.dumps({**valid, "feature_id": "F002"}),
                        json.dumps({**valid, "test_runs": None})):
            with self.subTest(content=content):
                self.evidence_path.write_text(content, encoding="utf-8")
                before = self.evidence_path.read_bytes()
                self.record(expected=2)
                self.assertEqual(self.evidence_path.read_bytes(), before)

    def test_each_feature_keeps_its_own_evidence(self):
        self.decide()
        self.record()
        self.write("docs/features/F002.json", {**self.detail, "id": "F002"})
        second = self.write_checklist("F002")
        self.decide("failed", checklist=second)
        self.record(feature="F002", checklist=second)
        self.assertEqual(self.load(self.root / evidence.evidence_relative_path("F002"))["human_acceptance"]["status"],
                         "rejected")
        self.assertEqual(self.load(self.evidence_path)["human_acceptance"]["status"], "accepted")
        self.assertEqual(self.load(self.evidence_path)["feature_id"], "F001")

    def test_checklists_outside_report_directory_are_rejected(self):
        self.decide()
        outside = tempfile.TemporaryDirectory(prefix="yaya-manual-outside-")
        self.addCleanup(outside.cleanup)
        for directory in (self.root / "reports/other", Path(outside.name)):
            with self.subTest(directory=directory):
                misplaced = self.write(directory / self.checklist.name, self.load(self.checklist))
                with self.assertRaisesRegex(verification_snapshot.EvidenceError,
                                            "^manual acceptance files must be JSON under reports/manual-acceptance$"):
                    read_checklist(self.root, "F001", misplaced)

    def test_automated_mode_cannot_reuse_manual_checklist(self):
        self.decide()
        self.detail["verification"].update(acceptance_mode="automated", manual_regression=None)
        self.detail["acceptance_criteria"][0]["verification"].update(manual_checks=[], automated_tests=["F001-AC01"])
        self.write("docs/features/F001.json", self.detail)
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "manual Feature"):
            read_checklist(self.root, "F001", self.checklist)

    def test_multiple_cases_per_obligation_are_supported_without_presupplied_success(self):
        value = self.load(self.checklist)
        extra = copy.deepcopy(value["tests"][0])
        extra["id"] = "F001-M04"
        value["tests"].append(extra)
        value["tests"][0]["status"] = "passed"
        self.write(self.checklist, value)
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "only pending"):
            prepare_checklist(self.root, "F001", self.checklist)
        value["tests"][0]["status"] = "pending"
        self.write(self.checklist, value)
        self.decide()
        self.assertEqual(read_checklist(self.root, "F001", self.checklist)["status"], "accepted")

    def test_non_json_numeric_constants_are_rejected(self):
        self.decide()
        text = self.checklist.read_text(encoding="utf-8")
        self.checklist.write_text(text[:-1] + ', "extra": NaN}', encoding="utf-8")
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "invalid JSON number"):
            read_checklist(self.root, "F001", self.checklist)


if __name__ == "__main__":
    unittest.main()
