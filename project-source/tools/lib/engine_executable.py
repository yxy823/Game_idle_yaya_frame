"""按配置契约解析 Godot 可执行文件：完整路径或项目相对文件路径，不查询 PATH。"""
from __future__ import annotations

from pathlib import Path


def engine_executable_path(root: Path, value: object) -> Path | None:
    """未配置（非字符串或空白）时返回 None；不检查文件是否存在。"""
    if not isinstance(value, str) or not value.strip():
        return None
    return (root / value).resolve()
