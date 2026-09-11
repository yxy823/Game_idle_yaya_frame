#!/usr/bin/env python3
"""Safely merge generated component records into a Yaya test catalog."""
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
    EvolutionError, CATALOG_SCHEMA_VERSION, validate_retirement_shape,
    referenced_test_ids, validate_retirements, validate_revisions,
)

COMPONENT_RE = re.compile(r"^[a-z][a-z0-9_]*$")
AC_TEST_RE = re.compile(r"^(F\d{3})-(AC\d{2})(?:-(\d{2}))?$")
REGRESSION_TEST_RE = re.compile(r"^(F\d{3})-RT\d{2}$")
INVARIANT_TEST_RE = re.compile(r"^INV-[A-Z0-9][A-Z0-9_-]*-\d{2}$")
ALLOWED_TEST_KINDS = {"acceptance", "regression", "invariant"}
ALLOWED_TEST_STATUSES = {"planned", "active", "retired"}


class CatalogError(ValueError):
    """Raised when catalog input cannot be merged without losing information."""


def _read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise CatalogError(f"JSON input does not exist: {path}") from exc
    except (OSError, json.JSONDecodeError) as exc:
        raise CatalogError(f"cannot read JSON input {path}: {exc}") from exc


def _string_list(value: Any, label: str, *, allow_empty: bool = True) -> list[str]:
    if not isinstance(value, list):
        raise CatalogError(f"{label} must be an array")
    if any(not isinstance(item, str) or not item.strip() for item in value):
        raise CatalogError(f"{label} must contain only non-empty strings")
    if not allow_empty and not value:
        raise CatalogError(f"{label} must not be empty")
    if len(value) != len(set(value)):
        raise CatalogError(f"{label} contains duplicates")
    return value


def _validate_component(component: Any, label: str) -> str:
    if not isinstance(component, dict):
        raise CatalogError(f"{label} must be an object")
    component_id = component.get("id")
    if not isinstance(component_id, str) or not COMPONENT_RE.fullmatch(component_id):
        raise CatalogError(f"{label}.id must be lower_snake_case")
    unit_paths = _string_list(component.get("unit_test_paths"), f"{label}.unit_test_paths")
    # The helper runs from the repository root. Unit paths are execution
    # targets, unlike test entries explicitly marked as planned.
    for unit_path in unit_paths:
        path = Path(unit_path)
        if not (path.is_file() or path.is_dir()):
            raise CatalogError(
                f"{label}.unit_test_paths references a missing unit suite: {unit_path}"
            )
    if not isinstance(component.get("full_suite_on_change"), bool):
        raise CatalogError(f"{label}.full_suite_on_change must be boolean")
    return component_id


def _validate_test(test: Any, label: str, component_ids: set[str]) -> str:
    if not isinstance(test, dict):
        raise CatalogError(f"{label} must be an object")
    test_id = test.get("id")
    if not isinstance(test_id, str) or not test_id.strip():
        raise CatalogError(f"{label}.id must be a non-empty string")
    kind = test.get("kind")
    if kind not in ALLOWED_TEST_KINDS:
        raise CatalogError(f"{label}.kind is invalid")
    status = test.get("status")
    if status not in ALLOWED_TEST_STATUSES:
        raise CatalogError(f"{label}.status is invalid")
    try:
        validate_retirement_shape(test)
    except EvolutionError as exc:
        raise CatalogError(str(exc)) from exc
    mapped_components = _string_list(
        test.get("components"), f"{label}.components", allow_empty=False
    )
    missing = sorted(set(mapped_components) - component_ids)
    if missing:
        raise CatalogError(
            f"{label}.components references missing components: {', '.join(missing)}"
        )
    path = test.get("path")
    if status in {"planned", "retired"}:
        if path is not None and (not isinstance(path, str) or not path.strip()):
            raise CatalogError(f"{label}.path must be null or a non-empty string")
    elif not isinstance(path, str) or not path.strip():
        raise CatalogError(f"{label}.path must be non-empty when status is {status}")
    case = test.get("case")
    if case is not None and (not isinstance(case, str) or not case.strip()):
        raise CatalogError(f"{label}.case must be null or a non-empty string")

    source_feature = test.get("source_feature")
    criterion_id = test.get("criterion_id")
    if kind == "acceptance":
        match = AC_TEST_RE.fullmatch(test_id)
        if match is None:
            raise CatalogError(f"{label}.id must match F0XX-ACyy[-NN]")
        if source_feature != match.group(1) or criterion_id != match.group(2):
            raise CatalogError(
                f"{label} acceptance id/source_feature/criterion_id disagree"
            )
    elif kind == "regression":
        match = REGRESSION_TEST_RE.fullmatch(test_id)
        if match is None:
            raise CatalogError(f"{label}.id must match F0XX-RTyy")
        if source_feature != match.group(1) or criterion_id is not None:
            raise CatalogError(
                f"{label} regression id/source_feature/criterion_id disagree"
            )
    elif (
        not INVARIANT_TEST_RE.fullmatch(test_id)
        or source_feature is not None
        or criterion_id is not None
    ):
        raise CatalogError(
            f"{label} invariant id/source_feature/criterion_id are invalid"
        )
    return test_id


