#!/usr/bin/env python3
"""显式检查 Feature 记录与测试引用；检查当前完整一致性。"""
# 沿用 Skill 中的现有调用路径；不读取工具事件或拦截写入。
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable

# 脚本在子目录直接启动时，显式加载本项目的共享包。
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.test_selection import acceptance_mode, read_json_value, SelectionError
from tools.lib.feature_evolution import (
    EvolutionError, TEST_REGISTRY_PATH, eligible_features, COMPONENT_ID,
    AC_TEST_ID, REGRESSION_TEST_ID, test_identity,
    validate_registry, validate_retirements, validate_revisions,
)

REPO_ROOT = Path(__file__).resolve().parents[3]
INDEX_FILE = REPO_ROOT / "docs" / "feature-list.json"
REVISIONS_FILE = REPO_ROOT / "docs" / "feature-list-revisions.json"
TEST_REGISTRY_FILE = REPO_ROOT / TEST_REGISTRY_PATH
DETAILS_DIR = REPO_ROOT / "docs" / "features"

ID_RE = re.compile(r"^F(\d{3})$")
AC_RE = re.compile(r"^AC(\d{2})$")

ALLOWED_STATUS = {"pending", "in_progress", "done", "obsolete", "obsolete_done", "blocked"}
ALLOWED_SCOPE = {"small", "medium"}
ALLOWED_ENGINEERING_CHANGE = {"bug", "refactor", "maintenance"}


def _rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def _error(message: str) -> None:
    print(f"[FEATURE] ERROR: {message}", file=sys.stderr)


def _load_json(path: Path) -> tuple[Any | None, bool]:
    try:
        return read_json_value(path), True
    except SelectionError as e:
        _error(str(e))
        return None, False


def _valid_iso8601(value: str) -> bool:
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
        return True
    except ValueError:
        return False


def _unique_string_list(value: Any, label: str, *, allow_empty: bool = True) -> tuple[bool, list[str]]:
    if not isinstance(value, list) or any(not isinstance(x, str) or not x.strip() for x in value):
        _error(f"{label} must be an array of non-empty strings")
        return False, []
    if not allow_empty and not value:
        _error(f"{label} must not be empty")
        return False, []
    if len(value) != len(set(value)):
        _error(f"{label} contains duplicates")
        return False, value
    return True, value


