"""Shared Markdown parsing of the link checks: headings and anchors, links with their text, file selection."""
# 链接检查与链接文字检查共用。锚点按 GitHub 的标题锚点规则生成；代码块和行内代码里的内容不算链接。
from __future__ import annotations

import re
import os
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote

DEFAULT_EXCLUDED_DIRECTORY_NAMES = (".git", ".godot", ".claude", "tmp", "addons", "__pycache__")
# 测试和界面试用的运行目录由工具生成，里面没有手写文档，沙箱也可能读不了。
DEFAULT_EXCLUDED_PATHS = ("reports/gdunit-wrapper", "reports/ui-trial")

FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
HEADING = re.compile(r"^ {0,3}(#{1,6})[ \t]+(.*?)[ \t]*#*[ \t]*$")
HTML_ANCHOR = re.compile(r"""<a\s[^>]*\b(?:id|name)\s*=\s*["']([^"']+)["']""", re.IGNORECASE)
REFERENCE_DEFINITION = re.compile(r"^ {0,3}\[[^\]]+\]:\s*(<[^>]*>|\S+)")
INLINE_CODE = re.compile(r"(`+)(?:(?!\1).)+?\1")
URL_SCHEME = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]+:")
WINDOWS_DRIVE = re.compile(r"^[A-Za-z]:[\\/]")


@dataclass(frozen=True)
class ScannedFile:
    anchors: dict[str, str | None]  # 锚点 -> 标题文字；<a id> 锚点没有标题，为 None
    links: list[tuple[int, str, str | None]]  # (行号, 目标, 链接文字)；不比较文字的链接为 None
    title: str | None  # 第一个一级标题


def heading_text(text: str) -> str:
    """Visible heading text: links reduced to their text, HTML tags, backticks and asterisks dropped."""
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", text)
    # 行内代码里的 <name> 是可见文字，GitHub 会保留；只删除代码以外的 HTML 标签。
    parts = re.split(r"(`+[^`]*`+)", text)
    text = "".join(part if part.startswith("`") else re.sub(r"<[^>]+>", "", part) for part in parts)
    return text.replace("`", "").replace("*", "")


def heading_slug(text: str) -> str:
    """GitHub style: drop markup and punctuation, lowercase, spaces to hyphens."""
    kept = []
    for character in heading_text(text).lower():
        category = unicodedata.category(character)
        if character in " -" or category[0] in "LMN" or category == "Pc":
            kept.append(character)
    return "".join(kept).replace(" ", "-")


def _strip_inline_code(line: str) -> str:
    return INLINE_CODE.sub(lambda match: " " * len(match.group(0)), line)


def scan(path: Path) -> ScannedFile:
    """Read a Markdown file's anchors, links and first H1.

    Link text is None where it is not compared: reference definitions, images and navigation lines at the page top.
    """
    anchors: dict[str, str | None] = {}
    slug_counts: dict[str, int] = {}
    links: list[tuple[int, str, str | None]] = []
    title: str | None = None
    fence: str | None = None
    top = True
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        fence_match = FENCE.match(line)
        if fence is not None:
            if fence_match and fence_match.group(1)[0] == fence[0] and len(fence_match.group(1)) >= len(fence):
                fence = None
            continue
        if fence_match:
            fence = fence_match.group(1)
            top = False
            continue
        anchors.update(dict.fromkeys(HTML_ANCHOR.findall(line)))
        heading = HEADING.match(line)
        if heading:
            slug = heading_slug(heading.group(2))
            count = slug_counts.get(slug, 0)
            slug_counts[slug] = count + 1
            text = heading_text(heading.group(2)).strip()
            anchors[slug if count == 0 else f"{slug}-{count}"] = text
            if title is None and len(heading.group(1)) == 1:
                title = text
        definition = REFERENCE_DEFINITION.match(line)
        if definition:
            links.append((number, definition.group(1), None))
            top = False
            continue
        targets, navigation = _inline_targets(line)
        if top and navigation:
            targets = [(target, None) for target, _ in targets]
        elif line.strip() and not (heading and len(heading.group(1)) == 1):
            top = False
        links.extend((number, target, text) for target, text in targets)
    return ScannedFile(anchors, links, title)


