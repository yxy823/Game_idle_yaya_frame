# 中立台账回归检查依赖、修订和退役语义，不以某个游戏的编号顺序建立规则。
from __future__ import annotations
from project_context import PROJECT_ROOT

import copy
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = PROJECT_ROOT
sys.path.insert(0, str(ROOT))
SPEC = importlib.util.spec_from_file_location("evolution_checker", ROOT / "tools/checks/check-feature-list.py")
assert SPEC and SPEC.loader
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)


class FeatureEvolutionTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="yaya-evolution-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "docs/features").mkdir(parents=True)
        self.index = {"meta": {"total_features": 3}, "features": [
            {"id": f"F{i:03d}", "title": f"Capability {i}",
             "status": "done" if i == 1 else "pending", "depends_on": [],
             "estimated_scope": "small", "completed_at": "2026-01-01T00:00:00Z" if i == 1 else None}
            for i in range(1, 4)
        ]}
        self.registry = {"meta": {"schema_version": 2}, "components": [
            {"id": "inventory", "unit_test_paths": [], "full_suite_on_change": False}
        ], "tests": []}
        for i in range(1, 4):
            fid = f"F{i:03d}"
            path = f"tests/{fid}.gd"
            self.write(path, "extends Node\n")
            self.registry["tests"].append({"id": f"{fid}-AC01", "kind": "acceptance",
                "source_feature": fid, "criterion_id": "AC01", "components": ["inventory"],
                "path": path, "case": "test_contract", "status": "active"})
            self.write(f"docs/features/{fid}.json", {"id": fid, "description": "Contract",
                "affected_components": ["inventory"], "acceptance_criteria": [{"id": "AC01",
                    "text": "The contract holds", "verification": {"automated_tests": [f"{fid}-AC01"], "manual_checks": []}}],
                "verification": {"acceptance_mode": "automated", "regression_tests": [], "manual_regression": None},
                "source": "docs/product.md#contract", "notes": ""})
        self.source = {"path": "docs/product.md#contract", "anchor_commit": "a" * 40}
        self.revisions = {"schema_version": 2, "revision_log": [{
            "schema_version": 2, "revision_id": "rev-contract-01", "revised_at": "2026-02-01T00:00:00Z",
            "anchor_commit": "b" * 40, "synced_at_commit": "a" * 40,
            "user_intent": "Change contract", "summary": "Replace an old contract",
            "migrations": [{"kind": "revise", "from": ["F001"], "to": ["F003"],
                "reason": "Approved new Product contract", "source": self.source}], "dependency_changes": []
        }]}

    def write(self, path: str, value: object) -> None:
        destination = self.root / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(value if isinstance(value, str) else json.dumps(value), encoding="utf-8")

    def validate(self, completion: str | None = None) -> bool:
        self.write("docs/feature-list.json", self.index)
        self.write("docs/test-registry.json", self.registry)
        self.write("docs/feature-list-revisions.json", self.revisions)
        with mock.patch.multiple(checker, REPO_ROOT=self.root, INDEX_FILE=self.root / "docs/feature-list.json",
                DETAILS_DIR=self.root / "docs/features", TEST_REGISTRY_FILE=self.root / "docs/test-registry.json",
                REVISIONS_FILE=self.root / "docs/feature-list-revisions.json"):
            if completion is None:
                return checker._validate_all()
            return checker._validate_all(completion_feature=completion)

    def retire(self) -> None:
        self.registry["meta"]["schema_version"] = 2
        self.registry["tests"][0]["status"] = "retired"
        self.registry["tests"][0]["retirement"] = {"reason": "Product superseded the old assertion",
            "source": copy.deepcopy(self.source), "replacement": {"feature_id": "F003", "test_ids": ["F003-AC01"]},
            "revision_id": "rev-contract-01"}
        (self.root / "tests/F001.gd").unlink()

    def test_only_current_ledger_contract_is_accepted(self) -> None:
        self.revisions = {"revision_log": [{"summary": "Old record"}]}
        self.assertFalse(self.validate())

    def test_string_criteria_and_missing_verification_cannot_waive_registry_checks(self) -> None:
        path = self.root / "docs/features/F001.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        for field, value in (("acceptance_criteria", ["Unstructured old criterion"]),
                             ("affected_components", None), ("verification", None)):
            with self.subTest(field=field):
                candidate = {**detail, field: value}
                self.write("docs/features/F001.json", candidate)
                self.assertFalse(self.validate())
        self.write("docs/features/F001.json", detail)
        self.registry["meta"]["schema_version"] = 1
        self.assertFalse(self.validate())

    def test_later_dependency_is_valid_and_determines_eligible_order(self) -> None:
        self.index["features"][1]["depends_on"] = ["F003"]
        self.assertTrue(self.validate())
        self.assertEqual(checker.eligible_features({f["id"]: f for f in self.index["features"]}), ["F003"])

    def test_dependency_cycle_missing_self_and_duplicate_remain_invalid(self) -> None:
        for deps in (["F002"], ["F999"], ["F003", "F003"]):
            with self.subTest(deps=deps):
                self.index["features"][1]["depends_on"] = deps
                self.assertFalse(self.validate())
        self.index["features"][1]["depends_on"] = ["F003"]
        self.index["features"][2]["depends_on"] = ["F002"]
        self.assertFalse(self.validate())

    def test_historical_done_can_retire_with_traceable_replacement(self) -> None:
        self.retire()
        self.assertTrue(self.validate())
        self.assertFalse(self.validate(completion="F001"))
        result = subprocess.run([sys.executable, "-B", str(ROOT / "tools/checks/check-feature-list.py"),
            "--repo-root", str(self.root), "--completion-feature", "F001"],
            cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("expected ['active']", result.stderr)

    def test_replacement_may_be_planned_until_its_feature_completes(self) -> None:
        self.retire()
        self.registry["tests"][2].update(status="planned", path=None)
        self.assertTrue(self.validate())
        self.index["features"][2].update(status="done", completed_at="2026-02-02T00:00:00Z")
        self.assertFalse(self.validate())

    def test_unfinished_feature_can_retire_an_ac_removed_by_approved_revision(self) -> None:
        # Current AC01 replaces a removed historical AC02; current IDs remain sequential.
        self.revisions["revision_log"][0]["migrations"][0].update(**{"from": ["F002"], "to": ["F002"]})
        old = self.registry["tests"][1]
        replacement = copy.deepcopy(old) | {"status": "planned", "path": None}
        self.registry["tests"].append(replacement)
        old.update(id="F002-AC02", criterion_id="AC02", status="retired", retirement={"reason": "Approved replacement of the unfinished AC",
            "source": copy.deepcopy(self.source), "replacement": {"feature_id": "F002", "test_ids": ["F002-AC01"]},
            "revision_id": "rev-contract-01"})
        for status in ("pending", "in_progress"):
            with self.subTest(status=status):
                self.index["features"][1]["status"] = status
                self.assertTrue(self.validate())
                self.assertFalse(self.validate(completion="F002"))
        replacement.update(status="active", path="tests/F002.gd")
        self.assertTrue(self.validate(completion="F002"))
        old["criterion_id"] = "AC03"
        self.assertFalse(self.validate())  # Retirement preserves the old identity contract.
        old["criterion_id"] = "AC02"
        old["retirement"]["revision_id"] = "missing-revision"
        self.assertFalse(self.validate())

    def test_current_acceptance_tests_still_require_an_existing_criterion(self) -> None:
        path = self.root / "docs/features/F002.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        self.registry["tests"][1].update(id="F002-AC02", criterion_id="AC02")
        detail["acceptance_criteria"][0]["verification"] = {
            "automated_tests": [], "manual_checks": ["Inspect the replacement behavior"]}
        detail["verification"]["acceptance_mode"] = "manual"
        self.write("docs/features/F002.json", detail)
        for status in ("planned", "active"):
            with self.subTest(status=status):
                self.registry["tests"][1]["status"] = status
                self.assertFalse(self.validate())

    def test_retirement_requires_reason_source_replacement_and_revision(self) -> None:
        self.retire()
        original = copy.deepcopy(self.registry["tests"][0]["retirement"])
        for field in original:
            with self.subTest(field=field):
                self.registry["tests"][0]["retirement"] = {k: v for k, v in original.items() if k != field}
                self.assertFalse(self.validate())

    def test_retirement_must_match_revision_and_replacement_ownership(self) -> None:
        self.retire()
        retirement = self.registry["tests"][0]["retirement"]
        for replacement in ("F999-AC01", "F002-AC01", "F001-AC01"):
            retirement["replacement"]["test_ids"] = [replacement]
            self.assertFalse(self.validate())
        retirement["replacement"]["test_ids"] = ["F003-AC01"]
        retirement["source"]["anchor_commit"] = "c" * 40
        self.assertFalse(self.validate())

    def test_replacement_must_be_mapped_into_its_features_verification_plan(self) -> None:
        self.retire()
        path = self.root / "docs/features/F003.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        detail["acceptance_criteria"][0]["verification"]["automated_tests"] = []
        self.write("docs/features/F003.json", detail)
        self.assertFalse(self.validate())

    def test_migrations_reject_wrong_cardinality_missing_ids_and_unsafe_sources(self) -> None:
        base = copy.deepcopy(self.revisions["revision_log"][0]["migrations"][0])
        for changes in ({"kind": "split"}, {"kind": "merge"}, {"kind": "invented"},
                        {"to": ["F999"]}, {"source": {"path": "../secret", "anchor_commit": "a" * 40}}):
            self.revisions["revision_log"][0]["migrations"] = [base | changes]
            self.assertFalse(self.validate())

    def test_split_and_merge_keep_original_ids_as_obsolete(self) -> None:
        self.index["features"][0]["status"] = "obsolete_done"
        revision = self.revisions["revision_log"][0]
        revision["migrations"][0].update(kind="split", to=["F002", "F003"])
        self.assertTrue(self.validate())
        self.index["features"][1]["status"] = "obsolete"
        revision["migrations"][0].update(kind="merge", **{"from": ["F001", "F002"], "to": ["F003"]})
        self.assertTrue(self.validate())

    def test_revision_dependency_after_must_match_current_or_later_revision(self) -> None:
        self.revisions["revision_log"][0]["dependency_changes"] = [{"feature": "F002", "before": [], "after": ["F003"]}]
        self.assertFalse(self.validate())
        self.index["features"][1]["depends_on"] = ["F003"]
        self.assertTrue(self.validate())

    def test_add_and_retire_are_incremental_and_keep_allocated_ids(self) -> None:
        migration = self.revisions["revision_log"][0]["migrations"][0]
        migration.update(kind="add", **{"from": [], "to": ["F003"]})
        self.assertTrue(self.validate())
        self.index["features"][1]["status"] = "obsolete"
        migration.update(kind="retire", **{"from": ["F002"], "to": []})
        self.assertTrue(self.validate())
        self.assertEqual([f["id"] for f in self.index["features"]], ["F001", "F002", "F003"])

    def test_retirement_chains_preserve_history_and_migration_cycles_fail(self) -> None:
        self.retire()
        old = self.registry["tests"][0]["retirement"]
        self.registry["tests"][2]["status"] = "retired"
        self.registry["tests"][2]["retirement"] = copy.deepcopy(old)
        self.registry["tests"][2]["retirement"]["replacement"] = {"feature_id": "F002", "test_ids": ["F002-AC01"]}
        migrations = self.revisions["revision_log"][0]["migrations"]
        migrations.append(migrations[0] | {"from": ["F003"], "to": ["F002"]})
        self.assertTrue(self.validate())
        migrations.append(migrations[0] | {"from": ["F002"], "to": ["F001"]})
        self.assertFalse(self.validate())

    def test_duplicate_revision_ids_future_versions_and_unversioned_new_fields_fail(self) -> None:
        original = copy.deepcopy(self.revisions)
        self.revisions["revision_log"].append(copy.deepcopy(self.revisions["revision_log"][0]))
        self.assertFalse(self.validate())
        self.revisions = copy.deepcopy(original)
        self.revisions["schema_version"] = 99
        self.assertFalse(self.validate())
        self.revisions = copy.deepcopy(original)
        self.revisions["revision_log"][0].pop("schema_version")
        self.assertFalse(self.validate())
        self.revisions = original
        self.registry["meta"]["schema_version"] = True
        self.assertFalse(self.validate())

    def test_component_merge_preserves_retirement_and_rejects_invalid_chain_atomically(self) -> None:
        self.retire()
        self.assertTrue(self.validate())
        helper = ROOT / ".agents/skills/feature-plan/scripts/merge_test_registry.py"
        self.write("components.json", [])
        command = [sys.executable, "-B", str(helper), "--components", "components.json"]
        path = self.root / "docs/test-registry.json"
        before = path.read_bytes()
        result = subprocess.run(command, cwd=self.root, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(path.read_bytes(), before)
        self.registry["tests"][0]["retirement"]["replacement"]["test_ids"] = ["F999-AC01"]
        self.write("docs/test-registry.json", self.registry)
        before = path.read_bytes()
        result = subprocess.run(command, cwd=self.root, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(path.read_bytes(), before)

    def test_templates_materialize_a_new_project_with_version_two_validation(self) -> None:
        fresh = self.root / "fresh"
        (fresh / "docs").mkdir(parents=True)
        (fresh / "tools").mkdir()
        for name in ("feature-list", "feature-list-revisions", "test-registry"):
            source = ROOT / f"methodology/templates/{name}.json.tmpl"
            (fresh / f"docs/{name}.json").write_bytes(source.read_bytes())
        for relative in ("tools/__init__.py", "tools/lib/__init__.py",
"tools/checks/check-feature-list.py", "tools/lib/feature_evolution.py",
                         "tools/lib/test_selection.py"):
            destination = fresh / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes((ROOT / relative).read_bytes())
        result = subprocess.run([sys.executable, "-B", str(fresh / "tools/checks/check-feature-list.py"), "--eligible"],
                                cwd=fresh, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [])
        self.assertEqual(json.loads((fresh / "docs/test-registry.json").read_text())["meta"]["schema_version"], 2)
        self.retire()
        self.assertTrue(self.validate())
        for name in ("feature-list", "feature-list-revisions", "test-registry"):
            (fresh / f"docs/{name}.json").write_bytes((self.root / f"docs/{name}.json").read_bytes())
        (fresh / "docs/features").mkdir()
        (fresh / "tests").mkdir()
        for path in (self.root / "docs/features").glob("*.json"):
            (fresh / "docs/features" / path.name).write_bytes(path.read_bytes())
        for path in (self.root / "tests").glob("*.gd"):
            (fresh / "tests" / path.name).write_bytes(path.read_bytes())
        command = [sys.executable, "-B", str(fresh / "tools/checks/check-feature-list.py")]
        result = subprocess.run(command, cwd=fresh, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        result = subprocess.run(command + ["--completion-feature", "F001"], cwd=fresh, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2, result.stderr)

    def test_explicit_validation_rejects_unsynchronized_cross_file_edits(self):
        self.revisions["revision_log"][0]["dependency_changes"] = [{"feature": "F002", "before": [], "after": ["F003"]}]
        self.assertFalse(self.validate())
        self.index["features"][1]["depends_on"] = ["F003"]
        self.assertTrue(self.validate())

    def test_retiring_unmaterialized_planned_test_does_not_invent_a_path(self) -> None:
        self.retire()
        self.registry["tests"][0]["path"] = None
        self.assertTrue(self.validate())

    def test_engineering_template_has_no_fabricated_bug_diagnosis_for_other_modes(self) -> None:
        template = (ROOT / "methodology/templates/engineering-feature-detail.json.tmpl").read_text(encoding="utf-8")
        values = {"feature_id": "F003", "description": "Maintain a documented contract", "component_id": "inventory",
                  "acceptance_criterion": "The contract is preserved", "source_or_infrastructure": "infrastructure"}
        for mode in ("bug", "refactor", "maintenance"):
            rendered = template
            for key, value in (values | {"bug_refactor_or_maintenance": mode}).items():
                rendered = rendered.replace("{{" + key + "}}", value)
            detail = json.loads(rendered)
            self.assertIsNone(detail["bug_diagnosis"])
            self.assertEqual(detail["verification"]["test_impact"], {"additional_tests": [], "full_suite_reasons": []})
            valid, _, _ = checker._validate_detail(self.root / "docs/features/F003.json", detail)
            self.assertTrue(valid)

        product = (ROOT / "methodology/templates/feature-detail.json.tmpl").read_text(encoding="utf-8")
        for key, value in (values | {"source": "docs/product.md#contract"}).items():
            product = product.replace("{{" + key + "}}", value)
        detail = json.loads(product)
        self.assertEqual(detail["verification"]["test_impact"], {"additional_tests": [], "full_suite_reasons": []})
        valid, _, _ = checker._validate_detail(self.root / "docs/features/F003.json", detail)
        self.assertTrue(valid)

    def test_bug_diagnosis_requires_root_cause_at_completion(self) -> None:
        path = self.root / "docs/features/F001.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        detail.update(engineering_change="bug")
        detail["verification"]["acceptance_mode"] = "manual"
        detail["verification"]["manual_regression"] = "Repeat the documented reproduction on the external device; deterministic device automation unavailable."
        self.write("docs/features/F001.json", detail)
        self.assertFalse(self.validate())  # Missing diagnosis is not a historical-format exemption.
        detail["bug_diagnosis"] = {"actual": "Reload loses the selected item", "expected": "Reload preserves the selected item",
            "source": "docs/product.md#restore", "reproduction": ["Select an item", "Save and reload"], "root_cause": None}
        self.write("docs/features/F001.json", detail)
        self.assertFalse(self.validate(completion="F001"))
        detail["bug_diagnosis"]["root_cause"] = "The save projection omitted the selected item identifier."
        self.write("docs/features/F001.json", detail)
        self.assertTrue(self.validate(completion="F001"))
        detail["engineering_change"] = "refactor"
        self.write("docs/features/F001.json", detail)
        self.assertFalse(self.validate())

    # 文档措辞和表格格式由静态审查核对；不把说明文档变成精确字符串协议。

    def test_approved_test_impact_has_typed_unique_scope_and_registry_references(self) -> None:
        path = self.root / "docs/features/F002.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        valid_impact = {"additional_tests": [{"id": "F003-AC01", "reason": "Restore crosses this independent contract"}],
                        "full_suite_reasons": ["Public serialization format changes"]}
        detail["verification"]["test_impact"] = valid_impact
        self.write("docs/features/F002.json", detail)
        self.assertTrue(self.validate(completion="F002"))
        for impact in (None, {}, {"additional_tests": [], "full_suite_reasons": [""]},
                       valid_impact | {"additional_tests": [{"id": "F003-AC01", "reason": ""}]},
                       valid_impact | {"additional_tests": valid_impact["additional_tests"] * 2},
                       valid_impact | {"additional_tests": [{"id": "F999-AC01", "reason": "Required"}]},
                       valid_impact | {"full_suite_reasons": ["Required", "Required"]},
                       valid_impact | {"approved": True}):
            with self.subTest(impact=impact):
                detail["verification"]["test_impact"] = impact
                self.write("docs/features/F002.json", detail)
                self.assertFalse(self.validate())

    def test_approved_extra_test_must_be_active_for_current_completion(self) -> None:
        path = self.root / "docs/features/F002.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        detail["verification"]["test_impact"] = {"additional_tests": [{"id": "F003-AC01", "reason": "Related restored state"}],
                                                  "full_suite_reasons": []}
        self.write("docs/features/F002.json", detail)
        self.registry["tests"][2].update(status="planned", path=None)
        self.assertTrue(self.validate())
        self.assertFalse(self.validate(completion="F002"))
        self.registry["tests"][2].update(status="active", path="tests/F003.gd")
        self.assertTrue(self.validate(completion="F002"))

    def test_external_extra_scope_cannot_impersonate_replacement_verification(self) -> None:
        self.retire()
        path = self.root / "docs/features/F003.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        detail["acceptance_criteria"][0]["verification"]["automated_tests"] = []
        detail["verification"]["test_impact"] = {"additional_tests": [{"id": "F003-AC01", "reason": "Additional investigation"}],
                                                  "full_suite_reasons": []}
        self.write("docs/features/F003.json", detail)
        self.assertFalse(self.validate())

    def test_neutral_projection_accepts_safe_later_dependency_without_rewriting_fixture(self) -> None:
        original = copy.deepcopy(self.index)
        data = copy.deepcopy(self.index)
        old = data["features"][-1]
        new = f"F{len(data['features']) + 1:03d}"
        old.update(status="pending", completed_at=None)
        old["depends_on"].append(new)
        data["features"].append({"id": new, "title": "Approved replacement prerequisite", "status": "pending",
                                 "depends_on": [], "estimated_scope": "small", "completed_at": None})
        data["meta"]["total_features"] = len(data["features"])
        valid, _ = checker._validate_index(data)
        self.assertTrue(valid)
        self.assertEqual(self.index, original)

    def test_neutral_ledger_cli_validates_explicit_root_without_host_project_data(self) -> None:
        self.assertTrue(self.validate())
        result = subprocess.run([sys.executable, "-B", str(ROOT / "tools/checks/check-feature-list.py"),
                                 "--repo-root", str(self.root)],
                                cwd=self.root, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)



if __name__ == "__main__":
    unittest.main()
