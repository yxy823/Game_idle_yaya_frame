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

    def run_check(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, "-B", str(SCRIPT), "--root", str(self.root)],
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

    def test_editor_saved_files_pass(self) -> None:
        self.write("game/ok.tscn", '[gd_scene format=3 uid="uid://abc"]\n\n'
                   '[ext_resource type="Script" uid="uid://def" path="res://a.gd" id="1"]\n')
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stdout)


if __name__ == "__main__":
    unittest.main()
