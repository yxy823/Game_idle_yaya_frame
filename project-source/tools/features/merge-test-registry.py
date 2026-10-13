#!/usr/bin/env python3
"""Safely merge generated component records into a Yaya test registry."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any, Iterable

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from tools.lib.atomic_json import write_json
from tools.lib.feature_evolution import (
    EvolutionError, TEST_REGISTRY_PATH, validate_registry, validate_registry_component,
    referenced_test_ids, validate_retirements, validate_revisions,
)
from tools.lib.test_selection import read_json_value, SelectionError

DEFAULT_REPO_ROOT = Path(__file__).resolve().parents[3]


class RegistryError(ValueError):
    """Raised when registry input cannot be merged without losing information."""


def _read_json(path: Path) -> Any:
    try:
        return read_json_value(path)
    except SelectionError as exc:
        raise RegistryError(str(exc)) from exc


def _read_candidates(path: Path, repo_root: Path) -> list[dict[str, Any]]:
    data = _read_json(path)
    if isinstance(data, dict):
        data = data.get("components")
    if not isinstance(data, list):
        raise RegistryError("component candidates must be an array or an object with components")
    candidates: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, component in enumerate(data):
        component_id = validate_registry_component(component, f"candidates[{index}]", repo_root)
        if component_id in seen:
            raise RegistryError(f"duplicate candidate component id: {component_id}")
        seen.add(component_id)
        candidates.append(component)
    return candidates


def merge_registry(candidates_path: Path, repo_root: Path) -> tuple[str, int, int, int]:
    registry_path = repo_root / TEST_REGISTRY_PATH
    registry = validate_registry(_read_json(registry_path), repo_root)
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

    candidates = _read_candidates(repo_root / candidates_path, repo_root)
    existing = {component["id"]: component for component in registry["components"]}
    added = extended = 0
    for candidate in candidates:
        component_id = candidate["id"]
        if component_id in existing:
            current = existing[component_id]
            # 认领目录可以随后来的 Feature 扩展；其他字段不同仍是冲突。
            if ({key: value for key, value in current.items() if key != "source_paths"}
                    != {key: value for key, value in candidate.items() if key != "source_paths"}):
                raise RegistryError(
                    f"component {component_id!r} conflicts with its existing registry record"
                )
            new_paths = [path for path in candidate["source_paths"] if path not in current["source_paths"]]
            if new_paths:
                current["source_paths"].extend(new_paths)
                extended += 1
            continue
        registry["components"].append(candidate)
        existing[component_id] = candidate
        added += 1

    validate_registry(registry, repo_root)
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
    if added or extended:
        write_json(registry_path, registry)

    state = "updated" if added or extended else "unchanged"
    return state, added, extended, len(registry["tests"])


def _parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Merge components into the selected project's docs/test-registry.json."
    )
    parser.add_argument("--repo-root", type=Path, default=DEFAULT_REPO_ROOT,
                        help="Target project; defaults to the project containing this script.")
    parser.add_argument("--components", type=Path, required=True,
                        help="Candidate JSON, absolute or relative to the selected project.")
    return parser.parse_args(list(argv))


def main() -> int:
    args = _parse_args(sys.argv[1:])
    try:
        state, added, extended, preserved_tests = merge_registry(args.components, args.repo_root.resolve())
    except (RegistryError, EvolutionError) as exc:
        print(f"TEST REGISTRY MERGE: BLOCKED - {exc}", file=sys.stderr)
        return 2
    print(
        "TEST REGISTRY MERGE: PASS - "
        f"{state}; added_components={added}; extended_components={extended}; preserved_tests={preserved_tests}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
