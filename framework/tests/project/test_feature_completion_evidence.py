"""Regression contracts for selection-driven, artifact-backed completion."""
# 共用中立仓库夹具检查测试计划与工件证据；合成结果不冒充真实引擎执行。
from __future__ import annotations
from project_context import PROJECT_ROOT

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = (PROJECT_ROOT / "tools")
sys.path.insert(0, str(PROJECT_ROOT))
from tools.lib import feature_completion_evidence
class FeatureCompletionEvidenceTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="yaya-evidence-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.write(".gitignore", "reports/\n")
        self.write("game.gd", "extends Node\n")
        self.write("tests/unit/example.gd", "extends GdUnitTestSuite\nfunc test_example():\n\tpass\n")
        self.write("tests/features/acceptance.gd", "extends GdUnitTestSuite\nfunc test_acceptance():\n\tpass\n")
        self.detail = {
            "id": "F001", "affected_components": ["example"],
            "acceptance_criteria": [{"id": "AC01", "text": "Example contract",
                "verification": {"automated_tests": ["F001-AC01"], "manual_checks": []}}],
            "verification": {"acceptance_mode": "automated", "regression_tests": [], "manual_regression": None}, "notes": "",
        }
        self.registry = {"meta": {"schema_version": 2}, "components": [
            {"id": "example", "unit_test_paths": ["tests/unit"], "full_suite_on_change": False}],
            "tests": [{"id": "F001-AC01", "kind": "acceptance", "source_feature": "F001",
                "criterion_id": "AC01", "components": ["example"],
                "path": "tests/features/acceptance.gd", "case": "test_acceptance", "status": "active"}]}
        self.write_json("docs/features/F001.json", self.detail)
        self.write_json("docs/test-registry.json", self.registry)
        self.write_json("docs/feature-list.json", {"meta": {"total_features": 1}, "features": [
            {"id": "F001", "status": "in_progress", "depends_on": [], "completed_at": None}]})
        self.write_json("docs/methodology-config.json", {"test_framework": "gdunit4", "test_unit_root": "tests/unit",
            "test_feature_root": "tests/features", "test_invariant_root": "tests/invariants",
            "python_executable": sys.executable,
            "environment_bootstrap": {"engine_executable": sys.executable}})
        self.git("init")
        self.git("config", "user.name", "Evidence Test")
        self.git("config", "user.email", "test@example.invalid")
        self.git("add", ".")
        self.git("commit", "-m", "fixture")

    def write(self, name: str, content: str) -> Path:
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def write_json(self, name: str, value: object) -> Path:
        return self.write(name, json.dumps(value, ensure_ascii=False) + "\n")

    def git(self, *args: str) -> None:
        result = subprocess.run(["git", "-C", str(self.root), *args], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def completion_fixture(self):
        from tools.lib.test_run_evidence import result_reference
        _, test_path = self.run_fixture()
        snapshot = feature_completion_evidence.current_snapshot(self.root)
        data = feature_completion_evidence.empty_evidence("F001", snapshot)
        data.update(recorded_at=feature_completion_evidence.utc_now(),
                    test_runs=[result_reference(self.root, test_path)])
        data["code_smell"].update(status="pass", must_fix=0, suggest=0, acceptable=0, **snapshot)
        feature_completion_evidence.write_evidence(self.root / "docs/feature-completion-evidence.json", data)
        return data

    def test_automated_decision_completes_without_fabricating_human_acceptance(self):
        data = self.completion_fixture()
        self.assertEqual(data["human_acceptance"]["status"], "pending")
        self.assertEqual(feature_completion_evidence.validate_completion_evidence(self.root, "F001")[0], True)

    def test_manual_decision_requires_actual_acceptance(self):
        self.detail["verification"]["acceptance_mode"] = "manual"
        self.detail["acceptance_criteria"][0]["verification"]["manual_checks"] = ["Listen to the sound"]
        self.write_json("docs/features/F001.json", self.detail)
        data = self.completion_fixture()
        valid, message = feature_completion_evidence.validate_completion_evidence(self.root, "F001")
        self.assertFalse(valid)
        self.assertIn("human acceptance", message)
        data["human_acceptance"].update(status="accepted", **feature_completion_evidence.current_snapshot(self.root))
        feature_completion_evidence.write_evidence(self.root / "docs/feature-completion-evidence.json", data)
        self.assertTrue(feature_completion_evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_test_registry_uses_fixed_path_even_with_obsolete_config(self):
        from tools.lib.test_selection import build_selection
        config_path = self.root / "docs/methodology-config.json"
        config = json.loads(config_path.read_text(encoding="utf-8"))
        config["test_catalog_path"] = "docs/unused-tests.json"
        self.write_json("docs/methodology-config.json", config)
        self.write_json("docs/unused-tests.json", {"meta": {"schema_version": 0}})

        selection = build_selection(self.root, "F001")

        self.assertEqual(selection["selectors"], ["tests/features/acceptance.gd", "tests/unit"])
        self.assertIn("F001-AC01", [test_id for item in selection["required"]
                                  for test_id in item["logical_ids"]])

    def test_empty_checks_do_not_decide_the_acceptance_mode(self):
        from tools.lib.test_selection import SelectionError, build_selection
        del self.detail["verification"]["acceptance_mode"]
        self.write_json("docs/features/F001.json", self.detail)
        with self.assertRaisesRegex(SelectionError, "must be decided"):
            build_selection(self.root, "F001")

    def manual_without_automated_obligations(self):
        self.detail["verification"]["acceptance_mode"] = "manual"
        self.detail["acceptance_criteria"][0]["verification"] = {
            "automated_tests": [], "manual_checks": ["Listen to the approved sound"]}
        self.registry["components"][0]["unit_test_paths"] = []
        self.registry["tests"] = []
        self.write_json("docs/features/F001.json", self.detail)
        self.write_json("docs/test-registry.json", self.registry)

    def test_manual_without_automated_obligations_still_needs_acceptance_and_review(self):
        from tools.lib.test_run_evidence import derive_test_evidence
        self.manual_without_automated_obligations()
        derived = derive_test_evidence(self.root, "F001", [])
        for name in ("required_test_set", "affected_tests", "full_suite"):
            self.assertEqual(derived[name]["status"], "not_required")
            self.assertEqual(derived[name]["run_ids"], [])
        snapshot = feature_completion_evidence.current_snapshot(self.root)
        data = feature_completion_evidence.empty_evidence("F001", snapshot)
        data["recorded_at"] = feature_completion_evidence.utc_now()
        feature_completion_evidence.write_evidence(self.root / "docs/feature-completion-evidence.json", data)
        self.assertIn("human acceptance", feature_completion_evidence.validate_completion_evidence(self.root, "F001")[1])
        data["human_acceptance"].update(status="accepted", **snapshot)
        feature_completion_evidence.write_evidence(self.root / "docs/feature-completion-evidence.json", data)
        self.assertIn("code-smell", feature_completion_evidence.validate_completion_evidence(self.root, "F001")[1])
        data["code_smell"].update(status="pass", must_fix=0, suggest=0, acceptable=0, **snapshot)
        feature_completion_evidence.write_evidence(self.root / "docs/feature-completion-evidence.json", data)
        self.assertTrue(feature_completion_evidence.validate_completion_evidence(self.root, "F001")[0])
        self.write("game.gd", "extends Node\nvar changed = true\n")
        self.assertIn("changed after verification", feature_completion_evidence.validate_completion_evidence(self.root, "F001")[1])

    def test_manual_mode_cannot_skip_any_current_automated_obligation(self):
        from tools.lib.test_run_evidence import RunEvidenceError, derive_test_evidence
        for obligation in ("unit", "affected", "full"):
            with self.subTest(obligation=obligation):
                self.manual_without_automated_obligations()
                self.registry["components"][0]["full_suite_on_change"] = obligation == "full"
                if obligation == "unit":
                    self.registry["components"][0]["unit_test_paths"] = ["tests/unit"]
                elif obligation == "affected":
                    self.registry["tests"] = [{"id": "F002-AC01", "kind": "acceptance",
                        "source_feature": "F002", "criterion_id": "AC01", "components": ["example"],
                        "path": "tests/features/acceptance.gd", "case": "test_acceptance", "status": "active"}]
                self.write_json("docs/test-registry.json", self.registry)
                with self.assertRaisesRegex(RunEvidenceError, "no real test run"):
                    derive_test_evidence(self.root, "F001", [])

    def test_no_obligations_does_not_hide_invalid_mapping_or_empty_execution(self):
        from tools.lib.test_run_evidence import derive_test_evidence
        from tools.lib.test_selection import SelectionError, build_selection, execution_selectors
        self.manual_without_automated_obligations()
        with self.assertRaisesRegex(SelectionError, "zero test paths"):
            execution_selectors(self.root, build_selection(self.root, "F001"), "affected")
        self.registry["components"][0]["unit_test_paths"] = ["tests/missing"]
        self.write_json("docs/test-registry.json", self.registry)
        with self.assertRaises(SelectionError):
            derive_test_evidence(self.root, "F001", [])
        self.manual_without_automated_obligations()
        self.detail["verification"]["acceptance_mode"] = "automated"
        self.write_json("docs/features/F001.json", self.detail)
        with self.assertRaisesRegex(SelectionError, "automated coverage"):
            derive_test_evidence(self.root, "F001", [])

    def test_no_obligations_does_not_hide_supplied_or_failed_runs(self):
        from tools.lib.test_run_evidence import RunEvidenceError, derive_test_evidence, start_run
        self.manual_without_automated_obligations()
        for references in (None, {}, [{"path": "reports/gdunit-wrapper/missing/result.json", "sha256": "missing"}]):
            with self.subTest(references=references), self.assertRaises(RunEvidenceError):
                derive_test_evidence(self.root, "F001", references)
        directory = self.root / "reports/gdunit-wrapper/run-unfinished"
        record = start_run(self.root, directory, "F001", "final", "affected")
        for status in ("running", "failed"):
            with self.subTest(status=status):
                record["status"] = status
                feature_completion_evidence.write_evidence(directory / "result.json", record)
                with self.assertRaisesRegex(RunEvidenceError, "unresolved failed or unfinished"):
                    derive_test_evidence(self.root, "F001", [])

    def test_declared_mode_and_check_contents_must_agree(self):
        from tools.lib.test_selection import SelectionError, acceptance_mode
        self.detail["verification"]["manual_regression"] = "Inspect existing layout"
        with self.assertRaisesRegex(SelectionError, "no manual obligations"):
            acceptance_mode(self.detail)
        self.detail["verification"]["acceptance_mode"] = "manual"
        self.assertEqual(acceptance_mode(self.detail), "manual")
        self.detail["verification"]["manual_regression"] = None
        with self.assertRaisesRegex(SelectionError, "concrete"):
            acceptance_mode(self.detail)

    def test_acceptance_decision_change_invalidates_prior_evidence(self):
        self.completion_fixture()
        self.detail["verification"]["acceptance_mode"] = "manual"
        self.detail["acceptance_criteria"][0]["verification"]["manual_checks"] = ["Inspect the presentation"]
        self.write_json("docs/features/F001.json", self.detail)
        valid, message = feature_completion_evidence.validate_completion_evidence(self.root, "F001")
        self.assertFalse(valid)
        self.assertIn("changed after verification", message)

    def test_feature_verification_text_and_mapping_invalidate_snapshot(self) -> None:
        initial = feature_completion_evidence.current_snapshot(self.root)["working_tree_fingerprint"]
        self.detail["acceptance_criteria"][0]["text"] = "Changed contract"
        self.write_json("docs/features/F001.json", self.detail)
        self.assertNotEqual(initial, feature_completion_evidence.current_snapshot(self.root)["working_tree_fingerprint"])

    def test_process_fields_notes_and_progress_archive_do_not_invalidate(self) -> None:
        initial = feature_completion_evidence.current_snapshot(self.root)["working_tree_fingerprint"]
        self.detail["notes"] = "Archived explanation"
        self.write_json("docs/features/F001.json", self.detail)
        self.write_json("docs/feature-list.json", {"meta": {"total_features": 1, "updated_at": "later"}, "features": [
            {"id": "F001", "status": "done", "depends_on": [], "completed_at": "later"}]})
        self.write("docs/progress/feature-one.md", "Historical evidence pointer\n")
        self.write("docs/progress.md", "Current status\n")
        self.assertEqual(initial, feature_completion_evidence.current_snapshot(self.root)["working_tree_fingerprint"])

    def test_duplicate_index_paths_from_git_do_not_change_after_staging(self) -> None:
        self.write("new.txt", "new source\n")
        initial = feature_completion_evidence.current_snapshot(self.root)["working_tree_fingerprint"]
        self.git("add", "new.txt")
        self.assertEqual(initial, feature_completion_evidence.current_snapshot(self.root)["working_tree_fingerprint"])

    def test_counts_cannot_authorize_completion(self) -> None:
        data = feature_completion_evidence.empty_evidence("F001", feature_completion_evidence.current_snapshot(self.root))
        for key in ("required_test_set", "affected_tests"):
            data[key] = dict(status="pass", total=0, failed=0, git_revision=data["git_revision"],
                working_tree_fingerprint=data["working_tree_fingerprint"])
        for key in ("human_acceptance", "code_smell"):
            data[key].update(git_revision=data["git_revision"], working_tree_fingerprint=data["working_tree_fingerprint"])
        data["full_suite"] = {"status": "pass"}
        data["human_acceptance"]["status"] = "accepted"
        data["code_smell"].update(status="pass", must_fix=0, suggest=0, acceptable=0)
        data["gate_status"] = "pass"
        feature_completion_evidence.write_evidence(self.root / "docs/feature-completion-evidence.json", data)
        self.assertFalse(feature_completion_evidence.validate_completion_evidence(self.root, "F001")[0])

    def test_selection_derives_required_and_removes_overlapping_targets(self) -> None:
        from tools.lib.test_selection import build_selection
        self.registry["components"][0]["unit_test_paths"].append("tests/unit/example.gd")
        self.write_json("docs/test-registry.json", self.registry)
        plan = build_selection(self.root, "F001")
        self.assertEqual(plan["selectors"], ["tests/features/acceptance.gd", "tests/unit"])
        self.assertEqual(len(plan["required"]), 3)
        self.assertFalse(plan["full_suite"]["required"])
        self.assertTrue(all(item["reasons"] for item in plan["required"]))

    def test_current_selection_rejects_missing_contract_mapping(self) -> None:
        from tools.lib.test_selection import SelectionError, build_selection
        plan = build_selection(self.root, "F001")
        self.detail["acceptance_criteria"][0]["verification"]["automated_tests"] = ["F001-AC99"]
        self.write_json("docs/features/F001.json", self.detail)
        with self.assertRaises(SelectionError):
            build_selection(self.root, "F001")

    def test_registry_full_trigger_and_missing_path_are_not_silently_filtered(self) -> None:
        from tools.lib.test_selection import SelectionError, build_selection
        self.registry["components"][0]["full_suite_on_change"] = True
        self.write_json("docs/test-registry.json", self.registry)
        self.assertTrue(build_selection(self.root, "F001")["full_suite"]["required"])
        self.registry["components"][0]["unit_test_paths"] = ["tests/missing"]
        self.write_json("docs/test-registry.json", self.registry)
        with self.assertRaises(SelectionError):
            build_selection(self.root, "F001")

    def test_junit_counts_must_match_actual_case_nodes(self) -> None:
        from tools.lib.test_run_evidence import RunEvidenceError, read_junit_cases
        report = self.write("reports/run/results.xml", '<testsuites tests="4" failures="0" skipped="0" flaky="0">'
            '<testsuite name="example" package="tests/unit" tests="4" errors="0" failures="0" skipped="0" flaky="0">'
            '<testcase name="test_example"/></testsuite></testsuites>')
        with self.assertRaises(RunEvidenceError):
            read_junit_cases(report)

    def run_fixture(self, *, scope: str = "full", skipped: bool = False,
                    omit: str | None = None, exit_code: int = 0) -> tuple[dict, Path]:
        from gdunit_report_fixture import make_run
        return make_run(self.root, scope=scope, skipped=skipped, omit=omit, exit_code=exit_code)

    def test_one_full_run_covers_required_and_affected_and_survives_process_commit(self) -> None:
        from tools.lib.test_run_evidence import derive_test_evidence, result_reference
        plan, path = self.run_fixture()
        refs = [result_reference(self.root, path)]
        derived = derive_test_evidence(self.root, "F001", refs)
        self.assertEqual(derived["required_test_set"]["total"], 2)
        self.assertEqual(derived["full_suite"]["status"], "pass")
        self.assertEqual(derived["required_test_set"]["run_ids"], derived["affected_tests"]["run_ids"])
        self.write("docs/progress/history.md", "archived process history\n")
        self.git("add", "docs/progress/history.md")
        self.git("commit", "-m", "process history only")
        self.assertEqual(derive_test_evidence(self.root, "F001", refs)["required_test_set"]["total"],
                         derived["required_test_set"]["total"])

    def test_missing_tests_skipped_tests_and_nonzero_process_reject_green_labels(self) -> None:
        from tools.lib.test_run_evidence import RunEvidenceError, derive_test_evidence, result_reference
        for args in ({"omit": "test_example"}, {"skipped": True}, {"exit_code": 7}):
            with self.subTest(args=args):
                plan, path = self.run_fixture(**args)
                with self.assertRaises(RunEvidenceError):
                    derive_test_evidence(self.root, "F001", [result_reference(self.root, path)])

    def test_artifacts_must_stay_current_and_within_the_originating_run(self) -> None:
        from tools.lib.test_run_evidence import RunEvidenceError, derive_test_evidence, result_reference
        plan, path = self.run_fixture()
        reference = result_reference(self.root, path)
        (path.parent / "report_1/results.xml").write_text("<testsuites/>", encoding="utf-8")
        with self.assertRaisesRegex(RunEvidenceError, "changed after"):
            derive_test_evidence(self.root, "F001", [reference])

    def test_low_precision_artifact_times_do_not_reject_current_session(self) -> None:
        from tools.lib.test_run_evidence import derive_test_evidence, result_reference
        plan, path = self.run_fixture()
        result = json.loads(path.read_text())
        coarse_time = 1_000_000_000
        for artifact in result["artifacts"].values():
            file = path.parent / artifact["path"]
            os.utime(file, ns=(coarse_time, coarse_time))
        path.write_text(json.dumps(result), encoding="utf-8")
        self.assertEqual(derive_test_evidence(self.root, "F001",
            [result_reference(self.root, path)])["full_suite"]["status"], "pass")

    def test_timestamp_only_changes_do_not_replace_hash_integrity(self) -> None:
        from tools.lib.test_run_evidence import RunEvidenceError, derive_test_evidence, result_reference
        plan, path = self.run_fixture()
        reference = result_reference(self.root, path)
        result = json.loads(path.read_text())
        report = path.parent / result["artifacts"]["junit"]["path"]
        original_time = report.stat().st_mtime_ns
        os.utime(report, ns=(1_000_000_000, 1_000_000_000))
        self.assertEqual(derive_test_evidence(self.root, "F001",
            [reference])["full_suite"]["status"], "pass")
        report.write_bytes(report.read_bytes() + b"\n<!-- modified bytes -->\n")
        os.utime(report, ns=(original_time, original_time))
        with self.assertRaisesRegex(RunEvidenceError, "changed after"):
            derive_test_evidence(self.root, "F001", [reference])

    def test_non_gdunit_configuration_cannot_import_gdunit_run(self) -> None:
        from tools.lib.test_run_evidence import RunEvidenceError, derive_test_evidence, result_reference
        config = json.loads((self.root / "docs/methodology-config.json").read_text())
        config["test_framework"] = "pytest"
        self.write_json("docs/methodology-config.json", config)
        plan, path = self.run_fixture()
        with self.assertRaisesRegex(RunEvidenceError, "gdunit4"):
            derive_test_evidence(self.root, "F001", [result_reference(self.root, path)])

    def test_required_full_escalation_cannot_be_claimed_by_affected_run(self) -> None:
        from tools.lib.test_run_evidence import RunEvidenceError, derive_test_evidence, result_reference
        self.registry["components"][0]["full_suite_on_change"] = True
        self.write_json("docs/test-registry.json", self.registry)
        plan, path = self.run_fixture(scope="affected")
        with self.assertRaisesRegex(RunEvidenceError, "full-suite"):
            derive_test_evidence(self.root, "F001", [result_reference(self.root, path)])

    def test_unmapped_criterion_cannot_borrow_unrelated_affected_test_pass(self) -> None:
        from tools.lib.test_selection import SelectionError, build_selection
        self.detail["acceptance_criteria"][0]["verification"] = {"automated_tests": [], "manual_checks": []}
        self.write_json("docs/features/F001.json", self.detail)
        with self.assertRaisesRegex(SelectionError, "automated coverage"):
            build_selection(self.root, "F001")

    def test_manual_criterion_does_not_allow_a_retired_direct_automated_mapping(self) -> None:
        from tools.lib.test_selection import SelectionError, build_selection
        self.registry["tests"][0]["status"] = "retired"
        self.write_json("docs/test-registry.json", self.registry)
        with self.assertRaisesRegex(SelectionError, "retired"):
            build_selection(self.root, "F001")

    def test_baseline_planned_tests_are_excluded_but_never_final_evidence(self) -> None:
        from tools.lib.test_selection import SelectionError, build_selection
        self.registry["tests"][0].update(status="planned", path="tests/future.gd")
        self.write_json("docs/test-registry.json", self.registry)
        plan = build_selection(self.root, "F001", phase="baseline")
        self.assertTrue(all(item["path"] != "tests/future.gd" for item in plan["required"]))
        with self.assertRaisesRegex(SelectionError, "planned"):
            build_selection(self.root, "F001")

    def test_code_change_rejects_an_unchanged_green_run(self) -> None:
        from tools.lib.test_run_evidence import derive_test_evidence, result_reference
        from tools.lib.test_run_evidence import RunEvidenceError
        plan, path = self.run_fixture()
        reference = result_reference(self.root, path)
        self.write("game.gd", "extends Node\nvar changed = true\n")
        with self.assertRaisesRegex(RunEvidenceError, "source changed"):
            derive_test_evidence(self.root, "F001", [reference])

    def test_source_inventory_handles_static_multiline_and_comment_examples(self) -> None:
        from tools.lib.test_run_evidence import expected_gdunit_cases
        self.write("tests/unit/example.gd", '''extends GdUnitTestSuite
# func test_comment():
const EXAMPLE = """
func test_documentation():
    pass
"""
static func test_static(
    value = 1
) -> void:
    pass
func test_plain():
    pass
''')
        cases = expected_gdunit_cases(self.root, ["tests/unit/example.gd"])
        self.assertEqual([case["case"] for case in cases], ["test_plain", "test_static"])

    def test_approved_full_obligation_survives_regeneration_without_cli_flag(self) -> None:
        from tools.lib.test_selection import build_selection
        self.detail["verification"]["test_impact"] = {
            "additional_tests": [], "full_suite_reasons": ["Approved shared infrastructure change"]}
        self.write_json("docs/features/F001.json", self.detail)
        plan = build_selection(self.root, "F001")
        self.assertTrue(plan["full_suite"]["required"])
        self.assertIn("Approved shared infrastructure change", plan["full_suite"]["reasons"])

    def test_runtime_discovery_cannot_lose_parameterized_cases_in_green_junit(self) -> None:
        from tools.lib.test_run_evidence import RunEvidenceError, artifact_reference, derive_test_evidence, result_reference
        plan, path = self.run_fixture()
        result = json.loads(path.read_text(encoding="utf-8"))
        discovered = json.loads((path.parent / "discovery.json").read_text())["cases"]
        discovered.append({"id": "tests/unit/example.gd::test_example:1 (second)",
                           "path": "tests/unit/example.gd", "case": "test_example:1 (second)", "method": "test_example"})
        discovery = path.parent / "discovery.json"
        discovery.write_text(json.dumps({"schema_version": 1, "run_id": path.parent.name, "engine_pid": 123, "cases": discovered}), encoding="utf-8")
        result["artifacts"]["discovery"] = artifact_reference(path.parent, discovery)
        path.write_text(json.dumps(result), encoding="utf-8")
        with self.assertRaisesRegex(RunEvidenceError, "discovery"):
            derive_test_evidence(self.root, "F001", [result_reference(self.root, path)])

    def test_revision_process_fields_preserve_but_migration_edges_invalidate_snapshot(self) -> None:
        revision = {"schema_version": 2, "revision_log": [{"id": "R001", "revised_at": "before",
            "summary": "Original explanation", "migrations": [{"kind": "revise", "from": ["F001"],
                "to": ["F002"], "source": {"path": "product.md", "anchor_commit": "a" * 40}}]}]}
        self.write_json("docs/feature-list-revisions.json", revision)
        initial = feature_completion_evidence.current_snapshot(self.root)["working_tree_fingerprint"]
        revision["revision_log"][0].update(revised_at="after", summary="Archived explanation")
        self.write_json("docs/feature-list-revisions.json", revision)
        self.assertEqual(initial, feature_completion_evidence.current_snapshot(self.root)["working_tree_fingerprint"])
        revision["revision_log"][0]["migrations"][0]["to"] = ["F003"]
        self.write_json("docs/feature-list-revisions.json", revision)
        self.assertNotEqual(initial, feature_completion_evidence.current_snapshot(self.root)["working_tree_fingerprint"])

    def test_selection_rejects_malformed_recorded_impact(self) -> None:
        from tools.lib.test_selection import SelectionError, build_selection
        for impact in (None, {}, {"additional_tests": [], "full_suite_reasons": [""]},
                       {"additional_tests": [{"id": "F001-AC01"}], "full_suite_reasons": []}):
            with self.subTest(impact=impact):
                self.detail["verification"]["test_impact"] = impact
                self.write_json("docs/features/F001.json", self.detail)
                with self.assertRaises(SelectionError):
                    build_selection(self.root, "F001")

    def test_expanded_runtime_cases_share_method_and_require_same_engine(self) -> None:
        from tools.lib.test_run_evidence import RunEvidenceError, require_coverage, verify_runtime_discovery
        records = [{"id": "tests/unit/example.gd::test_example:" + str(index),
            "path": "tests/unit/example.gd", "case": "test_example:" + str(index), "method": "test_example"}
            for index in range(2)]
        path = self.write_json("reports/discovery.json", {"schema_version": 1, "engine_pid": 123, "cases": records})
        actual = [{key: value for key, value in record.items() if key != "method"} | {"status": "passed"}
                  for record in records]
        cases = verify_runtime_discovery(path, 123, actual)
        self.assertEqual(len(require_coverage(cases, [{"path": "tests/unit/example.gd", "case": "test_example"}])), 2)
        with self.assertRaisesRegex(RunEvidenceError, "different engine"):
            verify_runtime_discovery(path, 456, actual)


    def test_maintenance_label_alone_does_not_require_full_suite(self):
        from tools.lib.test_selection import build_selection
        self.detail.update(engineering_change="maintenance", source="infrastructure")
        self.write_json("docs/features/F001.json", self.detail)
        self.assertFalse(build_selection(self.root, "F001")["full_suite"]["required"])

    def test_relabelled_discovery_from_another_run_is_rejected(self):
        from tools.lib.test_run_evidence import artifact_reference, derive_test_evidence, result_reference
        _, path = self.run_fixture()
        result = json.loads(path.read_text())
        discovery_path = path.parent / "discovery.json"
        discovery = json.loads(discovery_path.read_text())
        discovery["run_id"] = "run-from-another-session"
        discovery_path.write_text(json.dumps(discovery), encoding="utf-8")
        result["artifacts"]["discovery"] = artifact_reference(path.parent, discovery_path)
        path.write_text(json.dumps(result), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "different run"):
            derive_test_evidence(self.root, "F001", [result_reference(self.root, path)])

    def test_result_tampering_after_recording_is_rejected(self):
        from tools.lib.test_run_evidence import derive_test_evidence, result_reference
        _, path = self.run_fixture()
        reference = result_reference(self.root, path)
        path.write_bytes(path.read_bytes() + b"\n")
        with self.assertRaisesRegex(ValueError, "result changed"):
            derive_test_evidence(self.root, "F001", [reference])

    def test_gate_template_matches_the_single_completion_record(self):
        template = json.loads((PROJECT_ROOT / "methodology/templates/feature-completion-evidence.json.tmpl").read_text())
        self.assertEqual(template, feature_completion_evidence.empty_evidence(None, {"git_revision": None,
            "working_tree_fingerprint": None}))


if __name__ == "__main__":
    unittest.main()
