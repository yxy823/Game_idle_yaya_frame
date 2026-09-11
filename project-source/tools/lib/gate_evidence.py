#!/usr/bin/env python3
"""Create and validate structured Feature completion evidence."""
# 完成结论读取当前工作区与真实运行引用；这里不启动测试，也不获得人工接受。
from __future__ import annotations

import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 6
EVIDENCE_RELATIVE_PATH = Path("docs/gate-evidence.json")
EXCLUDED_EXACT_PATHS = {
    "docs/gate-evidence.json",
    "docs/progress.md",
}
FULL_SUITE_PASS_STATES = {"pass", "not_required"}
PROCESS_FIELDS = {"notes", "status", "completed_at", "created_at", "updated_at", "recorded_at"}


class EvidenceError(RuntimeError):
    """Raised when repository evidence cannot be created or trusted."""


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def _run_git(repo_root: Path, *args: str, expected_exit: int = 0) -> bytes:
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_root), *args],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except OSError as exc:
        raise EvidenceError(f"cannot execute git: {exc}") from exc
    if result.returncode != expected_exit:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise EvidenceError(f"git {' '.join(args)} failed (exit {result.returncode}, expected {expected_exit}): {detail or 'unexpected result'}")
    return result.stdout


def git_revision(repo_root: Path) -> str:
    """Record real commit provenance or a verified unborn working repository."""
    if _run_git(repo_root, "rev-parse", "--is-inside-work-tree").strip() != b"true":
        raise EvidenceError("snapshot requires a Git working repository")
    try:
        revision = _run_git(repo_root, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii", errors="strict").strip()
    except EvidenceError as head_error:
        # A missing initial commit is valid; a malformed HEAD, broken ref or
        # absent commit object is not. Only an absent branch ref proves unborn.
        try:
            branch = _run_git(repo_root, "symbolic-ref", "--quiet", "HEAD").decode("utf-8").strip()
            if not branch.startswith("refs/heads/"):
                raise EvidenceError("unborn HEAD must name a branch")
            _run_git(repo_root, "check-ref-format", branch)
            _run_git(repo_root, "show-ref", "--verify", "--quiet", branch, expected_exit=1)
        except EvidenceError:
            raise head_error
        return "UNBORN"
    if not revision:
        raise EvidenceError("git rev-parse HEAD^{commit} returned an empty revision")
    return revision


def _is_fingerprint_input(relative_path: str) -> bool:
    normalized = relative_path.replace("\\", "/").lstrip("./")
    if normalized in EXCLUDED_EXACT_PATHS:
        return False
    if normalized.startswith("reports/"):
        return False
    return not (normalized.startswith("docs/progress/") and normalized.endswith(".md"))


# 只排除明确的流程记账字段；嵌套 AC、verification 和测试状态仍属于验证合约。
def semantic_json(relative_path: str, data: Any) -> Any:
    """Project workflow state is not verification semantics; nested contracts are.

    Deliberately do not recursively drop fields: a Catalog test's status or an
    acceptance criterion's text/verification is part of the active contract.
    Unknown contract fields remain hashed rather than silently becoming exempt.
    """
    if not isinstance(data, dict):
        return data
    if relative_path.startswith("docs/features/"):
        return {key: value for key, value in data.items() if key not in PROCESS_FIELDS}
    result = dict(data)
    if relative_path == "docs/feature-list.json":
        result["features"] = [
            {key: value for key, value in feature.items() if key not in PROCESS_FIELDS}
            for feature in result.get("features", [])
        ]
    if relative_path in {"docs/feature-list.json", "docs/test-catalog.json"}:
        result["meta"] = {key: value for key, value in data.get("meta", {}).items()
                          if key not in PROCESS_FIELDS and not key.endswith("_at")}
    if relative_path == "docs/feature-list-revisions.json":
        # Migration edges, revision IDs and source anchors remain authoritative.
        # Editing an entry's prose or workflow timestamps is only bookkeeping.
        result["revision_log"] = [
            {key: value for key, value in entry.items()
             if key not in {"revised_at", "created_at", "updated_at", "recorded_at", "summary", "notes"}}
            for entry in data.get("revision_log", [])
        ]
    if relative_path == "docs/methodology-config.json" and isinstance(result.get("environment_bootstrap"), dict):
        result["environment_bootstrap"] = {key: value for key, value in result["environment_bootstrap"].items()
                                           if key not in PROCESS_FIELDS and not key.endswith("_at")}
    return result


def _hash_file(digest: Any, path: Path) -> None:
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)


