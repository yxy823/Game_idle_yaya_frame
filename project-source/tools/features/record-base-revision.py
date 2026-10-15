#!/usr/bin/env python3
"""Fix a Feature's base_revision, the start of its content-change test selection."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Iterable

# 脚本在子目录直接启动时，显式加载本项目的共享包。
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.atomic_json import write_json
from tools.lib.test_selection import (
    SelectionError, change_impact, component_full_reasons, read_json, touched_completed_features, verification_point,
)
from tools.lib.feature_evolution import TEST_REGISTRY_PATH

DEFAULT_REPO_ROOT = Path(__file__).resolve().parents[3]


def _feature_id(value: str) -> str:
    normalized = value.upper()
    if not re.fullmatch(r"F\d{3}", normalized):
        raise argparse.ArgumentTypeError("Feature ID must match F0XX")
    return normalized


def _preview(repo_root: Path, detail: dict, revision: str) -> None:
    registry = read_json(repo_root / TEST_REGISTRY_PATH)
    impact = change_impact(repo_root, registry, revision)
    components = set(detail["affected_components"]) | impact["inferred_components"].keys()
    approved = detail.get("verification", {}).get("test_impact", {}).get("full_suite_reasons", [])
    impact["full_suite_reasons"] = sorted(set(
        impact["full_suite_reasons"] + approved
        + component_full_reasons({item["id"]: item for item in registry["components"]}, components)))
    tests = {test["id"]: test for test in registry["tests"]}
    print(json.dumps({**impact, "declared_components": sorted(detail["affected_components"]),
                      "touched_completed_features": touched_completed_features(repo_root, tests, components)},
                     indent=2, ensure_ascii=False))


def _parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=DEFAULT_REPO_ROOT)
    parser.add_argument("--feature", required=True, type=_feature_id)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--reset", action="store_true",
                      help="Replace an existing base_revision with the current verification point")
    mode.add_argument("--dry-run", action="store_true",
                      help="Print the start, changed files, inferred components, graph suites and full-suite "
                           "reasons without writing")
    return parser.parse_args(list(argv))


def main() -> int:
    args = _parse_args(sys.argv[1:])
    repo_root = args.repo_root.resolve()
    path = repo_root / f"docs/features/{args.feature}.json"
    try:
        detail = read_json(path)
        existing = detail.get("base_revision")
        if args.dry_run:
            _preview(repo_root, detail, existing or verification_point(repo_root))
            return 0
        if existing and not args.reset:
            print(f"{args.feature} already has base_revision {existing}; kept. Use --reset to take a new verification point.")
            return 0
        detail["base_revision"] = verification_point(repo_root)
        write_json(path, detail)
    except (SelectionError, OSError) as exc:
        print(f"BASE REVISION: BLOCKED - {exc}", file=sys.stderr)
        return 2
    print(f"{args.feature} base_revision: {detail['base_revision']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
