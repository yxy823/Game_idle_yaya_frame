"""Shared reading, masking, file selection and output conventions of the text checks (terminology and wording)."""
# 代码、引号内的文字和链接目标不算出现，因为写作规范会把要避免的写法放进引号或代码当例子。
# .json 文件只查字符串值：每个值当作一段 Markdown，否则 JSON 自身的双引号会让所有文字都算作引号内。
from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path

# 与 check-markdown-links.py 相同：按目录名在任意层级排除。
DEFAULT_EXCLUDED_DIRECTORY_NAMES = (".git", ".godot", ".claude", "tmp", "addons", "__pycache__")

FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
INLINE_CODE = re.compile(r"(`+)(?:(?!\1).)+?\1")
QUOTED = re.compile(r"「[^」]*」|“[^”]*”|\"[^\"]*\"")
TABLE_SEPARATOR = re.compile(r"^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$")
CELL_SPLIT = re.compile(r"(?<!\\)\|")
LINK_TARGET = re.compile(r"(?<=\]\()[^)]*(?=\))")
JSON_STRING = re.compile(r'"(?:[^"\\]|\\.)*"')


class DocumentError(Exception):
    pass


@dataclass
class Document:
    path: str
    original: list[str]
    masked: list[str | None]  # None 表示整行在代码块里
    lines: list[int]  # 每行在源文件中的行号；JSON 字符串值拆出的多行共用该值所在的行号
    offsets: list[int]  # 列号偏移：Markdown 为 0，JSON 为该行在字符串值内的起点


def split_cells(row: str) -> list[str]:
    text = row.strip()
    if text.startswith("|"):
        text = text[1:]
    if text.endswith("|") and not text.endswith("\\|"):
        text = text[:-1]
    return [cell.strip().replace("\\|", "|") for cell in CELL_SPLIT.split(text)]


def closes_fence(line: str, fence: str) -> bool:
    match = FENCE.match(line)
    return bool(match) and match.group(1)[0] == fence[0] and len(match.group(1)) >= len(fence)


def mask_line(line: str) -> str:
    """Blank out inline code, link targets and quoted text, keeping every column in place."""
    line = INLINE_CODE.sub(lambda match: " " * len(match.group(0)), line)
    line = LINK_TARGET.sub(lambda match: " " * len(match.group(0)), line)
    return QUOTED.sub(lambda match: " " * len(match.group(0)), line)


def mask_markdown(lines: list[str]) -> list[str | None]:
    masked: list[str | None] = []
    fence: str | None = None
    for line in lines:
        if fence is not None:
            if closes_fence(line, fence):
                fence = None
            masked.append(None)
            continue
        fence_match = FENCE.match(line)
        if fence_match:
            fence = fence_match.group(1)
            masked.append(None)
            continue
        masked.append(mask_line(line))
    return masked


def read_json_document(text: str, display: str) -> Document:
    """Treat every JSON string value (not keys) as its own Markdown text, located at the line it starts on."""
    try:
        json.loads(text)
    except json.JSONDecodeError as exc:
        raise DocumentError(f"{display}:{exc.lineno}:{exc.colno}: JSON 解析失败：{exc.msg}") from exc
    document = Document(display, [], [], [], [])
    line_number, counted = 1, 0
    for match in JSON_STRING.finditer(text):
        if text[match.end():].lstrip().startswith(":"):
            continue
        line_number += text.count("\n", counted, match.start())
        counted = match.start()
        parts = json.loads(match.group(0)).split("\n")
        offset = 0
        for part, masked in zip(parts, mask_markdown(parts)):
            document.original.append(part)
            document.masked.append(masked)
            document.lines.append(line_number)
            document.offsets.append(offset)
            offset += len(part) + 1
    return document


def read_document(path: Path, display: str) -> Document:
    text = path.read_text(encoding="utf-8")
    if path.suffix.lower() == ".json":
        return read_json_document(text, display)
    original = text.splitlines()
    return Document(display, original, mask_markdown(original), list(range(1, len(original) + 1)), [0] * len(original))