def _validate_index(data: Any) -> tuple[bool, dict[str, dict[str, Any]]]:
    ok = True
    entries: dict[str, dict[str, Any]] = {}
    if not isinstance(data, dict):
        _error("docs/feature-list.json root must be an object")
        return False, entries

    meta = data.get("meta")
    features = data.get("features")
    if not isinstance(meta, dict):
        _error("docs/feature-list.json meta must be an object")
        ok = False
    if not isinstance(features, list):
        _error("docs/feature-list.json features must be an array")
        return False, entries

    for pos, entry in enumerate(features, start=1):
        prefix = f"docs/feature-list.json features[{pos - 1}]"
        if not isinstance(entry, dict):
            _error(f"{prefix} must be an object")
            ok = False
            continue
        fid = entry.get("id")
        if not isinstance(fid, str) or not ID_RE.fullmatch(fid):
            _error(f"{prefix}.id must match F followed by exactly three digits")
            ok = False
            continue
        if fid in entries:
            _error(f"duplicate Feature id {fid}")
            ok = False
            continue
        entries[fid] = entry
        if fid != f"F{pos:03d}":
            _error(f"Feature ids must remain sequential: position {pos} is {fid}, expected F{pos:03d}")
            ok = False
        if not isinstance(entry.get("title"), str) or not entry["title"].strip():
            _error(f"{fid}.title must be a non-empty string")
            ok = False
        status = entry.get("status")
        status_valid = isinstance(status, str) and status in ALLOWED_STATUS
        if not status_valid:
            _error(f"{fid}.status {status!r} is invalid")
            ok = False
        scope = entry.get("estimated_scope")
        if not isinstance(scope, str) or scope not in ALLOWED_SCOPE:
            _error(f"{fid}.estimated_scope {scope!r} is invalid; final values are small or medium")
            ok = False
        deps_ok, deps = _unique_string_list(entry.get("depends_on"), f"{fid}.depends_on")
        ok &= deps_ok
        if not status_valid:
            continue
        completed_at = entry.get("completed_at")
        if status in {"done", "obsolete_done"}:
            if not isinstance(completed_at, str) or not completed_at.strip() or not _valid_iso8601(completed_at):
                _error(f"{fid}.completed_at must be valid ISO 8601 when status is {status}")
                ok = False
        elif completed_at is not None:
            _error(f"{fid}.completed_at must be null when status is {status}")
            ok = False

    for fid, entry in entries.items():
        deps = entry.get("depends_on", [])
        if not isinstance(deps, list):
            continue
        for dep in deps:
            if not isinstance(dep, str) or dep not in entries:
                _error(f"{fid}.depends_on references missing Feature {dep}")
                ok = False
            elif dep == fid:
                _error(f"{fid} cannot depend on itself")
                ok = False
            elif (isinstance(entry.get("status"), str) and isinstance(entries[dep].get("status"), str)
                  and entry["status"] in {"pending", "in_progress", "blocked"}
                  and entries[dep]["status"] in {"obsolete", "obsolete_done"}):
                _error(f"{fid}.depends_on references obsolete prerequisite {dep}; synchronize its replacement")
                ok = False

    state: dict[str, int] = {}
    def visit(fid: str, stack: list[str]) -> None:
        nonlocal ok
        mark = state.get(fid, 0)
        if mark == 1:
            _error(f"Feature dependency cycle detected: {' -> '.join(stack + [fid])}")
            ok = False
            return
        if mark == 2:
            return
        state[fid] = 1
        deps = entries[fid].get("depends_on", [])
        for dep in deps if isinstance(deps, list) else []:
            if isinstance(dep, str) and dep in entries:
                visit(dep, stack + [fid])
        state[fid] = 2
    for fid in entries:
        visit(fid, [])

    return ok, entries


def _validate_criterion(fid: str, pos: int, item: Any, path: Path) -> tuple[bool, str | None, set[str]]:
    label = f"{_rel(path)}.acceptance_criteria[{pos}]"
    if not isinstance(item, dict):
        _error(f"{label} must be an object with id/text/verification")
        return False, None, set()

    ok = True
    ac_id = item.get("id")
    if not isinstance(ac_id, str) or not AC_RE.fullmatch(ac_id):
        _error(f"{label}.id must match AC followed by two digits")
        ok = False
    text = item.get("text")
    if not isinstance(text, str) or not text.strip():
        _error(f"{label}.text must be a non-empty string")
        ok = False
    verification = item.get("verification")
    automated: set[str] = set()
    if not isinstance(verification, dict):
        _error(f"{label}.verification must be an object")
        ok = False
    else:
        tests_ok, tests = _unique_string_list(verification.get("automated_tests"), f"{label}.verification.automated_tests")
        manual_ok, _ = _unique_string_list(verification.get("manual_checks"), f"{label}.verification.manual_checks")
        ok &= tests_ok and manual_ok
        automated = set(tests)
        if isinstance(ac_id, str):
            for tid in tests:
                m = AC_TEST_ID.fullmatch(tid)
                if not m or m.group(1) != fid or m.group(2) != ac_id:
                    _error(f"{label} automated test {tid!r} must belong to {fid}-{ac_id}")
                    ok = False
    return ok, ac_id if isinstance(ac_id, str) else None, automated


