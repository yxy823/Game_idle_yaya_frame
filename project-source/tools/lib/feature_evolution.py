"""Shared validation of the Test Registry and Feature evolution records.

Completed verification mappings are historical facts. Retirement changes the
active safety net through an explicit replacement chain; it does not rewrite
those mappings or act as evidence that a new Feature has passed its tests.
"""
from __future__ import annotations

import re
from datetime import datetime
from pathlib import Path, PurePosixPath
from typing import Any

from tools.lib.feature_ids import FEATURE_ID as _FEATURE_ID


REGISTRY_SCHEMA_VERSION = 4
TEST_REGISTRY_PATH = PurePosixPath("docs/test-registry.json")
COMPONENT_ID = re.compile(r"[a-z][a-z0-9_]*")
FEATURE_ID = re.compile(_FEATURE_ID)
AC_TEST_ID = re.compile(rf"({_FEATURE_ID})-(AC\d{{2}})(?:-\d{{2}})?")
REGRESSION_TEST_ID = re.compile(rf"({_FEATURE_ID})-RT\d{{2}}")
INVARIANT_TEST_ID = re.compile(r"INV-[A-Z0-9][A-Z0-9_-]*-\d{2}")
REVISION_ID = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.-]*")
COMMIT_ID = re.compile(r"[a-fA-F0-9]{7,64}")


class EvolutionError(ValueError):
    """An evolution record cannot establish an unambiguous migration chain."""


def test_identity(test_id: Any) -> tuple[str, str | None, str | None]:
    """Derive kind, owning Feature and criterion from the stable logical ID."""
    if isinstance(test_id, str):
        if match := AC_TEST_ID.fullmatch(test_id):
            return "acceptance", match.group(1), match.group(2)
        if match := REGRESSION_TEST_ID.fullmatch(test_id):
            return "regression", match.group(1), None
        if INVARIANT_TEST_ID.fullmatch(test_id):
            return "invariant", None, None
    raise EvolutionError(f"invalid test ID {test_id!r}; expected <Feature ID>-ACyy[-NN], <Feature ID>-RTyy or INV-<DOMAIN>-NN")


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


def resolve_test_path(repo_root: Path, value: str) -> Path:
    """Keep test paths inside the repository; callers own existence requirements."""
    if not isinstance(value, str) or not value:
        raise EvolutionError("test path must be a non-empty repository-relative path")
    value = value.replace("\\", "/")
    path = PurePosixPath(value)
    if path.is_absolute() or ":" in value or ".." in path.parts:
        raise EvolutionError(f"test path leaves repository: {value}")
    resolved = (repo_root / value).resolve()
    if not resolved.is_relative_to(repo_root.resolve()):
        raise EvolutionError(f"test path resolves outside repository: {value}")
    return resolved


def validate_registry_component(component: Any, label: str, repo_root: Path) -> str:
    if not isinstance(component, dict):
        raise EvolutionError(f"{label} must be an object")
    component_id = component.get("id")
    if not isinstance(component_id, str) or not COMPONENT_ID.fullmatch(component_id):
        raise EvolutionError(f"{label}.id must be lower_snake_case")
    unit_paths = _strings(component.get("unit_test_paths"), f"{label}.unit_test_paths")
    for unit_path in unit_paths:
        path = resolve_test_path(repo_root, unit_path)
        if not (path.is_file() or path.is_dir()):
            raise EvolutionError(
                f"{label}.unit_test_paths references a missing unit suite: {unit_path}"
            )
    if not isinstance(component.get("full_suite_on_change"), bool):
        raise EvolutionError(f"{label}.full_suite_on_change must be boolean")
    for pattern in _strings(component.get("source_paths"), f"{label}.source_paths", nonempty=True):
        if "\\" in pattern or ":" in pattern or pattern.startswith("/") or ".." in PurePosixPath(pattern).parts:
            raise EvolutionError(f"{label}.source_paths must hold repository-relative globs: {pattern}")
    return component_id


def _validate_registry_test(test: Any, label: str, component_ids: set[str], repo_root: Path) -> str:
    if not isinstance(test, dict):
        raise EvolutionError(f"{label} must be an object")
    test_id = test.get("id")
    status = test.get("status")
    if status not in ("planned", "active", "retired"):
        raise EvolutionError(f"{label}.status is invalid")
    test_identity(test_id)
    validate_retirement_shape(test)
    mapped_components = _strings(
        test.get("components"), f"{label}.components", nonempty=True
    )
    missing = sorted(set(mapped_components) - component_ids)
    if missing:
        raise EvolutionError(
            f"{label}.components references missing components: {', '.join(missing)}"
        )
    path = test.get("path")
    if status in {"planned", "retired"}:
        if path is not None and (not isinstance(path, str) or not path.strip()):
            raise EvolutionError(f"{label}.path must be null or a non-empty string")
    elif not isinstance(path, str) or not path.strip():
        raise EvolutionError(f"{label}.path must be non-empty when status is {status}")
    if status == "active" and not resolve_test_path(repo_root, path).exists():
        raise EvolutionError(f"active test {test_id} path does not exist: {path}")
    case = test.get("case")
    if case is not None and (not isinstance(case, str) or not case.strip()):
        raise EvolutionError(f"{label}.case must be null or a non-empty string")

    return test_id


