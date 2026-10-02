"""Neutral Git fixtures for manual file exchange; no game or human test execution."""
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[2] / "project-source"
sys.path.insert(0, str(SOURCE))
from tools.lib import feature_completion_evidence as evidence
from tools.lib import verification_snapshot
from tools.lib.manual_acceptance import prepare_checklist, read_result

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
                                        "regression_tests": []}}
        self.write("docs/features/F001.json", self.detail)
        self.write("docs/test-registry.json", {"meta": {"schema_version": 3}, "tests": [],
                    "components": [{"id": "example", "unit_test_paths": [], "full_suite_on_change": False}]})
        self.checklist = self.write("reports/manual-acceptance/F001/manual-acceptance-checklist.json", {
            "schema_version": 1, "feature_id": "F001", "title": "人工验收", "snapshot": None,
            "tests": [{"id": f"F001-M{index:02d}", "source_ref": ref, "title": ref,
                       "steps": ["执行操作", "观察并重置"], "expected_result": "符合预期"}
                      for index, ref in enumerate(("AC01/1", "AC01/2", "manual_regression"), 1)]})
        self.result = self.checklist.with_name("manual-acceptance-checklist.result.json")

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

    def prepared_result(self, status="passed"):
        prepare_checklist(self.root, "F001", self.checklist)
        value = self.load(self.checklist)
        for test in value["tests"]:
            test.update(status=status, comment="实际观察")
        self.write(self.result, value)
        return value

    def invoke(self, *args, expected=0):
        environment = os.environ.copy()
        environment["PYTHONPATH"] = str(SOURCE)
        result = subprocess.run([sys.executable, "-B", str(CLI), "--repo-root", str(self.root), *args],
                                capture_output=True, text=True, env=environment)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def record_file(self):
        return self.invoke("record-acceptance", "--feature", "F001", "--checklist", str(self.checklist), "--result", str(self.result))

    def test_roundtrip_preserves_extensions_defaults_bom_and_id_matching(self):
        original = verification_snapshot.current_snapshot(self.root)
        value = self.prepared_result()
        value["unrelated_metadata"] = {"version": "custom", "text": "保留"}
        value["tests"][0]["extra"] = "opaque"
        value["tests"].reverse()
        self.result.write_text(json.dumps(value, ensure_ascii=False), encoding="utf-8-sig")
        decision = read_result(self.root, "F001", self.checklist, self.result)
        self.assertEqual(decision["status"], "accepted")
        self.assertEqual(verification_snapshot.current_snapshot(self.root), original)
        self.record_file()
        stored = self.load(self.root / "docs/feature-completion-evidence.json")
        self.assertEqual(stored["human_acceptance"]["git_revision"], original["git_revision"])
        self.assertNotIn("tests", stored["human_acceptance"])
        self.assertEqual(self.load(self.result)["unrelated_metadata"], value["unrelated_metadata"])
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_pending_and_failed_do_not_complete(self):
        value = self.prepared_result()
        for status, expected in (("pending", "pending"), ("failed", "rejected")):
            with self.subTest(status=status):
                value["tests"][0]["status"] = status
                self.write(self.result, value)
                self.record_file()
                stored = self.load(self.root / "docs/feature-completion-evidence.json")
                self.assertEqual(stored["human_acceptance"]["status"], expected)
                self.assertFalse(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_definition_identity_and_snapshot_mismatches_are_rejected(self):
        original = self.prepared_result()
        mutations = (
            lambda d: d.update(feature_id="F002"),
            lambda d: d.update(tests=[]),
            lambda d: d["tests"].pop(),
            lambda d: d["tests"].append(copy.deepcopy(d["tests"][0])),
            lambda d: d["tests"][0].update(steps=["Different action"]),
            lambda d: d["tests"][0].update(expected_result="Easier outcome"),
            lambda d: d["tests"][0].update(source_ref="AC01/99"),
            lambda d: d["tests"][0].update(status="success"),
            lambda d: d["tests"][0].update(id="new-id"),
            lambda d: d["snapshot"].update(git_revision="other"),
        )
        for mutation in mutations:
            value = copy.deepcopy(original)
            mutation(value)
            self.write(self.result, value)
            with self.assertRaises((verification_snapshot.EvidenceError, ValueError)):
                read_result(self.root, "F001", self.checklist, self.result)

    def test_preparation_rejects_incomplete_coverage_and_rebinding(self):
        original = self.load(self.checklist)
        invalid = copy.deepcopy(original)
        invalid["tests"].pop()
        self.write(self.checklist, invalid)
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "missing manual obligations"):
            prepare_checklist(self.root, "F001", self.checklist)
        self.write(self.checklist, original)
        self.invoke("prepare-manual", "--feature", "F001", "--checklist", str(self.checklist))
        before = self.checklist.read_bytes()
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "already bound"):
            prepare_checklist(self.root, "F001", self.checklist)
        self.assertEqual(self.checklist.read_bytes(), before)

    def test_stale_result_is_not_rebound_to_current_source(self):
        self.prepared_result()
        (self.root / "implementation.txt").write_text("version two", encoding="utf-8")
        self.invoke("record-acceptance", "--feature", "F001", "--checklist", str(self.checklist),
                    "--result", str(self.result), expected=2)
        self.assertFalse((self.root / "docs/feature-completion-evidence.json").exists())

    def test_content_identical_commit_and_usage_readme_preserve_acceptance(self):
        self.prepared_result()
        (self.root / "README.md").write_text("Usage", encoding="utf-8")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "fixture")
        self.record_file()
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_manual_results_survive_staging_and_committing_source_deletion(self):
        implementation = self.root / "implementation.txt"
        implementation.unlink()
        self.prepared_result()
        self.record_file()
        originals = (self.checklist.read_bytes(), self.result.read_bytes())
        self.git("add", "implementation.txt")
        self.record_file()
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])
        self.git("commit", "--quiet", "-m", "Fixture accepted deletion")
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])
        self.assertEqual(originals, (self.checklist.read_bytes(), self.result.read_bytes()))
        implementation.write_text("restored source", encoding="utf-8")
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "current content snapshot"):
            read_result(self.root, "F001", self.checklist, self.result)
        self.assertFalse(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_completion_rereads_originals_and_blocks_later_failure_or_missing_file(self):
        value = self.prepared_result()
        self.record_file()
        value["tests"][0]["status"] = "failed"
        self.write(self.result, value)
        self.assertFalse(evidence.validate_completion_evidence(self.root, "F001")[0])
        self.result.unlink()
        self.assertFalse(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_explicit_conversation_remains_available_without_fake_file_source(self):
        self.assertFalse((self.root / evidence.EVIDENCE_RELATIVE_PATH).exists())
        self.invoke("record-acceptance", "--feature", "F001", "--status", "accepted")
        stored = self.load(self.root / "docs/feature-completion-evidence.json")
        self.assertEqual(stored["test_runs"], [])
        self.assertNotIn("source", stored["human_acceptance"])
        self.assertTrue(evidence.validate_completion_evidence(self.root, "F001")[0])
        self.invoke("record-acceptance", "--feature", "F001", "--status", "rejected")
        self.assertFalse(evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_invalid_existing_evidence_is_not_reset_by_recording(self):
        path = self.root / evidence.EVIDENCE_RELATIVE_PATH
        valid = evidence.empty_evidence("F001", verification_snapshot.current_snapshot(self.root))
        for content in ("{broken", "[]", json.dumps({**valid, "schema_version": 0}),
                        json.dumps({**valid, "feature_id": None}),
                        json.dumps({**valid, "test_runs": None})):
            with self.subTest(content=content):
                path.write_text(content, encoding="utf-8")
                before = path.read_bytes()
                self.invoke("record-acceptance", "--feature", "F001", "--status", "accepted", expected=2)
                self.assertEqual(path.read_bytes(), before)

    def test_new_feature_does_not_inherit_previous_acceptance(self):
        self.invoke("record-acceptance", "--feature", "F001", "--status", "accepted")
        self.invoke("record-acceptance", "--feature", "F002", "--status", "rejected")
        stored = self.load(self.root / evidence.EVIDENCE_RELATIVE_PATH)
        self.assertEqual(stored["feature_id"], "F002")
        self.assertEqual(stored["human_acceptance"]["status"], "rejected")
        self.assertEqual(stored["test_runs"], [])

    def test_cli_requires_paired_file_paths_and_never_overwrites_evidence_on_invalid_import(self):
        self.prepared_result()
        self.record_file()
        path = self.root / "docs/feature-completion-evidence.json"
        before = path.read_bytes()
        self.invoke("record-acceptance", "--feature", "F001", "--result", str(self.result), expected=2)
        self.result.write_text('{"schema_version":1,"schema_version":1}', encoding="utf-8")
        self.invoke("record-acceptance", "--feature", "F001", "--checklist", str(self.checklist),
                    "--result", str(self.result), expected=2)
        self.assertEqual(path.read_bytes(), before)

    def test_checklist_and_result_must_be_separate_files(self):
        self.prepared_result()
        with self.assertRaisesRegex(verification_snapshot.EvidenceError,
                                    "^checklist and result must be separate files$"):
            read_result(self.root, "F001", self.checklist, self.checklist)

    def test_reports_reject_valid_documents_outside_report_directory(self):
        self.prepared_result()
        self.assertEqual(read_result(self.root, "F001", self.checklist, self.result)["status"], "accepted")
        outside = tempfile.TemporaryDirectory(prefix="yaya-manual-outside-")
        self.addCleanup(outside.cleanup)
        # Valid documents outside the snapshot inputs isolate the path boundary from content errors.
        for directory in (self.root / "reports/other", Path(outside.name)):
            for source in (self.checklist, self.result):
                with self.subTest(directory=directory, document=source.name):
                    misplaced = self.write(directory / source.name, self.load(source))
                    checklist = misplaced if source == self.checklist else self.checklist
                    result = misplaced if source == self.result else self.result
                    with self.assertRaisesRegex(verification_snapshot.EvidenceError,
                                                "^manual acceptance files must be JSON under reports/manual-acceptance$"):
                        read_result(self.root, "F001", checklist, result)

    def test_contract_change_and_automated_mode_cannot_reuse_manual_results(self):
        self.prepared_result()
        self.detail["acceptance_criteria"][0]["verification"]["manual_checks"][0] = "Different judgment"
        self.write("docs/features/F001.json", self.detail)
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "snapshot"):
            read_result(self.root, "F001", self.checklist, self.result)
        self.detail["verification"].update(acceptance_mode="automated", manual_regression=None)
        self.detail["acceptance_criteria"][0]["verification"].update(manual_checks=[], automated_tests=["F001-AC01"])
        self.write("docs/features/F001.json", self.detail)
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "manual Feature"):
            read_result(self.root, "F001", self.checklist, self.result)

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
        self.prepared_result()
        self.assertEqual(read_result(self.root, "F001", self.checklist, self.result)["status"], "accepted")

    def test_non_json_numeric_constants_are_rejected(self):
        self.prepared_result()
        text = self.result.read_text(encoding="utf-8")
        self.result.write_text(text[:-1] + ', "extra": NaN}', encoding="utf-8")
        with self.assertRaisesRegex(verification_snapshot.EvidenceError, "invalid JSON number"):
            read_result(self.root, "F001", self.checklist, self.result)


if __name__ == "__main__":
    unittest.main()
