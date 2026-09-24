#!/usr/bin/env python3
"""Safely merge generated component records into a Yaya test registry."""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Iterable

sys.path.insert(0, str(Path(__file__).resolve().parents[4]))
from tools.lib.feature_evolution import (
    EvolutionError, REGISTRY_SCHEMA_VERSION, TEST_REGISTRY_PATH, validate_retirement_shape,
    referenced_test_ids, test_identity, validate_retirements, validate_revisions,
)
from tools.lib.test_selection import read_json_value, SelectionError

COMPONENT_RE = re.compile(r"^[a-z][a-z0-9_]*$")
ALLOWED_TEST_STATUSES = {"planned", "active", "retired"}


class RegistryError(ValueError):
    """Raised when registry input cannot be merged without losing information."""


def _read_json(path: Path) -> Any:
    try:
        return read_json_value(path)
    except SelectionError as exc:
        raise RegistryError(str(exc)) from exc


def _string_list(value: Any, label: str, *, allow_empty: bool = True) -> list[str]:
    if not isinstance(value, list):
        raise RegistryError(f"{label} must be an array")
    if any(not isinstance(item, str) or not item.strip() for item in value):
        raise RegistryError(f"{label} must contain only non-empty strings")
    if not allow_empty and not value:
        raise RegistryError(f"{label} must not be empty")
    if len(value) != len(set(value)):
        raise RegistryError(f"{label} contains duplicates")
    return value


def _validate_component(component: Any, label: str) -> str:
    if not isinstance(component, dict):
        raise RegistryError(f"{label} must be an object")
    component_id = component.get("id")
    if not isinstance(component_id, str) or not COMPONENT_RE.fullmatch(component_id):
        raise RegistryError(f"{label}.id must be lower_snake_case")
    unit_paths = _string_list(component.get("unit_test_paths"), f"{label}.unit_test_paths")
    # The helper runs from the repository root. Unit paths are execution
    # targets, unlike test entries explicitly marked as planned.
    for unit_path in unit_paths:
        path = Path(unit_path)
        if not (path.is_file() or path.is_dir()):
            raise RegistryError(
                f"{label}.unit_test_paths references a missing unit suite: {unit_path}"
            )
    if not isinstance(component.get("full_suite_on_change"), bool):
        raise RegistryError(f"{label}.full_suite_on_change must be boolean")
    return component_id


def _validate_test(test: Any, label: str, component_ids: set[str]) -> str:
    if not isinstance(test, dict):
        raise RegistryError(f"{label} must be an object")
    test_id = test.get("id")
    status = test.get("status")
    if status not in ALLOWED_TEST_STATUSES:
        raise RegistryError(f"{label}.status is invalid")
    try:
        test_identity(test_id)
        validate_retirement_shape(test)
    except EvolutionError as exc:
        raise RegistryError(str(exc)) from exc
    mapped_components = _string_list(
        test.get("components"), f"{label}.components", allow_empty=False
    )
    missing = sorted(set(mapped_components) - component_ids)
    if missing:
        raise RegistryError(
            f"{label}.components references missing components: {', '.join(missing)}"
        )
    path = test.get("path")
    if status in {"planned", "retired"}:
        if path is not None and (not isinstance(path, str) or not path.strip()):
            raise RegistryError(f"{label}.path must be null or a non-empty string")
    elif not isinstance(path, str) or not path.strip():
        raise RegistryError(f"{label}.path must be non-empty when status is {status}")
    case = test.get("case")
    if case is not None and (not isinstance(case, str) or not case.strip()):
        raise RegistryError(f"{label}.case must be null or a non-empty string")

    return test_id


