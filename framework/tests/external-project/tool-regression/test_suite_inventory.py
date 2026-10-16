from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import json
import os
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(PROJECT_ROOT / "yaya"))
from tools.lib.test_run_evidence import (
    RunEvidenceError, expected_gdunit_cases, require_coverage, verify_runtime_discovery,
)


class SuiteInventoryTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="yaya-suite-inventory-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)

    def write(self, name: str, source: str) -> Path:
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source, encoding="utf-8")
        return path

    def test_directory_inventory_excludes_non_suite_test_named_methods(self) -> None:
        self.write("tests/unit/suite.gd", "extends GdUnitTestSuite\nfunc test_real():\n\tpass\n")
        self.write("tests/unit/helper.gd", "extends RefCounted\nfunc test_condition():\n\treturn true\n")
        self.write("tests/unit/fixture.gd", "extends Node\nfunc test_input():\n\tpass\n")
        cases = expected_gdunit_cases(self.root, ["tests/unit"])
        self.assertEqual([(case["path"], case["case"]) for case in cases],
                         [("tests/unit/suite.gd", "test_real")])

    def test_class_name_and_script_path_inheritance_retain_real_suites(self) -> None:
        self.write("support/base.gd", "class_name ExampleSuiteBase\nextends GdUnitTestSuite\n")
        self.write("support/middle.gd", 'extends "res://support/base.gd"\n')
        self.write("tests/by_class.gd", "extends ExampleSuiteBase\nfunc test_named():\n\tpass\n")
        self.write("tests/by_path.gd", 'extends "res://support/middle.gd"\nfunc test_path():\n\tpass\n')
        self.write("tests/by_relative.gd", 'extends "../support/middle.gd"\nfunc test_relative():\n\tpass\n')
        cases = expected_gdunit_cases(self.root, ["tests"])
        self.assertEqual({case["case"] for case in cases}, {"test_named", "test_path", "test_relative"})

    def test_non_suite_inheritance_and_string_examples_do_not_create_suites(self) -> None:
        self.write("support/helper.gd", "class_name ExampleHelper\nextends RefCounted\n")
        self.write("tests/helper_child.gd", "extends ExampleHelper\nfunc test_condition():\n\treturn true\n")
        self.write("tests/path_child.gd", 'extends "res://support/helper.gd"\nfunc test_condition():\n\treturn true\n')
        self.write("tests/example.gd", 'extends RefCounted\nconst SAMPLE = """\nextends GdUnitTestSuite\n"""\n'
                   "# extends GdUnitTestSuite\nfunc test_documentation():\n\tpass\n")
        self.assertEqual(expected_gdunit_cases(self.root, ["tests"]), [])

    def test_inline_class_declaration_and_direct_vendor_script_base_are_suites(self) -> None:
        self.write("tests/inline.gd", "class_name InlineSuite extends GdUnitTestSuite # declaration\nfunc test_inline():\n\tpass\n")
        self.write("addons/gdUnit4/src/GdUnitTestSuite.gd", "class_name GdUnitTestSuite\nextends Node\n")
        self.write("tests/by_script.gd", "extends 'res://addons/gdUnit4/src/GdUnitTestSuite.gd' # base\nfunc test_script():\n\tpass\n")
        self.assertEqual({case["case"] for case in expected_gdunit_cases(self.root, ["tests"])},
                         {"test_inline", "test_script"})

    def test_an_unreadable_directory_stops_the_inventory(self) -> None:
        self.write("tests/readable/suite.gd", "extends GdUnitTestSuite\nfunc test_real():\n\tpass\n")
        locked = self.write("tests/locked/suite.gd", "extends GdUnitTestSuite\nfunc test_hidden():\n\tpass\n").parent
        real = os.scandir

        def scandir(path="."):
            if Path(path) == locked:
                raise PermissionError(13, "Access is denied", str(path))
            return real(path)

        with mock.patch.object(os, "scandir", scandir), self.assertRaisesRegex(RunEvidenceError, "cannot list"):
            expected_gdunit_cases(self.root, ["tests"])

    def test_godot_ignored_sample_is_not_required_as_an_active_suite(self) -> None:
        self.write("tests/active.gd", "extends GdUnitTestSuite\nfunc test_active():\n\tpass\n")
        self.write("tests/samples/.gdignore", "")
        self.write("tests/samples/invalid.gd", "extends GdUnitTestSuite\nfunc test_sample():\n\tpass\n")
        self.assertEqual([case["case"] for case in expected_gdunit_cases(self.root, ["tests"])], ["test_active"])

    def test_cyclic_or_missing_script_ancestry_cannot_silently_remove_coverage(self) -> None:
        self.write("tests/cyclic.gd", 'extends "res://support/base.gd"\nfunc test_cycle():\n\tpass\n')
        self.write("support/base.gd", 'extends "res://tests/cyclic.gd"\n')
        with self.assertRaisesRegex(RunEvidenceError, "cyclic"):
            expected_gdunit_cases(self.root, ["tests"])
        self.write("tests/cyclic.gd", 'extends "res://support/missing.gd"\nfunc test_missing():\n\tpass\n')
        with self.assertRaisesRegex(ValueError, "does not exist"):
            expected_gdunit_cases(self.root, ["tests"])

    def test_suite_base_declaring_test_methods_is_rejected(self) -> None:
        self.write("tests/base.gd", "extends GdUnitTestSuite\nfunc test_shared():\n\tpass\n")
        self.write("tests/child_test.gd", 'extends "res://tests/base.gd"\nfunc test_own():\n\tpass\n')
        with self.assertRaisesRegex(RunEvidenceError, "base script declares test_ methods: tests/base.gd"):
            expected_gdunit_cases(self.root, ["tests"])

    def test_omitted_or_skipped_genuine_suite_still_fails_coverage(self) -> None:
        self.write("tests/suite.gd", "extends GdUnitTestSuite\nfunc test_real():\n\tpass\n")
        declarations = expected_gdunit_cases(self.root, ["tests"])
        for cases in ([], [{"id": "tests/suite.gd::test_real", "path": "tests/suite.gd",
                           "case": "test_real", "status": "skipped"}]):
            with self.subTest(cases=cases), self.assertRaises(RunEvidenceError):
                require_coverage(cases, declarations)

    def test_missing_expanded_parameter_case_still_fails_runtime_reconciliation(self) -> None:
        records = [{"id": f"tests/suite.gd::test_parameter:{index}", "path": "tests/suite.gd",
                    "case": f"test_parameter:{index}", "method": "test_parameter"} for index in range(2)]
        discovery = self.write("discovery.json", json.dumps({"schema_version": 1, "engine_pid": 123, "cases": records}))
        incomplete = [{key: value for key, value in records[0].items() if key != "method"} | {"status": "passed"}]
        with self.assertRaisesRegex(RunEvidenceError, "sets differ"):
            verify_runtime_discovery(discovery, 123, incomplete)


if __name__ == "__main__":
    unittest.main()
