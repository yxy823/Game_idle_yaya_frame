"""Tool-neutral manual checklist preparation and result validation."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from tools.lib.atomic_json import write_json
from tools.lib.verification_snapshot import EvidenceError, changed_paths_since, current_snapshot
from tools.lib.test_selection import acceptance_mode


REPORT_DIRECTORY = Path("reports/manual-acceptance")
DEFINITION_FIELDS = ("id", "source_ref", "title", "preconditions", "steps", "expected_result")


def _text(value: Any, label: str, *, empty: bool = False) -> str:
    if not isinstance(value, str) or (not empty and not value.strip()):
        raise EvidenceError(f"{label} must be a {'string' if empty else 'nonempty string'}")
    return value


def _strings(value: Any, label: str, *, nonempty: bool = False) -> list[str]:
    if not isinstance(value, list) or (nonempty and not value):
        raise EvidenceError(f"{label} must be a {'nonempty ' if nonempty else ''}string array")
    for item in value:
        _text(item, label)
    return value


def _read(path: Path) -> dict[str, Any]:
    def invalid_constant(value):
        raise EvidenceError(f"invalid JSON number: {value}")

    def unique_object(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise EvidenceError(f"duplicate JSON field: {key}")
            result[key] = value
        return result

    try:
        value = json.loads(path.read_text(encoding="utf-8-sig"), object_pairs_hook=unique_object,
                           parse_constant=invalid_constant)
    except (OSError, ValueError) as error:
        raise EvidenceError(f"cannot read manual acceptance file {path}: {error}") from error
    if not isinstance(value, dict):
        raise EvidenceError("manual acceptance document must be an object")
    return value


def report_path(root: Path, path: Path) -> Path:
    """Keep referenced originals in the project's existing report boundary."""
    resolved = (root / path).resolve()
    if (not resolved.is_relative_to(root.resolve())
            or not resolved.is_relative_to((root / REPORT_DIRECTORY).resolve())
            or resolved.suffix.lower() != ".json"):
        raise EvidenceError(f"manual acceptance files must be JSON under {REPORT_DIRECTORY.as_posix()}")
    return resolved


def _obligations(root: Path, feature: str) -> set[str]:
    detail = _read(root / f"docs/features/{feature}.json")
    if detail.get("id") != feature or acceptance_mode(detail) != "manual":
        raise EvidenceError("manual acceptance requires the matching manual Feature")
    refs = {f"{criterion['id']}/{index}"
            for criterion in detail["acceptance_criteria"]
            for index, _ in enumerate(criterion["verification"].get("manual_checks", []), 1)}
    if detail["verification"].get("manual_regression"):
        refs.add("manual_regression")
    return refs


def _document(data: dict[str, Any], feature: str, obligations: set[str]) -> dict[str, dict]:
    if type(data.get("schema_version")) is not int or data["schema_version"] != 1:
        raise EvidenceError("manual acceptance schema_version must be 1")
    if data.get("feature_id") != feature:
        raise EvidenceError("manual acceptance file belongs to another Feature")
    for field in ("title", "description"):
        _text(data.get(field, ""), field, empty=True)
    tests = data.get("tests")
    if not isinstance(tests, list) or not tests:
        raise EvidenceError("manual acceptance requires a nonempty tests array")
    by_id, covered = {}, set()
    for test in tests:
        if not isinstance(test, dict):
            raise EvidenceError("each manual test must be an object")
        for field in ("id", "source_ref", "title", "expected_result"):
            _text(test.get(field), field)
        if test["id"] in by_id:
            raise EvidenceError(f"duplicate manual test ID: {test['id']}")
        if test["source_ref"] not in obligations:
            raise EvidenceError(f"unknown manual obligation: {test['source_ref']}")
        _strings(test.get("preconditions", []), "preconditions")
        _strings(test.get("steps"), "steps", nonempty=True)
        if test.get("status", "pending") not in ("pending", "passed", "failed"):
            raise EvidenceError("manual status must be pending, passed or failed")
        _text(test.get("comment", ""), "comment", empty=True)
        covered.add(test["source_ref"])
        by_id[test["id"]] = {**test, "preconditions": test.get("preconditions", []),
                             "status": test.get("status", "pending"), "comment": test.get("comment", "")}
    if covered != obligations:
        raise EvidenceError(f"missing manual obligations: {sorted(obligations - covered)}")
    return by_id




