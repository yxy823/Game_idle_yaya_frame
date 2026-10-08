#!/usr/bin/env python3
"""Sync a Godot project into a trial copy and rename the copy so it gets its own user:// data."""
# 先写入改名后的 project.godot 并读回确认，再同步其余文件：任何一步失败，副本都不会以原名运行。
from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ui_trial_project import TRIAL_SUFFIX, read_project_name, renamed_project_text, uses_custom_user_dir

PROJECT_ROOT = Path(__file__).resolve().parents[3]
# 源项目的 .git 不复制；副本自己的 reports/ 保存试用驱动与输出，不随同步覆盖或删除。
SKIPPED_TOP_LEVEL = {".git", "reports"}
PROJECT_FILE = "project.godot"


def _parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--copy", required=True, type=Path, help="Trial copy directory; created when missing")
    parser.add_argument("--project", type=Path, default=PROJECT_ROOT, help="Project to copy (default: this project)")
    return parser.parse_args(argv)


def _skipped(relative: Path) -> bool:
    return bool(relative.parts) and (relative.parts[0] in SKIPPED_TOP_LEVEL or ".git" in relative.parts)


def _fail(error: OSError) -> None:
    # 读不了的目录要停止同步，不能当成里面没有文件。
    raise error


def _same_file(source: Path, target: Path) -> bool:
    if not target.is_file():
        return False
    left, right = source.stat(), target.stat()
    return left.st_size == right.st_size and left.st_mtime_ns == right.st_mtime_ns


def _sync(source: Path, copy: Path) -> tuple[int, int]:
    copied = removed = 0
    for directory, folders, files in os.walk(source, onerror=_fail):
        relative = Path(directory).relative_to(source)
        folders[:] = [name for name in folders if not _skipped(relative / name)]
        (copy / relative).mkdir(parents=True, exist_ok=True)
        for name in files:
            # worktree 的 .git 是指向源仓库管理目录的文件，同样不复制。
            if relative == Path(".") and name == PROJECT_FILE or _skipped(relative / name):
                continue
            target = copy / relative / name
            if not _same_file(Path(directory) / name, target):
                shutil.copy2(Path(directory) / name, target)
                copied += 1
    # 源项目里已删除的文件也从副本删除，避免旧脚本或旧的全局类留在副本里。
    for directory, folders, files in os.walk(copy, topdown=True, onerror=_fail):
        relative = Path(directory).relative_to(copy)
        kept = []
        for name in folders:
            if _skipped(relative / name):
                continue
            if (source / relative / name).is_dir():
                kept.append(name)
            else:
                shutil.rmtree(Path(directory) / name)
                removed += 1
        folders[:] = kept
        for name in files:
            if relative == Path(".") and name == PROJECT_FILE or _skipped(relative / name):
                continue
            if not (source / relative / name).is_file():
                (Path(directory) / name).unlink()
                removed += 1
    return copied, removed + _remove_copied_git_pointer(source, copy)


def _remove_copied_git_pointer(source: Path, copy: Path) -> int:
    """旧版本复制过源 worktree 的 .git 文件；只删内容与源完全相同的那份，副本自己的 Git 数据不动。"""
    pointer, origin = copy / ".git", source / ".git"
    if pointer.is_file() and origin.is_file() and pointer.read_bytes() == origin.read_bytes():
        pointer.unlink()
        return 1
    return 0


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    source, copy = args.project.resolve(), args.copy.resolve()
    source_file = source / PROJECT_FILE
    if not source_file.is_file():
        print(f"ERROR: no {PROJECT_FILE} in project {source}", file=sys.stderr)
        return 2
    inside_source = copy.is_relative_to(source) and not copy.is_relative_to(source / "reports")
    if copy == source or source.is_relative_to(copy) or inside_source:
        print(f"ERROR: copy {copy} must be outside the project (or under its reports/)", file=sys.stderr)
        return 2
    if copy.exists() and any(copy.iterdir()) and not (copy / PROJECT_FILE).is_file():
        print(f"ERROR: {copy} is not empty and is not a project copy", file=sys.stderr)
        return 2
    name = read_project_name(source_file)
    if not name:
        print(f"ERROR: {source_file} has no [application] config/name", file=sys.stderr)
        return 1
    if name.endswith(TRIAL_SUFFIX):
        print(f"ERROR: {source} is already a trial copy ({name!r}); prepare from the real project", file=sys.stderr)
        return 2
    if uses_custom_user_dir(source_file):
        print("ERROR: application/config/use_custom_user_dir is on; renaming would not separate user:// data",
              file=sys.stderr)
        return 1
    expected = name + TRIAL_SUFFIX
    copy_file = copy / PROJECT_FILE
    try:
        copy.mkdir(parents=True, exist_ok=True)
        copy_file.write_text(renamed_project_text(source_file.read_text(encoding="utf-8"), expected),
                             encoding="utf-8", newline="")
    except (OSError, ValueError) as error:
        print(f"ERROR: cannot write {copy_file}: {error}", file=sys.stderr)
        return 1
    actual = read_project_name(copy_file)
    if actual != expected:
        print(f"ERROR: read back config/name {actual!r}, expected {expected!r}; copy not synced", file=sys.stderr)
        return 1
    try:
        copied, removed = _sync(source, copy)
        ignore = copy / "reports/.gdignore"
        ignore.parent.mkdir(parents=True, exist_ok=True)
        if not ignore.exists():
            ignore.write_text("", encoding="utf-8")
    except OSError as error:
        print(f"ERROR: sync stopped: {error}", file=sys.stderr)
        return 1
    print(f"TRIAL COPY READY: {copy}")
    print(f"config/name: {actual}")
    print(f"files copied: {copied}; stale paths removed: {removed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
