"""Deterministic Test Registry selection shared by runners and completion gates."""
# 仅从当前 Feature/Registry 计算运行选择；不写独立计划、快照或计划哈希。
from __future__ import annotations

import json
import math
import re
from pathlib import Path, PurePosixPath
from typing import Any

from tools.lib.feature_evolution import (
    EvolutionError, REGISTRY_SCHEMA_VERSION, TEST_REGISTRY_PATH, resolve_test_path, test_identity,
)


class SelectionError(ValueError):
    """A test contract cannot be translated into a safe, complete selection."""


def read_json_value(path: Path) -> Any:
    """Reject ambiguous JSON; each caller owns its root type and business schema."""
    def unique(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in pairs:
            if key in result:
                raise SelectionError(f"duplicate JSON key {key!r} in {path}")
            result[key] = value
        return result

    def finite_float(value: str) -> float:
        number = float(value)
        if not math.isfinite(number):
            raise SelectionError(f"invalid number {value}")
        return number

    try:
        return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique,
                          parse_float=finite_float,
                          parse_constant=lambda value: (_ for _ in ()).throw(SelectionError(f"invalid number {value}")))
    except (OSError, ValueError) as exc:
        raise SelectionError(f"cannot read {path}: {exc}") from exc


def read_json(path: Path) -> dict[str, Any]:
    value = read_json_value(path)
    if not isinstance(value, dict):
        raise SelectionError(f"expected JSON object: {path}")
    return value


def normalized_path(root: Path, value: str) -> str:
    if not isinstance(value, str) or not value:
        raise SelectionError("test path must be a non-empty repository-relative path")
    value = value.replace("\\", "/").removeprefix("res://")
    try:
        resolved = resolve_test_path(root, value)
    except EvolutionError as exc:
        raise SelectionError(str(exc)) from exc
    if not resolved.exists():
        raise SelectionError(f"registered test path does not exist: {value}")
    return PurePosixPath(value).as_posix()


def deduplicate_selectors(root: Path, paths: list[str]) -> list[str]:
    """Keep logical obligations intact but execute overlapping physical suites once."""
    ordered = sorted({normalized_path(root, path) for path in paths})
    result: list[str] = []
    for path in ordered:
        if any((root / ancestor).is_dir() and path.startswith(ancestor + "/") for ancestor in ordered):
            continue
        result.append(path)
    return result


# 全量 = tests/ 加调试台目录；项目没有 dev/debug/ 时只选 tests/。
def full_suite_selectors(root: Path) -> list[str]:
    return ["tests", *(["dev/debug"] if (root / "dev/debug").is_dir() else [])]


