"""显式运行项目工具回归；不生成、初始化或填入示例 Feature。"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[3]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True, type=Path, help="External project directory")
    args = parser.parse_args()
    project = args.project.resolve()
    if project.is_relative_to(SOURCE) or SOURCE.is_relative_to(project):
        parser.error("Project tests must run outside the maintenance source")
    if not (project / "project.godot").is_file() or not (project / "docs/methodology-config.json").is_file():
        parser.error("Choose an actual project directory")
    # 只向测试传入明确对象，沿用项目工具的回归；不登记发布资格或运行整套验收矩阵。
    environment = dict(os.environ, YAYA_TEST_PROJECT=str(project))
    return subprocess.run(
        [sys.executable, "-B", "-m", "unittest", "discover",
         "-s", str(SOURCE / "framework/tests/external-project/tool-regression"), "-p", "test_*.py"],
        cwd=project, env=environment, check=False,
    ).returncode


if __name__ == "__main__":
    raise SystemExit(main())
