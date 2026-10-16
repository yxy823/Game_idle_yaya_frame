"""Create and validate structured Feature completion evidence."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from tools.lib.verification_snapshot import EvidenceError, current_snapshot

SCHEMA_VERSION = 9


def evidence_relative_path(feature_id: str) -> Path:
    """Each Feature keeps its own record next to its detail and design files."""
    return Path(f"docs/features/{feature_id}-evidence.json")


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


def load_evidence(path: Path, feature_id: str) -> dict[str, Any]:
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
    if data["feature_id"] != feature_id:
        raise EvidenceError(f"gate evidence belongs to {data['feature_id']!r}, not {feature_id}")
    if not isinstance(data.get("test_runs"), list) or not isinstance(data.get("human_acceptance"), dict):
        raise EvidenceError("gate evidence requires test_runs and human_acceptance")
    return data


def evidence_for_snapshot(repo_root: Path, feature_id: str, snapshot: dict[str, str]) -> dict[str, Any]:
    path = repo_root / evidence_relative_path(feature_id)
    try:
        current = load_evidence(path, feature_id)
    except EvidenceError as exc:
        if isinstance(exc.__cause__, FileNotFoundError):
            return empty_evidence(feature_id, snapshot)
        raise
    current["git_revision"] = snapshot["git_revision"]
    current["working_tree_fingerprint"] = snapshot["working_tree_fingerprint"]
    return current


def _manual_acceptance_problem(repo_root: Path, feature_id: str, acceptance: Any,
                               snapshot: dict[str, str]) -> str | None:
    if not isinstance(acceptance, dict) or acceptance.get("status") != "accepted":
        return "explicit human acceptance is not recorded"
    if acceptance.get("working_tree_fingerprint") != snapshot["working_tree_fingerprint"]:
        return "human acceptance does not match the current code snapshot"
    try:
        from tools.lib.manual_acceptance import read_checklist
        source = acceptance.get("source")
        if not isinstance(source, dict) or set(source) != {"checklist"} or not isinstance(source["checklist"], str):
            raise EvidenceError("manual acceptance source requires the checklist path")
        decision = read_checklist(repo_root, feature_id, Path(source["checklist"]), snapshot,
                                  confirm_unrelated_changes=True)
        if decision["status"] != "accepted":
            raise EvidenceError("manual checklist is no longer fully passed")
        if decision.get("bound_fingerprint") != acceptance.get("bound_fingerprint"):
            raise EvidenceError("manual checklist binding changed after acceptance was recorded")
    except (EvidenceError, ValueError, OSError, KeyError, TypeError) as exc:
        return f"manual acceptance evidence is invalid: {exc}"
    return None


def validate_completion_evidence(repo_root: Path, feature_id: str) -> tuple[bool, str]:
    try:
        data = load_evidence(repo_root / evidence_relative_path(feature_id), feature_id)
        snapshot = current_snapshot(repo_root)
    except EvidenceError as exc:
        return False, str(exc)

    if data.get("working_tree_fingerprint") != snapshot["working_tree_fingerprint"]:
        return False, "working tree changed after verification"
    try:
        from tools.lib.test_run_evidence import derive_test_evidence
        from tools.lib.test_selection import acceptance_mode, read_json
        mode = acceptance_mode(read_json(repo_root / f"docs/features/{feature_id}.json"))
        derive_test_evidence(repo_root, feature_id, data.get("test_runs"))
    except (ValueError, OSError, TypeError, KeyError) as exc:
        return False, f"test run evidence is invalid: {exc}"
    if mode == "manual":
        problem = _manual_acceptance_problem(repo_root, feature_id, data.get("human_acceptance"), snapshot)
        if problem:
            return False, problem
    if not isinstance(data.get("recorded_at"), str) or not data["recorded_at"]:
        return False, "gate evidence has no execution timestamp"
    try:
        if current_snapshot(repo_root)["working_tree_fingerprint"] != snapshot["working_tree_fingerprint"]:
            return False, "source changed during completion validation"
    except (EvidenceError, ValueError, OSError) as error:
        return False, str(error)
    return True, "test/acceptance evidence matches the current snapshot; direct static checks and requested review conditions are assessed separately"