def _excluded(relative: Path, excluded_names: set[str], excluded_paths: list[Path]) -> bool:
    return (any(name in excluded_names for name in relative.parts[:-1])
            or any(relative == prefix or prefix in relative.parents for prefix in excluded_paths))


def scanned_files(root: Path, includes: list[str], excluded_names: set[str], excluded_paths: list[Path]) -> list[Path]:
    files = []
    for directory, subdirectories, names in os.walk(root):
        relative_directory = Path(directory).relative_to(root)
        subdirectories[:] = sorted(
            name for name in subdirectories
            if name not in excluded_names
            and not any(relative_directory / name == prefix or prefix in (relative_directory / name).parents
                        for prefix in excluded_paths)
        )
        for name in names:
            relative = relative_directory / name
            if any(relative == prefix or prefix in relative.parents for prefix in excluded_paths):
                continue
            posix = relative.as_posix()
            if any(fnmatch.fnmatchcase(posix if "/" in pattern else name, pattern) for pattern in includes):
                files.append(root / relative)
    return sorted(files)


def add_scan_arguments(parser: argparse.ArgumentParser) -> None:
    """Arguments shared by the text checks: scan root, file selection, context width and JSON output."""
    parser.add_argument("paths", nargs="*", type=Path, metavar="FILE",
                        help="check only these files (relative to --root unless absolute) instead of scanning --root; "
                             "files in excluded directories are skipped")
    parser.add_argument("--files-from", metavar="LIST",
                        help="also check the files listed in LIST, one path per line ('-' reads standard input); "
                             "an empty list checks no file")
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="directory to scan (default: current directory)")
    parser.add_argument("--include", action="append", metavar="GLOB",
                        help="file name glob, or path glob when it contains '/'; repeatable (default: *.md)")
    parser.add_argument("--exclude", action="append", default=[], metavar="PATH",
                        help="additional path relative to --root that is not scanned; repeatable")
    parser.add_argument("--context-width", type=int, default=80, help="maximum characters of line context (default: 80)")
    parser.add_argument("--json", action="store_true", help="print the result as JSON")


def selected_files(root: Path, args: argparse.Namespace) -> list[Path]:
    """Files named on the command line, or every file under root that matches --include."""
    excluded_names = set(DEFAULT_EXCLUDED_DIRECTORY_NAMES)
    excluded_paths = [Path(value) for value in args.exclude]
    if not args.paths and args.files_from is None:
        return scanned_files(root, args.include or ["*.md"], excluded_names, excluded_paths)
    listed = list(args.paths)
    if args.files_from is not None:
        if args.files_from == "-":
            text = sys.stdin.read()
        else:
            text = Path(args.files_from).read_text(encoding="utf-8")
        listed += [Path(line) for line in text.splitlines() if line.strip()]
    files = []
    for value in listed:
        path = (value if value.is_absolute() else root / value).resolve()
        try:
            relative = path.relative_to(root)
        except ValueError as exc:
            raise DocumentError(f"{value}: 文件不在 --root 内") from exc
        if not path.is_file():
            raise DocumentError(f"{value}: 文件不存在")
        if not _excluded(relative, excluded_names, excluded_paths):
            files.append(path)
    return sorted(set(files))


def read_documents(root: Path, files: list[Path]) -> list[Document]:
    return [read_document(path, path.relative_to(root).as_posix()) for path in files]


def display_path(path: Path, root: Path) -> str:
    try:
        return path.resolve().relative_to(root).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def context_snippet(line: str, column: int, width: int) -> str:
    stripped = line.strip()
    if len(stripped) <= width:
        return stripped
    offset = column - 1 - (len(line) - len(line.lstrip()))
    start = max(0, min(offset - width // 3, len(stripped) - width))
    snippet = stripped[start : start + width]
    return ("…" if start > 0 else "") + snippet + ("…" if start + width < len(stripped) else "")


def finding_line(path: str, line: int, column: int, rule: str, message: str, context: str) -> str:
    return f"{path}:{line}:{column}: [{rule}] {message} | {context}"
