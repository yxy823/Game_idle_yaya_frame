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
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.feature_completion_evidence import (
    evidence_for_snapshot,
    evidence_relative_path,
    load_evidence,
    validate_completion_evidence,
)
from tools.lib.atomic_json import write_json
from tools.lib.verification_snapshot import EvidenceError, current_snapshot, utc_now

DEFAULT_REPO_ROOT = Path(__file__).resolve().parents[3]
FEATURE_ID_RE = re.compile(r"F\d{3}")


def _feature_id(value: str) -> str:
    normalized = value.upper()
    if not FEATURE_ID_RE.fullmatch(normalized):
        raise argparse.ArgumentTypeError("Feature ID must match F0XX")
    return normalized


def _load_for_write(repo_root: Path, feature_id: str) -> tuple[Path, dict[str, Any], dict[str, str]]:
    snapshot = current_snapshot(repo_root)
    path = repo_root / evidence_relative_path(feature_id)
    data = evidence_for_snapshot(repo_root, feature_id, snapshot)
    return path, data, snapshot


def _save(path: Path, data: dict[str, Any]) -> None:
    data["recorded_at"] = utc_now()
    write_json(path, data)


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


# 接受来源是清单中按用户实际决定填写的状态；测试通过或 Agent 总结不能自行变成人工接受。
def _record_acceptance(repo_root: Path, args: argparse.Namespace) -> int:
    from tools.lib.manual_acceptance import read_checklist

    path, data, snapshot = _load_for_write(repo_root, args.feature)
    decision = read_checklist(repo_root, args.feature, args.checklist, snapshot,
                              confirm_unrelated_changes=args.confirm_unrelated_changes)
    previous = data.get("human_acceptance") or {}
    if all(previous.get(key) == decision.get(key) for key in ("status", "working_tree_fingerprint", "source")):
        print("NOTE: the same acceptance decision is already recorded for this snapshot.", file=sys.stderr)
    data["human_acceptance"] = {**decision, "recorded_at": utc_now()}
    _save(path, data)
    print(f"Human acceptance recorded: {decision['status']}; this is not Feature completion.")
    return 0


def _validate(repo_root: Path, feature_id: str) -> int:
    valid, message = validate_completion_evidence(repo_root, feature_id)
    print(f"Structured completion evidence: {'PASS' if valid else 'NOT READY'} - {message}")
    return 0 if valid else 2


def _show(repo_root: Path, feature_id: str) -> int:
    data = load_evidence(repo_root / evidence_relative_path(feature_id), feature_id)
    print(json.dumps(data, indent=2, ensure_ascii=False))
    return 0


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
    acceptance.add_argument("--checklist", required=True, type=Path,
                            help="Bound checklist whose status fields hold the user's actual decision.")
    acceptance.add_argument("--confirm-unrelated-changes", action="store_true",
                            help="Content changed after binding and none of the listed files affects this Feature.")

    show = subparsers.add_parser("show", help="Read the matching record; does not validate completion.")
    show.add_argument("--feature", required=True, type=_feature_id)

    validate = subparsers.add_parser("validate", help="Validate current test and acceptance evidence.")
    validate.add_argument("--feature", required=True, type=_feature_id)
    return parser.parse_args(list(argv))


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