def _validate_detail(path: Path, data: Any) -> tuple[bool, str | None, dict[str, Any]]:
    info: dict[str, Any] = {"criteria": set(), "automated": set(), "regressions": set(), "additional_tests": set(), "components": set()}
    if not isinstance(data, dict):
        _error(f"{_rel(path)} root must be an object")
        return False, None, info

    ok = True
    fid = data.get("id")
    if not isinstance(fid, str) or not ID_RE.fullmatch(fid):
        _error(f"{_rel(path)}.id must match F followed by exactly three digits")
        ok = False
        fid = path.stem
    elif fid != path.stem:
        _error(f"{_rel(path)} id {fid} does not match filename stem {path.stem}")
        ok = False

    if not isinstance(data.get("description"), str) or not data["description"].strip():
        _error(f"{_rel(path)}.description must be a non-empty string")
        ok = False

    components = data.get("affected_components")
    comps_ok, comps = _unique_string_list(components, f"{_rel(path)}.affected_components", allow_empty=False)
    ok &= comps_ok
    for comp in comps:
        if not COMPONENT_ID.fullmatch(comp):
            _error(f"{_rel(path)} affected component {comp!r} must be lower_snake_case")
            ok = False
    info["components"] = set(comps)

    criteria = data.get("acceptance_criteria")
    if not isinstance(criteria, list) or not criteria:
        _error(f"{_rel(path)}.acceptance_criteria must be a non-empty array")
        ok = False
    else:
        seen_ac: set[str] = set()
        last_number = 0
        for pos, item in enumerate(criteria):
            c_ok, ac_id, automated = _validate_criterion(fid, pos, item, path)
            ok &= c_ok
            info["automated"].update(automated)
            if ac_id:
                if ac_id in seen_ac:
                    _error(f"{_rel(path)} duplicate criterion id {ac_id}")
                    ok = False
                elif match := AC_RE.fullmatch(ac_id):
                    # Gaps are allowed so a removed AC's ID is never reused by a later criterion.
                    number = int(match.group(1))
                    if number <= last_number:
                        _error(f"{_rel(path)}.acceptance_criteria[{pos}].id must increase; found {ac_id} after AC{last_number:02d}")
                        ok = False
                    last_number = max(last_number, number)
                seen_ac.add(ac_id)
        info["criteria"] = seen_ac

    verification = data.get("verification")
    if not isinstance(verification, dict):
        _error(f"{_rel(path)}.verification must be an object")
        ok = False
    else:
        rt_ok, regressions = _unique_string_list(verification.get("regression_tests"), f"{_rel(path)}.verification.regression_tests")
        ok &= rt_ok
        for tid in regressions:
            m = REGRESSION_TEST_ID.fullmatch(tid)
            if not m or m.group(1) != fid:
                _error(f"{_rel(path)} regression test {tid!r} must use {fid}-RTxx")
                ok = False
        info["regressions"] = set(regressions)
        manual_regression = verification.get("manual_regression")
        if manual_regression is not None and (not isinstance(manual_regression, str) or not manual_regression.strip()):
            _error(f"{_rel(path)}.verification.manual_regression must be null or a non-empty string")
            ok = False
        if "test_impact" in verification:
            impact = verification["test_impact"]
            label = f"{_rel(path)}.verification.test_impact"
            if not isinstance(impact, dict) or set(impact) != {"additional_tests", "full_suite_reasons"}:
                _error(f"{label} requires exactly additional_tests/full_suite_reasons")
                ok = False
            else:
                reasons_ok, _ = _unique_string_list(impact["full_suite_reasons"], f"{label}.full_suite_reasons")
                ok &= reasons_ok
                additions = impact["additional_tests"]
                if not isinstance(additions, list):
                    _error(f"{label}.additional_tests must be an array")
                    ok = False
                else:
                    for addition in additions:
                        if (not isinstance(addition, dict) or set(addition) != {"id", "reason"}
                                or any(not isinstance(addition[key], str) or not addition[key].strip() for key in ("id", "reason"))):
                            _error(f"{label}.additional_tests entries require exactly non-empty id/reason")
                            ok = False
                            continue
                        if addition["id"] in info["additional_tests"]:
                            _error(f"{label}.additional_tests contains duplicate ID {addition['id']}")
                            ok = False
                        info["additional_tests"].add(addition["id"])

    if not isinstance(data.get("source"), str) or not data["source"].strip():
        _error(f"{_rel(path)}.source must be a non-empty string")
        ok = False
    if not isinstance(data.get("notes"), str):
        _error(f"{_rel(path)}.notes must be a string")
        ok = False
    engineering_change = data.get("engineering_change")
    if engineering_change is not None and (not isinstance(engineering_change, str)
                                           or engineering_change not in ALLOWED_ENGINEERING_CHANGE):
        _error(f"{_rel(path)}.engineering_change {engineering_change!r} is invalid")
        ok = False
    diagnosis = data.get("bug_diagnosis")
    info["bug_diagnosis"] = diagnosis
    if diagnosis is not None:
        expected_fields = {"actual", "expected", "source", "reproduction", "root_cause"}
        if engineering_change != "bug" or not isinstance(diagnosis, dict) or set(diagnosis) != expected_fields:
            _error(f"{_rel(path)}.bug_diagnosis requires bug mode and exactly actual/expected/source/reproduction/root_cause")
            ok = False
        else:
            for field in ("actual", "expected", "source"):
                if not isinstance(diagnosis[field], str) or not diagnosis[field].strip():
                    _error(f"{_rel(path)}.bug_diagnosis.{field} must be non-empty")
                    ok = False
            steps_ok, _ = _unique_string_list(diagnosis["reproduction"], f"{_rel(path)}.bug_diagnosis.reproduction", allow_empty=False)
            ok &= steps_ok
            cause = diagnosis["root_cause"]
            if cause is not None and (not isinstance(cause, str) or not cause.strip()):
                _error(f"{_rel(path)}.bug_diagnosis.root_cause must be null or non-empty")
                ok = False
    info["engineering_change"] = engineering_change
    info["acceptance_mode"] = verification.get("acceptance_mode") if isinstance(verification, dict) else None
    # 草案可暂未决定；已作出的决定必须与检查项一致，完成时必须有决定。
    if info["acceptance_mode"] is not None and ok:
        try:
            acceptance_mode(data)
        except (SelectionError, TypeError, AttributeError) as exc:
            _error(f"{_rel(path)}: {exc}")
            ok = False
    if isinstance(verification, dict):
        info["manual_regression"] = verification.get("manual_regression")
    else:
        info["manual_regression"] = None
    return ok, fid, info


