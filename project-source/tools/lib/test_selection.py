"""Deterministic Test Registry selection shared by runners and completion gates."""
# 仅从当前 Feature/Registry 计算运行选择；不写独立计划、快照或计划哈希。
from __future__ import annotations

import json
import math
import re
from datetime import datetime
from pathlib import Path, PurePosixPath
from typing import Any

from tools.lib.dependency_graph import build_graph, canonical, dependents
from tools.lib.feature_evolution import (
    EvolutionError, REGISTRY_SCHEMA_VERSION, TEST_REGISTRY_PATH, resolve_test_path, test_identity,
)
from tools.lib.verification_snapshot import (
    EvidenceError, changed_paths_since, commit_exists, is_ancestor, root_commit,
)

BASE_REVISION_COMMAND = "python -B yaya/tools/features/record-base-revision.py"
TEST_INFRASTRUCTURE_PREFIXES = ("yaya/tools/testing/", "addons/gdUnit4/")
TEST_INFRASTRUCTURE_FILES = {"docs/methodology-config.json"}
NON_GAME_PREFIXES = ("docs/", "yaya/", "addons/", ".agents/", ".claude/", ".codex/")
GAME_SUFFIXES = {
    ".gd", ".tscn", ".tres", ".res", ".gdshader", ".gdshaderinc", ".json", ".cfg", ".csv", ".translation",
    ".png", ".jpg", ".jpeg", ".webp", ".svg", ".bmp", ".tga", ".exr", ".hdr", ".ktx", ".dds",
    ".wav", ".ogg", ".mp3", ".ttf", ".otf", ".woff", ".woff2", ".fnt", ".font",
}
DEBUG_TEST_PATH = re.compile(r"dev/debug/(?:.*/)?tests/.+")


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


def _glob_regex(pattern: str) -> re.Pattern[str]:
    """`**` crosses directories, `*` and `?` stay within one path segment."""
    parts = re.split(r"(\*\*/|\*\*|\*|\?)", pattern)
    tokens = {"**/": "(?:.*/)?", "**": ".*", "*": "[^/]*", "?": "[^/]"}
    return re.compile("".join(tokens.get(part, re.escape(part)) for part in parts))


def claiming_components(components: dict[str, dict[str, Any]], path: str) -> list[str]:
    return sorted(component_id for component_id, component in components.items()
                  if any(_glob_regex(pattern).fullmatch(path) for pattern in component["source_paths"]))


def _completed_at(entry: dict[str, Any]) -> datetime:
    return datetime.fromisoformat(entry["completed_at"].replace("Z", "+00:00"))


def verification_point(root: Path) -> str:
    """Latest completed Feature evidence revision that HEAD still contains; else the first commit."""
    index = read_json(root / "docs/feature-list.json")
    completed = sorted((entry for entry in index["features"]
                        if entry.get("status") in {"done", "obsolete_done"} and entry.get("completed_at")),
                       key=_completed_at, reverse=True)
    try:
        for entry in completed:
            evidence = root / f"docs/features/{entry['id']}-evidence.json"
            revision = read_json(evidence).get("git_revision") if evidence.is_file() else None
            if isinstance(revision, str) and commit_exists(root, revision) and is_ancestor(root, revision):
                return revision
        return root_commit(root)
    except EvidenceError as exc:
        raise SelectionError(str(exc)) from exc


def feature_base_revision(root: Path, feature_id: str, detail: dict[str, Any]) -> str:
    revision = detail.get("base_revision")
    if not isinstance(revision, str) or not revision:
        raise SelectionError(f"{feature_id} has no base_revision; run {BASE_REVISION_COMMAND} --feature {feature_id}")
    try:
        exists = commit_exists(root, revision)
    except EvidenceError as exc:
        raise SelectionError(str(exc)) from exc
    if not exists:
        raise SelectionError(f"{feature_id} base_revision {revision} is not a commit in this repository; "
                             f"run {BASE_REVISION_COMMAND} --feature {feature_id} --reset")
    return revision


def _is_test_area(path: str) -> bool:
    return path.startswith("tests/") or bool(DEBUG_TEST_PATH.fullmatch(path))


def _is_game_file(path: str) -> bool:
    if path == "project.godot":
        return True
    # 根目录的其他文件是 lint、导出等工具配置，不是游戏内容。
    return ("/" in path and not path.startswith(NON_GAME_PREFIXES)
            and PurePosixPath(path).suffix.lower() in GAME_SUFFIXES)


