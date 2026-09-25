#!/usr/bin/env python3
"""Create and validate structured Feature completion evidence."""
# 完成结论读取当前工作区与真实运行引用；这里不启动测试，也不获得人工接受。
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from tools.lib.verification_snapshot import EvidenceError, current_snapshot

SCHEMA_VERSION = 8
EVIDENCE_RELATIVE_PATH = Path("docs/feature-completion-evidence.json")


def empty_evidence(feature_id: str | None = None, snapshot: dict[str, str] | None = None) -> dict[str, Any]:
    snapshot = snapshot or {"git_revision": None, "working_tree_fingerprint": None}
    result_snapshot = {
        "git_revision": None,
        "working_tree_fingerprint": None,
    }
    return {
        "schema_version": SCHEMA_VERSION,
        "feature_id": feature_id,
        "recorded_at": None,
        "git_revision": snapshot.get("git_revision"),
        "working_tree_fingerprint": snapshot.get("working_tree_fingerprint"),
        "test_runs": [],
        "human_acceptance": {
            "status": "pending",
            "recorded_at": None,
            **result_snapshot,
        },
    }


def load_evidence(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise EvidenceError(f"structured gate evidence is missing: {path}") from exc
    except (OSError, json.JSONDecodeError) as exc:
        raise EvidenceError(f"cannot read structured gate evidence {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise EvidenceError("structured gate evidence root must be an object")
    if data.get("schema_version") != SCHEMA_VERSION:
        raise EvidenceError(f"unsupported gate evidence schema_version: {data.get('schema_version')!r}")
    if not isinstance(data.get("feature_id"), str) or not re.fullmatch(r"F\d{3}", data["feature_id"]):
        raise EvidenceError("gate evidence feature_id must match F0XX")
    if not isinstance(data.get("test_runs"), list) or not isinstance(data.get("human_acceptance"), dict):
        raise EvidenceError("gate evidence requires test_runs and human_acceptance")
    return data


def evidence_for_snapshot(path: Path, feature_id: str, snapshot: dict[str, str]) -> dict[str, Any]:
    try:
        current = load_evidence(path)
    except EvidenceError as exc:
        if isinstance(exc.__cause__, FileNotFoundError):
            return empty_evidence(feature_id, snapshot)
        raise
    if current["feature_id"] != feature_id:
        return empty_evidence(feature_id, snapshot)
    current["git_revision"] = snapshot["git_revision"]
    current["working_tree_fingerprint"] = snapshot["working_tree_fingerprint"]
    return current


def _matches_snapshot(result: Any, data: dict[str, Any]) -> bool:
    return (
        isinstance(result, dict)
        and result.get("working_tree_fingerprint") == data.get("working_tree_fingerprint")
    )


# 检查测试与适用的人工接受；静态检查和用户指定的评审条件由 Agent 单独核对。
def validate_completion_evidence(
    repo_root: Path,
    feature_id: str,
    evidence_path: Path | None = None,
) -> tuple[bool, str]:
    evidence_path = evidence_path or repo_root / EVIDENCE_RELATIVE_PATH
    try:
        data = load_evidence(evidence_path)
        snapshot = current_snapshot(repo_root)
    except EvidenceError as exc:
        return False, str(exc)

    if data.get("feature_id") != feature_id:
        return False, f"gate evidence belongs to {data.get('feature_id')!r}, not {feature_id}"
    if data.get("working_tree_fingerprint") != snapshot["working_tree_fingerprint"]:
        return False, "working tree changed after verification"
    try:
        from tools.lib.test_run_evidence import derive_test_evidence
        from tools.lib.test_selection import acceptance_mode, read_json
        mode = acceptance_mode(read_json(repo_root / f"docs/features/{feature_id}.json"))
        derive_test_evidence(repo_root, feature_id, data.get("test_runs"))
    except (ValueError, OSError, TypeError, KeyError) as exc:
        return False, f"test run evidence is invalid: {exc}"
    acceptance = data.get("human_acceptance")
    # 验收方式是 Stage 1 的需求判断；这里不从空清单或测试通过反推该决定。
    if mode == "manual":
        if not isinstance(acceptance, dict) or acceptance.get("status") != "accepted":
            return False, "explicit human acceptance is not recorded"
        if not _matches_snapshot(acceptance, data):
            return False, "human acceptance does not match the current code snapshot"
        if "source" in acceptance:
            # 文件结果保留原件，完成时重读；口头决定不虚构文件来源。
            try:
                from tools.lib.manual_acceptance import read_result
                source = acceptance["source"]
                if not isinstance(source, dict) or set(source) != {"checklist", "result"}:
                    raise EvidenceError("manual source requires checklist and result paths")
                if any(not isinstance(value, str) or not value for value in source.values()):
                    raise EvidenceError("manual source paths must be nonempty strings")
                decision = read_result(repo_root, feature_id, Path(source["checklist"]), Path(source["result"]), snapshot)
                if decision["status"] != "accepted":
                    raise EvidenceError("manual result is no longer fully passed")
            except (EvidenceError, ValueError, OSError, KeyError, TypeError) as exc:
                return False, f"manual result evidence is invalid: {exc}"
    if not isinstance(data.get("recorded_at"), str) or not data["recorded_at"]:
        return False, "gate evidence has no execution timestamp"
    try:
        if current_snapshot(repo_root)["working_tree_fingerprint"] != snapshot["working_tree_fingerprint"]:
            return False, "source changed during completion validation"
    except (EvidenceError, ValueError, OSError) as error:
        return False, str(error)
    return True, "test/acceptance evidence matches the current snapshot; direct static checks and requested review conditions are assessed separately"
