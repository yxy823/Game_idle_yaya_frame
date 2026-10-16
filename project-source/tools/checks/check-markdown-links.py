#!/usr/bin/env python3
"""Check relative Markdown links and heading anchors inside a directory tree."""
# 只读检查：不联网、不改写文件。锚点按 GitHub 的标题锚点规则生成。
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.markdown_links import (  # noqa: E402
    DEFAULT_EXCLUDED_DIRECTORY_NAMES, ScanCache, markdown_files, split_target,
)

REPO_ROOT = Path(__file__).resolve().parents[3]


@dataclass(frozen=True)
class BrokenLink:
    file: str
    line: int
    target: str
    reason: str


def check_links(root: Path, files: list[Path]) -> tuple[int, list[BrokenLink]]:
    """Check every local link in files; anchors in targets outside files are read on demand."""
    scan = ScanCache()
    checked = 0
    broken: list[BrokenLink] = []
    for source in files:
        display = source.relative_to(root).as_posix()
        for line, raw, _ in scan(source).links:
            parts = split_target(raw)
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
            if anchor and target.is_file() and target.suffix.lower() == ".md":
                if anchor not in scan(target).anchors:
                    broken.append(BrokenLink(display, line, raw, "anchor not found in target"))
    return checked, broken


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*", type=Path, help="Markdown files under --root to check instead of scanning it")
    parser.add_argument("--root", type=Path, default=REPO_ROOT, help="directory to scan (default: this project)")
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        metavar="PATH",
        help="additional path relative to --root whose Markdown files are not scanned; repeatable",
    )
    parser.add_argument("--json", action="store_true", help="print the result as JSON")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    excluded_paths = [Path(value) for value in args.exclude]
    try:
        files = ([path.resolve() for path in args.files] if args.files
                 else markdown_files(root, set(DEFAULT_EXCLUDED_DIRECTORY_NAMES), excluded_paths))
        for path in files:
            if not path.is_relative_to(root):
                parser.error(f"file is not under --root: {path}")
        checked, broken = check_links(root, files)
    except (OSError, UnicodeDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(
            {"files": len(files), "links": checked, "broken": [asdict(item) for item in broken]},
            ensure_ascii=False,
            indent=2,
        ))
    else:
        for item in broken:
            print(f"{item.file}:{item.line}  {item.target}  {item.reason}")
        print(f"{len(files)} files, {checked} local links, {len(broken)} broken")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
