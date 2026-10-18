#!/usr/bin/env python3
"""Check the staged changes for relaxed checks, changed UIDs and new editor signal connections."""
# 只读检查，只看本次暂存相对 HEAD 的改动。放宽检查和改 UID 有时是用户批准过的，硬拦截要放行开关，
# 而 Agent 能自己打开开关，所以这两类只列出，由 Agent 原样写进完成汇报的「待确认」交给用户；
# 项目场景里新增编辑器信号连接没有例外，命中就失败。
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
GAME_DIRECTORIES = ("game/", "main/", "components/")
GDLINT_SECTIONS = ("limits", "checks", "scanning", "exclude")
GDUNIT_KEYS = re.compile(r"^(?:report/.*|flaky_check_enable|hooks/session_hooks)$")
RELAXATION = re.compile(r"@warning_ignore|gdlint:ignore|\bdo_skip\b|\bskip_reason\b")
IMPORT_IDENTITY = re.compile(r'^(uid|source_file)=(.*)$', re.M)
HEADER_UID = re.compile(r'^\[gd_(?:scene|resource)\b[^\n]*?\buid="([^"]+)"')


def git(root: Path, *args: str) -> str:
    # core.quotepath=false：含中文的路径原样输出，不转成八进制转义。
    return subprocess.run(["git", "-c", "core.quotepath=false", *args], cwd=root, check=True, capture_output=True,
                          encoding="utf-8").stdout


def staged(root: Path, revision: str, path: str) -> str | None:
    result = subprocess.run(["git", "show", f"{revision}:{path}"], cwd=root, capture_output=True, encoding="utf-8")
    return result.stdout if result.returncode == 0 else None


def added_lines(root: Path, *pathspecs: str) -> list[tuple[str, int, str]]:
    """(path, new line number, text) of every line the staged changes add."""
    diff = git(root, "diff", "--cached", "--no-renames", "-U0", "--no-color", "--", *pathspecs)
    found, path, number = [], "", 0
    for line in diff.splitlines():
        if line.startswith("+++ "):
            path = line[6:] if line.startswith("+++ b/") else ""
        elif hunk := re.match(r"@@ -\S+ \+(\d+)", line):
            number = int(hunk.group(1))
        elif line.startswith("+") and path:
            found.append((path, number, line[1:]))
            number += 1
    return found


def gdunit_settings(text: str | None) -> dict[str, str]:
    settings, section = {}, ""
    for line in (text or "").splitlines():
        if heading := re.fullmatch(r"\[([^\]]+)\]", line.strip()):
            section = heading.group(1)
        elif section == "gdunit4" and "=" in line:
            key, value = line.split("=", 1)
            if GDUNIT_KEYS.match(key.strip()):
                settings[key.strip()] = value.strip()
    return settings


def review_items(root: Path, modified: list[str]) -> list[str]:
    items = [f"{path}:{number}: adds `{text.strip()}`"
             for path, number, text in added_lines(root, "*.gd") if RELAXATION.search(text)]
    old_lint, new_lint = staged(root, "HEAD", "gdlint.json"), staged(root, "", "gdlint.json")
    if old_lint is not None and new_lint is not None and old_lint != new_lint:
        old, new = json.loads(old_lint), json.loads(new_lint)
        items.extend(f"gdlint.json: changes `{section}`" for section in GDLINT_SECTIONS
                     if old.get(section) != new.get(section))
    old_gdunit, new_gdunit = (gdunit_settings(staged(root, revision, "project.godot")) for revision in ("HEAD", ""))
    items.extend(f"project.godot [gdunit4]: changes `{key}` from {old_gdunit.get(key, '(unset)')} to "
                 f"{new_gdunit.get(key, '(unset)')}" for key in sorted(set(old_gdunit) | set(new_gdunit))
                 if old_gdunit.get(key) != new_gdunit.get(key))
    for path in modified:
        if path.startswith("addons/"):
            items.append(f"{path}: modifies a plugin file")
            continue
        old, new = staged(root, "HEAD", path) or "", staged(root, "", path) or ""
        if path.endswith(".uid"):
            changed = old.strip() != new.strip()
        elif path.endswith(".import"):
            changed = dict(IMPORT_IDENTITY.findall(old)) != dict(IMPORT_IDENTITY.findall(new))
        elif path.endswith((".tscn", ".tres")):
            old_uid, new_uid = (HEADER_UID.match(text.partition("\n")[0]) for text in (old, new))
            changed = (old_uid and old_uid.group(1)) != (new_uid and new_uid.group(1))
        else:
            continue
        if changed:
            items.append(f"{path}: changes the UID of an existing file")
    return items


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=REPO_ROOT)
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        # 新仓库的第一个提交没有可以比较的旧内容。
        if subprocess.run(["git", "rev-parse", "--verify", "-q", "HEAD"], cwd=root, capture_output=True).returncode:
            print("OK: no HEAD to compare with")
            return 0
        modified = git(root, "diff", "--cached", "--no-renames", "--name-only", "--diff-filter=M").splitlines()
        connections = [f"{path}:{number}: adds an editor signal connection; connect the signal in code instead"
                       for path, number, text in added_lines(root, *(f"{directory}*.tscn" for directory in GAME_DIRECTORIES))
                       if text.startswith("[connection ")]
        review = review_items(root, modified)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    for line in connections:
        print(line)
    if connections:
        print("Project scenes connect signals in code (yaya/agent-rules/20-scenes/ui-and-scripts.md); "
              "remove these [connection] entries and connect in _ready().")
    if review:
        print("本次提交放宽了检查或改了已有文件的 UID。提交不因此被拒绝；把下面每一行原样写进完成汇报的「待确认」，由用户确认：")
        for line in review:
            print(f"- {line}")
    if connections:
        return 1
    if not review:
        print("OK: no relaxed checks, changed UIDs or new editor signal connections staged")
    return 0


if __name__ == "__main__":
    sys.exit(main())
