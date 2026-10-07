# 中立 Feature 记录回归检查依赖、修订和退役语义，不以某个游戏的编号顺序建立规则。
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import copy
import importlib.util
import json
import subprocess
import shutil
import tempfile
import unittest
from unittest import mock


ROOT = PROJECT_ROOT
FRAMEWORK_DEFAULT_DOCS = Path(__file__).resolve().parents[4] / "project-source/defaults/docs"
sys.path.insert(0, str(ROOT / "yaya"))
SPEC = importlib.util.spec_from_file_location("evolution_checker", ROOT / "yaya/tools/checks/check-feature-list.py")
assert SPEC and SPEC.loader
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)


class FeatureEvolutionTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="yaya-evolution-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "docs/features").mkdir(parents=True)
        self.index = {"meta": {}, "features": [
            {"id": f"F{i:03d}", "title": f"Capability {i}",
             "status": "done" if i == 1 else "pending", "depends_on": [],
             "estimated_scope": "small", "completed_at": "2026-01-01T00:00:00Z" if i == 1 else None}
            for i in range(1, 4)
        ]}
        self.registry = {"meta": {"schema_version": 3}, "components": [
            {"id": "inventory", "unit_test_paths": [], "full_suite_on_change": False}
        ], "tests": []}
        for i in range(1, 4):
            fid = f"F{i:03d}"
            path = f"tests/{fid}.gd"
            self.write(path, "extends Node\n")
            self.registry["tests"].append({"id": f"{fid}-AC01", "components": ["inventory"],
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
        self.registry["tests"][0]["status"] = "retired"
        self.registry["tests"][0]["retirement"] = {"reason": "Product superseded the old assertion",
            "source": copy.deepcopy(self.source), "replacement": {"feature_id": "F003", "test_ids": ["F003-AC01"]},
            "revision_id": "rev-contract-01"}
        (self.root / "tests/F001.gd").unlink()

    def test_only_current_ledger_contract_is_accepted(self) -> None:
        self.revisions = {"revision_log": [{"summary": "Old record"}]}
        self.assertFalse(self.validate())

    def test_registry_old_version_and_invalid_logical_ids_are_rejected(self) -> None:
        self.registry["meta"]["schema_version"] = 2
        self.assertFalse(self.validate())
        self.registry["meta"]["schema_version"] = 3
        for test_id in (None, "F002-AC1", "F002-AC01-1", "F002-RT1", "INV-lower-01", "F999-AC01"):
            with self.subTest(test_id=test_id):
                self.registry["tests"].append(self.registry["tests"][1] | {"id": test_id})
                self.assertFalse(self.validate())
            self.registry["tests"].pop()

    def test_multiple_tests_for_one_criterion_keep_their_id_derived_ownership(self) -> None:
        self.registry["tests"].append(self.registry["tests"][1] | {"id": "F002-AC01-02"})
        path = self.root / "docs/features/F002.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        detail["acceptance_criteria"][0]["verification"]["automated_tests"].append("F002-AC01-02")
        self.write("docs/features/F002.json", detail)
        self.assertTrue(self.validate(completion="F002"))
        detail["acceptance_criteria"][0]["verification"]["automated_tests"] = ["F003-AC01"]
        self.write("docs/features/F002.json", detail)
        self.assertFalse(self.validate(completion="F002"))

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

    def test_initial_baseline_records_added_features_and_intent(self) -> None:
        baseline = {"schema_version": 2, "revision_id": "R000", "revised_at": "2026-01-01T00:00:00Z",
                    "anchor_commit": "b" * 40, "synced_at_commit": "b" * 40, "user_intent": None,
                    "summary": "First plan", "added": ["F001", "F002"],
                    "migrations": [], "dependency_changes": []}
        later = self.revisions["revision_log"][0]
        self.revisions["revision_log"] = [baseline, later]
        self.assertTrue(self.validate())
        for change in ({"added": []}, {"added": ["F001", "F001"]}, {"added": ["F009"]},
                       {"user_intent": 3}, {"migrations": later["migrations"]},
                       {"synced_at_commit": "a" * 40}):
            with self.subTest(change=change):
                self.revisions["revision_log"] = [{**baseline, **change}, later]
                self.assertFalse(self.validate())
        missing_intent = {key: value for key, value in baseline.items() if key != "user_intent"}
        self.revisions["revision_log"] = [missing_intent, later]
        self.assertFalse(self.validate())
        self.revisions["revision_log"] = [later, baseline]
        self.assertFalse(self.validate())

    def test_invalid_json_field_types_return_field_diagnostics(self) -> None:
        self.index["features"][1]["depends_on"] = ["F001"]
        self.index["features"][2]["depends_on"] = ["F002"]
        self.revisions["revision_log"].insert(0, {
            "schema_version": 2, "revision_id": "R000", "revised_at": "2026-01-01T00:00:00Z",
            "anchor_commit": "b" * 40, "synced_at_commit": "b" * 40, "user_intent": None,
            "summary": "First plan", "added": ["F001", "F002", "F003"],
            "migrations": [], "dependency_changes": [],
        })
        self.assertTrue(self.validate())
        cases = (
            ("docs/feature-list.json", ("features", 0, "status"), [], "F001.status"),
            ("docs/feature-list.json", ("features", 1, "status"), {}, "F002.status"),
            ("docs/feature-list.json", ("features", 0, "estimated_scope"), {}, "F001.estimated_scope"),
            ("docs/features/F003.json", ("engineering_change",), [], "engineering_change"),
            ("docs/feature-list-revisions.json", ("revision_log", 0, "added"), [{}], "revision_log[0].added"),
        )
        originals = {name: json.loads((self.root / name).read_text(encoding="utf-8"))
                     for name, _, _, _ in cases}
        self.write("components.json", [])
        registry_path = self.root / "docs/test-registry.json"
        registry_before = registry_path.read_bytes()
        for name, keys, value, diagnostic in cases:
            with self.subTest(field=diagnostic):
                for original_name, original in originals.items():
                    self.write(original_name, original)
                changed = copy.deepcopy(originals[name])
                parent = changed
                for key in keys[:-1]:
                    parent = parent[key]
                parent[keys[-1]] = value
                self.write(name, changed)
                commands = [[sys.executable, "-B", str(ROOT / "yaya/tools/checks/check-feature-list.py"),
                             "--repo-root", str(self.root)]]
                if keys[-1] == "added":
                    commands.append([sys.executable, "-B", str(ROOT / "yaya/tools/features/merge-test-registry.py"),
                                     "--repo-root", str(self.root), "--components", "components.json"])
                for command in commands:
                    result = subprocess.run(command, cwd=self.root, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                    self.assertIn(diagnostic, result.stderr)
                    self.assertNotIn("Traceback", result.stderr)
                    self.assertEqual(registry_path.read_bytes(), registry_before)

    def test_passing_check_prints_verdict_but_eligible_prints_only_json(self) -> None:
        self.validate()
        command = [sys.executable, "-B", str(ROOT / "yaya/tools/checks/check-feature-list.py"), "--repo-root", str(self.root)]
        passed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(passed.returncode, 0, passed.stderr)
        self.assertEqual(passed.stdout.strip(), "FEATURE LIST CHECK: PASS")
        eligible = subprocess.run([*command, "--eligible"], cwd=ROOT, capture_output=True, text=True)
        self.assertIsInstance(json.loads(eligible.stdout), list)

    def test_evidence_and_design_files_beside_details_are_not_read_as_details(self) -> None:
        self.assertTrue(self.validate())
        self.write("docs/features/F001-evidence.json", {"schema_version": 9, "feature_id": "F001"})
        (self.root / "docs/features/F001-design.md").write_text("# Design\n", encoding="utf-8")
        self.assertTrue(self.validate())

    def test_historical_done_can_retire_with_traceable_replacement(self) -> None:
        self.retire()
        self.assertTrue(self.validate())
        self.assertFalse(self.validate(completion="F001"))
        result = subprocess.run([sys.executable, "-B", str(ROOT / "yaya/tools/checks/check-feature-list.py"),
            "--repo-root", str(self.root), "--completion-feature", "F001"],
            cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("expected ['active']", result.stderr)

    def test_replacement_may_be_planned_until_its_feature_completes(self) -> None:
        self.retire()
        for path in (None, "tests/future.gd"):
            with self.subTest(path=path):
                self.registry["tests"][2].update(status="planned", path=path)
                self.assertTrue(self.validate())
        self.index["features"][2].update(status="done", completed_at="2026-02-02T00:00:00Z")
        self.assertFalse(self.validate())

    def test_unfinished_feature_can_retire_an_ac_removed_by_approved_revision(self) -> None:
        # Current AC01 replaces a removed historical AC02; current IDs remain sequential.
        self.revisions["revision_log"][0]["migrations"][0].update(**{"from": ["F002"], "to": ["F002"]})
        old = self.registry["tests"][1]
        replacement = copy.deepcopy(old) | {"status": "planned", "path": None}
        self.registry["tests"].append(replacement)
        old.update(id="F002-AC02", status="retired", retirement={"reason": "Approved replacement of the unfinished AC",
            "source": copy.deepcopy(self.source), "replacement": {"feature_id": "F002", "test_ids": ["F002-AC01"]},
            "revision_id": "rev-contract-01"})
        for status in ("pending", "in_progress"):
            with self.subTest(status=status):
                self.index["features"][1]["status"] = status
                self.assertTrue(self.validate())
                self.assertFalse(self.validate(completion="F002"))
        replacement.update(status="active", path="tests/F002.gd")
        self.assertTrue(self.validate(completion="F002"))
        old["id"] = "F001-AC02"
        self.assertFalse(self.validate())  # The historical ID still owns its revision source.
        old["id"] = "F002-AC02"
        old["retirement"]["revision_id"] = "missing-revision"
        self.assertFalse(self.validate())

    def test_acceptance_ids_may_skip_numbers_but_must_increase(self) -> None:
        path = self.root / "docs/features/F002.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        third = {"id": "AC03", "text": "A later contract holds",
                 "verification": {"automated_tests": [], "manual_checks": ["Inspect the later contract"]}}
        detail["acceptance_criteria"].append(third)
        detail["verification"]["acceptance_mode"] = "manual"
        self.write("docs/features/F002.json", detail)
        self.assertTrue(self.validate())  # AC02 was removed; its ID is not reused.
        detail["acceptance_criteria"].reverse()
        self.write("docs/features/F002.json", detail)
        self.assertFalse(self.validate())

    def test_planned_tests_cannot_belong_to_finished_or_obsolete_features(self) -> None:
        self.registry["tests"].append({"id": "F002-RT01", "components": ["inventory"],
            "path": None, "case": None, "status": "planned"})
        for status in ("pending", "in_progress", "blocked"):
            with self.subTest(status=status):
                self.index["features"][1]["status"] = status
                self.assertTrue(self.validate())
        self.index["features"][1]["status"] = "obsolete"
        self.assertFalse(self.validate())

    def test_current_acceptance_tests_still_require_an_existing_criterion(self) -> None:
        path = self.root / "docs/features/F002.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        self.registry["tests"][1].update(id="F002-AC02")
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
        replacement_id = "F003-AC01-02"
        self.registry["tests"].append({**self.registry["tests"][2], "id": replacement_id,
                                       "case": "test_replacement"})
        self.registry["tests"][0]["retirement"]["replacement"]["test_ids"] = [replacement_id]
        path = self.root / "docs/features/F003.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        with mock.patch.object(checker, "_error") as errors:
            self.assertFalse(self.validate())
        errors.assert_called_once_with(
            f"retired test F001-AC01 replacement {replacement_id} is not mapped in Feature F003 verification")
        detail["acceptance_criteria"][0]["verification"]["automated_tests"].append(replacement_id)
        self.write("docs/features/F003.json", detail)
        self.assertTrue(self.validate())

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

    def test_retiring_without_replacement_clears_planned_tests_mappings_and_mode(self) -> None:
        self.registry["tests"][1].update(path=None, case=None, status="planned")
        self.revisions["revision_log"][0]["migrations"][0].update(kind="retire", **{"from": ["F002"], "to": []})
        self.index["features"][1]["status"] = "obsolete"
        del self.registry["tests"][1]
        self.assertFalse(self.validate())
        path = self.root / "docs/features/F002.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        detail["acceptance_criteria"][0]["verification"]["automated_tests"] = []
        detail["verification"]["acceptance_mode"] = None
        self.write("docs/features/F002.json", detail)
        self.assertTrue(self.validate())

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
        self.registry["tests"][0]["path"] = "tests/removed_historical_test.gd"
        self.assertTrue(self.validate())
        helper = ROOT / "yaya/tools/features/merge-test-registry.py"
        self.write("components.json", [])
        command = [sys.executable, "-B", str(helper), "--repo-root", str(self.root),
                   "--components", "components.json"]
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

    def test_templates_materialize_a_new_project_with_current_ledger_validation(self) -> None:
        fresh = self.root / "fresh"
        (fresh / "docs").mkdir(parents=True)
        for name in ("feature-list", "feature-list-revisions", "test-registry"):
            source = FRAMEWORK_DEFAULT_DOCS / f"{name}.json"
            (fresh / f"docs/{name}.json").write_bytes(source.read_bytes())
        # 默认登记表登记了调试台的单元测试目录与依赖方向不变量，新项目随附这些文件。
        shutil.copytree(FRAMEWORK_DEFAULT_DOCS.parent / "dev/debug/_shared/tests", fresh / "dev/debug/_shared/tests")
        shutil.copytree(FRAMEWORK_DEFAULT_DOCS.parent / "tests", fresh / "tests")
        for relative in ("yaya/tools/__init__.py", "yaya/tools/lib/__init__.py",
"yaya/tools/checks/check-feature-list.py", "yaya/tools/lib/feature_evolution.py",
                         "yaya/tools/lib/test_selection.py"):
            destination = fresh / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes((ROOT / relative).read_bytes())
        result = subprocess.run([sys.executable, "-B", str(fresh / "yaya/tools/checks/check-feature-list.py"), "--eligible"],
                                cwd=fresh, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [])
        self.assertEqual(json.loads((fresh / "docs/test-registry.json").read_text())["meta"]["schema_version"], 3)
        self.assertEqual(json.loads((fresh / "docs/feature-list-revisions.json").read_text())["schema_version"], 2)
        self.retire()
        self.assertTrue(self.validate())
        for name in ("feature-list", "feature-list-revisions", "test-registry"):
            (fresh / f"docs/{name}.json").write_bytes((self.root / f"docs/{name}.json").read_bytes())
        (fresh / "docs/features").mkdir()
        for path in (self.root / "docs/features").glob("*.json"):
            (fresh / "docs/features" / path.name).write_bytes(path.read_bytes())
        for path in (self.root / "tests").glob("*.gd"):
            (fresh / "tests" / path.name).write_bytes(path.read_bytes())
        command = [sys.executable, "-B", str(fresh / "yaya/tools/checks/check-feature-list.py")]
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
        template = (ROOT / "yaya/methodology/templates/engineering-feature-detail.json.tmpl").read_text(encoding="utf-8")
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

        product = (ROOT / "yaya/methodology/templates/feature-detail.json.tmpl").read_text(encoding="utf-8")
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
        replacement_id = "F003-AC01-02"
        self.registry["tests"].append({**self.registry["tests"][2], "id": replacement_id,
                                       "case": "test_replacement"})
        self.registry["tests"][0]["retirement"]["replacement"]["test_ids"] = [replacement_id]
        path = self.root / "docs/features/F003.json"
        detail = json.loads(path.read_text(encoding="utf-8"))
        detail["verification"]["test_impact"] = {"additional_tests": [{"id": replacement_id, "reason": "Additional investigation"}],
                                                  "full_suite_reasons": []}
        self.write("docs/features/F003.json", detail)
        with mock.patch.object(checker, "_error") as errors:
            self.assertFalse(self.validate())
        errors.assert_called_once_with(
            f"retired test F001-AC01 replacement {replacement_id} is not mapped in Feature F003 verification")
        detail["acceptance_criteria"][0]["verification"]["automated_tests"].append(replacement_id)
        self.write("docs/features/F003.json", detail)
        self.assertTrue(self.validate())

    def test_neutral_projection_accepts_safe_later_dependency_without_rewriting_fixture(self) -> None:
        original = copy.deepcopy(self.index)
        data = copy.deepcopy(self.index)
        old = data["features"][-1]
        new = f"F{len(data['features']) + 1:03d}"
        old.update(status="pending", completed_at=None)
        old["depends_on"].append(new)
        data["features"].append({"id": new, "title": "Approved replacement prerequisite", "status": "pending",
                                 "depends_on": [], "estimated_scope": "small", "completed_at": None})
        valid, _ = checker._validate_index(data)
        self.assertTrue(valid)
        self.assertEqual(self.index, original)

    def test_neutral_ledger_cli_validates_explicit_root_without_host_project_data(self) -> None:
        self.assertTrue(self.validate())
        result = subprocess.run([sys.executable, "-B", str(ROOT / "yaya/tools/checks/check-feature-list.py"),
                                 "--repo-root", str(self.root)],
                                cwd=self.root, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)



if __name__ == "__main__":
    unittest.main()
