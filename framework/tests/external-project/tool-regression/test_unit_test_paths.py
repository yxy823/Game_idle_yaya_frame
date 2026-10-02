# 用中立 Registry 和测试路径检查登记/合并/引用，避免默认依赖旧项目的 feature-list。
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import copy
import json
import os
import subprocess
import tempfile
import unittest

REPO_ROOT = PROJECT_ROOT
MERGE_HELPER = (
    REPO_ROOT / "tools/features/merge-test-registry.py"
)
CHECKER = REPO_ROOT / "tools/checks/check-feature-list.py"


class UnitTestPathsTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="unit-registry-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "docs").mkdir()
        self.registry_path = self.root / "docs/test-registry.json"
        self._write_json(self.registry_path, {
            "meta": {"schema_version": 3}, "components": [], "tests": [],
        })
        self._write_json(self.root / "docs/feature-list.json", {"meta": {}, "features": []})
        self._write_json(self.root / "docs/feature-list-revisions.json", {"schema_version": 2, "revision_log": []})
        self.candidates_path = self.root / "components.json"

    def _component(self, *paths: str) -> dict:
        return {
            "id": "inventory",
            "unit_test_paths": list(paths),
            "full_suite_on_change": False,
        }

    def _write_json(self, path: Path, data: object) -> None:
        path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

    def _suite(self) -> str:
        path = "tests/unit/inventory/test_inventory.gd"
        suite = self.root / path
        suite.parent.mkdir(parents=True, exist_ok=True)
        suite.write_text(
            "extends GdUnitTestSuite\n\n"
            "func test_inventory() -> void:\n\tassert_bool(true).is_true()\n",
            encoding="utf-8",
        )
        return path

    def _merge(self, components: list[dict] | dict) -> subprocess.CompletedProcess[str]:
        self._write_json(self.candidates_path, components)
        return self._merge_file()

    def _merge_file(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "-B", str(MERGE_HELPER),
             "--repo-root", str(self.root), "--components", str(self.candidates_path)],
            cwd=self.root, text=True, capture_output=True, check=False,
        )

    def _strict(self) -> subprocess.CompletedProcess[str]:
        checker = self.root / "tools/checks/check-feature-list.py"
        # 只物化校验器所需的包和模块，夹具布局与生成项目一致。
        for relative in ("tools/__init__.py", "tools/lib/__init__.py",
"tools/checks/check-feature-list.py", "tools/lib/feature_evolution.py",
                         "tools/lib/test_selection.py"):
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes((REPO_ROOT / relative).read_bytes())
        return subprocess.run(
            [sys.executable, "-B", str(checker)],
            cwd=self.root, text=True, capture_output=True, check=False,
        )

    def _registry(self) -> dict:
        return json.loads(self.registry_path.read_text(encoding="utf-8"))

    def test_new_component_without_suites_has_no_unit_targets(self) -> None:
        result = self._merge([self._component()])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self._registry()["components"][0]["unit_test_paths"], [])
        self.assertFalse((self.root / "tests/unit/inventory").exists())
        self.assertEqual(self._registry()["tests"], [])
        self.assertEqual(self._strict().returncode, 0)

    def test_explicit_project_resolves_candidates_and_suites_outside_working_directory(self) -> None:
        component = self._component(self._suite())
        self._write_json(self.candidates_path, [component])
        result = subprocess.run(
            [sys.executable, "-B", str(MERGE_HELPER), "--repo-root", str(self.root),
             "--components", "components.json"],
            cwd=self.root.parent, text=True, capture_output=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self._registry()["components"], [component])

    def test_default_project_is_script_owner_not_another_project_in_cwd(self) -> None:
        for relative in ("tools/__init__.py", "tools/lib/__init__.py",
                         "tools/features/merge-test-registry.py", "tools/lib/atomic_json.py",
                         "tools/lib/feature_evolution.py", "tools/lib/test_selection.py"):
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes((REPO_ROOT / relative).read_bytes())
        component = self._component(self._suite())
        self._write_json(self.candidates_path, [component])
        foreign = self.root / "another-project"
        (foreign / "docs").mkdir(parents=True)
        for name in ("test-registry.json", "feature-list.json", "feature-list-revisions.json"):
            (foreign / "docs" / name).write_bytes((self.root / "docs" / name).read_bytes())
        foreign_registry = foreign / "docs/test-registry.json"
        original = foreign_registry.read_bytes()
        result = subprocess.run(
            [sys.executable, "-B", str(self.root / "tools/features/merge-test-registry.py"),
             "--components", "components.json"],
            cwd=foreign, text=True, capture_output=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self._registry()["components"], [component])
        self.assertEqual(foreign_registry.read_bytes(), original)

    def test_existing_suite_file_and_directory_are_retained(self) -> None:
        from tools.lib.test_selection import normalized_path
        suite = self._suite()
        for path in (suite, "tests/unit/inventory", "./" + suite, suite.replace("/", "\\")):
            with self.subTest(path=path):
                component = self._component(path)
                self._write_json(self.registry_path, {
                    "meta": {"schema_version": 3},
                    "components": [component], "tests": [],
                })
                result = self._merge([component, {
                    "id": "new_component", "unit_test_paths": [],
                    "full_suite_on_change": False,
                }])
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self._registry()["components"][0], component)
                self.assertEqual(self._strict().returncode, 0)
                self.assertEqual(normalized_path(self.root, path),
                                 path.replace("\\", "/").removeprefix("./"))

    def _assert_path_rejected_before_write(self, path: str) -> None:
        from tools.lib.test_selection import normalized_path, SelectionError
        with self.assertRaisesRegex(SelectionError, "repository"):
            normalized_path(self.root, path)
        registry = {"meta": {"schema_version": 3}, "components": [], "tests": []}
        self._write_json(self.registry_path, registry)
        before = self.registry_path.read_bytes()
        result = self._merge([self._component(path)])
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("repository", result.stderr)
        self.assertEqual(self.registry_path.read_bytes(), before)
        # 已有组件和 active 测试也必须被普通检查与合并入口拒绝。
        for active_test in (False, True):
            with self.subTest(active_test=active_test):
                registry["components"] = [self._component() if active_test else self._component(path)]
                registry["tests"] = [{"id": "INV-INVENTORY-01", "components": ["inventory"],
                                      "path": path, "case": None, "status": "active"}] if active_test else []
                self._write_json(self.registry_path, registry)
                before = self.registry_path.read_bytes()
                for result in (self._merge([]), self._strict()):
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                    self.assertIn("repository", result.stderr)
                    self.assertNotIn("Traceback", result.stderr)
                self.assertEqual(self.registry_path.read_bytes(), before)

    def test_nonrelative_existing_paths_are_rejected_before_write(self) -> None:
        suite = self._suite()
        with tempfile.TemporaryDirectory(prefix="external-registry-", dir=self.root.parent) as external:
            outside = Path(external)
            (outside / "test_external.gd").write_text("extends GdUnitTestSuite\n", encoding="utf-8")
            for path in (f"../{outside.name}", f"..\\{outside.name}\\test_external.gd",
                         str(outside), str(self.root / suite), "tests/../" + suite):
                with self.subTest(path=path):
                    self.assertTrue((self.root / path).exists())
                    self._assert_path_rejected_before_write(path)

    def test_resolved_external_link_is_rejected_before_write(self) -> None:
        with tempfile.TemporaryDirectory(prefix="linked-registry-", dir=self.root.parent) as external:
            link = self.root / "linked-tests"
            try:
                link.symlink_to(external, target_is_directory=True)
            except OSError as exc:
                if os.name == "nt" and getattr(exc, "winerror", None) == 1314:
                    self.skipTest("Windows account cannot create symbolic links")
                raise
            try:
                self._assert_path_rejected_before_write("linked-tests")
            finally:
                link.unlink()

    def test_resource_prefix_remains_a_selector_adapter_not_a_registry_alias(self) -> None:
        from tools.lib.test_selection import normalized_path
        suite = self._suite()
        self.assertEqual(normalized_path(self.root, "res://" + suite), suite)
        before = self.registry_path.read_bytes()
        result = self._merge([self._component("res://" + suite)])
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(self.registry_path.read_bytes(), before)

    def test_missing_initial_ledger_blocks_merge_and_check_without_recreation(self) -> None:
        for name in ("feature-list.json", "feature-list-revisions.json", "test-registry.json"):
            with self.subTest(name=name):
                path = self.root / "docs" / name
                original = path.read_bytes()
                registry = self.registry_path.read_bytes()
                path.unlink()
                result = self._merge([self._component()])
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                checked = self._strict()
                self.assertEqual(checked.returncode, 2, checked.stdout + checked.stderr)
                self.assertIn(name, checked.stderr)
                self.assertFalse(path.exists())
                if path != self.registry_path:
                    self.assertEqual(self.registry_path.read_bytes(), registry)
                path.write_bytes(original)

    def test_missing_candidate_suite_preserves_registry(self) -> None:
        original = self.registry_path.read_bytes()
        result = self._merge([self._component("tests/unit/inventory")])
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("unit_test_paths", result.stderr)
        self.assertIn("tests/unit/inventory", result.stderr)
        self.assertEqual(self.registry_path.read_bytes(), original)

    def test_invalid_candidate_preserves_existing_registry_bytes(self) -> None:
        self.assertEqual(self._merge([self._component()]).returncode, 0)
        original = self.registry_path.read_bytes()
        result = self._merge([{
            "id": "new_component", "unit_test_paths": ["tests/unit/future"],
            "full_suite_on_change": False,
        }])
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(self.registry_path.read_bytes(), original)

    def test_deleted_registered_suite_blocks_merge_without_silent_removal(self) -> None:
        suite = self._suite()
        self.assertEqual(self._merge([self._component(suite)]).returncode, 0)
        original = self.registry_path.read_bytes()
        (self.root / suite).unlink()
        result = self._merge([])
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn(suite, result.stderr)
        self.assertEqual(self.registry_path.read_bytes(), original)

    def test_deleted_registered_suite_blocks_strict_validation(self) -> None:
        suite = self._suite()
        self.assertEqual(self._merge([self._component(suite)]).returncode, 0)
        original = self.registry_path.read_bytes()
        (self.root / suite).unlink()
        result = self._strict()
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("unit_test_paths", result.stderr)
        self.assertIn(suite, result.stderr)
        self.assertEqual(self.registry_path.read_bytes(), original)

    def test_merge_preserves_existing_registry_data_and_is_idempotent(self) -> None:
        suite = self._suite()
        component = self._component(suite)
        component.update(full_suite_on_change=True, note="keep component metadata")
        before = {
            "meta": {"schema_version": 3, "note": "keep schema metadata"},
            "components": [component],
            "tests": [{
                "id": "INV-INVENTORY-01",
                "components": ["inventory"], "path": suite,
                "case": "test_inventory", "status": "active",
            }],
        }
        self._write_json(self.registry_path, before)
        addition = {"id": "new_component", "unit_test_paths": [],
                    "full_suite_on_change": False}
        result = self._merge([component, addition])
        self.assertEqual(result.returncode, 0, result.stderr)
        expected = copy.deepcopy(before)
        expected["components"].append(addition)
        self.assertEqual(self._registry(), expected)
        original = self.registry_path.read_bytes()
        self.assertEqual(self._merge([component, addition]).returncode, 0)
        self.assertEqual(self.registry_path.read_bytes(), original)
        self.assertEqual(self._strict().returncode, 0)

    def test_existing_component_conflict_is_not_overwritten(self) -> None:
        self.assertEqual(self._merge([self._component()]).returncode, 0)
        original = self.registry_path.read_bytes()
        changed = self._component()
        changed["full_suite_on_change"] = True
        result = self._merge([changed])
        self.assertEqual(result.returncode, 2)
        self.assertIn("conflicts", result.stderr)
        self.assertEqual(self.registry_path.read_bytes(), original)

    def test_merge_and_check_reject_the_same_invalid_registry_without_rewriting(self) -> None:
        suite = self._suite()
        valid = {"meta": {"schema_version": 3}, "components": [self._component()],
                 "tests": [{"id": "INV-INVENTORY-01", "components": ["inventory"],
                            "path": suite, "case": "test_inventory", "status": "active"}]}
        mutations = (
            lambda d: d["meta"].update(schema_version=True),
            lambda d: d["components"].append(copy.deepcopy(d["components"][0])),
            lambda d: d["tests"].append(copy.deepcopy(d["tests"][0])),
            lambda d: d["tests"][0].update(id="unknown"),
            lambda d: d["tests"][0].update(components=["missing"]),
            lambda d: d["tests"][0].update(status=[]),
            lambda d: d["tests"][0].update(path="tests/missing.gd"),
            lambda d: d["tests"][0].update(case=[]),
        )
        for index, mutate in enumerate(mutations):
            with self.subTest(index=index):
                invalid = copy.deepcopy(valid)
                mutate(invalid)
                self._write_json(self.registry_path, invalid)
                before = self.registry_path.read_bytes()
                merged = self._merge([{"id": "extra", "unit_test_paths": [], "full_suite_on_change": False}])
                checked = self._strict()
                for result in (merged, checked):
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                    self.assertNotIn("Traceback", result.stderr)
                self.assertEqual(self.registry_path.read_bytes(), before)

    def test_ambiguous_registry_is_rejected_by_all_readers_without_rewrite(self) -> None:
        from tools.lib.test_selection import read_json, SelectionError
        registry = {
            "meta": {"schema_version": 3}, "components": [self._component()],
            "tests": [{"id": "INV-INVENTORY-01",
                       "components": ["inventory"], "path": None, "case": None,
                       "status": "planned"}],
        }
        encoded = json.dumps(registry)
        payloads = [
            (encoded[:-1] + ', "tests": []}', "duplicate JSON key"),
            (encoded.replace('"full_suite_on_change": false',
                             '"full_suite_on_change": true, "full_suite_on_change": false'),
             "duplicate JSON key"),
        ]
        payloads.extend((encoded[:-1] + ', "note": ' + value + '}', "invalid number")
                        for value in ("NaN", "Infinity", "-Infinity"))
        for payload, error in payloads:
            with self.subTest(payload=payload):
                self.registry_path.write_text(payload, encoding="utf-8")
                original = self.registry_path.read_bytes()
                result = self._merge([{"id": "extra", "unit_test_paths": [], "full_suite_on_change": False}])
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertIn(error, result.stderr)
                self.assertEqual(self.registry_path.read_bytes(), original)
                checked = self._strict()
                self.assertEqual(checked.returncode, 2, checked.stdout + checked.stderr)
                self.assertIn(error, checked.stderr)
                with self.assertRaisesRegex(SelectionError, error):
                    read_json(self.registry_path)
                self.assertEqual(self.registry_path.read_bytes(), original)

    def test_duplicate_candidate_keys_preserve_registry_and_candidate_originals(self) -> None:
        self.assertEqual(self._merge([self._component()]).returncode, 0)
        original = self.registry_path.read_bytes()
        candidate = json.dumps({"id": "extra", "unit_test_paths": [], "full_suite_on_change": False})
        payloads = ['{"components": [' + candidate + '], "components": []}',
                    '[' + candidate[:-1] + ', "id": "other"}]']
        for payload in payloads:
            with self.subTest(payload=payload):
                self.candidates_path.write_text(payload, encoding="utf-8")
                candidate_bytes = self.candidates_path.read_bytes()
                result = self._merge_file()
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertIn("duplicate JSON key", result.stderr)
                self.assertEqual(self.registry_path.read_bytes(), original)
                self.assertEqual(self.candidates_path.read_bytes(), candidate_bytes)

    def test_unique_candidates_keep_array_and_object_formats(self) -> None:
        from tools.lib.test_selection import read_json, SelectionError
        components = [self._component()]
        for candidates in (components, {"components": components}):
            with self.subTest(candidates=candidates):
                result = self._merge(candidates)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(self._strict().returncode, 0)
                self.assertEqual(read_json(self.registry_path)["components"], components)
                if isinstance(candidates, list):
                    with self.assertRaisesRegex(SelectionError, "expected JSON object"):
                        read_json(self.candidates_path)

    def test_runner_still_rejects_registered_target_with_zero_discovery(self) -> None:
        suite = self._suite()
        target = "tests/unit/inventory"
        self.assertEqual(self._merge([self._component(target)]).returncode, 0)
        (self.root / suite).unlink()
        self.assertEqual(self._merge([]).returncode, 0)
        self.assertEqual(self._registry()["components"][0]["unit_test_paths"], [target])
        self.assertEqual(self._strict().returncode, 0)
        # The directory still exists, so filesystem checks retain its selector.
        # The runner's zero-discovery report, modeled below, must fail instead.
        from tools.lib.test_run_evidence import read_junit_cases
        report = self.root / "results.xml"
        report.write_text('<testsuites tests="0" failures="0" skipped="0" flaky="0"/>', encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "zero|no tests|no executed"):
            read_junit_cases(report)


if __name__ == "__main__":
    unittest.main()
