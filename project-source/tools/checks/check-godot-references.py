#!/usr/bin/env python3
"""Check res:// and uid:// references, duplicate UIDs and the export filters in export_presets.cfg."""
# 只读检查：移动或改名素材后，按字符串 load() 的路径在编辑器里不报错，运行到才失败；
# 大小写不符的路径在 Windows 上能用，导出后的包区分大小写就找不到；导出过滤漏掉 tests/、dev/ 时，测试和调试台会进入正式包。
from __future__ import annotations

import argparse
import fnmatch
import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
SKIPPED_DIRECTORY_NAMES = {".git", ".godot", ".claude", "tmp", "reports"}
SOURCE_SUFFIXES = {".gd", ".tscn", ".tres", ".gdshader", ".gdshaderinc", ".json"}
SOURCE_NAMES = {"project.godot"}
GD_TOKEN = re.compile(r'(?P<comment>#[^\n]*)|(?P<string>"""[\s\S]*?"""|"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\')')
SHADER_TOKEN = re.compile(r'(?P<comment>//[^\n]*|/\*[\s\S]*?\*/)|(?P<string>"(?:[^"\\\n]|\\.)*")')
TEXT_TOKEN = re.compile(r'(?P<comment>(?m:^;[^\n]*))|(?P<string>"(?:[^"\\\n]|\\.)*")')
UID_VALUE = re.compile(r"uid://[0-9a-z]+")
HEADER_UID = re.compile(r'^\[gd_(?:scene|resource)\b[^\n]*?\buid="(uid://[0-9a-z]+)"')
IMPORT_UID = re.compile(r'^uid="(uid://[0-9a-z]+)"', re.M)
EXT_RESOURCE = re.compile(r'^\[ext_resource\b[^\n]*', re.M)
ATTRIBUTE = re.compile(r'\b(uid|path)="([^"]*)"')
REQUIRED_EXCLUDES = ("tests/", "dev/", "addons/gdUnit4/")
BROAD_FILTERS = {"*", "*.*", "**", "**/*"}


def skipped_directory(root: Path, directory: Path) -> bool:
    relative = directory.relative_to(root)
    if any(part in SKIPPED_DIRECTORY_NAMES for part in relative.parts):
        return True
    # Godot 不导入含 .gdignore 的目录，其中的文件既不登记 UID，也不会被游戏加载。
    return any((root / parent / ".gdignore").is_file() for parent in (relative, *relative.parents))


def project_files(root: Path) -> list[Path]:
    def fail(error: OSError) -> None:
        raise error

    files = []
    for directory, subdirectories, names in os.walk(root, onerror=fail):
        subdirectories[:] = [name for name in subdirectories if not skipped_directory(root, Path(directory) / name)]
        files.extend(Path(directory) / name for name in names)
    return sorted(files)


class Tree:
    """Exact-case lookups; Windows paths are case-insensitive, exported packs are not."""

    def __init__(self, root: Path) -> None:
        self.root = root
        self.listings: dict[Path, set[str] | None] = {}

    def _names(self, directory: Path) -> set[str] | None:
        if directory not in self.listings:
            self.listings[directory] = set(os.listdir(directory)) if directory.is_dir() else None
        return self.listings[directory]

    def status(self, relative: str) -> str:
        """'ok', 'missing' or 'case' for a path relative to the project root."""
        directory = self.root
        for part in [part for part in relative.split("/") if part]:
            names = self._names(directory)
            if names is None:
                return "missing"
            if part not in names:
                folded = part.casefold()
                return "case" if any(name.casefold() == folded for name in names) else "missing"
            directory = directory / part
        return "ok"


def registered_uids(root: Path, files: list[Path]) -> dict[str, list[str]]:
    """UID → files that register it: .uid sidecars, .import files and scene/resource headers."""
    owners: dict[str, list[str]] = {}

    def add(uid: str, owner: Path) -> None:
        owners.setdefault(uid, []).append(owner.relative_to(root).as_posix())

    for path in files:
        if path.suffix == ".uid":
            text = path.read_text(encoding="utf-8").strip()
            if UID_VALUE.fullmatch(text):
                add(text, path.with_suffix(""))
        elif path.suffix == ".import":
            if match := IMPORT_UID.search(path.read_text(encoding="utf-8")):
                add(match.group(1), path.with_suffix(""))
        elif path.suffix in {".tscn", ".tres"}:
            with path.open(encoding="utf-8") as stream:
                if match := HEADER_UID.match(stream.readline()):
                    add(match.group(1), path)
    return owners


def string_literals(path: Path, text: str) -> list[tuple[int, str]]:
    """(line, value) of string literals that are whole values, not parts of a built path."""
    token = {".gd": GD_TOKEN, ".gdshader": SHADER_TOKEN, ".gdshaderinc": SHADER_TOKEN}.get(path.suffix, TEXT_TOKEN)
    found = []
    for match in token.finditer(text):
        literal = match.group("string")
        if literal is None or ("res://" not in literal and "uid://" not in literal):
            continue
        if path.suffix == ".gd":
            before = text[max(0, match.start() - 80):match.start()].rstrip()
            after = text[match.end():match.end() + 80].lstrip()
            # "res://x/" + name 和 "res://%s.tres" % name 这类拼接出来的路径无法判断，只查完整的字面量。
            if before.endswith("+") or after[:1] in {"+", "%"}:
                continue
            literal = literal[3:-3] if literal.startswith('"""') else literal[1:-1]
        else:
            literal = literal[1:-1]
        found.append((text.count("\n", 0, match.start()) + 1, literal))
    return found


