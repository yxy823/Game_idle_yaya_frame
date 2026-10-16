#!/usr/bin/env python3
"""Report terminology problems: forbidden wordings registered in the terms file, and optional candidate variants."""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import NamedTuple

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.document_text import (  # noqa: E402
    FENCE, TABLE_SEPARATOR, Document, DocumentError, add_scan_arguments, closes_fence, context_snippet,
    display_path, finding_line, markdown_document, read_documents, selected_files, split_cells,
)

LIST_SPLIT = re.compile(r"[、,，]")
ENTRY_LINE = re.compile(r"^ {0,3}(#{2,6}\s|[-*+]\s|\d+[.)]\s|\|)")
CJK = re.compile(r"[\u3400-\u9fff]")
ASCII_TERM = re.compile(r"[A-Za-z][A-Za-z0-9_-]*")
ASCII_RUN = re.compile(r"(?<![A-Za-z0-9_-])[A-Za-z][A-Za-z0-9_-]*")
STOP_CHARACTERS = set("的了和与及或中里在是时等也都就而并把被让给向对从到按以不只这那其之每各由会要须")


class TermsFileError(Exception):
    pass


@dataclass
class Term:
    name: str
    aliases: list[str]
    code_aliases: list[str]
    forbidden: list[str]
    definition: str


@dataclass
class Finding:
    path: str
    line: int
    column: int
    rule: str
    term: str
    found: str
    suggestion: str
    definition: str
    context: str
    message: str


def split_aliases(cell: str) -> list[str]:
    """Split a term cell on '/' outside inline code; backticks are dropped from the result."""
    parts, current, in_code = [], [], False
    for character in cell:
        if character == "`":
            in_code = not in_code
        elif character == "/" and not in_code:
            parts.append("".join(current))
            current = []
            continue
        current.append(character)
    parts.append("".join(current))
    return [part.strip().replace("`", "") for part in parts if part.strip()]


def parse_terms(path: Path, display: str) -> list[Term]:
    lines = path.read_text(encoding="utf-8").splitlines()
    terms: list[Term] = []
    entry_line: int | None = None
    fence: str | None = None
    index = 0
    while index < len(lines):
        line = lines[index]
        if fence is not None:
            if closes_fence(line, fence):
                fence = None
            index += 1
            continue
        fence_match = FENCE.match(line)
        if fence_match:
            fence = fence_match.group(1)
            index += 1
            continue
        if not (line.lstrip().startswith("|") and index + 1 < len(lines) and TABLE_SEPARATOR.match(lines[index + 1])):
            if entry_line is None and ENTRY_LINE.match(line):
                entry_line = index + 1
            index += 1
            continue
        header = split_cells(line)
        term_column = next((i for i, cell in enumerate(header) if "术语" in cell), None)
        forbidden_column = next((i for i, cell in enumerate(header) if "不用的说法" in cell), None)
        valid = term_column is not None and forbidden_column is not None
        index += 2
        while index < len(lines) and lines[index].lstrip().startswith("|"):
            if valid:
                cells = split_cells(lines[index])
                if len(cells) < len(header):
                    raise TermsFileError(f"{display}:{index + 1}: 表格行有 {len(cells)} 列，表头有 {len(header)} 列")
                aliases = split_aliases(cells[term_column])
                if not aliases:
                    raise TermsFileError(f"{display}:{index + 1}: 术语格为空")
                forbidden = [item.strip().replace("`", "") for item in LIST_SPLIT.split(cells[forbidden_column])]
                forbidden = [item for item in forbidden if item]
                code = {alias for alias in aliases if f"`{alias}`" in cells[term_column]}
                name = next((alias for alias in aliases if alias not in code), aliases[0])
                terms.append(Term(name, aliases, sorted(code), forbidden, f"{display}:{index + 1}"))
            elif entry_line is None:
                entry_line = index + 1
            index += 1
    if not terms and entry_line is not None:
        raise TermsFileError(f"{display}:{entry_line}: 术语文件无法解析：有条目却没有从表格读出术语，"
                             "请按项目术语规范的“术语文件的格式”改用 | 术语 | 含义与边界 | 不用的说法 | 表格")
    return terms


def lines_for(term: Term, documents: list[Document]):
    """Yield (document, line index, masked text) outside code, skipping the term's own definition line."""
    for document in documents:
        for index, masked in enumerate(document.masked):
            if masked is None or f"{document.path}:{document.lines[index]}" == term.definition:
                continue
            yield document, index, masked


