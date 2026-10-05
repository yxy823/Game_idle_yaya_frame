#!/usr/bin/env python3
"""Check that .tscn/.tres files carry editor-saved UIDs and no load_steps."""
# 只读检查：以文本方式编写后忘了用 resave_godot_files.gd 重存的文件，下次打开编辑器会被改写。
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
# 第三方插件按原样保留，不要求符合本项目的保存格式。
EXCLUDED_DIRECTORY_NAMES = {".git", ".godot", ".claude", "tmp", "reports", "addons"}
HEADER = re.compile(r"^\[gd_(?:scene|resource)\b")
UID = re.compile(r'\buid="uid://[^"]+"')


def resource_files(root: Path) -> list[Path]:
    files = []
    for path in root.rglob("*"):
        if path.suffix not in {".tscn", ".tres"} or not path.is_file():
            continue
        parents = path.relative_to(root).parents
        if any(part in EXCLUDED_DIRECTORY_NAMES for part in path.relative_to(root).parts[:-1]):
            continue
        # Godot 不导入含 .gdignore 的目录，其中的文件不会被编辑器改写。
        if any((root / parent / ".gdignore").is_file() for parent in parents):
            continue
        files.append(path)
    return sorted(files)


def problems(path: Path) -> list[tuple[int, str]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or not HEADER.match(lines[0]):
        return [(1, "not a Godot text scene or resource header")]
    found = []
    if not UID.search(lines[0]):
        found.append((1, "header has no uid"))
    if "load_steps=" in lines[0]:
        found.append((1, "header contains load_steps"))
    for number, line in enumerate(lines, start=1):
        if line.startswith("[ext_resource") and not UID.search(line):
            found.append((number, "ext_resource has no uid"))
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", help="Files to check; default: all project .tscn/.tres outside excluded directories")
    parser.add_argument("--root", type=Path, default=REPO_ROOT)
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        files = [root / path for path in args.paths] if args.paths else resource_files(root)
        report = [(path, line, reason) for path in files for line, reason in problems(path)]
    except (OSError, UnicodeDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    for path, line, reason in report:
        print(f"{path.relative_to(root).as_posix()}:{line}: {reason}")
    if report:
        print("Resave these files with yaya/tools/godot/resave_godot_files.gd, then rerun this check.")
        return 1
    print(f"OK: {len(files)} scene/resource files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
