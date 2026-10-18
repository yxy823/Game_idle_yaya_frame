from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import os
import subprocess
import tempfile
import unittest

CHECKS = PROJECT_ROOT / "yaya/tools/checks"
GIT_ENVIRONMENT = {"GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.invalid",
                   "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.invalid"}


class CheckCase(unittest.TestCase):
    script = ""

    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)

    def write(self, name: str, text: str) -> None:
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8", newline="\n")

    def run_check(self, *args: str, stdin: str = "") -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, "-B", str(CHECKS / self.script), "--root", str(self.root), *args],
                              input=stdin, capture_output=True, encoding="utf-8", env={**os.environ, **GIT_ENVIRONMENT})


class GdscriptTextTests(CheckCase):
    script = "check-gdscript-text.py"

    def test_unawaited_coroutine_assertion_in_tests_is_reported(self) -> None:
        self.write("tests/unit/a_test.gd", 'func test_a():\n'
                   '\tassert_signal(node).is_emitted("done")\n'
                   '\tawait (assert_signal(node) as Impl).is_emitted("done",\n\t\t[1])\n'
                   '\t# assert_signal(node).is_emitted("in a comment")\n'
                   '\tvar text := "x.is_emitted(y)"\n')
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.splitlines()[:-1], ["tests/unit/a_test.gd:2: coroutine assertion is not awaited"])

    def test_game_code_and_tests_writing_res_are_reported(self) -> None:
        self.write("game/save.gd", 'func save():\n'
                   '\tFileAccess.open("res://game/save.json", FileAccess.WRITE)\n'
                   '\tFileAccess.open("user://save.json", FileAccess.WRITE)\n'
                   '\tFileAccess.open("res://game/data.json", FileAccess.READ)\n')
        self.write("tests/unit/save_test.gd", 'func test_a():\n'
                   '\tResourceSaver.save(res, "res://tests/tmp/a.tres")\n'
                   '\tResourceSaver.save(res, "res://game/a.tres")\n')
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.splitlines()[:-1], [
            "game/save.gd:2: game code writes to res://game/save.json; exported games cannot write res://",
            "tests/unit/save_test.gd:3: test writes to res://game/a.tres outside its own temporary directory under res://tests/",
        ])


class GodotReferenceTests(CheckCase):
    script = "check-godot-references.py"

    def test_missing_and_wrong_case_paths_are_reported_but_built_paths_are_not(self) -> None:
        self.write("game/Icon.png", "")
        self.write("game/main.gd", 'const ICON := "res://game/icon.png"\n'
                   'const GONE := preload("res://game/gone.tscn")\n'
                   'var built := "res://game/levels/" + name\n'
                   'var log := "res://reports/run.log"\n'
                   '# load("res://game/old.tscn")\n')
        self.write("tests/unit/main_test.gd", 'const FIXTURE := "res://game/fixture_only.tres"\n')
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.splitlines()[:-1], [
            "game/main.gd:1: res://game/icon.png differs in case from the file on disk",
            "game/main.gd:2: res://game/gone.tscn does not exist",
        ])

    def test_unknown_duplicate_and_mismatched_uids_are_reported(self) -> None:
        self.write("game/a.gd", "extends Node\n")
        self.write("game/a.gd.uid", "uid://aaa\n")
        self.write("game/copy.gd", "extends Node\n")
        self.write("game/copy.gd.uid", "uid://aaa\n")
        self.write("game/b.gd", "extends Node\n")
        self.write("game/b.gd.uid", "uid://bbb\n")
        self.write("game/scene.tscn", '[gd_scene format=3 uid="uid://scene"]\n\n'
                   '[ext_resource type="Script" uid="uid://bbb" path="res://game/a.gd" id="1"]\n'
                   '[ext_resource type="Script" uid="uid://nowhere" path="res://game/b.gd" id="2"]\n')
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.splitlines()[:-1], [
            "game/scene.tscn:4: uid://nowhere is not registered by any .uid, .import or scene/resource header",
            "game/scene.tscn:3: ext_resource uid uid://bbb does not match uid://aaa registered for res://game/a.gd",
            "game/scene.tscn:4: ext_resource uid uid://nowhere does not match uid://bbb registered for res://game/b.gd",
            "uid://aaa is registered by more than one file: game/a.gd, game/copy.gd",
        ])

    def test_export_presets_must_exclude_test_and_debug_files(self) -> None:
        self.write("export_presets.cfg", '[preset.0]\n\nname="Windows"\ninclude_filter="data/*.json"\n'
                   'exclude_filter="tests/*, addons/*"\n\n[preset.0.options]\n\n'
                   '[preset.1]\n\nexclude_filter="tests/*, dev/*, addons/gdUnit4/*"\n')
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.splitlines()[:-1], [
            "export_presets.cfg:5: [preset.0] exclude_filter excludes the whole addons/ directory",
            "export_presets.cfg:1: [preset.0] exclude_filter does not exclude dev/",
        ])

    def test_related_to_reports_references_to_a_deleted_file_only(self) -> None:
        self.write("game/main.gd", 'const OLD := preload("res://game/moved.tscn")\n')
        self.write("game/other.gd", 'const MISSING := preload("res://game/missing.tscn")\n')
        result = self.run_check("--related-to", "-", stdin="game/moved.tscn\n")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.splitlines()[:-1], ["game/main.gd:1: res://game/moved.tscn does not exist"])


class StagedChangeTests(CheckCase):
    script = "check-staged-changes.py"

    def git(self, *args: str) -> None:
        subprocess.run(["git", *args], cwd=self.root, check=True, capture_output=True,
                       env={**os.environ, **GIT_ENVIRONMENT})

    def setUp(self) -> None:
        super().setUp()
        self.git("init", "-q")
        self.write("game/a.gd", "extends Node\n")
        self.write("game/a.gd.uid", "uid://aaa\n")
        self.write("project.godot", "[gdunit4]\n\nflaky_check_enable=false\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "init")

    def test_relaxed_checks_and_changed_uids_are_listed_without_failing(self) -> None:
        self.write("game/a.gd", '@warning_ignore("unused_variable")\nextends Node\n')
        self.write("game/a.gd.uid", "uid://zzz\n")
        self.write("project.godot", "[gdunit4]\n\nflaky_check_enable=true\n")
        self.git("add", "-A")
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines()[1:], [
            '- game/a.gd:1: adds `@warning_ignore("unused_variable")`',
            "- project.godot [gdunit4]: changes `flaky_check_enable` from false to true",
            "- game/a.gd.uid: changes the UID of an existing file",
        ])

    def test_new_editor_connection_in_a_game_scene_fails(self) -> None:
        connection = '[gd_scene format=3 uid="uid://s"]\n\n[node name="Root" type="Node"]\n\n' \
                     '[connection signal="ready" from="." to="." method="_on_ready"]\n'
        self.write("game/board.tscn", connection)
        self.write("dev/debug/board.tscn", connection)
        self.git("add", "-A")
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.splitlines()[0],
                         "game/board.tscn:5: adds an editor signal connection; connect the signal in code instead")
        self.assertNotIn("dev/debug", result.stdout)


if __name__ == "__main__":
    unittest.main()