def check_forbidden(terms: list[Term], documents: list[Document], options: argparse.Namespace) -> list[Finding]:
    findings = []
    for term in terms:
        phrases = sorted(set(term.forbidden), key=len, reverse=True)
        for document, index, masked in lines_for(term, documents):
            taken: list[tuple[int, int]] = []
            for phrase in phrases:
                for match in re.finditer(re.escape(phrase), masked):
                    span = match.span()
                    if any(span[0] < end and start < span[1] for start, end in taken):
                        continue
                    taken.append(span)
                    findings.append(Finding(
                        document.path, document.lines[index], document.offsets[index] + span[0] + 1, "TERM-FORBIDDEN",
                        term.name, phrase, term.name, term.definition,
                        context_snippet(document.original[index], span[0] + 1, options.context_width),
                        f"「{phrase}」是不用的说法，应改为「{term.name}」（定义见 {term.definition}）",
                    ))
    return findings


def _common_prefix(left: str, right: str) -> int:
    size = 0
    while size < min(len(left), len(right)) and left[size].lower() == right[size].lower():
        size += 1
    return size


def _variants(alias: str, masked: str, options: argparse.Namespace):
    """Yield (start index, word) for words in masked that begin like alias.

    English terms match whole words equal to the term or its plural with -s/-es, ignoring case; Chinese
    terms match the first --prefix-length characters (default: term length - 1, at least 2) and extend over
    Chinese characters to a stop character; a run longer than --max-length is a phrase, not a variant, and
    is skipped.
    """
    if ASCII_TERM.fullmatch(alias):
        forms = {alias.lower(), alias.lower() + "s", alias.lower() + "es"}
        for match in ASCII_RUN.finditer(masked):
            if match.group(0).lower() in forms:
                yield match.start(), match.group(0)
        return
    prefix_length = options.prefix_length or max(2, len(alias) - 1)
    prefix = alias[:prefix_length]
    if len(prefix) < prefix_length or not all(CJK.match(character) for character in prefix):
        return
    for match in re.finditer(re.escape(prefix), masked):
        start, end = match.span()
        limit = min(len(masked), start + options.max_length)
        while end < limit and CJK.match(masked[end]) and masked[end] not in STOP_CHARACTERS:
            end += 1
        truncated = end < len(masked) and CJK.match(masked[end]) and masked[end] not in STOP_CHARACTERS
        if end - start > prefix_length and not truncated:
            yield start, masked[start:end]


class _BestTerm(NamedTuple):
    shared_prefix: int
    order: int
    term: Term


class _Occurrence(NamedTuple):
    path: str
    line_number: int
    column: int
    line_index: int
    inline_column: int


def discover_candidates(terms: list[Term], documents: list[Document], options: argparse.Namespace) -> list[Finding]:
    known = {alias for term in terms for alias in term.aliases} | {phrase for term in terms for phrase in term.forbidden}
    best_term_by_word: dict[str, _BestTerm] = {}
    occurrences: dict[tuple[str, str], set[_Occurrence]] = defaultdict(set)
    for order, term in enumerate(terms):
        for alias in term.aliases:
            if alias in term.code_aliases:
                continue
            for document, index, masked in lines_for(term, documents):
                for start, word in _variants(alias, masked, options):
                    if word in known:
                        continue
                    if not options.include_compounds and any(word.startswith(other) for other in term.aliases
                                                              if not ASCII_TERM.fullmatch(other)):
                        continue
                    shared = _common_prefix(word, alias)
                    best = best_term_by_word.get(word)
                    if best is None or (shared, -order) > (best.shared_prefix, -best.order):
                        best_term_by_word[word] = _BestTerm(shared, order, term)
                    occurrences[(term.name, word)].add(_Occurrence(
                        document.path, document.lines[index], document.offsets[index] + start + 1, index, start + 1))
    document_lines = {document.path: document.original for document in documents}
    findings = []
    for word, (_, _, term) in best_term_by_word.items():
        places = sorted(occurrences[(term.name, word)])
        if len(places) < options.min_count:
            continue
        for place in places:
            findings.append(Finding(
                place.path, place.line_number, place.column, "TERM-CANDIDATE", term.name, word, term.name,
                term.definition,
                context_snippet(document_lines[place.path][place.line_index], place.inline_column,
                                options.context_width),
                f"「{word}」与术语「{term.name}」开头相同，可能是另一种写法（定义见 {term.definition}）",
            ))
    return findings


CHECKERS = {
    "forbidden": (check_forbidden, True),
    "discover": (discover_candidates, False),
}