def change_impact(root: Path, registry: dict[str, Any], base_revision: str) -> dict[str, Any]:
    """Map content changes since ``base_revision`` to components, suites and full-suite reasons.

    Only file content is read, never commit messages or Feature status, so the
    result is a function of the base revision and the current working tree.
    """
    from tools.lib.test_run_evidence import _SuiteInheritance, _declared_tests

    components = {item["id"]: item for item in registry["components"]}
    try:
        changed = sorted({canonical(path) for path in changed_paths_since(root, base_revision, [])})
    except EvidenceError as exc:
        raise SelectionError(str(exc)) from exc
    inheritance = _SuiteInheritance(root.resolve())

    # 只对测试目录里的脚本判断是否套件，游戏脚本的继承写法不影响选择。
    def is_suite(path: str) -> bool:
        file = (root / path).resolve()
        return (path.endswith(".gd") and file.is_file() and bool(_declared_tests(inheritance.source(file)))
                and inheritance.is_suite(file))

    inferred: dict[str, set[str]] = {}
    suites: dict[str, dict[str, Any]] = {}
    full_reasons: list[str] = []
    starts: list[str] = []
    unclaimed: list[str] = []
    for path in changed:
        if path.startswith(TEST_INFRASTRUCTURE_PREFIXES) or path in TEST_INFRASTRUCTURE_FILES:
            full_reasons.append(f"test-infrastructure:{path}")
        elif _is_test_area(path):
            if is_suite(path):
                suites[path] = {"path": path, "reasons": [f"changed-test:{path}"], "chain": [path]}
            else:
                starts.append(path)
        elif _is_game_file(path):
            starts.append(path)
            owners = claiming_components(components, path)
            for component_id in owners:
                inferred.setdefault(component_id, set()).add(path)
            if not owners:
                if (root / path).exists():
                    unclaimed.append(path)
                else:
                    full_reasons.append(f"unclaimed-changed-file:{path}")
    reached = dependents(build_graph(root), starts) if starts else {}
    for start, chains in reached.items():
        for node, chain in sorted(chains.items()):
            if _is_test_area(node) and is_suite(node):
                item = suites.setdefault(node, {"path": node, "reasons": [], "chain": chain})
                reason = f"dependency-graph:{start}"
                if reason not in item["reasons"]:
                    item["reasons"].append(reason)
                if len(chain) < len(item["chain"]):
                    item["chain"] = chain
    for path in unclaimed:
        # 调试台引用大量游戏文件；只被调试台依赖的未认领文件不归入调试台。
        owners = {component_id for node in reached[path] if not node.startswith("dev/debug/")
                  for component_id in claiming_components(components, node)}
        for component_id in owners:
            inferred.setdefault(component_id, set()).add(path)
        if not owners:
            full_reasons.append(f"unclaimed-changed-file:{path}")
    return {"base_revision": base_revision, "changed_files": changed,
            "inferred_components": {key: sorted(value) for key, value in sorted(inferred.items())},
            "dependency_suites": [{**item, "reasons": sorted(item["reasons"])}
                                  for _, item in sorted(suites.items())],
            "full_suite_reasons": sorted(set(full_reasons))}


def _read_registry(root: Path) -> tuple[dict[str, Any], dict[str, dict], dict[str, dict]]:
    registry = read_json(root / TEST_REGISTRY_PATH)
    if registry.get("meta", {}).get("schema_version") != REGISTRY_SCHEMA_VERSION:
        raise SelectionError("unsupported Test Registry schema")
    components = {item["id"]: item for item in registry["components"]}
    tests = {item["id"]: item for item in registry["tests"]}
    if len(components) != len(registry["components"]) or len(tests) != len(registry["tests"]):
        raise SelectionError("duplicate component or logical test ID")
    return registry, components, tests


def touched_completed_features(root: Path, tests: dict[str, dict], component_ids: set[str]) -> list[str]:
    """Reminder only: done Features whose registered tests protect a selected component."""
    statuses = {entry["id"]: entry.get("status") for entry in read_json(root / "docs/feature-list.json")["features"]}
    owners = {test_identity(test_id)[1] for test_id, test in tests.items()
              if set(test["components"]) & component_ids}
    return sorted(owner for owner in owners if owner and statuses.get(owner) == "done")


def _stable(mapping: dict) -> list[dict[str, Any]]:
    for item in mapping.values():
        item["logical_ids"].sort()
        item["reasons"].sort()
    return sorted(mapping.values(), key=lambda item: (item["path"], item["case"] or ""))


def _add(root: Path, mapping: dict, path: str, case: str | None, logical_id: str | None, reason: str) -> None:
    path = normalized_path(root, path)
    if case is not None and (not isinstance(case, str) or not case.strip()):
        raise SelectionError("Registry case must be null or a non-empty string")
    item = mapping.setdefault((path, case), {"path": path, "case": case, "logical_ids": [], "reasons": []})
    if logical_id and logical_id not in item["logical_ids"]:
        item["logical_ids"].append(logical_id)
    if reason not in item["reasons"]:
        item["reasons"].append(reason)