def _impact_options(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != {"additional_tests", "full_suite_reasons"}:
        raise SelectionError("test impact requires additional_tests and full_suite_reasons arrays")
    additions, reasons = value["additional_tests"], value["full_suite_reasons"]
    if not isinstance(additions, list) or not isinstance(reasons, list):
        raise SelectionError("test impact options must be arrays")
    ids: set[str] = set()
    for item in additions:
        if not isinstance(item, dict) or set(item) != {"id", "reason"}:
            raise SelectionError("additional tests require exactly id and reason")
        if any(not isinstance(text, str) or not text.strip() for text in item.values()) or item["id"] in ids:
            raise SelectionError("additional test IDs must be unique and have nonempty reasons")
        ids.add(item["id"])
    if any(not isinstance(reason, str) or not reason.strip() for reason in reasons) or len(reasons) != len(set(reasons)):
        raise SelectionError("full-suite reasons must be unique nonempty strings")
    return value


def acceptance_mode(detail: dict[str, Any]) -> str:
    """Read the planned acceptance decision; check lists are its outputs, not its cause."""
    verification = detail.get("verification", {})
    if not isinstance(verification, dict):
        raise SelectionError("Feature verification must be an object")
    mode = verification.get("acceptance_mode")
    if mode not in {"automated", "manual"}:
        raise SelectionError("Feature verification.acceptance_mode must be decided as automated or manual")
    criteria = detail.get("acceptance_criteria", [])
    if not criteria:
        raise SelectionError("Feature requires acceptance criteria")
    checks = [criterion.get("verification", {}) for criterion in criteria]
    manual = any(item.get("manual_checks") for item in checks) or verification.get("manual_regression")
    if mode == "automated":
        if manual or any(not item.get("automated_tests") for item in checks):
            raise SelectionError("automated acceptance needs automated coverage for every AC and no manual obligations")
    elif not manual:
        raise SelectionError("manual acceptance needs concrete manual_checks or manual_regression")
    return mode


# 从当前合约与显式影响说明计算义务；只有真实 full 结果覆盖选择集时才可复用。
def build_selection(root: Path, feature_id: str, *, phase: str = "final") -> dict[str, Any]:
    if not re.fullmatch(r"F\d{3}", feature_id) or phase not in {"baseline", "final"}:
        raise SelectionError("invalid Feature ID or test-selection phase")
    detail = read_json(root / f"docs/features/{feature_id}.json")
    if phase == "final":
        acceptance_mode(detail)
    registry = read_json(root / TEST_REGISTRY_PATH)
    if registry.get("meta", {}).get("schema_version") != REGISTRY_SCHEMA_VERSION:
        raise SelectionError("unsupported Test Registry schema")
    components = {item["id"]: item for item in registry["components"]}
    tests = {item["id"]: item for item in registry["tests"]}
    if len(components) != len(registry["components"]) or len(tests) != len(registry["tests"]):
        raise SelectionError("duplicate component or logical test ID")
    affected_components = sorted(set(detail["affected_components"]))
    if set(affected_components) - components.keys():
        raise SelectionError("Feature references unknown affected components")
    required: dict[tuple[str, str | None], dict[str, Any]] = {}
    affected: dict[tuple[str, str | None], dict[str, Any]] = {}

    def add(mapping: dict, path: str, case: str | None, logical_id: str | None, reason: str) -> None:
        path = normalized_path(root, path)
        if case is not None and (not isinstance(case, str) or not case.strip()):
            raise SelectionError("Registry case must be null or a non-empty string")
        item = mapping.setdefault((path, case), {"path": path, "case": case, "logical_ids": [], "reasons": []})
        if logical_id and logical_id not in item["logical_ids"]:
            item["logical_ids"].append(logical_id)
        if reason not in item["reasons"]:
            item["reasons"].append(reason)

    def add_test(mapping: dict, test_id: str, reason: str, *, direct: bool = False) -> None:
        if test_id not in tests:
            raise SelectionError(f"required test is missing from Registry: {test_id}")
        test = tests[test_id]
        if phase == "baseline" and test["status"] == "planned":
            return
        if test["status"] != "active":
            raise SelectionError(f"required test {test_id} is {test['status']}; expected active")
        if direct and test_identity(test_id)[1] != feature_id:
            raise SelectionError(f"current verification test belongs to another Feature: {test_id}")
        add(mapping, test["path"], test.get("case"), test_id, reason)

    for criterion in detail["acceptance_criteria"]:
        verification = criterion.get("verification", {})
        if phase == "final" and not verification.get("automated_tests") and not verification.get("manual_checks"):
            raise SelectionError(f"criterion {feature_id}-{criterion['id']} has no approved verification mapping")
        for test_id in verification.get("automated_tests", []):
            add_test(required, test_id, f"criterion:{feature_id}-{criterion['id']}", direct=True)
    for test_id in detail.get("verification", {}).get("regression_tests", []):
        add_test(required, test_id, f"regression:{feature_id}", direct=True)
    approved_impact = _impact_options(detail.get("verification", {}).get("test_impact", {
        "additional_tests": [], "full_suite_reasons": []}))
    full_reasons = list(approved_impact["full_suite_reasons"])
    for component_id in affected_components:
        component = components[component_id]
        for path in component["unit_test_paths"]:
            add(required, path, None, None, f"component-unit:{component_id}")
        if component["full_suite_on_change"]:
            full_reasons.append(f"component-full-suite:{component_id}")
    for test_id, test in sorted(tests.items()):
        if test["status"] != "active" or not set(test["components"]).intersection(affected_components):
            continue
        kind, _, _ = test_identity(test_id)
        if kind in {"regression", "invariant"}:
            add_test(required, test_id, f"affected-{kind}")
        add_test(affected, test_id, "affected-component-contract")
    additions = sorted(approved_impact["additional_tests"],
                       key=lambda item: (item["id"], item["reason"]))
    for extra in additions:
        add_test(required, extra["id"], "approved-addition:" + extra["reason"])
    for item in required.values():
        for reason in item["reasons"]:
            for logical_id in item["logical_ids"] or [None]:
                add(affected, item["path"], item["case"], logical_id, reason)

    def stable(mapping: dict) -> list[dict[str, Any]]:
        for item in mapping.values():
            item["logical_ids"].sort()
            item["reasons"].sort()
        return sorted(mapping.values(), key=lambda item: (item["path"], item["case"] or ""))

    result = {"feature_id": feature_id, "phase": phase,
              "affected_components": affected_components,
              "required": stable(required), "affected": stable(affected),
              "selectors": deduplicate_selectors(root, [item["path"] for item in affected.values()]),
              "full_suite": {"required": bool(full_reasons), "reasons": sorted(set(full_reasons)),
                             "selectors": full_suite_selectors(root)}}
    return result


# 将内存中的选择转换成 Godot 参数；执行结果只记录实际选择与报告。
def execution_selectors(root: Path, selection: dict[str, Any], scope: str) -> list[str]:
    if scope == "full":
        selectors = deduplicate_selectors(root, selection["full_suite"]["selectors"])
    elif scope in {"required", "affected"}:
        selectors = deduplicate_selectors(root, [item["path"] for item in selection[scope]])
    else:
        raise SelectionError(f"unsupported scope: {scope}")
    if not selectors:
        raise SelectionError(f"{scope} selects zero test paths; do not claim an empty run passed")
    return selectors
