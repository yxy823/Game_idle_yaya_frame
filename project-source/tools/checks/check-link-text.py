#!/usr/bin/env python3
"""Report Markdown links whose text is not the target heading, file title, or the target's own name."""
# 只读检查：不联网、不改写文件。比较规则见 tools/README.md 的 check-link-text.py 一节；
# 链接是否存在由 check-markdown-links.py 负责，这里跳过目标或锚点不存在的链接。
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.document_text import DocumentError, selected_files  # noqa: E402
from tools.lib.markdown_links import ScanCache, split_target  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[3]
# 方法论文件的一级标题带“NN · ”编号，只链到文件时链接文字可以省略。
TITLE_NUMBER = re.compile(r"^\d+\s*·\s*")


@dataclass(frozen=True)
class LinkTextMismatch:
    file: str
    line: int
    target: str
    text: str
    expected: str
    rule: str = "LINK-TEXT"


def _normalize(text: str) -> str:
    return " ".join(text.replace("`", "").replace("*", "").split()).casefold()


def _contains_heading(text: str, expected: str, number_optional: bool) -> bool:
    candidates = {_normalize(expected)}
    if number_optional:
        candidates.add(_normalize(TITLE_NUMBER.sub("", expected)))
    return any(candidate in _normalize(text) for candidate in candidates)


def _names_target(text: str, target: Path) -> bool:
    """True when the text is, letter for letter, the target's file or directory name or a trailing path of it.

    `$` before a Skill name and backticks are dropped first. The last segment may be the file name with or
    without extension; a text ending at the containing directory (with or without a trailing '/') names
    that directory, which for SKILL.md is the Skill name.
    """
    name = text.replace("`", "").strip().removeprefix("$").rstrip("/")
    if not name:
        return False
    segments = name.split("/")
    parts = target.parts
    for tail in (parts[:-1] + (target.stem,), parts, parts[:-1]):
        if len(segments) <= len(tail) and list(tail[len(tail) - len(segments):]) == segments:
            return True
    return False


def check_link_text(root: Path, files: list[Path]) -> tuple[int, list[LinkTextMismatch]]:
    """Compare the text of every local link in files with its target; return (links compared, mismatches)."""
    scan = ScanCache()
    compared = 0
    mismatched: list[LinkTextMismatch] = []
    for source in files:
        display = source.relative_to(root).as_posix()
        for line, raw, text in scan(source).links:
            parts = split_target(raw) if text is not None else None
            if parts is None:
                continue
            path_text, anchor = parts
            if path_text.startswith("/"):
                continue
            target = source if not path_text else (source.parent / path_text)
            if not (target.is_file() and target.suffix.lower() == ".md"):
                continue
            scanned = scan(target)
            expected = scanned.anchors.get(anchor) if anchor else scanned.title
            if not expected:  # 锚点不存在、<a id> 锚点或文件没有一级标题
                continue
            compared += 1
            if _contains_heading(text, expected, number_optional=not anchor):
                continue
            if not anchor and _names_target(text, target.resolve()):
                continue
            mismatched.append(LinkTextMismatch(display, line, raw, text.strip(), expected))
    return compared, mismatched


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path, metavar="FILE",
                        help="check only these Markdown files (relative to --root unless absolute); "
                             "other file types and files in excluded directories are skipped")
    parser.add_argument("--files-from", metavar="LIST",
                        help="also check the files listed in LIST, one path per line ('-' reads standard input); "
                             "an empty list checks no file")
    parser.add_argument("--root", type=Path, default=REPO_ROOT, help="directory to scan (default: this project)")
    parser.add_argument("--exclude", action="append", default=[], metavar="PATH",
                        help="additional path relative to --root whose Markdown files are not scanned; repeatable")
    parser.add_argument("--json", action="store_true", help="print the result as JSON")
    args = parser.parse_args(argv)
    args.include = None  # 扫描整个目录时只查 *.md

    root = args.root.resolve()
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    try:
        files = [path for path in selected_files(root, args) if path.suffix.lower() == ".md"]
        compared, mismatched = check_link_text(root, files)
    except (DocumentError, OSError, UnicodeDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(
            {"files": len(files), "links": compared, "findings": [asdict(item) for item in mismatched]},
            ensure_ascii=False,
            indent=2,
        ))
    else:
        for item in mismatched:
            print(f"{item.file}:{item.line}  [{item.rule}] [{item.text}]({item.target})  标题：{item.expected}")
        print(f"{len(files)} files, {compared} links compared, {len(mismatched)} link text mismatches")
    return 1 if mismatched else 0


if __name__ == "__main__":
    sys.exit(main())
