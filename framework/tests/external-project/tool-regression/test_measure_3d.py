from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import json
import subprocess
import unittest

SCRIPT = "res://yaya/tools/godot/measure-3d/measure_3d.gd"


class Measure3dTests(unittest.TestCase):
    def test_headless_run_stops_at_once_and_says_why(self) -> None:
        config = json.loads((PROJECT_ROOT / "docs/methodology-config.json").read_text(encoding="utf-8"))
        engine = Path(config["engine_executable"])
        engine = engine if engine.is_absolute() else PROJECT_ROOT / engine
        # 无头模式没有渲染画面；入口要立刻退出，不能等到截图超时。
        result = subprocess.run([str(engine), "--headless", "--path", str(PROJECT_ROOT), "--script", SCRIPT, "--",
                                 "yaya/tools/godot/measure-3d/example_request.json"],
                                capture_output=True, encoding="utf-8", errors="replace", timeout=60)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("needs a real window", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
