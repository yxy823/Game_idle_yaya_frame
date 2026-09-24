"""按相对路径清单创建空白项目，并建立 Git 仓库与本地初始提交。"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
from pathlib import Path


def relative_path(root: Path, value: str) -> Path:
    """清单中的位置必须留在对应根目录内。"""
    relative = Path(value)
    if not value or relative.is_absolute() or relative.drive or ".." in relative.parts:
        raise ValueError(f"Expected a relative path: {value!r}")
    path = (root / relative).resolve()
    if not path.is_relative_to(root):
        raise ValueError(f"Path leaves its root: {value!r}")
    return path


def copy_project(source: Path, output: Path) -> int:
    """先检查目标和清单，再复制；复制失败时保留现场并返回原始错误。"""
    source = source.resolve()
    output = output.absolute()
    # 检查用户写出的路径和解析后的路径，避免父目录中的空格或中文被忽略。
    invalid = r"[\s\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\U00020000-\U000323af]"
    if re.search(invalid, str(output)) or re.search(invalid, str(output.resolve())):
        raise ValueError("Project path must not contain Chinese characters or whitespace")
    output = output.resolve()
    if output.is_relative_to(source) or source.is_relative_to(output):
        raise ValueError("Project path must be outside the source directory")
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        raise ValueError("Project path must be absent or an empty directory")

    entries = json.loads((source / "framework/project-files.json").read_text(encoding="utf-8"))
    copies = []
    for entry in entries:
        origin = relative_path(source, entry["source"])
        destination = relative_path(output, entry["target"])
        if not origin.exists():
            raise FileNotFoundError(origin)
        copies.append((origin, destination))

    # 展开实际写入路径；目录可合并，文件不得被重复写入或占据目录位置。
    targets: dict[Path, bool] = {}

    def claim(path: Path, is_directory: bool) -> None:
        if path in targets and not (targets[path] and is_directory):
            raise ValueError(f"Copy target conflict: {path.relative_to(output)}")
        targets[path] = is_directory
        for parent in path.parents:
            if not parent.is_relative_to(output):
                break
            if parent in targets and not targets[parent]:
                raise ValueError(f"Copy target conflict: {parent.relative_to(output)}")
            targets[parent] = True

    for origin, destination in copies:
        claim(destination, origin.is_dir())
        if origin.is_dir():
            for child in origin.rglob("*"):
                claim(destination / child.relative_to(origin), child.is_dir())

    # 只复制清单明确指定的文件或目录，不渲染内容，也不附加身份或状态文件。
    output.mkdir(parents=True, exist_ok=True)
    for origin, destination in copies:
        destination.parent.mkdir(parents=True, exist_ok=True)
        if origin.is_dir():
            shutil.copytree(origin, destination, dirs_exist_ok=True)
        else:
            shutil.copyfile(origin, destination)
    return len(copies)


def create_project(source: Path, output: Path) -> int:
    """复制完成后提交新项目文件；Git 失败时保留现场并向调用方报错。"""
    count = copy_project(source, output)
    output = output.resolve()
    initial_paths = sorted(path.name for path in output.iterdir())
    subprocess.run(["git", "init"], cwd=output, check=True)
    subprocess.run(["git", "add", "--", *initial_paths], cwd=output, check=True)
    subprocess.run(
        ["git", "commit", "-m", "chore(init): 创建空白 Godot 项目"],
        cwd=output,
        check=True,
    )
    return count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path, help="New empty project directory")
    args = parser.parse_args()
    try:
        count = create_project(Path(__file__).resolve().parents[2], args.output)
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Creation failed: {error}\n")
    print(f"Created {args.output.resolve()} from {count} entries with an initial Git commit")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