def validate_catalog(data: Any) -> dict[str, Any]:
    if not isinstance(data, dict):
        raise CatalogError("test catalog root must be an object")
    meta = data.get("meta")
    if (not isinstance(meta, dict) or type(meta.get("schema_version")) is not int
            or meta["schema_version"] != CATALOG_SCHEMA_VERSION):
        raise CatalogError("test catalog meta.schema_version must be integer 2")
    components = data.get("components")
    tests = data.get("tests")
    if not isinstance(components, list):
        raise CatalogError("test catalog components must be an array")
    if not isinstance(tests, list):
        raise CatalogError("test catalog tests must be an array")

    component_ids: set[str] = set()
    for index, component in enumerate(components):
        component_id = _validate_component(component, f"components[{index}]")
        if component_id in component_ids:
            raise CatalogError(f"duplicate component id: {component_id}")
        component_ids.add(component_id)

    test_ids: set[str] = set()
    for index, test in enumerate(tests):
        test_id = _validate_test(test, f"tests[{index}]", component_ids)
        if test_id in test_ids:
            raise CatalogError(f"duplicate test id: {test_id}")
        test_ids.add(test_id)
    return data


def _read_candidates(path: Path) -> list[dict[str, Any]]:
    data = _read_json(path)
    if isinstance(data, dict):
        data = data.get("components")
    if not isinstance(data, list):
        raise CatalogError("component candidates must be an array or an object with components")
    candidates: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, component in enumerate(data):
        component_id = _validate_component(component, f"candidates[{index}]")
        if component_id in seen:
            raise CatalogError(f"duplicate candidate component id: {component_id}")
        seen.add(component_id)
        candidates.append(component)
    return candidates


def merge_catalog(catalog_path: Path, candidates_path: Path) -> tuple[str, int, int]:
    existed = catalog_path.exists()
    if existed:
        catalog = validate_catalog(_read_json(catalog_path))
    else:
        catalog = {
            "meta": {"schema_version": CATALOG_SCHEMA_VERSION},
            "components": [],
            "tests": [],
        }

    candidates = _read_candidates(candidates_path)
    existing = {component["id"]: component for component in catalog["components"]}
    added = 0
    for candidate in candidates:
        component_id = candidate["id"]
        if component_id in existing:
            if existing[component_id] != candidate:
                raise CatalogError(
                    f"component {component_id!r} conflicts with its existing catalog record"
                )
            continue
        catalog["components"].append(candidate)
        existing[component_id] = candidate
        added += 1

    validate_catalog(catalog)
    if any(test["status"] == "retired" for test in catalog["tests"]):
        # Component merging must preserve valid evolution, not merely its JSON shape.
        index = _read_json(catalog_path.parent / "feature-list.json")
        if not isinstance(index, dict) or not isinstance(index.get("features"), list):
            raise CatalogError("retirement validation requires the adjacent Feature index")
        if any(not isinstance(entry, dict) or not isinstance(entry.get("id"), str)
               for entry in index["features"]):
            raise CatalogError("retirement validation requires valid Feature entries")
        entries = {entry["id"]: entry for entry in index["features"]}
        try:
            revisions = validate_revisions(_read_json(catalog_path.parent / "feature-list-revisions.json"), entries)
            replacement_features = {test["retirement"]["replacement"]["feature_id"]
                                    for test in catalog["tests"] if test["status"] == "retired"}
            verification_ids = {fid: referenced_test_ids(_read_json(catalog_path.parent / "features" / f"{fid}.json"))
                                for fid in replacement_features}
            validate_retirements({test["id"]: test for test in catalog["tests"]}, entries, revisions, verification_ids)
        except EvolutionError as exc:
            raise CatalogError(str(exc)) from exc
    if not existed or added:
        catalog_path.parent.mkdir(parents=True, exist_ok=True)
        temporary = catalog_path.with_name(f".{catalog_path.name}.{os.getpid()}.tmp")
        try:
            temporary.write_text(
                json.dumps(catalog, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
                newline="\n",
            )
            os.replace(temporary, catalog_path)
        finally:
            try:
                temporary.unlink()
            except FileNotFoundError:
                pass

    state = "created" if not existed else ("updated" if added else "unchanged")
    return state, added, len(catalog["tests"])


def _parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--components", type=Path, required=True)
    return parser.parse_args(list(argv))


def main() -> int:
    args = _parse_args(sys.argv[1:])
    try:
        state, added, preserved_tests = merge_catalog(args.catalog, args.components)
    except CatalogError as exc:
        print(f"TEST CATALOG MERGE: BLOCKED - {exc}", file=sys.stderr)
        return 2
    print(
        "TEST CATALOG MERGE: PASS - "
        f"{state}; added_components={added}; preserved_tests={preserved_tests}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
