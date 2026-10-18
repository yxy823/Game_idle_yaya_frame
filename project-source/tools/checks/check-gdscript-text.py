#!/usr/bin/env python3
"""Check GDScript text for unawaited gdUnit coroutine assertions and writes to res:// from game code or tests."""
# 只读检查：漏写 await 的协程断言不等结果就继续，失败不计入，测试绿灯却什么也没证明；
# 编辑器里写得进 res://，导出后的游戏写不进去，存档或配置要到发布后才失效。
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
SKIPPED_DIRECTORY_NAMES = {".git", ".godot", ".claude", "tmp", "reports", "addons"}
GAME_DIRECTORIES = {"game", "main", "components"}
TOKEN = re.compile(r'(?P<comment>#[^\n]*)|(?P<string>"""[\s\S]*?"""|"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\')')
COROUTINE_ASSERTION = re.compile(
    r"\.(?:is_emitted|is_not_emitted|is_push_error|is_push_warning|is_runtime_error|wait_until)\s*\(")
AWAIT = re.compile(r"\bawait\b")
WRITE_CALL = re.compile(
    r"\b(?:FileAccess\.open\w*\s*\((?=[^\n]*\bWRITE)|ResourceSaver\.save\s*\("
    r"|DirAccess\.(?:make_dir|make_dir_recursive|remove|rename|copy)_absolute\s*\()")
RES_LITERAL = re.compile(r'["\'](res://[^"\']*)["\']')


def skipped_directory(root: Path, directory: Path) -> bool:
    relative = directory.relative_to(root)
    if any(part in SKIPPED_DIRECTORY_NAMES for part in relative.parts):
        return True
    return any((root / parent / ".gdignore").is_file() for parent in (relative, *relative.parents))


def scripts(root: Path) -> list[Path]:
    def fail(error: OSError) -> None:
        raise error

    files = []
    for directory, subdirectories, names in os.walk(root, onerror=fail):
        subdirectories[:] = [name for name in subdirectories if not skipped_directory(root, Path(directory) / name)]
        files.extend(Path(directory) / name for name in names if name.endswith(".gd"))
    return sorted(files)


def statements(text: str) -> list[tuple[int, str, str]]:
    """(first line, code with strings blanked, code with strings kept); comments removed.

    Lines joined by a trailing backslash or by unclosed brackets form one statement.
    """
    blanked, kept, last = [], [], 0
    for match in TOKEN.finditer(text):
        blanked.append(text[last:match.start()])
        kept.append(text[last:match.start()])
        if match.group("string"):
            # 保留换行，行号才对得上。
            blanked.append('""' + "\n" * match.group(0).count("\n"))
            kept.append(match.group(0))
        last = match.end()
    blanked.append(text[last:])
    kept.append(text[last:])
    plain_lines = "".join(blanked).split("\n")
    kept_lines = "".join(kept).split("\n")
    found, start, depth, plain, full = [], 0, 0, [], []
    for index, (line, original) in enumerate(zip(plain_lines, kept_lines)):
        if not plain:
            start = index + 1
        plain.append(line)
        full.append(original)
        depth += sum(line.count(opening) for opening in "([{") - sum(line.count(closing) for closing in ")]}")
        if depth > 0 or line.rstrip().endswith("\\"):
            continue
        found.append((start, " ".join(plain), " ".join(full)))
        plain, full, depth = [], [], 0
    if plain:
        found.append((start, " ".join(plain), " ".join(full)))
    return found


def problems(relative: str, text: str) -> list[tuple[int, str]]:
    parts = relative.split("/")
    in_tests = "tests" in parts[:-1]
    in_game = parts[0] in GAME_DIRECTORIES
    in_root_tests = parts[0] == "tests"
    found = []
    for line, plain, full in statements(text):
        if in_tests and COROUTINE_ASSERTION.search(plain) and not AWAIT.search(plain):
            found.append((line, "coroutine assertion is not awaited"))
        if (in_game or in_root_tests) and WRITE_CALL.search(plain):
            for path in RES_LITERAL.findall(full):
                if in_game:
                    found.append((line, f"game code writes to {path}; exported games cannot write res://"))
                elif not path.startswith("res://tests/"):
                    found.append((line, f"test writes to {path} outside its own temporary directory under res://tests/"))
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", help="Scripts to check; default: all project .gd outside skipped directories")
    parser.add_argument("--root", type=Path, default=REPO_ROOT)
    args = parser.parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"ERROR: project root is not a directory: {root}", file=sys.stderr)
        return 2
    try:
        if args.paths:
            files = [path for path in (root / name for name in args.paths)
                     if path.suffix == ".gd" and not skipped_directory(root, path.parent)]
        else:
            files = scripts(root)
        report = [(path.relative_to(root).as_posix(), line, reason) for path in files
                  for line, reason in problems(path.relative_to(root).as_posix(), path.read_text(encoding="utf-8"))]
    except (OSError, UnicodeDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    for relative, line, reason in report:
        print(f"{relative}:{line}: {reason}")
    if report:
        print("Await every coroutine assertion (yaya/agent-rules/70-tests/gdunit4-profile.md), save game data to "
              "user://, and keep test files under a temporary directory in res://tests/.")
        return 1
    print(f"OK: {len(files)} scripts")
    return 0


if __name__ == "__main__":
    sys.exit(main())
