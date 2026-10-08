#!/usr/bin/env python3
"""Check relative Markdown links and heading anchors inside a directory tree."""
# 只读检查：不联网、不改写文件。锚点按 GitHub 的标题锚点规则生成。
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from dataclasses import asdict, dataclass
from pathlib import Path
from urllib.parse import unquote

REPO_ROOT = Path(__file__).resolve().parents[3]
# 按目录名在任意层级排除：版本库、引擎缓存、临时材料、Agent 客户端数据和第三方插件。
DEFAULT_EXCLUDED_DIRECTORY_NAMES = (".git", ".godot", ".claude", "tmp", "addons", "__pycache__")

FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
HEADING = re.compile(r"^ {0,3}(#{1,6})[ \t]+(.*?)[ \t]*#*[ \t]*$")
HTML_ANCHOR = re.compile(r"""<a\s[^>]*\b(?:id|name)\s*=\s*["']([^"']+)["']""", re.IGNORECASE)
REFERENCE_DEFINITION = re.compile(r"^ {0,3}\[[^\]]+\]:\s*(<[^>]*>|\S+)")
INLINE_CODE = re.compile(r"(`+)(?:(?!\1).)+?\1")
URL_SCHEME = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]+:")
WINDOWS_DRIVE = re.compile(r"^[A-Za-z]:[\\/]")
# 方法论文件的一级标题带“NN · ”编号，链接文字可以省略。
TITLE_NUMBER = re.compile(r"^\d+\s*·\s*")


@dataclass(frozen=True)
class BrokenLink:
    file: str
    line: int
    target: str
    reason: str


@dataclass(frozen=True)
class LinkTextMismatch:
    file: str
    line: int
    target: str
    text: str
    expected: str
    rule: str = "LINK-TEXT"


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


def _scan(path: Path) -> tuple[dict[str, str | None], list[tuple[int, str, str | None]], str | None]:
    """Return the file's anchors (slug -> heading text), its (line, target, link text) links and first H1.

    Link text is None where it is not compared: reference definitions, images and navigation lines.
    """
    anchors: dict[str, str | None] = {}
    slug_counts: dict[str, int] = {}
    links: list[tuple[int, str, str | None]] = []
    title: str | None = None
    fence: str | None = None
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        fence_match = FENCE.match(line)
        if fence is not None:
            if fence_match and fence_match.group(1)[0] == fence[0] and len(fence_match.group(1)) >= len(fence):
                fence = None
            continue
        if fence_match:
            fence = fence_match.group(1)
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
            continue
        links.extend((number, target, text) for target, text in _inline_targets(line))
    return anchors, links, title


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


def _inline_targets(original: str) -> list[tuple[str, str | None]]:
    """Return (target, link text) pairs; text is None for images and on navigation lines."""
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
                break  # 后面是可选的链接标题
            end += 1
        add(start, line[index:end], end)
        start = line.find("](", end)
    # 导航行（一行只有链接和“·”，例如场景页顶部的返回链接）可以用缩写，不比较链接文字。
    residue = list(line)
    for begin, finish in spans:
        residue[begin:finish] = " " * (finish - begin)
    if spans and not "".join(residue).replace("·", "").strip():
        return [(target, None) for target, _ in targets]
    return targets


def _split_target(raw: str) -> tuple[str, str] | None:
    """Return (path, anchor) for a local link, or None for links this tool skips."""
    target = raw.strip()
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1]
    if not target or (URL_SCHEME.match(target) and not WINDOWS_DRIVE.match(target)):
        return None
    path, _, anchor = target.partition("#")
    path = path.split("?", 1)[0]
    return unquote(path), unquote(anchor)


def _is_excluded(relative: Path, excluded_names: set[str], excluded_paths: list[Path]) -> bool:
    if any(part in excluded_names for part in relative.parts[:-1]):
        return True
    return any(relative == prefix or prefix in relative.parents for prefix in excluded_paths)


