#!/usr/bin/env python3
"""Report terminology problems: forbidden wordings registered in the terms file, and optional candidate variants."""
# 只读检查：不改写文件。代码、引号内的文字和术语自己的定义行不算出现，因为写作规范会把禁用词当例子列出。
from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import sys
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path

# 与 check-markdown-links.py 相同：按目录名在任意层级排除。
DEFAULT_EXCLUDED_DIRECTORY_NAMES = (".git", ".godot", ".claude", "tmp", "addons", "__pycache__")

FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
INLINE_CODE = re.compile(r"(`+)(?:(?!\1).)+?\1")
QUOTED = re.compile(r"「[^」]*」|“[^”]*”|\"[^\"]*\"")
TABLE_SEPARATOR = re.compile(r"^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$")
CELL_SPLIT = re.compile(r"(?<!\\)\|")
LIST_SPLIT = re.compile(r"[、,，]")
LINK_TARGET = re.compile(r"(?<=\]\()[^)]*(?=\))")
CJK = re.compile(r"[\u3400-\u9fff]")
ASCII_TERM = re.compile(r"[A-Za-z][A-Za-z0-9_-]*")
ASCII_RUN = re.compile(r"(?<![A-Za-z0-9_-])[A-Za-z][A-Za-z0-9_-]*")
# 候选词在这些虚词处截断，避免把「分发源的」「游戏中」之类当成新写法。
STOP_CHARACTERS = set("的了和与及或中里在是时等也都就而并把被让给向对从到按以不只这那其之每各由会要须")


class TermsFileError(Exception):
    pass


@dataclass
class Term:
    name: str
    aliases: list[str]
    code_aliases: list[str]  # 反引号里的代码或路径写法，不参与候选发现
    forbidden: list[str]
    definition: str  # 路径:行号


@dataclass
class Document:
    path: str
    original: list[str]
    masked: list[str | None]  # None 表示整行在代码块里


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


def split_cells(row: str) -> list[str]:
    text = row.strip()
    if text.startswith("|"):
        text = text[1:]
    if text.endswith("|") and not text.endswith("\\|"):
        text = text[:-1]
    return [cell.strip().replace("\\|", "|") for cell in CELL_SPLIT.split(text)]


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
    fence: str | None = None
    index = 0
    while index < len(lines):
        line = lines[index]
        fence_match = FENCE.match(line)
        if fence is not None:
            if fence_match and fence_match.group(1)[0] == fence[0] and len(fence_match.group(1)) >= len(fence):
                fence = None
            index += 1
            continue
        if fence_match:
            fence = fence_match.group(1)
            index += 1
            continue
        if not (line.lstrip().startswith("|") and index + 1 < len(lines) and TABLE_SEPARATOR.match(lines[index + 1])):
            index += 1
            continue
        header = split_cells(line)
        term_column = next((i for i, cell in enumerate(header) if "术语" in cell), None)
        forbidden_column = next((i for i, cell in enumerate(header) if "不用的说法" in cell), None)
        index += 2
        while index < len(lines) and lines[index].lstrip().startswith("|"):
            if term_column is not None:
                cells = split_cells(lines[index])
                if len(cells) < len(header):
                    raise TermsFileError(f"{display}:{index + 1}: 表格行有 {len(cells)} 列，表头有 {len(header)} 列")
                aliases = split_aliases(cells[term_column])
                if not aliases:
                    raise TermsFileError(f"{display}:{index + 1}: 术语格为空")
                forbidden = []
                if forbidden_column is not None:
                    forbidden = [item.strip().replace("`", "") for item in LIST_SPLIT.split(cells[forbidden_column])]
                    forbidden = [item for item in forbidden if item]
                code = {alias for alias in aliases if f"`{alias}`" in cells[term_column]}
                name = next((alias for alias in aliases if alias not in code), aliases[0])
                terms.append(Term(name, aliases, sorted(code), forbidden, f"{display}:{index + 1}"))
            index += 1
    return terms


def mask_line(line: str) -> str:
    """Blank out inline code, link targets and quoted text, keeping every column in place."""
    line = INLINE_CODE.sub(lambda match: " " * len(match.group(0)), line)
    line = LINK_TARGET.sub(lambda match: " " * len(match.group(0)), line)
    return QUOTED.sub(lambda match: " " * len(match.group(0)), line)


def read_document(path: Path, display: str) -> Document:
    original = path.read_text(encoding="utf-8").splitlines()
    masked: list[str | None] = []
    fence: str | None = None
    for line in original:
        fence_match = FENCE.match(line)
        if fence is not None:
            if fence_match and fence_match.group(1)[0] == fence[0] and len(fence_match.group(1)) >= len(fence):
                fence = None
            masked.append(None)
            continue
        if fence_match:
            fence = fence_match.group(1)
            masked.append(None)
            continue
        masked.append(mask_line(line))
    return Document(display, original, masked)


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


