#!/usr/bin/env python3
"""Record auditable Feature completion evidence for the current Git snapshot."""
# 显式记录入口保存真实报告引用与人工决定；通过状态由验证器重新计算。
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable

# 脚本在子目录直接启动时，显式加载本项目的共享包。
sys.path.insert(0, str(Path(__file__).resolve().parents[4]))

from tools.lib.feature_completion_evidence import (
    EVIDENCE_RELATIVE_PATH,
    EvidenceError,
    current_snapshot,
    evidence_for_snapshot,
    load_evidence,
    utc_now,
    validate_completion_evidence,
    write_evidence,
)

DEFAULT_REPO_ROOT = Path(__file__).resolve().parents[4]
FEATURE_ID_RE = re.compile(r"F\d{3}")


def _feature_id(value: str) -> str:
    normalized = value.upper()
    if not FEATURE_ID_RE.fullmatch(normalized):
        raise argparse.ArgumentTypeError("Feature ID must match F0XX")
    return normalized


def _result_snapshot(snapshot: dict[str, str]) -> dict[str, str]:
    return {
        "git_revision": snapshot["git_revision"],
        "working_tree_fingerprint": snapshot["working_tree_fingerprint"],
    }


def _load_for_write(repo_root: Path, feature_id: str) -> tuple[Path, dict[str, Any], dict[str, str]]:
    snapshot = current_snapshot(repo_root)
    path = repo_root / EVIDENCE_RELATIVE_PATH
    data = evidence_for_snapshot(path, feature_id, snapshot)
    return path, data, snapshot


def _save(path: Path, data: dict[str, Any]) -> None:
    data["recorded_at"] = utc_now()
    write_evidence(path, data)


# 只导入实际测试结果；脚本解析与 lint 由 Agent 直接执行、阅读原始输出。
def _record_tests(repo_root: Path, args: argparse.Namespace) -> int:
    from tools.lib.test_run_evidence import derive_test_evidence, result_reference

    path, data, _snapshot = _load_for_write(repo_root, args.feature)
    data["test_runs"] = []
    try:
        references = [result_reference(repo_root, (repo_root / run).resolve()) for run in args.run]
        derive_test_evidence(repo_root, args.feature, references)
        data["test_runs"] = references
    except (EvidenceError, ValueError, OSError, KeyError, TypeError) as exc:
        # 失败时清除旧引用，原始测试报告仍保留。
        _save(path, data)
        raise ValueError(f"test evidence rejected: {exc}") from exc
    _save(path, data)
    return 0


# 接受来源由明确人工决定提供；测试通过或 Agent 总结不能自行变成人工接受。
def _record_acceptance(repo_root: Path, args: argparse.Namespace) -> int:
    from tools.lib.manual_acceptance import read_result

    path, data, snapshot = _load_for_write(repo_root, args.feature)
    if args.result:
        decision = read_result(repo_root, args.feature, args.checklist, args.result, snapshot)
    else:
        decision = {"status": args.status, **_result_snapshot(snapshot)}
    data["human_acceptance"] = {**decision, "recorded_at": utc_now()}
    _save(path, data)
    print(f"Human acceptance recorded: {decision['status']}; this is not Feature completion.")
    return 0


def _validate(repo_root: Path, feature_id: str) -> int:
    valid, message = validate_completion_evidence(repo_root, feature_id)
    print(f"Structured completion evidence: {'PASS' if valid else 'NOT READY'} - {message}")
    return 0 if valid else 2


def _show(repo_root: Path, feature_id: str) -> int:
    path = repo_root / EVIDENCE_RELATIVE_PATH
    data = load_evidence(path)
    print(json.dumps(data, indent=2, ensure_ascii=False))
    valid, message = validate_completion_evidence(repo_root, feature_id, evidence_path=path)
    print(f"Current completion gate: {'PASS' if valid else 'NOT READY'} - {message}", file=sys.stderr)
    return 0 if valid else 2


def _parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=DEFAULT_REPO_ROOT)
    subparsers = parser.add_subparsers(dest="command", required=True)

    prepare = subparsers.add_parser("prepare-manual")
    prepare.add_argument("--feature", required=True, type=_feature_id)
    prepare.add_argument("--checklist", required=True, type=Path,
                         help="Agent-authored pending checklist under reports/manual-acceptance.")

    tests = subparsers.add_parser("record-tests")
    tests.add_argument("--feature", required=True, type=_feature_id)
    tests.add_argument("--run", required=True, action="append", type=Path,
                       help="Real wrapper result; repeat for multiple non-overlapping runs.")

    acceptance = subparsers.add_parser("record-acceptance")
    acceptance.add_argument("--feature", required=True, type=_feature_id)
    decision = acceptance.add_mutually_exclusive_group(required=True)
    decision.add_argument("--status", choices=("accepted", "rejected"), help="Explicit conversational decision.")
    decision.add_argument("--result", type=Path, help="User-submitted manual result JSON.")
    acceptance.add_argument("--checklist", type=Path, help="Unchanged original checklist for --result.")

    show = subparsers.add_parser("show")
    show.add_argument("--feature", required=True, type=_feature_id)

    validate = subparsers.add_parser("validate")
    validate.add_argument("--feature", required=True, type=_feature_id)
    args = parser.parse_args(list(argv))
    if args.command == "record-acceptance" and bool(args.result) != bool(args.checklist):
        parser.error("--result and --checklist must be supplied together; --status cannot use --checklist")
    return args


def main() -> int:
    args = _parse_args(sys.argv[1:])
    repo_root = args.repo_root.resolve()
    try:
        if args.command == "prepare-manual":
            from tools.lib.manual_acceptance import prepare_checklist
            path = prepare_checklist(repo_root, args.feature, args.checklist)
            print(f"Manual checklist prepared: {path}")
            return 0
        if args.command == "record-tests":
            return _record_tests(repo_root, args)
        if args.command == "record-acceptance":
            return _record_acceptance(repo_root, args)
        if args.command == "validate":
            return _validate(repo_root, args.feature)
        return _show(repo_root, args.feature)
    except (EvidenceError, OSError, ValueError, KeyError, TypeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