def _impact_summary(impact: dict[str, Any], declared: list[str]) -> dict[str, Any]:
    return {"base_revision": impact["base_revision"], "changed_files": impact["changed_files"],
            "inferred_components": [{"id": component_id, "files": files}
                                    for component_id, files in impact["inferred_components"].items()
                                    if component_id not in declared],
            "dependency_suites": impact["dependency_suites"]}


def _component_tests(root: Path, components: dict[str, dict], tests: dict[str, dict], selected: list[str],
                     required: dict, add_test) -> list[str]:
    """Add selected components' unit suites, regressions and invariants; return component full reasons."""
    reasons = []
    for component_id in selected:
        component = components[component_id]
        for path in component["unit_test_paths"]:
            _add(root, required, path, None, None, f"component-unit:{component_id}")
        if component["full_suite_on_change"]:
            reasons.append(f"component-full-suite:{component_id}")
    for test_id, test in sorted(tests.items()):
        if test["status"] == "active" and set(test["components"]).intersection(selected):
            kind = test_identity(test_id)[0]
            if kind in {"regression", "invariant"}:
                add_test(required, test_id, f"affected-{kind}")
    return reasons


def _dependency_suites(root: Path, impact: dict[str, Any], required: dict) -> None:
    for suite in impact["dependency_suites"]:
        for reason in suite["reasons"]:
            _add(root, required, suite["path"], None, None, reason)


# 从当前合约、显式影响说明和起点以来的内容差异计算义务；只有真实 full 结果覆盖选择集时才可复用。
def build_selection(root: Path, feature_id: str, *, phase: str = "final") -> dict[str, Any]:
    if not re.fullmatch(r"F\d{3}", feature_id) or phase not in {"baseline", "final"}:
        raise SelectionError("invalid Feature ID or test-selection phase")
    detail = read_json(root / f"docs/features/{feature_id}.json")
    if phase == "final":
        acceptance_mode(detail)
    registry, components, tests = _read_registry(root)
    affected_components = sorted(set(detail["affected_components"]))
    if set(affected_components) - components.keys():
        raise SelectionError("Feature references unknown affected components")
    impact = change_impact(root, registry, feature_base_revision(root, feature_id, detail))
    selected = sorted(set(affected_components) | impact["inferred_components"].keys())
    required: dict[tuple[str, str | None], dict[str, Any]] = {}
    affected: dict[tuple[str, str | None], dict[str, Any]] = {}

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
        _add(root, mapping, test["path"], test.get("case"), test_id, reason)

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
    full_reasons = [*approved_impact["full_suite_reasons"], *impact["full_suite_reasons"],
                    *_component_tests(root, components, tests, selected, required, add_test)]
    for test_id, test in sorted(tests.items()):
        if test["status"] == "active" and set(test["components"]).intersection(selected):
            add_test(affected, test_id, "affected-component-contract")
    additions = sorted(approved_impact["additional_tests"],
                       key=lambda item: (item["id"], item["reason"]))
    for extra in additions:
        add_test(required, extra["id"], "approved-addition:" + extra["reason"])
    _dependency_suites(root, impact, required)
    for item in required.values():
        for reason in item["reasons"]:
            for logical_id in item["logical_ids"] or [None]:
                _add(root, affected, item["path"], item["case"], logical_id, reason)

    result = {"feature_id": feature_id, "phase": phase,
              "affected_components": affected_components,
              **_impact_summary(impact, affected_components),
              "touched_completed_features": touched_completed_features(root, tests, set(selected)),
              "required": _stable(required), "affected": _stable(affected),
              "selectors": deduplicate_selectors(root, [item["path"] for item in affected.values()]),
              "full_suite": {"required": bool(full_reasons), "reasons": sorted(set(full_reasons)),
                             "selectors": full_suite_selectors(root)}}
    return result


def build_changed_selection(root: Path) -> dict[str, Any]:
    """Select tests for changes since the verification point, without any Feature or evidence."""
    registry, components, tests = _read_registry(root)
    impact = change_impact(root, registry, verification_point(root))
    selected = sorted(impact["inferred_components"])
    required: dict[tuple[str, str | None], dict[str, Any]] = {}

    def add_test(mapping: dict, test_id: str, reason: str) -> None:
        _add(root, mapping, tests[test_id]["path"], tests[test_id].get("case"), test_id, reason)

    full_reasons = [*impact["full_suite_reasons"],
                    *_component_tests(root, components, tests, selected, required, add_test)]
    _dependency_suites(root, impact, required)
    stable = _stable(required)
    return {"feature_id": None, **_impact_summary(impact, []),
            "touched_completed_features": touched_completed_features(root, tests, set(selected)),
            "required": stable, "affected": stable,
            "selectors": deduplicate_selectors(root, [item["path"] for item in stable]),
            "full_suite": {"required": bool(full_reasons), "reasons": sorted(set(full_reasons)),
                           "selectors": full_suite_selectors(root)}}


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