def _validate_test_registry(data: Any, entries: dict[str, dict[str, Any]], details: dict[str, dict[str, Any]]) -> tuple[bool, dict[str, dict[str, Any]], set[str]]:
    try:
        validate_registry(data, REPO_ROOT)
    except EvolutionError as exc:
        _error(f"docs/test-registry.json: {exc}")
        return False, {}, set()
    ok = True
    component_ids = {component["id"] for component in data["components"]}
    registry_tests = {test["id"]: test for test in data["tests"]}
    for tid, test in registry_tests.items():
        kind, source_feature, criterion_id = test_identity(tid)
        status = test["status"]
        if source_feature is not None and source_feature not in entries:
            _error(f"test {tid} references missing Feature {source_feature}")
            ok = False
        # Retired IDs keep their historical AC; the replacement chain remains mandatory.
        if (kind == "acceptance" and status != "retired" and source_feature in details
                and criterion_id not in details[source_feature]["criteria"]):
            _error(f"acceptance test {tid} references missing criterion {source_feature}-{criterion_id}")
            ok = False

    return ok, registry_tests, component_ids


# 聚合索引、详情、Registry 和演进关系；跨文件规则在这里汇合，避免入口各自判断。
def _validate_all(completion_feature: str | None = None) -> bool:
    ok = True
    index_data, loaded = _load_json(INDEX_FILE)
    ok &= loaded
    index_ok, entries = _validate_index(index_data) if loaded else (False, {})
    ok &= index_ok

    revisions_data, loaded = _load_json(REVISIONS_FILE)
    ok &= loaded
    revisions: dict[str, dict] = {}
    if loaded and index_ok:
        try:
            revisions = validate_revisions(revisions_data, entries)
        except EvolutionError as exc:
            _error(str(exc))
            ok = False

    details: dict[str, dict[str, Any]] = {}
    detail_ids: set[str] = set()
    if DETAILS_DIR.exists():
        # 同目录还有设计稿与 F0XX-evidence.json，只读取 F0XX.json 详情。
        for path in sorted(p for p in DETAILS_DIR.glob("F*.json") if re.fullmatch(r"F\d{3}\.json", p.name)):
            data, loaded = _load_json(path)
            ok &= loaded
            if not loaded:
                continue
            d_ok, fid, info = _validate_detail(path, data)
            ok &= d_ok
            if fid:
                if fid in detail_ids:
                    _error(f"duplicate detail id {fid}")
                    ok = False
                detail_ids.add(fid)
                details[fid] = info

    index_ids = set(entries)
    only_index = sorted(index_ids - detail_ids)
    only_detail = sorted(detail_ids - index_ids)
    if only_index or only_detail:
        msg = f"Feature index/detail sets differ (index without detail: {only_index}; detail without index: {only_detail})"
        _error(msg)
        ok = False

    registry_data, loaded = _load_json(TEST_REGISTRY_FILE)
    ok &= loaded
    cat_ok, registry_tests, component_ids = _validate_test_registry(registry_data, entries, details) if loaded else (False, {}, set())
    ok &= cat_ok
    if cat_ok and index_ok:
        try:
            validate_retirements(registry_tests, entries, revisions,
                                {fid: info["automated"] | info["regressions"] for fid, info in details.items()})
        except EvolutionError as exc:
            _error(str(exc))
            ok = False
    if cat_ok and index_ok:
        for tid, cat in registry_tests.items():
            owner = test_identity(tid)[1]
            if cat.get("status") == "planned" and owner in entries and entries[owner].get("status") not in {"pending", "in_progress", "blocked"}:
                _error(f"planned test {tid} belongs to {entries[owner].get('status')} Feature {owner}; implement, retire or remove it")
                ok = False
    if completion_feature is not None and completion_feature not in entries:
        _error(f"completion Feature {completion_feature} does not exist")
        ok = False

    for fid, info in details.items():
        for cid in info["components"]:
            if cid not in component_ids:
                _error(f"{fid}.affected_components references missing test-registry component {cid}")
                ok = False
        status = entries.get(fid, {}).get("status")
        if (status == "done" or fid == completion_feature) and info.get("acceptance_mode") is None:
            _error(f"completion Feature {fid} requires a decided verification.acceptance_mode")
            ok = False
        # Approved external scope is required coverage, but never changes ownership
        # of a Feature's own AC/regression mapping used by retirement migrations.
        referenced = set(info["automated"]) | set(info["regressions"]) | set(info["additional_tests"])
        for tid in referenced:
            cat = registry_tests.get(tid)
            if cat is None:
                _error(f"{fid} references test {tid} missing from docs/test-registry.json")
                ok = False
                continue
            allowed = {"active"} if fid == completion_feature else {"active", "retired"}
            if (status == "done" or fid == completion_feature) and cat.get("status") not in allowed:
                _error(f"Feature {fid} references test {tid} with status {cat.get('status')!r}; expected {sorted(allowed)}")
                ok = False
        if info.get("engineering_change") == "bug" and (status == "done" or fid == completion_feature):
            if not info["regressions"] and not info.get("manual_regression"):
                _error(f"done Bug Feature {fid} requires regression_tests or manual_regression")
                ok = False
            if not isinstance(info.get("bug_diagnosis"), dict) or not info["bug_diagnosis"].get("root_cause"):
                _error(f"completion Bug Feature {fid} requires a confirmed bug_diagnosis.root_cause")
                ok = False

    return bool(ok)


def _parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT, help="project directory to validate")
    parser.add_argument("--completion-feature", metavar="FXXX", help="require active coverage for this current completion")
    parser.add_argument("--eligible", action="store_true", help="print dependency-eligible pending Feature IDs as JSON")
    return parser.parse_args(list(argv))


def main() -> int:
    global REPO_ROOT, INDEX_FILE, REVISIONS_FILE, TEST_REGISTRY_FILE, DETAILS_DIR
    args = _parse_args(sys.argv[1:])
    REPO_ROOT = args.repo_root.resolve()
    INDEX_FILE = REPO_ROOT / "docs/feature-list.json"
    REVISIONS_FILE = REPO_ROOT / "docs/feature-list-revisions.json"
    TEST_REGISTRY_FILE = REPO_ROOT / TEST_REGISTRY_PATH
    DETAILS_DIR = REPO_ROOT / "docs/features"
    if not _validate_all(completion_feature=args.completion_feature):
        return 2
    if args.eligible:
        # --eligible 的标准输出只有 JSON，供调用方直接解析。
        data, _ = _load_json(INDEX_FILE)
        print(json.dumps(eligible_features({entry["id"]: entry for entry in data["features"]})))
    else:
        print("FEATURE LIST CHECK: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
