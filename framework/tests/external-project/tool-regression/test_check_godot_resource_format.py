# 手写后未重存的场景与资源要被报告；第三方插件和 Godot 忽略的目录不检查。
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import subprocess
import tempfile
import unittest

SCRIPT = PROJECT_ROOT / "yaya/tools/checks/check-godot-resource-format.py"
UNSAVED = '[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://a.gd" id="1"]\n'


class GodotResourceFormatTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)

    def write(self, name: str, text: str) -> None:
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def run_check(self, *paths: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, "-B", str(SCRIPT), "--root", str(self.root), *paths],
                              capture_output=True, text=True, encoding="utf-8")

    def test_unsaved_text_resource_is_reported_outside_excluded_directories(self) -> None:
        self.write("game/ok.tres", '[gd_resource type="Resource" format=3 uid="uid://abc"]\n')
        self.write("game/bad.tscn", UNSAVED)
        self.write("addons/vendor/bad.tscn", UNSAVED)
        self.write("samples/.gdignore", "")
        self.write("samples/bad.tscn", UNSAVED)
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.splitlines()[:3], [
            "game/bad.tscn:1: header has no uid",
            "game/bad.tscn:1: header contains load_steps",
            "game/bad.tscn:3: ext_resource has no uid",
        ])
        self.assertNotIn("addons/", result.stdout)
        self.assertNotIn("samples/", result.stdout)

    def test_debug_console_saves_are_skipped_but_other_debug_resources_are_checked(self) -> None:
        saved = '[gd_resource type="Resource" format=3]\n\n[ext_resource type="Script" path="res://a.gd" id="1"]\n'
        self.write("dev/debug/board/slots/removal/sfx/presets/loud.tres", saved)
        self.write("dev/debug/board/combos/calm.tres", saved)
        self.write("dev/debug/board/slots/removal/sfx/glass/candidate.tres", saved)
        self.write("dev/debug/_shared/tests/fixtures/sample/debug/sample/combos/a.tres", saved)
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("presets/", result.stdout)
        self.assertNotIn("dev/debug/board/combos/", result.stdout)
        self.assertIn("dev/debug/board/slots/removal/sfx/glass/candidate.tres:1: header has no uid", result.stdout)
        self.assertIn("dev/debug/_shared/tests/fixtures/sample/debug/sample/combos/a.tres:1: header has no uid",
                      result.stdout)

    def test_editor_saved_files_pass(self) -> None:
        self.write("game/ok.tscn", '[gd_scene format=3 uid="uid://abc"]\n\n'
                   '[ext_resource type="Script" uid="uid://def" path="res://a.gd" id="1"]\n')
        self.write("game/a.gd", "extends Node\n")
        self.write("game/a.gd.uid", "uid://def\n")
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_script_or_shader_without_uid_is_reported(self) -> None:
        self.write("game/new.gd", "extends Node\n")
        self.write("game/glow.gdshader", "shader_type canvas_item;\n")
        self.write("addons/vendor/plugin.gd", "extends Node\n")
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertIn("game/new.gd: missing .uid file", result.stdout)
        self.assertIn("game/glow.gdshader: missing .uid file", result.stdout)
        self.assertNotIn("addons/", result.stdout)

    def test_asset_without_import_is_reported(self) -> None:
        self.write("assets/new.png", "not really a png")
        self.write("assets/click.WAV", "not really audio")
        self.write("assets/old.png", "not really a png")
        self.write("assets/old.png.import", "[remap]\n")
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertIn("assets/new.png: missing .import file", result.stdout)
        self.assertIn("assets/click.WAV: missing .import file", result.stdout)
        self.assertNotIn("assets/old.png:", result.stdout)

    def test_listed_files_skip_excluded_locations(self) -> None:
        # 提交钩子把全部暂存文件列为参数，插件和 Godot 忽略的目录仍不检查。
        self.write("game/bad.tscn", UNSAVED)
        self.write("addons/vendor/bad.tscn", UNSAVED)
        self.write("samples/.gdignore", "")
        self.write("samples/bad.tscn", UNSAVED)
        result = self.run_check("game/bad.tscn", "addons/vendor/bad.tscn", "samples/bad.tscn")
        self.assertEqual(result.returncode, 1)
        self.assertIn("game/bad.tscn:1: header has no uid", result.stdout)
        self.assertNotIn("addons/", result.stdout)
        self.assertNotIn("samples/", result.stdout)

    def test_missing_root_is_an_error_not_an_empty_pass(self) -> None:
        self.root = self.root / "missing"
        result = self.run_check()
        self.assertEqual(result.returncode, 2)
        self.assertNotIn("OK", result.stdout)


if __name__ == "__main__":
    unittest.main()
