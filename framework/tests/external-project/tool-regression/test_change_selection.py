"""Content-change test selection: base revision, inferred components and dependency graph."""
# 合成一个小项目和 Git 仓库，只检查选择结果；不启动 Godot，也不产生运行证据。
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import importlib.util
import io
import json
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock

from tools.lib.dependency_graph import build_graph
from tools.lib.test_run_evidence import expected_gdunit_cases
from tools.lib.test_selection import SelectionError, build_changed_selection, build_selection

SUITE = "extends GdUnitTestSuite\nfunc test_case():\n\tpass\n"
RUNNER_SPEC = importlib.util.spec_from_file_location(
    "change_selection_runner", PROJECT_ROOT / "yaya/tools/testing/run-gdunit-tests.py")
runner = importlib.util.module_from_spec(RUNNER_SPEC)
sys.modules[RUNNER_SPEC.name] = runner
with mock.patch.object(sys, "path", [str(PROJECT_ROOT / "yaya"), *sys.path]):
    RUNNER_SPEC.loader.exec_module(runner)


class ChangeSelectionTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="yaya-change-selection-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.write(".gitignore", "reports/\n")
        self.write("project.godot", "config_version=5\n")
        self.write("game/inventory/inventory.gd", "extends RefCounted\n")
        self.write("game/combat/combat.gd", "extends RefCounted\n")
        self.write("tests/unit/inventory/inventory_test.gd", SUITE)
        self.write("tests/unit/combat/combat_test.gd", SUITE)
        self.write("tests/features/F001/acceptance_test.gd", SUITE)
        self.registry = {"meta": {"schema_version": 4}, "components": [
            {"id": "inventory", "unit_test_paths": ["tests/unit/inventory"], "full_suite_on_change": False,
             "source_paths": ["game/inventory/**"]},
            {"id": "combat", "unit_test_paths": ["tests/unit/combat"], "full_suite_on_change": False,
             "source_paths": ["game/combat/**"]}],
            "tests": [{"id": "F001-AC01", "components": ["inventory"], "path": "tests/features/F001/acceptance_test.gd",
                       "case": "test_case", "status": "active"}]}
        self.write_json("docs/test-registry.json", self.registry)
        self.write_json("docs/feature-list.json", {"meta": {}, "features": [
            {"id": "F001", "status": "in_progress", "depends_on": [], "completed_at": None}]})
        self.detail = {"id": "F001", "affected_components": ["inventory"],
                       "acceptance_criteria": [{"id": "AC01", "text": "Contract",
                           "verification": {"automated_tests": ["F001-AC01"], "manual_checks": []}}],
                       "verification": {"acceptance_mode": "automated", "regression_tests": [],
                                        "manual_regression": None}}
        self.write_json("docs/features/F001.json", self.detail)
        self.git("init")
        self.git("config", "user.name", "Selection Test")
        self.git("config", "user.email", "test@example.invalid")
        self.commit("fixture")
        self.base = self.git("rev-parse", "HEAD")
        self.detail["base_revision"] = self.base
        self.write_json("docs/features/F001.json", self.detail)

    def write(self, name: str, content: str) -> None:
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="\n")

    def write_json(self, name: str, value: object) -> None:
        self.write(name, json.dumps(value) + "\n")

    def git(self, *args: str) -> str:
        result = subprocess.run(["git", "-C", str(self.root), *args], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def commit(self, message: str) -> None:
        self.git("add", "-A")
        self.git("commit", "-m", message)

    def start_after(self, message: str) -> None:
        """Commit the fixture additions and move F001's base past them."""
        self.commit(message)
        self.detail["base_revision"] = self.git("rev-parse", "HEAD")
        self.write_json("docs/features/F001.json", self.detail)

    def selection(self) -> dict:
        return build_selection(self.root, "F001")

    def required_paths(self, selection: dict) -> set[str]:
        return {item["path"] for item in selection["required"]}

    def test_undeclared_claimed_change_adds_component_tests_and_lists_trigger(self) -> None:
        self.write("game/combat/combat.gd", "extends RefCounted\nvar damage := 2\n")
        selection = self.selection()
        self.assertIn("tests/unit/combat", self.required_paths(selection))
        self.assertEqual(selection["inferred_components"], [{"id": "combat", "files": ["game/combat/combat.gd"]}])
        self.assertFalse(selection["full_suite"]["required"])

    def test_indirect_dependency_selects_suite_with_chain_across_notations(self) -> None:
        self.write("game/shared/b.gd", "extends RefCounted\nclass_name SharedB\n")
        self.write("game/shared/b.gd.uid", "uid://bshared\n")
        self.write("game/shared/a.gd", 'extends "b.gd"\n# preload("res://game/combat/combat.gd")\n')
        self.write("tests/features/t.gd", SUITE + 'const A := preload("res://game/shared/a.gd")\n')
        self.write("game/shared/uses_class.gd", "extends RefCounted\nvar value: SharedB\n")
        self.write("game/shared/scene.tscn", '[gd_scene format=3 uid="uid://scene"]\n\n'
                   '[ext_resource type="Script" uid="uid://bshared" id="1"]\n\n'
                   '[sub_resource type="GDScript" id="2"]\nscript/source = "extends Node\\nconst S = '
                   'preload(\\"res://game/shared/embedded.gd\\")\\n"\n\n'
                   '[node name="Root" type="Node" instance_placeholder="res://game/shared/placeholder.tscn"]\n')
        self.write("game/shared/look.gdshader", '#include "res://game/shared/common.gdshaderinc"\n')
        self.write("game/autoload/events.gd", "extends Node\n")
        self.write("project.godot", 'config_version=5\n\n[autoload]\n\nEvents="*res://game/autoload/events.gd"\n')
        self.write("game/shared/listener.gd", 'extends Node\nfunc _ready():\n\tget_node("/root/Events")\n')
        graph = build_graph(self.root)
        self.assertEqual(graph["game/shared/a.gd"], {"game/shared/b.gd"})
        self.assertIn("game/shared/b.gd", graph["game/shared/uses_class.gd"])
        self.assertEqual(graph["game/shared/scene.tscn"],
                         {"game/shared/b.gd", "game/shared/embedded.gd", "game/shared/placeholder.tscn"})
        self.assertEqual(graph["game/shared/look.gdshader"], {"game/shared/common.gdshaderinc"})
        self.assertEqual(graph["game/shared/listener.gd"], {"game/autoload/events.gd", "project.godot"})
        self.start_after("shared code")
        self.write("game/shared/b.gd", "extends RefCounted\nclass_name SharedB\nvar changed := true\n")
        suite = next(item for item in self.selection()["dependency_suites"] if item["path"] == "tests/features/t.gd")
        self.assertEqual(suite["reasons"], ["dependency-graph:game/shared/b.gd"])
        self.assertEqual(suite["chain"], ["tests/features/t.gd", "game/shared/a.gd", "game/shared/b.gd"])
        self.assertIn("tests/features/t.gd", self.required_paths(self.selection()))

    def test_change_between_features_is_selected_by_next_feature(self) -> None:
        self.write_json("docs/feature-list.json", {"meta": {}, "features": [
            {"id": "F001", "status": "done", "depends_on": [], "completed_at": "2026-10-01T00:00:00Z"},
            {"id": "F002", "status": "pending", "depends_on": [], "completed_at": None}]})
        self.write_json("docs/features/F001-evidence.json", {"git_revision": self.base})
        self.write_json("docs/features/F002.json", {**self.detail, "id": "F002", "affected_components": ["inventory"],
                                                    "base_revision": None, "acceptance_criteria": [
                                                        {"id": "AC01", "text": "Manual", "verification": {
                                                            "automated_tests": [], "manual_checks": ["Look"]}}],
                                                    "verification": {"acceptance_mode": "manual",
                                                                     "regression_tests": []}})
        self.commit("F001 done")
        self.write("game/combat/combat.gd", "extends RefCounted\nvar manual := true\n")
        self.commit("manual change between Features")
        command = [sys.executable, "-B", str(PROJECT_ROOT / "yaya/tools/features/record-base-revision.py"),
                   "--repo-root", str(self.root), "--feature", "F002"]
        written = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(written.returncode, 0, written.stderr)
        self.assertEqual(json.loads((self.root / "docs/features/F002.json").read_text())["base_revision"], self.base)
        kept = subprocess.run(command, capture_output=True, text=True)
        self.assertIn("kept", kept.stdout)
        selection = build_selection(self.root, "F002")
        self.assertIn("tests/unit/combat", self.required_paths(selection))
        self.assertEqual(selection["touched_completed_features"], ["F001"])

    def test_unclaimed_unreferenced_game_file_escalates_to_full(self) -> None:
        self.write("game/orphan.gd", "extends Node\n")
        selection = self.selection()
        self.assertTrue(selection["full_suite"]["required"])
        self.assertIn("unclaimed-changed-file:game/orphan.gd", selection["full_suite"]["reasons"])

    def test_deleted_uid_and_renamed_class_keep_current_consumers_selected(self) -> None:
        for reference in ("uid", "class"):
            with self.subTest(reference=reference):
                source = f"game/combat/old_{reference}.gd"
                suite = f"tests/features/old_{reference}_consumer.gd"
                self.write(source, "extends RefCounted\nclass_name OldCombat\n")
                self.write(source + ".uid", f"uid://old{reference}\n")
                consumer = ('const Old = preload("uid://olduid")\n' if reference == "uid"
                            else "var old: OldCombat\n")
                self.write(suite, SUITE + consumer)
                self.start_after("old identities")
                (self.root / source).unlink()
                (self.root / (source + ".uid")).unlink()
                if reference == "class":
                    self.write("game/combat/new_class.gd", "extends RefCounted\nclass_name NewCombat\n")
                    self.write("game/combat/new_class.gd.uid", "uid://oldclass\n")
                selection = self.selection()
                self.assertIn(suite, self.required_paths(selection))
                self.assertFalse(selection["full_suite"]["required"])
                self.assertEqual(next(item["reasons"] for item in selection["dependency_suites"]
                                      if item["path"] == suite), [f"dependency-graph:{source}"])

    def test_deleted_script_without_historical_identity_requires_full(self) -> None:
        (self.root / "game/combat/combat.gd").unlink()
        self.assertIn("dependency-graph-unresolved:game/combat/combat.gd",
                      self.selection()["full_suite"]["reasons"])

    def test_deleted_path_only_data_selects_consumer_without_full(self) -> None:
        self.write("game/combat/table.json", '{"damage": 2}\n')
        self.write("game/combat/table_reader.gd", 'extends RefCounted\n'
                   'var table = load("res://game/combat/table.json")\n')
        suite = "tests/features/table_consumer_test.gd"
        self.write(suite, SUITE + 'const Reader = preload("res://game/combat/table_reader.gd")\n')
        self.start_after("path-only data")
        (self.root / "game/combat/table.json").unlink()
        selection = self.selection()
        self.assertFalse(selection["full_suite"]["required"])
        self.assertIn(suite, self.required_paths(selection))

    def test_automatic_suites_obey_godot_visibility_but_explicit_target_still_works(self) -> None:
        hidden = ["tests/ignored/hidden_test.gd", "tests/.hidden/hidden_test.gd", "tests/.hidden_test.gd"]
        self.write("tests/ignored/.gdignore", "")
        for path in [*hidden, "tests/visible_test.gd"]:
            self.write(path, SUITE)
        selected = self.required_paths(self.selection())
        self.assertTrue(set(hidden).isdisjoint(selected))
        self.assertIn("tests/visible_test.gd", selected)
        self.assertEqual(expected_gdunit_cases(self.root, [hidden[0]]),
                         [{"path": hidden[0], "case": "test_case"}])

    def test_preview_includes_inferred_component_full_reason_without_writing(self) -> None:
        self.registry["components"][1]["full_suite_on_change"] = True
        self.write_json("docs/test-registry.json", self.registry)
        self.write("game/combat/combat.gd", "extends RefCounted\nvar damage := 2\n")
        before = (self.root / "docs/features/F001.json").read_bytes()
        preview = subprocess.run([sys.executable, "-B", str(PROJECT_ROOT / "yaya/tools/features/record-base-revision.py"),
                                  "--repo-root", str(self.root), "--feature", "F001", "--dry-run"],
                                 capture_output=True, text=True)
        self.assertEqual(preview.returncode, 0, preview.stderr)
        self.assertEqual(json.loads(preview.stdout)["full_suite_reasons"],
                         self.selection()["full_suite"]["reasons"])
        self.assertIn("component-full-suite:combat", json.loads(preview.stdout)["full_suite_reasons"])
        self.assertEqual((self.root / "docs/features/F001.json").read_bytes(), before)

    def test_markdown_and_docs_changes_add_nothing(self) -> None:
        before = self.selection()
        self.write("README.md", "# Notes\n")
        self.write("game/inventory/NOTES.md", "notes\n")
        self.write("docs/gdd/design.md", "design\n")
        self.write_json("docs/extra.json", {"value": 1})
        after = self.selection()
        self.assertEqual((before["required"], before["full_suite"]), (after["required"], after["full_suite"]))

    def test_selection_ignores_other_feature_status(self) -> None:
        # Stage 0 例外由流程保证另一个 Feature 停在 GREEN；选择本身不读状态，同一内容同一结果。
        self.write("game/combat/combat.gd", "extends RefCounted\nvar damage := 2\n")
        index = {"meta": {}, "features": [
            {"id": "F001", "status": "in_progress", "depends_on": [], "completed_at": None},
            {"id": "F002", "status": "in_progress", "depends_on": [], "completed_at": None}]}
        self.write_json("docs/feature-list.json", index)
        before = self.selection()
        index["features"][1].update(status="done", completed_at="2026-10-02T00:00:00Z")
        self.write_json("docs/feature-list.json", index)
        after = self.selection()
        self.assertEqual((before["required"], before["selectors"], before["full_suite"]),
                         (after["required"], after["selectors"], after["full_suite"]))

    def test_rewritten_commit_messages_keep_selection(self) -> None:
        self.write("game/combat/combat.gd", "extends RefCounted\nvar one := 1\n")
        self.commit("first")
        self.write("game/inventory/inventory.gd", "extends RefCounted\nvar two := 2\n")
        self.commit("second")
        before = self.selection()
        self.git("commit", "--amend", "-m", "Work item: F009 reworded")
        self.git("reset", "--soft", self.base)
        self.git("commit", "-m", "squashed")
        self.assertEqual(before, self.selection())

    def test_changed_mode_runs_without_feature_or_evidence(self) -> None:
        self.write("game/combat/combat.gd", "extends RefCounted\nvar damage := 2\n")
        selection = build_changed_selection(self.root)
        self.assertEqual(selection["base_revision"], self.base)
        self.assertEqual(self.required_paths(selection), {"tests/unit/combat"})
        self.git("checkout", "--", "game/combat/combat.gd")
        output = io.StringIO()
        with mock.patch.object(runner, "REPO_ROOT", self.root), redirect_stdout(output), \
                mock.patch.object(runner, "_run_process") as engine:
            self.assertEqual(runner._run_tests(runner._parse_args(["--changed"])), 0)
            engine.assert_not_called()
            with self.assertRaises(SystemExit), mock.patch("sys.stderr", io.StringIO()):
                runner._parse_args(["--changed", "--scope", "full"])
        self.assertIn("No tests need to run", output.getvalue())
        self.assertNotIn("PASS", output.getvalue())
        self.assertFalse((self.root / "reports").exists())
        self.assertFalse((self.root / "docs/features/F001-evidence.json").exists())

    def test_changes_only_add_to_existing_derivation(self) -> None:
        before = self.selection()
        self.assertEqual(self.required_paths(before),
                         {"tests/unit/inventory", "tests/features/F001/acceptance_test.gd"})
        self.write("game/combat/combat.gd", "extends RefCounted\nvar damage := 2\n")
        self.write("game/inventory/inventory.gd", "extends RefCounted\nvar slots := 3\n")
        after = self.selection()
        self.assertLessEqual(self.required_paths(before), self.required_paths(after))
        self.assertLessEqual({(item["path"], item["case"]) for item in before["affected"]},
                             {(item["path"], item["case"]) for item in after["affected"]})

    def test_cyclic_dependencies_terminate(self) -> None:
        self.write("game/inventory/a.gd", 'extends RefCounted\nconst B = preload("b.gd")\n')
        self.write("game/inventory/b.gd", 'extends RefCounted\nconst A = preload("a.gd")\n')
        self.write("tests/features/cycle_test.gd", SUITE + 'const A = preload("res://game/inventory/a.gd")\n')
        self.start_after("cycle")
        self.write("game/inventory/b.gd", 'extends RefCounted\nconst A = preload("a.gd")\nvar x := 1\n')
        suites = {item["path"]: item for item in self.selection()["dependency_suites"]}
        self.assertEqual(suites["tests/features/cycle_test.gd"]["chain"],
                         ["tests/features/cycle_test.gd", "game/inventory/a.gd", "game/inventory/b.gd"])

    def test_test_helper_is_followed_but_not_selected(self) -> None:
        self.write("tests/helpers/builder.gd", "extends RefCounted\nfunc build():\n\treturn 1\n")
        self.write("tests/features/uses_helper_test.gd", SUITE + 'const H = preload("res://tests/helpers/builder.gd")\n')
        self.start_after("helper")
        self.write("tests/helpers/builder.gd", "extends RefCounted\nfunc build():\n\treturn 2\n")
        selection = self.selection()
        paths = self.required_paths(selection)
        self.assertIn("tests/features/uses_helper_test.gd", paths)
        self.assertNotIn("tests/helpers/builder.gd", paths)
        self.assertFalse(selection["full_suite"]["required"])

    def test_missing_or_unknown_base_revision_is_an_error(self) -> None:
        del self.detail["base_revision"]
        self.write_json("docs/features/F001.json", self.detail)
        for phase in ("baseline", "final"):
            with self.subTest(phase=phase), self.assertRaisesRegex(SelectionError, "record-base-revision"):
                build_selection(self.root, "F001", phase=phase)
        self.detail["base_revision"] = "f" * 40
        self.write_json("docs/features/F001.json", self.detail)
        with self.assertRaisesRegex(SelectionError, "--reset"):
            self.selection()


if __name__ == "__main__":
    unittest.main()
