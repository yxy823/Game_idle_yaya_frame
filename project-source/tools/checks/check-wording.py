#!/usr/bin/env python3
"""Report wordings matched by the checks in wording-check.json: hard checks fail, checks to review are listed only."""
# 只读检查：不改写文件。要找的写法和例外都写在配置的正则里，脚本不保存词表；代码、引号内的文字不算出现。
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
    Document, DocumentError, add_scan_arguments, context_snippet, display_path, finding_line, read_documents,
    selected_files,
)

DEFAULT_CONFIG = Path(__file__).resolve().parent / "wording-check.json"
LEVELS = {"hard": "WORDING-HARD", "review": "WORDING-REVIEW"}
LEVEL_NAMES = {"hard": "硬性", "review": "待复核"}
SCOPES = {"rule-files": "规则文件", "all": "全部文档"}
FIELDS = ("name", "level", "scope", "pattern", "suggestion")


class ConfigError(Exception):
    pass


@dataclass
class Check:
    name: str
    level: str
    scope: str
    pattern: str
    suggestion: str
    regex: re.Pattern


@dataclass
class Finding:
    path: str
    line: int
    column: int
    rule: str
    check: str
    found: str
    level: str
    scope: str
    suggestion: str
    context: str
    message: str


def load_checks(path: Path, display: str) -> list[Check]:
    """Read {"checks": [{name, level, scope, pattern, suggestion}, ...]} and compile every pattern."""
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ConfigError(f"{display}:{exc.lineno}:{exc.colno}: JSON 解析失败：{exc.msg}") from exc
    items = data.get("checks") if isinstance(data, dict) else None
    if not isinstance(items, list) or not items:
        raise ConfigError(f"{display}: 缺少非空的 checks 列表")
    checks = []
    for number, item in enumerate(items, 1):
        where = f"{display}: 第 {number} 个检查项"
        if not isinstance(item, dict) or set(item) != set(FIELDS):
            raise ConfigError(f"{where}的字段必须正好是 {'、'.join(FIELDS)}")
        if not all(isinstance(item[field], str) and item[field] for field in FIELDS):
            raise ConfigError(f"{where}有空字段或非字符串字段")
        where = f"{display}: 检查项「{item['name']}」"
        if item["level"] not in LEVELS:
            raise ConfigError(f"{where}的 level「{item['level']}」不是 {'、'.join(LEVELS)} 之一")
        if item["scope"] not in SCOPES:
            raise ConfigError(f"{where}的 scope「{item['scope']}」不是 {'、'.join(SCOPES)} 之一")
        try:
            regex = re.compile(item["pattern"])
        except re.error as exc:
            raise ConfigError(f"{where}的 pattern 不是合法的正则：{exc}") from exc
        checks.append(Check(*(item[field] for field in FIELDS), regex))
    return checks


def is_rule_file(path: str) -> bool:
    """Rule files: AGENTS files, agent rules, methodology, project rules, Skill bodies and references, prompt libraries,
    and the framework's scenario guide and design guidelines."""
    parts = PurePosixPath(path).parts
    name = parts[-1]
    if name in ("AGENTS.md", "Project_AGENTS.md") or path in ("docs/project-rules.md",
                                                               "project-source/defaults/docs/project-rules.md",
                                                               "framework/prompt-scenarios/scenarios/README.md"):
        return True
    if path.startswith("framework/maintenance/design-guidelines/"):
        return True
    if any(part in ("agent-rules", "methodology") for part in parts[:-1]):
        return True
    for index, part in enumerate(parts[:-1]):
        if part == "skills" and index + 2 < len(parts):
            return name == "SKILL.md" and index + 3 == len(parts) or "references" in parts[index + 2:-1]
    return name.endswith(".json") and len(parts) > 1 and parts[-2] == "prompts"


def check_documents(checks: list[Check], documents: list[Document], options: argparse.Namespace) -> list[Finding]:
    """Scan every applicable check over every line; a position matched by several checks is reported by each."""
    findings = []
    for document in documents:
        rule_file = is_rule_file(document.path)
        applicable = [check for check in checks if check.scope == "all" or rule_file]
        for index, masked in enumerate(document.masked):
            if masked is None:
                continue
            for check in applicable:
                for match in check.regex.finditer(masked):
                    if not match.group(0):
                        continue
                    found = match.group(0)
                    if check.level == "hard":
                        message = f"「{found}」（{check.name}）在{SCOPES[check.scope]}中不用：{check.suggestion}"
                    else:
                        message = f"「{found}」（{check.name}）待复核：{check.suggestion}"
                    findings.append(Finding(
                        document.path, document.lines[index], document.offsets[index] + match.start() + 1,
                        LEVELS[check.level], check.name, found, check.level, check.scope, check.suggestion,
                        context_snippet(document.original[index], match.start() + 1, options.context_width), message,
                    ))
    return sorted(findings, key=lambda item: (item.rule != "WORDING-HARD", item.path, item.line, item.column))


def print_checks(checks: list[Check], verbose: bool) -> None:
    """Print the checks as a Markdown table; --verbose adds the regular expressions."""
    header = ["名称", "级别", "范围", "推荐写法"] + (["正则"] if verbose else [])
    print("| " + " | ".join(header) + " |")
    print("|" + " --- |" * len(header))
    for check in checks:
        cells = [check.name, LEVEL_NAMES[check.level], SCOPES[check.scope], check.suggestion]
        if verbose:
            cells.append(f"`{check.pattern}`")
        print("| " + " | ".join(cell.replace("|", "\\|") for cell in cells) + " |")
    print()
    print(f"共 {len(checks)} 项：硬性 {sum(check.level == 'hard' for check in checks)} 项，"
          f"待复核 {sum(check.level == 'review' for check in checks)} 项")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    add_scan_arguments(parser)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG,
                        help="wording check configuration, relative to --root unless absolute "
                             "(default: wording-check.json next to this script)")
    parser.add_argument("--level", choices=("all", "hard"), default="all",
                        help="hard: report only hard checks, for the commit hook (default: all)")
    parser.add_argument("--list", action="store_true", help="print the checks of the configuration and exit")
    parser.add_argument("--verbose", action="store_true", help="with --list, also print the regular expressions")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    if args.context_width < 10:
        parser.error("--context-width must be >= 10")
    config_path = args.config if args.config.is_absolute() else root / args.config
    if not config_path.is_file():
        print(f"error: wording check configuration not found: {config_path}", file=sys.stderr)
        return 2
    try:
        checks = load_checks(config_path, display_path(config_path, root))
        if args.list:
            print_checks(checks, args.verbose)
            return 0
        files = selected_files(root, args)
        documents = read_documents(root, files)
    except (ConfigError, DocumentError, OSError, UnicodeDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.level == "hard":
        checks = [check for check in checks if check.level == "hard"]
    findings = check_documents(checks, documents, args)
    hard = [item for item in findings if item.rule == "WORDING-HARD"]
    review = [item for item in findings if item.rule == "WORDING-REVIEW"]
    summary = {
        "files": len(files),
        "rule_files": sum(1 for document in documents if is_rule_file(document.path)),
        "checks": len(checks),
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
    print(f"扫描 {summary['files']} 个文件（规则文件 {summary['rule_files']} 个），检查项 {summary['checks']} 项；"
          f"[WORDING-HARD] 硬性 {summary['hard']} 处；{review_text}")
    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main())
