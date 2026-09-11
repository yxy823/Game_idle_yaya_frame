"""Shared validation of Feature and test evolution records.

Completed verification mappings are historical facts. Retirement changes the
active safety net through an explicit replacement chain; it does not rewrite
those mappings or act as evidence that a new Feature has passed its tests.
"""
# 共享合约计算：保留历史验证语义，通过明确替代关系维护当前安全网。
from __future__ import annotations

import re
from datetime import datetime
from pathlib import PurePosixPath
from typing import Any


CATALOG_SCHEMA_VERSION = 2
FEATURE_ID = re.compile(r"F\d{3}")
REVISION_ID = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.-]*")
COMMIT_ID = re.compile(r"[a-fA-F0-9]{7,64}")


class EvolutionError(ValueError):
    """An evolution record cannot establish an unambiguous migration chain."""


class EvolutionReferenceError(EvolutionError):
    """Cross-file state may be temporarily incomplete during an ordered edit."""


def _text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise EvolutionError(f"{label} must be a non-empty string")
    return value


def _strings(value: Any, label: str, *, nonempty: bool = False) -> list[str]:
    if not isinstance(value, list) or any(not isinstance(x, str) or not x.strip() for x in value):
        raise EvolutionError(f"{label} must be an array of non-empty strings")
    if len(set(value)) != len(value) or (nonempty and not value):
        raise EvolutionError(f"{label} must be unique{' and non-empty' if nonempty else ''}")
    return value


def _source(value: Any, label: str) -> dict[str, str]:
    if not isinstance(value, dict) or set(value) != {"path", "anchor_commit"}:
        raise EvolutionError(f"{label} requires exactly path and anchor_commit")
    path = _text(value["path"], f"{label}.path")
    filename = path.partition("#")[0]
    if (not filename or "\\" in path or ":" in filename or filename.startswith("/")
            or ".." in PurePosixPath(filename).parts):
        raise EvolutionError(f"{label}.path must be a repository-relative source path, optionally with #section")
    commit = _text(value["anchor_commit"], f"{label}.anchor_commit")
    if not COMMIT_ID.fullmatch(commit):
        raise EvolutionError(f"{label}.anchor_commit must be a Git commit identifier")
    return value


def _feature_ids(value: Any, label: str, entries: dict[str, dict], *, nonempty: bool = False) -> list[str]:
    ids = _strings(value, label, nonempty=nonempty)
    if any(not FEATURE_ID.fullmatch(fid) for fid in ids):
        raise EvolutionError(f"{label} references an invalid Feature ID")
    if any(fid not in entries for fid in ids):
        raise EvolutionReferenceError(f"{label} references a missing Feature")
    return ids


def _acyclic(graph: dict[str, set[str]], label: str) -> None:
    # Iterative traversal also handles long histories without Python recursion limits.
    visiting: set[str] = set()
    visited: set[str] = set()
    for start in graph:
        stack = [(start, False)]
        while stack:
            node, returning = stack.pop()
            if returning:
                visiting.discard(node)
                visited.add(node)
            elif node in visiting:
                raise EvolutionError(f"{label} cycle detected at {node}")
            elif node not in visited:
                visiting.add(node)
                stack.append((node, True))
                stack.extend((child, False) for child in sorted(graph.get(node, ()), reverse=True))


# 执行顺序由依赖图和当前状态决定，不能把 Feature 编号大小当作依赖顺序。
def eligible_features(entries: dict[str, dict]) -> list[str]:
    """ID is a stable tie-breaker, never a prerequisite ordering constraint."""
    return sorted(fid for fid, entry in entries.items()
                  if entry.get("status") == "pending"
                  and all(entries.get(dep, {}).get("status") == "done" for dep in entry.get("depends_on", [])))


