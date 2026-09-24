# 用中立 Registry 和测试路径检查登记/合并/引用，避免默认依赖旧项目的 feature-list。
from __future__ import annotations
from project_context import PROJECT_ROOT

import copy
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = PROJECT_ROOT
MERGE_HELPER = (
    REPO_ROOT / ".agents/skills/feature-plan/scripts/merge_test_registry.py"
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
            "meta": {"schema_version": 2}, "components": [], "tests": [],
        })
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
             "--components", str(self.candidates_path)],
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

    def test_existing_suite_file_and_directory_are_retained(self) -> None:
        suite = self._suite()
        for path in (suite, "tests/unit/inventory"):
            with self.subTest(path=path):
                component = self._component(path)
                self._write_json(self.registry_path, {
                    "meta": {"schema_version": 2},
                    "components": [component], "tests": [],
                })
                result = self._merge([component, {
                    "id": "new_component", "unit_test_paths": [],
                    "full_suite_on_change": False,
                }])
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self._registry()["components"][0], component)
                self.assertEqual(self._strict().returncode, 0)

    def test_missing_registry_is_not_recreated(self) -> None:
        self.registry_path.unlink()
        result = self._merge([self._component()])
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertFalse(self.registry_path.exists())

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
            "meta": {"schema_version": 2, "note": "keep schema metadata"},
            "components": [component],
            "tests": [{
                "id": "INV-INVENTORY-01", "kind": "invariant",
                "source_feature": None, "criterion_id": None,
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

    def test_ambiguous_registry_is_rejected_by_all_readers_without_rewrite(self) -> None:
        from tools.lib.test_selection import read_json, SelectionError
        registry = {
            "meta": {"schema_version": 2}, "components": [self._component()],
            "tests": [{"id": "INV-INVENTORY-01", "kind": "invariant",
                       "source_feature": None, "criterion_id": None,
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
