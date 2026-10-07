#!/usr/bin/env python3
"""Check editor-saved .tscn/.tres headers, script/shader .uid files and asset .import files."""
# 只读检查：以文本方式编写后忘了用 resave_godot_files.gd 重存的文件，下次打开编辑器会被改写；
# 新建脚本、Shader 或素材后没运行 Godot 扫描，就没有 .uid 或 .import，之后的扫描会冒出未提交的文件。
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.verification_snapshot import DEBUG_CONSOLE_SAVES_RE

REPO_ROOT = Path(__file__).resolve().parents[3]
# 第三方插件按原样保留，不要求符合本项目的保存格式。
EXCLUDED_DIRECTORY_NAMES = {".git", ".godot", ".claude", "tmp", "reports", "addons"}
HEADER = re.compile(r"^\[gd_(?:scene|resource)\b")
UID = re.compile(r'\buid="uid://[^"]+"')


UID_SIDECAR_SUFFIXES = {".gd", ".gdshader"}
IMPORT_SIDECAR_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".svg", ".bmp", ".tga",
                           ".wav", ".ogg", ".mp3", ".ttf", ".otf"}


def resource_files(root: Path, suffixes: set[str]) -> list[Path]:
    files = []
    for path in root.rglob("*"):
        if path.suffix.lower() not in suffixes or not path.is_file():
            continue
        parents = path.relative_to(root).parents
        if any(part in EXCLUDED_DIRECTORY_NAMES for part in path.relative_to(root).parts[:-1]):
            continue
        # 调试台运行时保存的预设与组合不经编辑器重存，不写 UID。
        if DEBUG_CONSOLE_SAVES_RE.fullmatch(path.relative_to(root).as_posix()):
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
    if not root.is_dir():
        print(f"ERROR: project root is not a directory: {root}", file=sys.stderr)
        return 2
    try:
        if args.paths:
            listed = [root / path for path in args.paths]
            files = [path for path in listed if path.suffix in {".tscn", ".tres"}]
            sources = [path for path in listed if path.suffix in UID_SIDECAR_SUFFIXES]
            assets = [path for path in listed if path.suffix.lower() in IMPORT_SIDECAR_SUFFIXES]
        else:
            files = resource_files(root, {".tscn", ".tres"})
            sources = resource_files(root, UID_SIDECAR_SUFFIXES)
            assets = resource_files(root, IMPORT_SIDECAR_SUFFIXES)
        report = [(path, line, reason) for path in files for line, reason in problems(path)]
        missing_uid = [path for path in sources if not path.with_name(path.name + ".uid").is_file()]
        missing_import = [path for path in assets if not path.with_name(path.name + ".import").is_file()]
    except (OSError, UnicodeDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    for path, line, reason in report:
        print(f"{path.relative_to(root).as_posix()}:{line}: {reason}")
    for path in missing_uid:
        print(f"{path.relative_to(root).as_posix()}: missing .uid file")
    for path in missing_import:
        print(f"{path.relative_to(root).as_posix()}: missing .import file")
    if report:
        print("Resave these files with yaya/tools/godot/resave_godot_files.gd, then rerun this check.")
    if missing_uid or missing_import:
        print("Run the first Godot scan command in yaya/tools/README.md, commit the generated .uid/.import files, then rerun this check.")
    if report or missing_uid or missing_import:
        return 1
    print(f"OK: {len(files)} scene/resource files, {len(sources)} scripts/shaders with .uid, "
          f"{len(assets)} assets with .import")
    return 0


if __name__ == "__main__":
    sys.exit(main())