def reference_problems(root: Path, path: Path, tree: Tree, owners: dict[str, list[str]]) -> list[tuple[int, str, str]]:
    """(line, target, reason); target is the referenced project path, or '' for a UID."""
    text = path.read_text(encoding="utf-8")
    found = []
    for line, value in string_literals(path, text):
        if value.startswith("res://") and not re.search(r"[%{}*?]", value):
            target = value[len("res://"):].split("::", 1)[0]
            # reports/、tmp/ 这类运行输出目录由程序运行时创建，不要求事先存在。
            if target and target.split("/", 1)[0] not in SKIPPED_DIRECTORY_NAMES:
                status = tree.status(target)
                if status != "ok":
                    found.append((line, target, f"{value} {'differs in case from the file on disk' if status == 'case' else 'does not exist'}"))
        elif UID_VALUE.fullmatch(value) and value not in owners:
            found.append((line, "", f"{value} is not registered by any .uid, .import or scene/resource header"))
    if path.suffix in {".tscn", ".tres"}:
        uid_of = {Path(owner).as_posix(): uid for uid, paths in owners.items() for owner in paths}
        for match in EXT_RESOURCE.finditer(text):
            attributes = dict(ATTRIBUTE.findall(match.group(0)))
            uid, target = attributes.get("uid"), attributes.get("path", "").removeprefix("res://")
            registered = uid_of.get(target)
            if uid and registered and uid != registered:
                found.append((text.count("\n", 0, match.start()) + 1, target,
                              f"ext_resource uid {uid} does not match {registered} registered for res://{target}"))
    return found


def filter_problems(path: Path) -> list[tuple[int, str]]:
    found = []
    section, section_line, excludes = "", 0, None

    def finish() -> None:
        if re.fullmatch(r"preset\.\d+", section):
            for prefix in REQUIRED_EXCLUDES:
                sample = prefix + "x.gd"
                if not any(fnmatch.fnmatchcase(sample, pattern) or fnmatch.fnmatchcase("res://" + sample, pattern)
                           for pattern in excludes or []):
                    found.append((section_line, f"[{section}] exclude_filter does not exclude {prefix}"))

    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if heading := re.fullmatch(r"\[([^\]]+)\]", line.strip()):
            finish()
            section, section_line, excludes = heading.group(1), number, None
            continue
        if setting := re.fullmatch(r'(include_filter|exclude_filter)="(.*)"', line.strip()):
            patterns = [pattern.strip() for pattern in setting.group(2).split(",") if pattern.strip()]
            if setting.group(1) == "exclude_filter":
                excludes = patterns
                if any(pattern.removeprefix("res://").rstrip("/*") == "addons" for pattern in patterns):
                    found.append((number, f"[{section}] exclude_filter excludes the whole addons/ directory"))
            for pattern in patterns:
                if pattern.removeprefix("res://") in BROAD_FILTERS:
                    found.append((number, f"[{section}] {setting.group(1)} uses the broad pattern {pattern}"))
    finish()
    return found


def read_list(value: str) -> set[str]:
    text = sys.stdin.read() if value == "-" else Path(value).read_text(encoding="utf-8")
    return {line.strip().replace("\\", "/") for line in text.splitlines() if line.strip()}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=REPO_ROOT)
    parser.add_argument("--related-to", help="Only report problems in, or pointing to, the listed files; '-' reads stdin")
    args = parser.parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"ERROR: project root is not a directory: {root}", file=sys.stderr)
        return 2
    related = read_list(args.related_to) if args.related_to else None
    try:
        files = project_files(root)
        owners = registered_uids(root, files)
        tree = Tree(root)
        report = []
        for path in files:
            relative = path.relative_to(root).as_posix()
            # 插件内部的引用由插件自己负责；插件之外指向插件的引用照常检查。
            # 测试用不存在的路径和 UID 当夹具数据，测试里的错误路径在运行测试时就会失败，所以测试不作为引用来源。
            if (relative.startswith("addons/") or "tests" in Path(relative).parts[:-1]
                    or not (path.suffix in SOURCE_SUFFIXES or path.name in SOURCE_NAMES)):
                continue
            for line, target, reason in reference_problems(root, path, tree, owners):
                if related is None or relative in related or target in related:
                    report.append(f"{relative}:{line}: {reason}")
        for uid, paths in sorted(owners.items()):
            if len(paths) > 1 and (related is None or related.intersection(paths)):
                report.append(f"{uid} is registered by more than one file: {', '.join(paths)}")
        presets = root / "export_presets.cfg"
        if presets.is_file() and (related is None or "export_presets.cfg" in related):
            report.extend(f"export_presets.cfg:{line}: {reason}" for line, reason in filter_problems(presets))
    except (OSError, UnicodeDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    for line in report:
        print(line)
    if report:
        print("Point each reference at the file's current path with its exact case, give copied files their own "
              "UID by deleting the copied .uid/.import and rescanning, and make every export preset exclude "
              "tests/, dev/ and addons/gdUnit4/.")
        return 1
    print(f"OK: {len(files)} files scanned, {len(owners)} UIDs registered")
    return 0


if __name__ == "__main__":
    sys.exit(main())
