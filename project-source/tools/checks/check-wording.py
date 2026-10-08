#!/usr/bin/env python3
"""Report wordings listed in the wording table: hard words fail the check, words to review are listed only."""
# 只读检查：不改写文件。词表是写作指南中的一张表；代码、引号内的文字和词表自己的表格行不算出现。
# 读取、遮蔽、文件选择和输出格式与术语检查共用 tools/lib/document_text.py。
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path, PurePosixPath

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.document_text import (  # noqa: E402
    FENCE, TABLE_SEPARATOR, Document, DocumentError, add_scan_arguments, closes_fence, context_snippet,
    display_path, finding_line, read_documents, selected_files, split_cells,
)

DEFAULT_WORDS = Path(".agents/skills/technical-documentation-writing-godot/references/writing-guide.md")
HEADER = ("词", "级别", "适用范围", "推荐写法")
LEVELS = {"硬性": "WORDING-HARD", "待复核": "WORDING-REVIEW"}
SCOPES = ("规则文件", "全部文档")
# 单字词只在不属于这些词语时算出现：“应用”“对应”里的“应”不表示要求。词表新增单字词时在这里补它的词语。
COMPOUNDS = {
    "应": ("应用", "对应", "相应", "响应", "反应", "适应", "供应", "回应", "呼应", "感应", "效应", "答应", "顺应",
          "照应", "因应", "报应", "内应", "应对", "应急", "应变", "应答", "应聘", "应征", "应届", "应酬", "应邀",
          "应验", "应援"),
    "宜": ("适宜", "便宜", "事宜", "合宜", "权宜", "宜人", "时宜", "相宜", "机宜", "宜居"),
}


class WordsFileError(Exception):
    pass


@dataclass
class Word:
    text: str
    level: str
    scope: str
    suggestion: str
    definition: str  # 路径:行号


@dataclass
class Finding:
    path: str
    line: int
    column: int
    rule: str
    word: str
    level: str
    scope: str
    suggestion: str
    definition: str
    context: str
    message: str


def parse_words(path: Path, display: str) -> tuple[list[Word], set[str]]:
    """Read the first table whose header is exactly 词 | 级别 | 适用范围 | 推荐写法; also return its row locations."""
    lines = path.read_text(encoding="utf-8").splitlines()
    fence: str | None = None
    for index, line in enumerate(lines):
        if fence is not None:
            if closes_fence(line, fence):
                fence = None
            continue
        fence_match = FENCE.match(line)
        if fence_match:
            fence = fence_match.group(1)
            continue
        if not (line.lstrip().startswith("|") and index + 1 < len(lines) and TABLE_SEPARATOR.match(lines[index + 1])):
            continue
        if tuple(split_cells(line)) != HEADER:
            continue
        words, rows = [], set()
        row = index + 2
        while row < len(lines) and lines[row].lstrip().startswith("|"):
            location = f"{display}:{row + 1}"
            cells = split_cells(lines[row])
            if len(cells) != len(HEADER):
                raise WordsFileError(f"{location}: 表格行有 {len(cells)} 列，表头有 {len(HEADER)} 列")
            text, level, scope, suggestion = (cell.replace("`", "").strip() for cell in cells)
            if not text:
                raise WordsFileError(f"{location}: 词格为空")
            if level not in LEVELS:
                raise WordsFileError(f"{location}: 级别「{level}」不是 {'、'.join(LEVELS)} 之一")
            if scope not in SCOPES:
                raise WordsFileError(f"{location}: 适用范围「{scope}」不是 {'、'.join(SCOPES)} 之一")
            words.append(Word(text, level, scope, suggestion, location))
            rows.add(location)
            row += 1
        return words, rows
    raise WordsFileError(f"{display}: 没有找到表头为 | {' | '.join(HEADER)} | 的词表")


def is_rule_file(path: str) -> bool:
    """Rule files: AGENTS files, agent rules, methodology, project rules, Skill bodies and references, prompt libraries."""
    parts = PurePosixPath(path).parts
    name = parts[-1]
    if name in ("AGENTS.md", "Project_AGENTS.md") or path == "docs/project-rules.md":
        return True
    if any(part in ("agent-rules", "methodology") for part in parts[:-1]):
        return True
    for index, part in enumerate(parts[:-1]):
        if part == "skills" and index + 2 < len(parts):
            return name == "SKILL.md" and index + 3 == len(parts) or "references" in parts[index + 2:-1]
    return name.endswith(".json") and len(parts) > 1 and parts[-2] == "prompts"