def validate_revisions(data: Any, entries: dict[str, dict]) -> dict[str, dict]:
    if data is None:
        return {}
    if not isinstance(data, dict) or not isinstance(data.get("revision_log"), list):
        raise EvolutionError("feature-list-revisions must contain a revision_log array")
    version = data.get("schema_version")
    if type(version) is not int or version != 2:
        raise EvolutionError("feature-list-revisions schema_version must be 2")
    revisions: dict[str, dict] = {}
    graph: dict[str, set[str]] = {}
    latest_dependencies: dict[str, list[str]] = {}
    for index, revision in enumerate(data["revision_log"]):
        label = f"revision_log[{index}]"
        if not isinstance(revision, dict):
            raise EvolutionError(f"{label} must be an object")
        version = revision.get("schema_version")
        if type(version) is not int or version != 2:
            raise EvolutionError(f"{label}.schema_version must be 2")
        rid = _text(revision.get("revision_id"), f"{label}.revision_id")
        if not REVISION_ID.fullmatch(rid) or rid in revisions:
            raise EvolutionError(f"{label}.revision_id must be unique and use letters, digits, dot, dash or underscore")
        for field in ("anchor_commit", "synced_at_commit"):
            if not COMMIT_ID.fullmatch(_text(revision.get(field), f"{label}.{field}")):
                raise EvolutionError(f"{label}.{field} must be a Git commit identifier")
        try:
            datetime.fromisoformat(_text(revision.get("revised_at"), f"{label}.revised_at").replace("Z", "+00:00"))
        except ValueError as exc:
            raise EvolutionError(f"{label}.revised_at must be ISO 8601") from exc
        _text(revision.get("summary"), f"{label}.summary")
        migrations = revision.get("migrations")
        changes = revision.get("dependency_changes")
        if not isinstance(migrations, list) or not isinstance(changes, list):
            raise EvolutionError(f"{label} requires migrations and dependency_changes arrays")
        for pos, migration in enumerate(migrations):
            ml = f"{label}.migrations[{pos}]"
            if not isinstance(migration, dict) or set(migration) != {"kind", "from", "to", "reason", "source"}:
                raise EvolutionError(f"{ml} requires exactly kind/from/to/reason/source")
            before = _feature_ids(migration["from"], f"{ml}.from", entries)
            after = _feature_ids(migration["to"], f"{ml}.to", entries)
            _text(migration["reason"], f"{ml}.reason")
            source = _source(migration["source"], f"{ml}.source")
            if source["anchor_commit"] not in {revision["anchor_commit"], revision["synced_at_commit"]}:
                raise EvolutionError(f"{ml}.source must name this revision's before or after source commit")
            kind = migration["kind"]
            valid = {"add": not before and bool(after), "revise": len(before) == len(after) == 1,
                     "split": len(before) == 1 and len(after) >= 2,
                     "merge": len(before) >= 2 and len(after) == 1,
                     "retire": bool(before)}
            if not isinstance(kind, str) or kind not in valid or not valid[kind]:
                raise EvolutionError(f"{ml} has invalid kind/cardinality")
            if kind != "revise" and set(before) & set(after):
                raise EvolutionError(f"{ml} source and replacement IDs must be disjoint")
            if kind in {"split", "merge", "retire"}:
                if any(entries[fid].get("status") not in {"obsolete", "obsolete_done"} for fid in before):
                    raise EvolutionReferenceError(f"{ml} must retain superseded entries as obsolete or obsolete_done")
            for fid in before:
                graph.setdefault(fid, set()).update(target for target in after if target != fid)
        changed: set[str] = set()
        for change in changes:
            if not isinstance(change, dict) or set(change) != {"feature", "before", "after"}:
                raise EvolutionError(f"{label}.dependency_changes requires feature/before/after")
            fid = change["feature"]
            if not isinstance(fid, str) or fid not in entries or fid in changed:
                raise EvolutionError(f"{label}.dependency_changes feature must exist and be unique")
            before = _feature_ids(change["before"], f"{label}.dependencies.before", entries)
            after = _feature_ids(change["after"], f"{label}.dependencies.after", entries)
            if fid in before or fid in after:
                raise EvolutionError(f"{label}.dependency_changes cannot introduce a self dependency")
            if fid in latest_dependencies and set(before) != set(latest_dependencies[fid]):
                raise EvolutionError(f"{label}.dependency_changes breaks the earlier before/after chain for {fid}")
            latest_dependencies[fid] = after
            changed.add(fid)
        revisions[rid] = revision
    for fid, after in latest_dependencies.items():
        if set(entries[fid].get("depends_on", [])) != set(after):
            raise EvolutionReferenceError(f"latest dependency_changes.after for {fid} differs from current depends_on")
    _acyclic(graph, "Feature migration")
    return revisions