def _definition_digest(data: dict[str, Any], tests: dict[str, dict]) -> str:
    """Hash what the user is asked to check, matched by ID; status and comment stay editable."""
    definition = {
        "title": data.get("title", ""),
        "description": data.get("description", ""),
        "tests": [{field: tests[key][field] for field in DEFINITION_FIELDS} for key in sorted(tests)],
    }
    encoded = json.dumps(definition, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return f"sha256:{hashlib.sha256(encoded).hexdigest()}"


def prepare_checklist(root: Path, feature: str, checklist: Path) -> Path:
    """Bind an Agent-authored pending checklist once; never rebind old results."""
    path = report_path(root, checklist)
    data = _read(path)
    snapshot = current_snapshot(root)
    tests = _document(data, feature, _obligations(root, feature))
    if data.get("snapshot") is not None:
        raise EvidenceError("checklist is already bound; prepare a separate checklist for a new attempt")
    if any(test["status"] != "pending" or test["comment"] for test in tests.values()):
        raise EvidenceError("new checklist must contain only pending tests with empty comments")
    data["tests"] = list(tests.values())
    data["snapshot"] = {**snapshot, "definition_sha256": _definition_digest(data, tests)}
    if current_snapshot(root)["working_tree_fingerprint"] != snapshot["working_tree_fingerprint"]:
        raise EvidenceError("source changed while preparing manual checklist")
    write_json(path, data)
    return path


def read_checklist(root: Path, feature: str, checklist: Path, snapshot: dict[str, str] | None = None, *,
                   confirm_unrelated_changes: bool = False) -> dict[str, Any]:
    """Derive the acceptance decision from the statuses recorded in the bound checklist.

    The Agent must separately confirm that every status reflects the user's actual
    decision and resolve contradictory comments. This parser cannot judge prose.
    When content changed after binding, the changed inputs are returned only after
    the Agent confirmed that none of them affects this Feature's checked scope.
    """
    path = report_path(root, checklist)
    before = snapshot or current_snapshot(root)
    data = _read(path)
    tests = _document(data, feature, _obligations(root, feature))
    origin = data.get("snapshot")
    if not isinstance(origin, dict) or any(not isinstance(origin.get(key), str) or not origin[key]
                                           for key in ("git_revision", "working_tree_fingerprint", "definition_sha256")):
        raise EvidenceError("checklist has no prepared snapshot")
    if origin["definition_sha256"] != _definition_digest(data, tests):
        raise EvidenceError("checklist definitions changed after binding; only status and comment may be edited")
    decision: dict[str, Any] = {}
    if origin["working_tree_fingerprint"] != before["working_tree_fingerprint"]:
        changed = changed_paths_since(root, origin["git_revision"])
        if not confirm_unrelated_changes:
            raise EvidenceError(
                "content changed after the checklist was bound; check whether these files affect this Feature "
                f"and rerun with --confirm-unrelated-changes only if none does: {changed}")
        decision["unrelated_changes"] = changed
    statuses = {test["status"] for test in tests.values()}
    status = "rejected" if "failed" in statuses else "pending" if "pending" in statuses else "accepted"
    if current_snapshot(root)["working_tree_fingerprint"] != before["working_tree_fingerprint"]:
        raise EvidenceError("source changed while reading manual checklist")
    return {"status": status, "git_revision": before["git_revision"],
            "working_tree_fingerprint": before["working_tree_fingerprint"],
            "bound_fingerprint": origin["working_tree_fingerprint"], **decision,
            "source": {"checklist": path.relative_to(root.resolve()).as_posix()}}
