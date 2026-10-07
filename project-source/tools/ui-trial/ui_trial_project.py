"""Read and rename a trial copy's project name; shared by prepare-trial-copy.py and run-ui-trial.py."""
# 副本改名是防止写进用户真实 user:// 存档的唯一屏障：Godot 按 config/name 选择存档目录。
from __future__ import annotations

from pathlib import Path

TRIAL_SUFFIX = " trial"
_NAME_KEY = "config/name="
_CUSTOM_USER_DIR_KEY = "config/use_custom_user_dir="


def _application_lines(lines: list[str]) -> list[int]:
    indexes, section = [], ""
    for index, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            section = stripped[1:-1]
        elif section == "application":
            indexes.append(index)
    return indexes


def _decode(value: str) -> str | None:
    if len(value) < 2 or not value.startswith('"') or not value.endswith('"'):
        return None
    return value[1:-1].replace('\\"', '"').replace("\\\\", "\\")


def _encode(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def read_project_name(project_file: Path) -> str | None:
    lines = project_file.read_text(encoding="utf-8").splitlines()
    for index in _application_lines(lines):
        if lines[index].startswith(_NAME_KEY):
            return _decode(lines[index][len(_NAME_KEY):].strip())
    return None


def uses_custom_user_dir(project_file: Path) -> bool:
    lines = project_file.read_text(encoding="utf-8").splitlines()
    return any(lines[index].replace(" ", "") == _CUSTOM_USER_DIR_KEY + "true"
               for index in _application_lines(lines))


def renamed_project_text(source_text: str, name: str) -> str:
    """Return source_text with config/name replaced; raise ValueError when it has no name line."""
    lines = source_text.splitlines(keepends=True)
    for index in _application_lines([line.rstrip("\r\n") for line in lines]):
        if lines[index].startswith(_NAME_KEY):
            ending = lines[index][len(lines[index].rstrip("\r\n")):]
            lines[index] = _NAME_KEY + _encode(name) + ending
            return "".join(lines)
    raise ValueError("project.godot has no [application] config/name")