# 基于 Git 列出的当前字节和规范化合约，不靠文件修改时间先后判断源码是否相同。
def working_tree_fingerprint(repo_root: Path) -> str:
    """Hash tracked and non-ignored untracked content for the current code snapshot.

    Feature/Catalog verification semantics are canonical JSON inputs. Only known
    process fields, evidence outputs and Progress Markdown are exempt. A Git
    commit is provenance, not an additional invalidation of identical content.
    """

    raw_paths = _run_git(repo_root, "ls-files", "--cached", "--others", "--exclude-standard", "-z")
    paths = sorted({path for path in raw_paths.decode("utf-8", errors="surrogateescape").split("\0") if path})
    digest = hashlib.sha256()
    digest.update(b"yaya-working-tree-v2\0")
    resolved_root = repo_root.resolve()

    for relative_path in paths:
        normalized = relative_path.replace("\\", "/")
        if not _is_fingerprint_input(normalized):
            continue
        candidate = (resolved_root / Path(normalized)).resolve(strict=False)
        try:
            candidate.relative_to(resolved_root)
        except ValueError as exc:
            raise EvidenceError(f"git reported a path outside the repository: {relative_path}") from exc

        digest.update(normalized.encode("utf-8", errors="surrogateescape"))
        digest.update(b"\0")
        if candidate.is_file():
            digest.update(b"file\0")
            if normalized.startswith("docs/features/") and normalized.endswith(".json") or normalized in {
                "docs/feature-list.json", "docs/test-catalog.json", "docs/methodology-config.json",
                "docs/feature-list-revisions.json",
            }:
                try:
                    projected = semantic_json(normalized, json.loads(candidate.read_text(encoding="utf-8")))
                except (OSError, ValueError, TypeError) as exc:
                    raise EvidenceError(f"cannot fingerprint workflow contract {normalized}: {exc}") from exc
                digest.update(json.dumps(projected, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode("utf-8"))
            else:
                _hash_file(digest, candidate)
        elif candidate.exists():
            digest.update(b"non-file\0")
        else:
            digest.update(b"missing\0")
        digest.update(b"\0")

    return f"sha256:{digest.hexdigest()}"


def current_snapshot(repo_root: Path) -> dict[str, str]:
    return {
        "git_revision": git_revision(repo_root),
        "working_tree_fingerprint": working_tree_fingerprint(repo_root),
    }


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
        "code_smell": {
            "status": "not_run",
            "must_fix": None,
            "suggest": None,
            "acceptable": None,
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
    return data


def write_evidence(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    try:
        with temporary.open("w", encoding="utf-8", newline="\n") as stream:
            stream.write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def evidence_for_snapshot(path: Path, feature_id: str, snapshot: dict[str, str]) -> dict[str, Any]:
    try:
        current = load_evidence(path)
    except EvidenceError:
        return empty_evidence(feature_id, snapshot)
    if current.get("schema_version") != SCHEMA_VERSION or current.get("feature_id") != feature_id:
        return empty_evidence(feature_id, snapshot)
    current["git_revision"] = snapshot["git_revision"]
    current["working_tree_fingerprint"] = snapshot["working_tree_fingerprint"]
    return current


def _matches_snapshot(result: Any, data: dict[str, Any]) -> bool:
    return (
        isinstance(result, dict)
        and result.get("working_tree_fingerprint") == data.get("working_tree_fingerprint")
    )


def _is_non_negative_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def _passing_test_result(result: Any, data: dict[str, Any]) -> bool:
    return (
        isinstance(result, dict)
        and result.get("status") == "pass"
        and _is_non_negative_int(result.get("total"))
        and result.get("failed") == 0
        and bool(result.get("run_ids"))
        and _matches_snapshot(result, data)
    )


# 检查测试、适用的人工接受和复审；静态检查由 Agent 直接执行并单独核对。
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

    if data.get("schema_version") != SCHEMA_VERSION:
        return False, f"unsupported gate evidence schema_version: {data.get('schema_version')!r}"
    if data.get("feature_id") != feature_id:
        return False, f"gate evidence belongs to {data.get('feature_id')!r}, not {feature_id}"
    if data.get("working_tree_fingerprint") != snapshot["working_tree_fingerprint"]:
        return False, "working tree changed after verification"
    try:
        from tools.lib.execution_attempts import journal_path, read_journal
        attempts_before = read_journal(journal_path(repo_root))
    except (ValueError, OSError, TypeError, KeyError) as exc:
        return False, f"test attempt history is invalid: {exc}"
    try:
        from tools.lib.run_evidence import derive_test_evidence
        from tools.lib.test_selection import acceptance_mode, read_json
        mode = acceptance_mode(read_json(repo_root / f"docs/features/{feature_id}.json"))
        verified = derive_test_evidence(repo_root, feature_id, data.get("test_runs"))
    except (ValueError, OSError, TypeError, KeyError) as exc:
        return False, f"test run evidence is invalid: {exc}"
    required = verified["required_test_set"]
    affected = verified["affected_tests"]
    full_suite = verified["full_suite"]
    acceptance = data.get("human_acceptance")
    smell = data.get("code_smell")
    if not _passing_test_result(required, data):
        return False, "Required Test Set has not passed"
    if not _passing_test_result(affected, data):
        return False, "affected tests have not passed"
    if not isinstance(full_suite, dict) or full_suite.get("status") not in FULL_SUITE_PASS_STATES:
        return False, "full-suite result is neither pass nor not_required"
    if not _matches_snapshot(full_suite, data):
        return False, "full-suite decision does not match the current code snapshot"
    # 验收方式是 Stage 1 的需求判断；这里不从空清单或测试通过反推该决定。
    if mode == "manual":
        if not isinstance(acceptance, dict) or acceptance.get("status") != "accepted":
            return False, "explicit human acceptance is not recorded"
        if not _matches_snapshot(acceptance, data):
            return False, "human acceptance does not match the current code snapshot"
    if (
        not isinstance(smell, dict)
        or smell.get("status") != "pass"
        or smell.get("must_fix") != 0
        or not _is_non_negative_int(smell.get("suggest"))
        or not _is_non_negative_int(smell.get("acceptable"))
    ):
        return False, "code-smell review has unresolved MUST-FIX findings"
    if not _matches_snapshot(smell, data):
        return False, "code-smell evidence does not match the current code snapshot"
    if not isinstance(data.get("recorded_at"), str) or not data["recorded_at"]:
        return False, "gate evidence has no execution timestamp"
    try:
        if attempts_before != read_journal(journal_path(repo_root)):
            return False, "verification attempt changed during completion validation"
        if current_snapshot(repo_root)["working_tree_fingerprint"] != snapshot["working_tree_fingerprint"]:
            return False, "source changed during completion validation"
    except (EvidenceError, ValueError, OSError) as error:
        return False, str(error)
    return True, "test/acceptance/review evidence matches the current snapshot; direct static checks are assessed separately"