class ScanCache:
    """Scan each file once; link targets outside the checked files are read on demand."""

    def __init__(self) -> None:
        self._files: dict[Path, ScannedFile] = {}

    def __call__(self, path: Path) -> ScannedFile:
        key = path.resolve()
        if key not in self._files:
            self._files[key] = scan(key)
        return self._files[key]


def _link_open(line: str, close: int) -> int:
    """Index of the '[' matching the ']' at close, or -1."""
    depth = 0
    for index in range(close - 1, -1, -1):
        if line[index] == "]":
            depth += 1
        elif line[index] == "[":
            if depth == 0:
                return index
            depth -= 1
    return -1


def _inline_targets(original: str) -> tuple[list[tuple[str, str | None]], bool]:
    """Return (target, link text) pairs, text None for images, and whether the line holds only links and '·'."""
    line = _strip_inline_code(original)
    targets: list[tuple[str, str | None]] = []
    spans: list[tuple[int, int]] = []

    def add(start: int, target: str, end: int) -> None:
        opening = _link_open(line, start)
        image = opening > 0 and line[opening - 1] == "!"
        targets.append((target, original[opening + 1 : start] if opening != -1 and not image else None))
        if opening != -1:
            spans.append((opening - image, end + 1))

    start = line.find("](")
    while start != -1:
        index = start + 2
        if line.startswith("<", index):
            end = line.find(">", index)
            if end == -1:
                break
            add(start, line[index : end + 1], end + 1)
            start = line.find("](", end)
            continue
        depth = 0
        end = index
        while end < len(line):
            character = line[end]
            if character == "(":
                depth += 1
            elif character == ")":
                if depth == 0:
                    break
                depth -= 1
            elif character in " \t" and depth == 0:
                break
            end += 1
        add(start, line[index:end], end)
        start = line.find("](", end)
    residue = list(line)
    for begin, finish in spans:
        residue[begin:finish] = " " * (finish - begin)
    return targets, bool(spans) and not "".join(residue).replace("·", "").strip()


def split_target(raw: str) -> tuple[str, str] | None:
    """Return (path, anchor) for a local link, or None for links the checks skip."""
    target = raw.strip()
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1]
    if not target or (URL_SCHEME.match(target) and not WINDOWS_DRIVE.match(target)):
        return None
    path, _, anchor = target.partition("#")
    path = path.split("?", 1)[0]
    return unquote(path), unquote(anchor)


def is_excluded(relative: Path, excluded_names: set[str], excluded_paths: list[Path]) -> bool:
    if any(part in excluded_names for part in relative.parts[:-1]):
        return True
    return any(relative == prefix or prefix in relative.parents for prefix in excluded_paths)


def markdown_files(root: Path, excluded_names: set[str], excluded_paths: list[Path]) -> list[Path]:
    def fail(error: OSError) -> None:
        raise error

    files = []
    for directory, subdirectories, names in os.walk(root, onerror=fail):
        relative = Path(directory).relative_to(root)
        subdirectories[:] = [name for name in subdirectories if name not in excluded_names
                             and not is_excluded(relative / name, excluded_names, excluded_paths)]
        files.extend(Path(directory) / name for name in names
                     if Path(name).suffix.lower() == ".md" and (Path(directory) / name).is_file()
                     and not is_excluded(relative / name, excluded_names, excluded_paths))
    return sorted(files)


def read_path_list(value: str) -> set[Path]:
    """Read root-relative paths, one per line, from a file or from standard input when value is '-'."""
    text = sys.stdin.read() if value == "-" else Path(value).read_text(encoding="utf-8")
    return {Path(line.strip()) for line in text.splitlines() if line.strip()}


def is_related(root: Path, related: set[Path], file: str, raw: str) -> bool:
    """True when the link sits in a listed file or points at one; listed files may already be deleted."""
    if Path(file) in related:
        return True
    path_text, _ = split_target(raw)
    target = (root / file).parent / path_text if path_text else root / file
    try:
        return Path(os.path.relpath(target, root)) in related
    except ValueError:
        return False