def markdown_files(root: Path, excluded_names: set[str], excluded_paths: list[Path]) -> list[Path]:
    return sorted(
        path
        for path in root.rglob("*.md")
        if path.is_file() and not _is_excluded(path.relative_to(root), excluded_names, excluded_paths)
    )


def _normalize(text: str) -> str:
    return " ".join(text.replace("`", "").replace("*", "").split()).casefold()


def _text_mismatch(text: str, expected: str | None, number_optional: bool) -> bool:
    """True when the link text contains neither the expected heading nor, optionally, its unnumbered form."""
    if not expected:
        return False
    candidates = {_normalize(expected)}
    if number_optional:
        candidates.add(_normalize(TITLE_NUMBER.sub("", expected)))
    return not any(candidate in _normalize(text) for candidate in candidates)


def check_links(
    root: Path, files: list[Path], check_text: bool = False
) -> tuple[int, list[BrokenLink], list[LinkTextMismatch]]:
    """Check every local link in files; anchors in targets outside files are read on demand.

    With check_text, also list links whose text does not contain the target heading (anchor links)
    or the target file's H1 (links to a Markdown file without anchor).
    """
    cache: dict[Path, tuple[dict[str, str | None], list[tuple[int, str, str | None]], str | None]] = {}

    def scan(path: Path) -> tuple[dict[str, str | None], list[tuple[int, str, str | None]], str | None]:
        key = path.resolve()
        if key not in cache:
            cache[key] = _scan(key)
        return cache[key]

    checked = 0
    broken: list[BrokenLink] = []
    mismatched: list[LinkTextMismatch] = []
    for source in files:
        display = source.relative_to(root).as_posix()
        for line, raw, text in scan(source)[1]:
            parts = _split_target(raw)
            if parts is None:
                continue
            checked += 1
            path_text, anchor = parts
            if path_text.startswith("/"):
                broken.append(BrokenLink(display, line, raw, "root-relative path is not portable"))
                continue
            target = source if not path_text else (source.parent / path_text)
            if not target.exists():
                broken.append(BrokenLink(display, line, raw, "target does not exist"))
                continue
            if not (target.is_file() and target.suffix.lower() == ".md"):
                continue
            anchors, _, title = scan(target)
            if anchor and anchor not in anchors:
                broken.append(BrokenLink(display, line, raw, "anchor not found in target"))
                continue
            if check_text and text is not None:
                expected = anchors[anchor] if anchor else title
                if _text_mismatch(text, expected, number_optional=not anchor):
                    mismatched.append(LinkTextMismatch(display, line, raw, text.strip(), expected))
    return checked, broken, mismatched


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=REPO_ROOT, help="directory to scan (default: this project)")
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        metavar="PATH",
        help="additional path relative to --root whose Markdown files are not scanned; repeatable",
    )
    parser.add_argument("--json", action="store_true", help="print the result as JSON")
    parser.add_argument(
        "--check-link-text",
        action="store_true",
        help="also report (without failing) links whose text is not the target heading or file title",
    )
    args = parser.parse_args(argv)

    root = args.root.resolve()
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    excluded_paths = [Path(value) for value in args.exclude]
    files = markdown_files(root, set(DEFAULT_EXCLUDED_DIRECTORY_NAMES), excluded_paths)
    try:
        checked, broken, mismatched = check_links(root, files, args.check_link_text)
    except (OSError, UnicodeDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.json:
        result = {"files": len(files), "links": checked, "broken": [asdict(item) for item in broken]}
        if args.check_link_text:
            result["link_text"] = [asdict(item) for item in mismatched]
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        for item in broken:
            print(f"{item.file}:{item.line}  {item.target}  {item.reason}")
        for item in mismatched:
            print(f"{item.file}:{item.line}  [{item.rule}] [{item.text}]({item.target})  标题：{item.expected}")
        summary = f"{len(files)} files, {checked} local links, {len(broken)} broken"
        if args.check_link_text:
            summary += f", {len(mismatched)} link text mismatches (report only)"
        print(summary)
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