def context_snippet(line: str, column: int, width: int) -> str:
    stripped = line.strip()
    if len(stripped) <= width:
        return stripped
    offset = column - 1 - (len(line) - len(line.lstrip()))
    start = max(0, min(offset - width // 3, len(stripped) - width))
    snippet = stripped[start : start + width]
    return ("…" if start > 0 else "") + snippet + ("…" if start + width < len(stripped) else "")


def lines_for(term: Term, documents: list[Document]):
    """Yield (document, line number, masked text) outside code, skipping the term's own definition line."""
    for document in documents:
        for number, masked in enumerate(document.masked, start=1):
            if masked is None or f"{document.path}:{number}" == term.definition:
                continue
            yield document, number, masked


def check_forbidden(terms: list[Term], documents: list[Document], options: argparse.Namespace) -> list[Finding]:
    findings = []
    for term in terms:
        phrases = sorted(set(term.forbidden), key=len, reverse=True)
        for document, number, masked in lines_for(term, documents):
            taken: list[tuple[int, int]] = []
            for phrase in phrases:
                for match in re.finditer(re.escape(phrase), masked):
                    span = match.span()
                    if any(span[0] < end and start < span[1] for start, end in taken):
                        continue
                    taken.append(span)
                    column = span[0] + 1
                    line = document.original[number - 1]
                    findings.append(Finding(
                        document.path, number, column, "TERM-FORBIDDEN", term.name, phrase, term.name, term.definition,
                        context_snippet(line, column, options.context_width),
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


def discover_candidates(terms: list[Term], documents: list[Document], options: argparse.Namespace) -> list[Finding]:
    known = {alias for term in terms for alias in term.aliases} | {phrase for term in terms for phrase in term.forbidden}
    # 同一候选词归到与它公共前缀最长的术语（同长取术语文件中靠前的），避免在几个术语下重复列出。
    owners: dict[str, tuple[int, int, Term]] = {}
    occurrences: dict[tuple[str, str], set[tuple[str, int, int]]] = defaultdict(set)
    for order, term in enumerate(terms):
        for alias in term.aliases:
            if alias in term.code_aliases:
                continue
            for document, number, masked in lines_for(term, documents):
                for start, word in _variants(alias, masked, options):
                    if word in known:
                        continue
                    if not options.include_compounds and any(word.startswith(other) for other in term.aliases
                                                              if not ASCII_TERM.fullmatch(other)):
                        continue
                    rank = (_common_prefix(word, alias), -order)
                    if word not in owners or rank > owners[word][:2]:
                        owners[word] = (*rank, term)
                    occurrences[(term.name, word)].add((document.path, number, start + 1))
    document_lines = {document.path: document.original for document in documents}
    findings = []
    for word, (_, _, term) in owners.items():
        places = sorted(occurrences[(term.name, word)])
        if len(places) < options.min_count:
            continue
        for path, number, column in places:
            findings.append(Finding(
                path, number, column, "TERM-CANDIDATE", term.name, word, term.name, term.definition,
                context_snippet(document_lines[path][number - 1], column, options.context_width),
                f"「{word}」与术语「{term.name}」开头相同，可能是另一种写法（定义见 {term.definition}）",
            ))
    return findings


# 注册表：名称 → (检查器, 是否影响退出码)。新增检查时写一个同签名的函数并在这里登记。
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
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="directory to scan (default: current directory)")
    parser.add_argument("--terms", type=Path, default=Path("docs/terminology.md"),
                        help="terms file, relative to --root unless absolute (default: docs/terminology.md)")
    parser.add_argument("--include", action="append", metavar="GLOB",
                        help="file name glob, or path glob when it contains '/'; repeatable (default: *.md)")
    parser.add_argument("--exclude", action="append", default=[], metavar="PATH",
                        help="additional path relative to --root that is not scanned; repeatable")
    parser.add_argument("--discover", action="store_true",
                        help="also list candidate variants that share a term's first characters; does not affect the exit code")
    parser.add_argument("--prefix-length", type=int,
                        help="characters a candidate shares with a Chinese term (default: term length - 1, at least 2)")
    parser.add_argument("--include-compounds", action="store_true",
                        help="also list candidates that start with a whole allowed wording of the term")
    parser.add_argument("--min-count", type=int, default=2, help="minimum occurrences for a candidate (default: 2)")
    parser.add_argument("--max-length", type=int, default=6, help="maximum characters in a candidate (default: 6)")
    parser.add_argument("--context-width", type=int, default=80, help="maximum characters of line context (default: 80)")
    parser.add_argument("--json", action="store_true", help="print the result as JSON")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    if ((args.prefix_length is not None and (args.prefix_length < 1 or args.max_length <= args.prefix_length))
            or args.min_count < 1 or args.max_length < 3 or args.context_width < 10):
        parser.error("--prefix-length and --min-count must be >= 1, --max-length >= 3 and > --prefix-length, --context-width >= 10")
    terms_path = args.terms if args.terms.is_absolute() else root / args.terms
    if not terms_path.is_file():
        print(f"error: terms file not found: {terms_path}", file=sys.stderr)
        return 2
    try:
        terms_display = terms_path.resolve().relative_to(root).as_posix()
    except ValueError:
        terms_display = terms_path.resolve().as_posix()
    try:
        terms = parse_terms(terms_path, terms_display)
        files = scanned_files(root, args.include or ["*.md"], set(DEFAULT_EXCLUDED_DIRECTORY_NAMES),
                              [Path(value) for value in args.exclude])
        documents = [read_document(path, path.relative_to(root).as_posix()) for path in files]
    except TermsFileError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    except (OSError, UnicodeDecodeError) as exc:
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
        return f"{item.path}:{item.line}:{item.column}: [{item.rule}] {item.message} | {item.context}"

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
