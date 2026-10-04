"""项目工具回归从明确指定的项目读取实现。"""
import os
import sys
from pathlib import Path

value = os.environ.get("YAYA_TEST_PROJECT")
if not value:
    raise RuntimeError("Set YAYA_TEST_PROJECT or use framework/tests/external-project/run_project_tool_tests.py --project PATH")
PROJECT_ROOT = Path(value).resolve()
if not (PROJECT_ROOT / "project.godot").is_file() or not (PROJECT_ROOT / "docs/methodology-config.json").is_file():
    raise RuntimeError("Project regressions require an actual project directory")
# 项目工具以 yaya/ 为包根：`from tools.lib import ...`。
sys.path.insert(0, str(PROJECT_ROOT / "yaya"))