def validate_retirement_shape(test: dict) -> None:
    retirement = test.get("retirement")
    label = f"test {test.get('id')} retirement"
    if test.get("status") != "retired":
        if retirement is not None:
            raise EvolutionError(f"{label} is only valid for status retired")
        return
    if not isinstance(retirement, dict) or set(retirement) != {"reason", "source", "replacement", "revision_id"}:
        raise EvolutionError(f"{label} requires exactly reason/source/replacement/revision_id")
    _text(retirement["reason"], f"{label}.reason")
    _source(retirement["source"], f"{label}.source")
    rid = _text(retirement["revision_id"], f"{label}.revision_id")
    if not REVISION_ID.fullmatch(rid):
        raise EvolutionError(f"{label}.revision_id is invalid")
    replacement = retirement["replacement"]
    if not isinstance(replacement, dict) or set(replacement) != {"feature_id", "test_ids"}:
        raise EvolutionError(f"{label}.replacement requires exactly feature_id/test_ids")
    fid = _text(replacement["feature_id"], f"{label}.replacement.feature_id")
    if not FEATURE_ID.fullmatch(fid):
        raise EvolutionError(f"{label}.replacement.feature_id is invalid")
    ids = _strings(replacement["test_ids"], f"{label}.replacement.test_ids", nonempty=True)
    if test.get("id") in ids:
        raise EvolutionError(f"{label} cannot replace itself")


def referenced_test_ids(detail: Any) -> set[str]:
    """Read the canonical mappings, without treating Catalog membership as coverage."""
    if not isinstance(detail, dict) or not isinstance(detail.get("acceptance_criteria"), list):
        raise EvolutionError("replacement Feature requires acceptance_criteria")
    verification = detail.get("verification")
    if not isinstance(verification, dict):
        raise EvolutionError("replacement Feature requires verification")
    result = set(_strings(verification.get("regression_tests"), "replacement Feature regression_tests"))
    for criterion in detail["acceptance_criteria"]:
        if not isinstance(criterion, dict) or not isinstance(criterion.get("verification"), dict):
            raise EvolutionError("replacement criterion requires verification")
        result.update(_strings(criterion["verification"].get("automated_tests"), "replacement criterion automated_tests"))
    return result


# 退役必须能追溯到理由、来源和替代；不自动把历史完成记录重新标成 pending。
def validate_retirements(tests: dict[str, dict], entries: dict[str, dict], revisions: dict[str, dict],
                         verification_ids: dict[str, set[str]]) -> None:
    graph: dict[str, set[str]] = {}
    for tid, test in tests.items():
        validate_retirement_shape(test)
        if test.get("status") != "retired":
            continue
        retirement = test["retirement"]
        replacement = retirement["replacement"]
        fid = replacement["feature_id"]
        revision = revisions.get(retirement["revision_id"])
        if fid not in entries or not revision:
            raise EvolutionReferenceError(f"retired test {tid} references missing replacement Feature or version-2 revision")
        if not any(retirement["source"] == migration["source"] and fid in migration["to"]
                   and (test.get("source_feature") is None or test["source_feature"] in migration["from"])
                   for migration in revision["migrations"]):
            raise EvolutionError(f"retired test {tid} source/replacement does not match its revision migration")
        for replacement_id in replacement["test_ids"]:
            target = tests.get(replacement_id)
            if not target or target.get("source_feature") != fid:
                raise EvolutionReferenceError(f"retired test {tid} replacement {replacement_id} is missing or belongs to another Feature")
            if replacement_id not in verification_ids.get(fid, set()):
                raise EvolutionReferenceError(f"retired test {tid} replacement {replacement_id} is not mapped in Feature {fid} verification")
            status = target.get("status")
            if status == "planned" and entries[fid].get("status") not in {"pending", "in_progress", "blocked"}:
                raise EvolutionError(f"retired test {tid} planned replacement cannot cover a completed/obsolete Feature")
            if status not in {"active", "planned", "retired"}:
                raise EvolutionError(f"retired test {tid} replacement has invalid status")
        graph[tid] = set(replacement["test_ids"])
    _acyclic(graph, "Test retirement")