def validate_registry(data: Any, repo_root: Path) -> dict[str, Any]:
    if not isinstance(data, dict):
        raise EvolutionError("test registry root must be an object")
    meta = data.get("meta")
    if (not isinstance(meta, dict) or type(meta.get("schema_version")) is not int
            or meta["schema_version"] != REGISTRY_SCHEMA_VERSION):
        raise EvolutionError(f"test registry meta.schema_version must be integer {REGISTRY_SCHEMA_VERSION}")
    components = data.get("components")
    tests = data.get("tests")
    if not isinstance(components, list):
        raise EvolutionError("test registry components must be an array")
    if not isinstance(tests, list):
        raise EvolutionError("test registry tests must be an array")

    component_ids: set[str] = set()
    for index, component in enumerate(components):
        component_id = validate_registry_component(component, f"components[{index}]", repo_root)
        if component_id in component_ids:
            raise EvolutionError(f"duplicate component id: {component_id}")
        component_ids.add(component_id)

    test_ids: set[str] = set()
    for index, test in enumerate(tests):
        test_id = _validate_registry_test(test, f"tests[{index}]", component_ids, repo_root)
        if test_id in test_ids:
            raise EvolutionError(f"duplicate test id: {test_id}")
        test_ids.add(test_id)
    return data


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
        raise EvolutionError(f"{label} references a missing Feature")
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


def eligible_features(entries: dict[str, dict]) -> list[str]:
    """ID is a stable tie-breaker, never a prerequisite ordering constraint."""
    return sorted(fid for fid, entry in entries.items()
                  if entry.get("status") == "pending"
                  and all(entries.get(dep, {}).get("status") == "done" for dep in entry.get("depends_on", [])))


def _initial_baseline(revision: dict, label: str, entries: dict[str, dict], index: int) -> None:
    if index != 0:
        raise EvolutionError(f"{label}: R000 must be the first revision")
    if revision["anchor_commit"] != revision["synced_at_commit"]:
        raise EvolutionError(f"{label}: R000 anchor_commit and synced_at_commit must be equal")
    if "user_intent" not in revision or not (revision["user_intent"] is None or isinstance(revision["user_intent"], str)):
        raise EvolutionError(f"{label}.user_intent must be present as a string or null")
    _feature_ids(revision.get("added"), f"{label}.added", entries, nonempty=True)
    if revision["migrations"] or revision["dependency_changes"]:
        raise EvolutionError(f"{label} records the initial plan; migrations and dependency_changes must be empty")


def validate_revisions(data: Any, entries: dict[str, dict]) -> dict[str, dict]:
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
        if rid == "R000":
            _initial_baseline(revision, label, entries, index)
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
                    raise EvolutionError(f"{ml} must retain superseded entries as obsolete or obsolete_done")
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
            raise EvolutionError(f"latest dependency_changes.after for {fid} differs from current depends_on")
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
    """Read the canonical mappings, without treating Registry membership as coverage."""
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
            raise EvolutionError(f"retired test {tid} references missing replacement Feature or version-2 revision")
        _, source_feature, _ = test_identity(tid)
        if not any(retirement["source"] == migration["source"] and fid in migration["to"]
                   and (source_feature is None or source_feature in migration["from"])
                   for migration in revision["migrations"]):
            raise EvolutionError(f"retired test {tid} source/replacement does not match its revision migration")
        for replacement_id in replacement["test_ids"]:
            target = tests.get(replacement_id)
            if not target or test_identity(replacement_id)[1] != fid:
                raise EvolutionError(f"retired test {tid} replacement {replacement_id} is missing or belongs to another Feature")
            if replacement_id not in verification_ids.get(fid, set()):
                raise EvolutionError(f"retired test {tid} replacement {replacement_id} is not mapped in Feature {fid} verification")
            status = target.get("status")
            if status == "planned" and entries[fid].get("status") not in {"pending", "in_progress", "blocked"}:
                raise EvolutionError(f"retired test {tid} planned replacement cannot cover a completed/obsolete Feature")
            if status not in {"active", "planned", "retired"}:
                raise EvolutionError(f"retired test {tid} replacement has invalid status")
        graph[tid] = set(replacement["test_ids"])
    _acyclic(graph, "Test retirement")