def validate_registry(data: Any) -> dict[str, Any]:
    if not isinstance(data, dict):
        raise RegistryError("test registry root must be an object")
    meta = data.get("meta")
    if (not isinstance(meta, dict) or type(meta.get("schema_version")) is not int
            or meta["schema_version"] != REGISTRY_SCHEMA_VERSION):
        raise RegistryError(f"test registry meta.schema_version must be integer {REGISTRY_SCHEMA_VERSION}")
    components = data.get("components")
    tests = data.get("tests")
    if not isinstance(components, list):
        raise RegistryError("test registry components must be an array")
    if not isinstance(tests, list):
        raise RegistryError("test registry tests must be an array")

    component_ids: set[str] = set()
    for index, component in enumerate(components):
        component_id = _validate_component(component, f"components[{index}]")
        if component_id in component_ids:
            raise RegistryError(f"duplicate component id: {component_id}")
        component_ids.add(component_id)

    test_ids: set[str] = set()
    for index, test in enumerate(tests):
        test_id = _validate_test(test, f"tests[{index}]", component_ids)
        if test_id in test_ids:
            raise RegistryError(f"duplicate test id: {test_id}")
        test_ids.add(test_id)
    return data


def _read_candidates(path: Path) -> list[dict[str, Any]]:
    data = _read_json(path)
    if isinstance(data, dict):
        data = data.get("components")
    if not isinstance(data, list):
        raise RegistryError("component candidates must be an array or an object with components")
    candidates: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, component in enumerate(data):
        component_id = _validate_component(component, f"candidates[{index}]")
        if component_id in seen:
            raise RegistryError(f"duplicate candidate component id: {component_id}")
        seen.add(component_id)
        candidates.append(component)
    return candidates


def merge_registry(candidates_path: Path) -> tuple[str, int, int]:
    # Run from the project root, as required for registered unit-test paths.
    registry_path = Path(TEST_REGISTRY_PATH)
    registry = validate_registry(_read_json(registry_path))
    index = _read_json(registry_path.parent / "feature-list.json")
    if not isinstance(index, dict) or not isinstance(index.get("features"), list):
        raise RegistryError("component merging requires the adjacent Feature index")
    if any(not isinstance(entry, dict) or not isinstance(entry.get("id"), str)
           for entry in index["features"]):
        raise RegistryError("component merging requires valid Feature entries")
    entries = {entry["id"]: entry for entry in index["features"]}
    try:
        revisions = validate_revisions(_read_json(registry_path.parent / "feature-list-revisions.json"), entries)
    except EvolutionError as exc:
        raise RegistryError(str(exc)) from exc

    candidates = _read_candidates(candidates_path)
    existing = {component["id"]: component for component in registry["components"]}
    added = 0
    for candidate in candidates:
        component_id = candidate["id"]
        if component_id in existing:
            if existing[component_id] != candidate:
                raise RegistryError(
                    f"component {component_id!r} conflicts with its existing registry record"
                )
            continue
        registry["components"].append(candidate)
        existing[component_id] = candidate
        added += 1

    validate_registry(registry)
    if any(test["status"] == "retired" for test in registry["tests"]):
        # Component merging must preserve valid evolution, not merely its JSON shape.
        try:
            replacement_features = {test["retirement"]["replacement"]["feature_id"]
                                    for test in registry["tests"] if test["status"] == "retired"}
            verification_ids = {fid: referenced_test_ids(_read_json(registry_path.parent / "features" / f"{fid}.json"))
                                for fid in replacement_features}
            validate_retirements({test["id"]: test for test in registry["tests"]}, entries, revisions, verification_ids)
        except EvolutionError as exc:
            raise RegistryError(str(exc)) from exc
    if added:
        temporary = registry_path.with_name(f".{registry_path.name}.{os.getpid()}.tmp")
        try:
            temporary.write_text(
                json.dumps(registry, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
                newline="\n",
            )
            os.replace(temporary, registry_path)
        finally:
            try:
                temporary.unlink()
            except FileNotFoundError:
                pass

    state = "updated" if added else "unchanged"
    return state, added, len(registry["tests"])


def _parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Merge components into docs/test-registry.json; run from the project root."
    )
    parser.add_argument("--components", type=Path, required=True)
    return parser.parse_args(list(argv))


def main() -> int:
    args = _parse_args(sys.argv[1:])
    try:
        state, added, preserved_tests = merge_registry(args.components)
    except RegistryError as exc:
        print(f"TEST REGISTRY MERGE: BLOCKED - {exc}", file=sys.stderr)
        return 2
    print(
        "TEST REGISTRY MERGE: PASS - "
        f"{state}; added_components={added}; preserved_tests={preserved_tests}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