def candidate_groups(findings: list[Finding]) -> list[tuple[str, list[tuple[str, int]], list[Finding]]]:
    by_term: dict[str, list[Finding]] = defaultdict(list)
    for finding in findings:
        by_term[finding.term].append(finding)
    groups = []
    for term, items in by_term.items():
        counts = Counter(item.found for item in items).most_common()
        order = {word: index for index, (word, _) in enumerate(counts)}
        items.sort(key=lambda item: (order[item.found], item.path, item.line, item.column))
        groups.append((term, counts, items))
    groups.sort(key=lambda group: -sum(count for _, count in group[1]))
    return groups


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    add_scan_arguments(parser)
    parser.add_argument("--terms", type=Path, default=Path("docs/terminology.md"),
                        help="terms file, relative to --root unless absolute (default: docs/terminology.md)")
    parser.add_argument("--discover", action="store_true",
                        help="also list candidate variants that share a term's first characters; does not affect the exit code")
    parser.add_argument("--prefix-length", type=int,
                        help="characters a candidate shares with a Chinese term (default: term length - 1, at least 2)")
    parser.add_argument("--include-compounds", action="store_true",
                        help="also list candidates that start with a whole allowed wording of the term")
    parser.add_argument("--min-count", type=int, default=2, help="minimum occurrences for a candidate (default: 2)")
    parser.add_argument("--max-length", type=int, default=6, help="maximum characters in a candidate (default: 6)")
    parser.add_argument("--stdin-text", action="store_true",
                        help="check UTF-8 Markdown text read from standard input instead of files; reported as <stdin>")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    if ((args.prefix_length is not None and (args.prefix_length < 1 or args.max_length <= args.prefix_length))
            or args.min_count < 1 or args.max_length < 3 or args.context_width < 10):
        parser.error("--prefix-length and --min-count must be >= 1, --max-length >= 3 and > --prefix-length, --context-width >= 10")
    if args.stdin_text and (args.paths or args.files_from is not None):
        parser.error("--stdin-text cannot be combined with FILE or --files-from")
    terms_path = args.terms if args.terms.is_absolute() else root / args.terms
    if not terms_path.is_file():
        print(f"error: terms file not found: {terms_path}", file=sys.stderr)
        return 2
    try:
        terms = parse_terms(terms_path, display_path(terms_path, root))
        if args.stdin_text:
            files = [Path("<stdin>")]
            documents = [markdown_document(sys.stdin.buffer.read().decode("utf-8"), "<stdin>")]
        else:
            files = selected_files(root, args)
            documents = read_documents(root, files)
    except (TermsFileError, DocumentError, OSError, UnicodeDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    selected = ["forbidden"] + (["discover"] if args.discover else [])
    results = {name: CHECKERS[name][0](terms, documents, args) for name in selected}
    forbidden = sorted(results["forbidden"], key=lambda item: (item.path, item.line, item.column))
    groups = candidate_groups(results["discover"]) if args.discover else []
    candidates = [item for _, _, items in groups for item in items]
    failed = any(results[name] for name in selected if CHECKERS[name][1])

    summary = {
        "files": len(files),
        "terms": len(terms),
        "terms_with_forbidden": sum(1 for term in terms if term.forbidden),
        "forbidden": len(forbidden),
        "discover_run": args.discover,
        "candidate_words": sum(len(counts) for _, counts, _ in groups),
        "candidates": len(candidates),
    }
    if args.json:
        print(json.dumps({
            "summary": summary,
            "findings": [asdict(item) for item in forbidden + candidates],
            "candidate_groups": [{"term": term, "candidates": [{"found": word, "count": count} for word, count in counts]}
                                 for term, counts, _ in groups],
        }, ensure_ascii=False, indent=2))
        return 1 if failed else 0

    def line_of(item: Finding) -> str:
        return finding_line(item.path, item.line, item.column, item.rule, item.message, item.context)

    for item in forbidden:
        print(line_of(item))
    for term, counts, items in groups:
        print(f"{term} → " + "、".join(f"{word}（{count}）" for word, count in counts))
        for item in items:
            print(line_of(item))
    print()
    discover_text = (f"[TERM-CANDIDATE] 候选词 {summary['candidate_words']} 个、{summary['candidates']} 处（只作参考，不影响退出码）"
                     if args.discover else "[TERM-CANDIDATE] 未运行（加 --discover 运行）")
    print(f"扫描 {summary['files']} 个文件，术语 {summary['terms']} 个（登记了不用的说法的 {summary['terms_with_forbidden']} 个）；"
          f"[TERM-FORBIDDEN] 不用的说法 {summary['forbidden']} 处；{discover_text}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