def occurrences(word: str, masked: str):
    """Yield start indexes of word; a single character inside one of its listed compounds is skipped."""
    covered: set[int] = set()
    for compound in COMPOUNDS.get(word, ()):
        offset = compound.index(word)
        for match in re.finditer(re.escape(compound), masked):
            covered.add(match.start() + offset)
    for match in re.finditer(re.escape(word), masked):
        if match.start() not in covered:
            yield match.start()


def check_words(words: list[Word], skipped_rows: set[str], documents: list[Document],
                options: argparse.Namespace) -> list[Finding]:
    findings = []
    ordered = sorted(words, key=lambda item: len(item.text), reverse=True)
    for document in documents:
        rule_file = is_rule_file(document.path)
        applicable = [word for word in ordered if word.scope == "全部文档" or rule_file]
        for index, masked in enumerate(document.masked):
            if masked is None or f"{document.path}:{document.lines[index]}" in skipped_rows:
                continue
            taken: list[tuple[int, int]] = []
            for word in applicable:
                for start in occurrences(word.text, masked):
                    span = (start, start + len(word.text))
                    if any(span[0] < end and begin < span[1] for begin, end in taken):
                        continue
                    taken.append(span)
                    if word.level == "硬性":
                        message = f"「{word.text}」在{word.scope}中不用：{word.suggestion}（词表见 {word.definition}）"
                    else:
                        message = f"「{word.text}」待复核：{word.suggestion}（词表见 {word.definition}）"
                    findings.append(Finding(
                        document.path, document.lines[index], document.offsets[index] + start + 1, LEVELS[word.level],
                        word.text, word.level, word.scope, word.suggestion, word.definition,
                        context_snippet(document.original[index], start + 1, options.context_width), message,
                    ))
    return sorted(findings, key=lambda item: (item.rule != "WORDING-HARD", item.path, item.line, item.column))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    add_scan_arguments(parser)
    parser.add_argument("--words", type=Path, default=DEFAULT_WORDS,
                        help=f"file holding the wording table, relative to --root unless absolute (default: {DEFAULT_WORDS.as_posix()})")
    parser.add_argument("--level", choices=("all", "hard"), default="all",
                        help="hard: report only hard words, for the commit hook (default: all)")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    if args.context_width < 10:
        parser.error("--context-width must be >= 10")
    words_path = args.words if args.words.is_absolute() else root / args.words
    if not words_path.is_file():
        print(f"error: wording table file not found: {words_path}", file=sys.stderr)
        return 2
    try:
        words, skipped_rows = parse_words(words_path, display_path(words_path, root))
        files = selected_files(root, args)
        documents = read_documents(root, files)
    except (WordsFileError, DocumentError, OSError, UnicodeDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.level == "hard":
        words = [word for word in words if word.level == "硬性"]
    findings = check_words(words, skipped_rows, documents, args)
    hard = [item for item in findings if item.rule == "WORDING-HARD"]
    review = [item for item in findings if item.rule == "WORDING-REVIEW"]
    summary = {
        "files": len(files),
        "rule_files": sum(1 for document in documents if is_rule_file(document.path)),
        "words": len(words),
        "level": args.level,
        "hard": len(hard),
        "review": len(review),
    }
    if args.json:
        print(json.dumps({"summary": summary, "findings": [asdict(item) for item in findings]},
                         ensure_ascii=False, indent=2))
        return 1 if hard else 0

    for item in findings:
        print(finding_line(item.path, item.line, item.column, item.rule, item.message, item.context))
    print()
    review_text = (f"[WORDING-REVIEW] 待复核 {summary['review']} 处（逐处看上下文判断，不影响退出码）"
                   if args.level == "all" else "[WORDING-REVIEW] 未运行（--level hard）")
    print(f"扫描 {summary['files']} 个文件（规则文件 {summary['rule_files']} 个），词表 {summary['words']} 个词；"
          f"[WORDING-HARD] 硬性 {summary['hard']} 处；{review_text}")
    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main())
