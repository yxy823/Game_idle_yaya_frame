"""Read one run result and its original gdUnit reports.

These are local execution records, not a signature against an actor who can
rewrite the project. Current content, actual case coverage and unresolved
failures matter; duplicated manifests and receipts do not add authority.
"""
from __future__ import annotations

import hashlib
import os
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

from tools.lib.atomic_json import write_json
from tools.lib.verification_snapshot import EvidenceError, current_snapshot, utc_now
from tools.lib.test_selection import execution_selectors, normalized_path, read_json, build_selection


class RunEvidenceError(ValueError):
    """The recorded execution cannot prove the requested test obligations."""


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)
    return "sha256:" + digest.hexdigest()


def _count(element: ET.Element, name: str, *, optional: bool = False) -> int:
    value = element.get(name, "0" if optional else "")
    if not value.isdecimal():
        raise RunEvidenceError(f"invalid or missing JUnit {element.tag}.{name}")
    return int(value)


def _suite_path(suite: ET.Element) -> str:
    if suite.get("file"):
        return suite.get("file", "").replace("\\", "/").removeprefix("res://")
    package = suite.get("package", "").replace("\\", "/").removeprefix("res://").strip("/")
    name = suite.get("name", "")
    name = name if name.endswith(".gd") else name + ".gd"
    return f"{package}/{name}" if package else name


def read_junit_cases(path: Path) -> list[dict[str, str]]:
    """Read identities/status from actual testcase nodes and reconcile counters."""
    try:
        root = ET.parse(path).getroot()
    except (OSError, ET.ParseError) as exc:
        raise RunEvidenceError(f"cannot read JUnit: {exc}") from exc
    if root.tag not in {"testsuites", "testsuite"}:
        raise RunEvidenceError("JUnit root must be testsuites or testsuite")
    suites = root.findall("testsuite") if root.tag == "testsuites" else [root]
    cases: list[dict[str, str]] = []
    for suite in suites:
        nodes = suite.findall("testcase")
        if _count(suite, "tests") != len(nodes):
            raise RunEvidenceError("JUnit suite count does not match actual testcase nodes")
        suite_cases = []
        for case in nodes:
            case_name = case.get("name", "")
            suite_path = case.get("file", _suite_path(suite)).replace("\\", "/").removeprefix("res://")
            if not case_name or not suite_path:
                raise RunEvidenceError("JUnit testcase has no stable path/name identity")
            failed = case.find("failure") is not None or case.find("error") is not None
            status = "failed" if failed else "skipped" if case.find("skipped") is not None else "passed"
            suite_cases.append({"id": f"{suite_path}::{case_name}", "path": suite_path,
                                "case": case_name, "status": status})
        skipped = sum(case["status"] == "skipped" for case in suite_cases)
        if _count(suite, "skipped", optional=True) != skipped:
            raise RunEvidenceError("JUnit skipped count disagrees with testcase nodes")
        # GdUnit can report several assertion failures per testcase. Counts need
        # not equal failed *tests*, but green counters can never hide failed nodes.
        failures = _count(suite, "failures", optional=True)
        errors = _count(suite, "errors", optional=True)
        if (failures + errors > 0) != any(case["status"] == "failed" for case in suite_cases):
            raise RunEvidenceError("JUnit error/failure counters disagree with testcase nodes")
        if _count(suite, "flaky", optional=True):
            raise RunEvidenceError("JUnit reports flaky tests")
        cases.extend(suite_cases)
    if _count(root, "tests") != len(cases):
        raise RunEvidenceError("JUnit root count does not match actual testcase nodes")
    if root.tag == "testsuites":
        for key in ("failures", "skipped", "flaky"):
            if _count(root, key, optional=True) != sum(_count(suite, key, optional=True) for suite in suites):
                raise RunEvidenceError(f"JUnit root/suite {key} mismatch")
    if len({case["id"] for case in cases}) != len(cases):
        raise RunEvidenceError("duplicate JUnit testcase identity")
    if not cases or not any(case["status"] != "skipped" for case in cases):
        raise RunEvidenceError("zero tests discovered or executed")
    return sorted(cases, key=lambda case: case["id"])


def _without_strings(source: str) -> str:
    """Preserve newlines while excluding comments/string examples from inventory."""
    token = re.compile(r'"""[\s\S]*?"""|\x27\x27\x27[\s\S]*?\x27\x27\x27|"(?:\\.|[^"\\\n])*"|\x27(?:\\.|[^\x27\\\n])*\x27|#[^\n]*')
    return token.sub(lambda match: "".join("\n" if char == "\n" else " " for char in match.group()), source)


def _gdscript_paths(directory: Path) -> list[Path]:
    """Use Godot-visible directories for script class and suite discovery."""
    paths = []
    for current, directories, files in os.walk(directory):
        directories[:] = [name for name in directories if not name.startswith(".")]
        if ".gdignore" in files:
            directories.clear()
            continue
        paths.extend(Path(current) / name for name in files if name.endswith(".gd") and not name.startswith("."))
    return paths


class _SuiteInheritance:
    """Resolve script/class-name ancestry without treating test_* as a type marker.

    Native parsing and runtime discovery remain authoritative. Unsupported base
    expressions fail closed instead of silently removing declaration coverage.
    """
    def __init__(self, root: Path) -> None:
        self.root = root
        self.classes: dict[str, Path] | None = None
        self.sources: dict[Path, str] = {}
        self.resolved: dict[Path, bool] = {}

    def source(self, path: Path) -> str:
        if path not in self.sources:
            self.sources[path] = path.read_text(encoding="utf-8")
        return self.sources[path]

    def class_path(self, name: str) -> Path | None:
        if self.classes is None:
            self.classes = {}
            for path in _gdscript_paths(self.root):
                match = re.search(r"^class_name[ \t]+(\w+)\b", _without_strings(self.source(path)), re.MULTILINE)
                if match:
                    if match[1] in self.classes:
                        raise RunEvidenceError(f"ambiguous GDScript class_name: {match[1]}")
                    self.classes[match[1]] = path
        return self.classes.get(name)

    def is_suite(self, path: Path, visiting: frozenset[Path] = frozenset()) -> bool:
        path = path.resolve()
        if not path.is_relative_to(self.root):
            raise RunEvidenceError(f"suite script leaves repository: {path}")
        if path in self.resolved:
            return self.resolved[path]
        if path in visiting:
            raise RunEvidenceError(f"cyclic GDScript inheritance: {path}")
        source = self.source(path)
        match = re.search(r"^(?:class_name[ \t]+\w+[ \t]+)?extends\b", _without_strings(source), re.MULTILINE)
        result = False
        if match:
            expression = source[match.end():].splitlines()[0].lstrip(" \t")
            base = re.fullmatch(r'''(?:"([^"\n]+)"|'([^'\n]+)'|([A-Za-z_]\w*))[ \t]*(?:#[^\n]*)?''', expression)
            if base is None:
                raise RunEvidenceError(f"cannot resolve GDScript suite inheritance: {path}")
            if base[3] == "GdUnitTestSuite":
                result = True
            else:
                location = base[1] or base[2]
                if location:
                    candidate = self.root / location.removeprefix("res://") if location.startswith("res://") else path.parent / location
                    candidate = candidate.resolve()
                    if not candidate.is_relative_to(self.root):
                        raise RunEvidenceError(f"suite base script leaves repository: {location}")
                    relative = candidate.relative_to(self.root).as_posix()
                    parent = self.root / normalized_path(self.root, relative)
                    result = relative == "addons/gdUnit4/src/GdUnitTestSuite.gd" or self.is_suite(parent, visiting | {path})
                else:
                    parent = self.class_path(base[3])
                    result = parent is not None and self.is_suite(parent, visiting | {path})
        self.resolved[path] = result
        return result


# 静态声明是应执行集合的边界，还需与引擎实际 discovery 对照，不能当作已运行。
def expected_gdunit_cases(root: Path, selectors: list[str]) -> list[dict[str, str]]:
    """Supplement runtime discovery with declared root-level GDScript test methods.

    This protects an entire selected suite from silently vanishing from JUnit.
    It is not runtime discovery; the adapter records the complete expanded set.
    Parameterized cases may expand one declaration into multiple runtime cases.
    """
    root = root.resolve()
    inheritance = _SuiteInheritance(root)
    paths: set[Path] = set()
    for selector in selectors:
        path = root / normalized_path(root, selector)
        paths.update(_gdscript_paths(path) if path.is_dir() else [path])
    expected = []
    for path in sorted(paths):
        if path.suffix != ".gd":
            raise RunEvidenceError(f"GdUnit selector is not a GDScript suite: {path}")
        source = _without_strings(inheritance.source(path))
        names = re.findall(r"^(?:static\s+)?func\s+(test_\w+)\s*\(", source, re.MULTILINE)
        if not names or not inheritance.is_suite(path):
            continue
        relative = path.relative_to(root).as_posix()
        expected.extend({"path": relative, "case": name} for name in names)
    return sorted(expected, key=lambda item: (item["path"], item["case"]))


def _matches(case: dict[str, str], obligation: dict[str, Any]) -> bool:
    path = obligation["path"]
    if not (case["path"] == path or case["path"].startswith(path.rstrip("/") + "/")):
        return False
    wanted = obligation.get("case")
    return wanted is None or case["case"] == wanted or case.get("method") == wanted


def verify_runtime_discovery(path: Path, engine_pid: int, cases: list[dict[str, str]]) -> list[dict[str, str]]:
    """Reconcile the runner's complete expanded discovery with actual JUnit IDs."""
    try:
        discovery = read_json(path)
    except (ValueError, OSError) as exc:
        raise RunEvidenceError(f"cannot read runtime discovery: {exc}") from exc
    if discovery.get("schema_version") != 1 or type(engine_pid) is not int or engine_pid <= 0:
        raise RunEvidenceError("invalid runtime discovery schema or process identity")
    if discovery.get("engine_pid") != engine_pid:
        raise RunEvidenceError("runtime discovery belongs to a different engine process")
    records = discovery.get("cases")
    if not isinstance(records, list) or not records:
        raise RunEvidenceError("runtime discovery found zero tests")
    indexed: dict[str, dict[str, str]] = {}
    for record in records:
        if not isinstance(record, dict) or set(record) != {"id", "path", "case", "method"}:
            raise RunEvidenceError("malformed runtime discovery testcase")
        if any(not isinstance(value, str) or not value for value in record.values()):
            raise RunEvidenceError("runtime discovery testcase has no stable identity")
        if record["id"] != record["path"] + "::" + record["case"] or record["id"] in indexed:
            raise RunEvidenceError("duplicate or inconsistent runtime discovery identity")
        indexed[record["id"]] = record
    if set(indexed) != {case["id"] for case in cases}:
        raise RunEvidenceError("actual runtime discovery and JUnit testcase sets differ")
    return [{**case, "method": indexed[case["id"]]["method"]} for case in cases]


def require_coverage(cases: list[dict[str, str]], obligations: list[dict[str, Any]]) -> list[str]:
    covered: set[str] = set()
    for obligation in obligations:
        matches = [case for case in cases if _matches(case, obligation)]
        label = obligation["path"] + ("::" + obligation["case"] if obligation.get("case") else "")
        if not matches:
            raise RunEvidenceError(f"required test/suite was not discovered: {label}")
        if any(case["status"] != "passed" for case in matches):
            raise RunEvidenceError(f"required test/suite failed or was skipped: {label}")
        covered.update(case["id"] for case in matches)
    return sorted(covered)


def artifact_reference(directory: Path, path: Path) -> dict[str, str]:
    relative = path.resolve().relative_to(directory.resolve()).as_posix()
    return {"path": relative, "sha256": file_hash(path)}


def run_history_directory(root: Path, feature_id: str | None) -> Path:
    if feature_id is not None and (not isinstance(feature_id, str) or not re.fullmatch(r"F\d{3}", feature_id)):
        raise RunEvidenceError("Feature ID must match F0XX")
    return root / "reports/gdunit-wrapper" / (feature_id if feature_id is not None else "focused")


def _run_records(root: Path, feature_id: str | None) -> tuple[list[dict], list[str]]:
    """Read usable run headers and report errors without discarding their paths."""
    records, errors = [], []
    for path in run_history_directory(root, feature_id).glob("run-*/result.json"):
        try:
            record = read_json(path)
            if type(record.get("schema_version")) is not int or record["schema_version"] != 1:
                raise RunEvidenceError("unsupported run result schema")
            if record.get("run_id") != path.parent.name:
                raise RunEvidenceError("run identity does not match its directory")
            if record.get("feature_id") != feature_id:
                raise RunEvidenceError("run Feature does not match its history directory")
            if type(record.get("sequence")) is not int or record["sequence"] < 1:
                raise RunEvidenceError("run sequence must be a positive integer")
            # Validate every field used to classify history before filtering out
            # baseline, passed or older-snapshot runs. Missing metadata is not
            # evidence that a failed attempt belongs to some other verification.
            if record.get("phase") not in ("baseline", "final"):
                raise RunEvidenceError("run phase must be baseline or final")
            if record.get("status") not in ("running", "failed", "passed"):
                raise RunEvidenceError("run status must be running, failed or passed")
            if record.get("scope") not in ("auto", "required", "affected", "full"):
                raise RunEvidenceError("run scope must be auto, required, affected or full")
            if (not isinstance(record.get("selectors"), list)
                    or any(not isinstance(item, str) or not item for item in record["selectors"])):
                raise RunEvidenceError("run selectors must be a list of nonempty paths")
            preparation = (record.get("command") == [] and record["selectors"] == []
                           and record.get("process", {}) is None)
            if feature_id is not None and record["scope"] == "auto":
                if record["status"] == "passed" or not preparation:
                    raise RunEvidenceError("invalid auto preparation record: " + record["run_id"])
            if "snapshot" not in record:
                raise RunEvidenceError("run snapshot is missing")
            snapshot = record["snapshot"]
            if snapshot is None:
                # start_run can fail to obtain a snapshot before any execution.
                # Keep that explicit failure distinct from damaged history.
                if feature_id is not None and not (
                        record["status"] == "failed" and preparation
                        and isinstance(record.get("errors"), list) and record["errors"]
                        and all(isinstance(error, str) and error for error in record["errors"])):
                    raise RunEvidenceError("null run snapshot requires a failed preparation")
            elif (not isinstance(snapshot, dict)
                  or not isinstance(snapshot.get("working_tree_fingerprint"), str)
                  or not re.fullmatch(r"sha256:[0-9a-f]{64}", snapshot["working_tree_fingerprint"])):
                raise RunEvidenceError("run snapshot has no valid working tree fingerprint")
            records.append(record)
        except (ValueError, OSError) as error:
            errors.append(f"invalid run history {path}: {error}")
    return records, errors


def start_run(root: Path, directory: Path, feature_id: str | None,
              phase: str, scope: str) -> dict:
    # Scan before the first write so this run cannot select itself as history.
    # History damage is reported without preventing a new measurement. Completion
    # independently rejects referenced damage and unresolved/unknown history.
    started_at = utc_now()
    records, history_errors = _run_records(root, feature_id)
    for error in history_errors:
        print("WARNING: " + error, file=sys.stderr)
    errors = []
    snapshot = None
    try:
        snapshot = current_snapshot(root) if feature_id else None
    except (EvidenceError, ValueError, OSError) as error:
        errors.append(str(error))
    result = {"schema_version": 1, "run_id": directory.name,
              "sequence": 1 + max((item["sequence"] for item in records), default=0),
              "feature_id": feature_id, "phase": phase, "scope": scope,
              "snapshot": snapshot,
              "started_at": started_at, "finished_at": utc_now() if errors else None,
              "command": [], "selectors": [], "status": "failed" if errors else "running",
              "process": None, "errors": errors, "artifacts": {}}
    write_json(directory / "result.json", result)
    return result


def result_reference(root: Path, path: Path) -> dict[str, str]:
    return artifact_reference(root, path)


def _checked_cases(root: Path, directory: Path, result: dict) -> list[dict]:
    """Use raw reports once; result.json does not duplicate their case arrays."""
    process = result.get("process") or {}
    if process.get("returncode") != 0 or process.get("timed_out") is not False:
        raise RunEvidenceError("test process failed or timed out")
    files = {}
    for name, reference in result["artifacts"].items():
        path = (directory / reference["path"]).resolve()
        if not path.is_relative_to(directory.resolve()) or not path.is_file():
            raise RunEvidenceError("artifact missing or outside its run directory")
        if file_hash(path) != reference["sha256"]:
            raise RunEvidenceError(f"run artifact changed after execution: {path.name}")
        files[name] = path
    if set(files) != {"junit", "discovery", "diagnostics", "engine_log"}:
        raise RunEvidenceError("run is missing original test reports")
    discovery = read_json(files["discovery"])
    if discovery.get("run_id") != result["run_id"]:
        raise RunEvidenceError("discovery belongs to a different run")
    cases = verify_runtime_discovery(files["discovery"], process.get("engine_pid"),
                                     read_junit_cases(files["junit"]))
    if any(case["status"] != "passed" for case in cases):
        raise RunEvidenceError("run contains failed or skipped tests")
    require_coverage(cases, expected_gdunit_cases(root, result["selectors"]))
    require_coverage(cases, [{"path": path, "case": None} for path in result["selectors"]])
    from tools.lib.gdunit_diagnostics import unexpected_diagnostics
    import json
    first = json.loads(files["diagnostics"].read_text(encoding="utf-8").splitlines()[0])
    if first.get("engine_pid") != process.get("engine_pid"):
        raise RunEvidenceError("diagnostics belong to a different engine process")
    unexpected = unexpected_diagnostics(files["engine_log"].read_text(encoding="utf-8"), files["junit"])
    if unexpected:
        raise RunEvidenceError("unexpected engine diagnostics: " + "; ".join(unexpected))
    return cases


def finish_run(root: Path, directory: Path, result: dict, *,
               process: dict | None = None, errors: list[str] | None = None,
               required_test: str | None = None) -> dict:
    """Finalize the same file even on failure; preserve all raw artifacts."""
    result["process"] = process
    result["errors"] = list(errors or [])
    reports = list(directory.glob("report_*/results.xml"))
    paths = {"engine_log": directory / "engine.log", "discovery": directory / "discovery.json"}
    if len(reports) == 1:
        paths.update(junit=reports[0], diagnostics=reports[0].parent / "diagnostics.jsonl")
    else:
        result["errors"].append(f"expected one current JUnit report, found {len(reports)}")
    result["artifacts"] = {key: artifact_reference(directory, path)
                           for key, path in paths.items() if path.is_file()}
    try:
        if not result["errors"]:
            cases = _checked_cases(root, directory, result)
            if required_test:
                path, separator, case = required_test.rpartition("::")
                if not separator or not path or not case:
                    raise RunEvidenceError("required test must use <suite-path>::<test-case>")
                require_coverage(cases, [{"path": path.removeprefix("res://"), "case": case}])
        if result["snapshot"] and current_snapshot(root)["working_tree_fingerprint"] != result["snapshot"]["working_tree_fingerprint"]:
            result["errors"].append("source changed during test execution")
    except (EvidenceError, ValueError, OSError, KeyError, TypeError, IndexError) as error:
        result["errors"].append(str(error))
    result["status"] = "failed" if result["errors"] else "passed"
    result["finished_at"] = utc_now()
    write_json(directory / "result.json", result)
    return result


def verify_run(root: Path, reference: dict[str, str], selection: dict,
               snapshot: dict) -> tuple[dict, list[dict]]:
    path = (root / reference["path"]).resolve()
    history_directory = run_history_directory(root, selection["feature_id"]).resolve()
    if (path.parent.parent != history_directory or path.name != "result.json"
            or not path.parent.name.startswith("run-") or not path.is_file()):
        raise RunEvidenceError(f"run result must exist at {history_directory}/run-<id>/result.json")
    if file_hash(path) != reference["sha256"]:
        raise RunEvidenceError("run result changed after recording")
    result = read_json(path)
    if result.get("schema_version") != 1 or result.get("run_id") != path.parent.name:
        raise RunEvidenceError("invalid run result schema or identity")
    if result.get("feature_id") != selection["feature_id"] or result.get("phase") != "final":
        raise RunEvidenceError("run belongs to another Feature or is not final verification")
    if result.get("snapshot", {}).get("working_tree_fingerprint") != snapshot["working_tree_fingerprint"]:
        raise RunEvidenceError("source changed after the recorded run")
    if result.get("status") != "passed" or result.get("errors") != []:
        raise RunEvidenceError("test run failed or did not finish")
    if execution_selectors(root, selection, result["scope"]) != result["selectors"]:
        raise RunEvidenceError("run selectors differ from current required scope")
    cases = _checked_cases(root, path.parent, result)
    return result, cases


def _require_resolved_failures(root: Path, selection: dict, snapshot: dict, runs: list[dict]) -> None:
    # Sequence is this Feature's run order, not filesystem timestamp precision. A tie from
    # concurrent launches never clears a different failed/unfinished run.
    rank = {"required": 1, "affected": 2, "full": 3}
    records, errors = _run_records(root, selection["feature_id"])
    if errors:
        raise RunEvidenceError("; ".join(errors))
    for record in records:
        if (record.get("phase") != "final"
                or record.get("status") == "passed"
                or (record.get("snapshot") or {}).get("working_tree_fingerprint") != snapshot["working_tree_fingerprint"]):
            continue
        scope = record.get("scope")
        if scope == "auto":
            # Before selection, auto is a request rather than an executed scope.
            # The same semantic snapshot lets current obligations resolve it.
            scope = "full" if selection["full_suite"]["required"] else "affected"
        if not any(run["sequence"] > record["sequence"]
                   and rank[run["scope"]] >= rank.get(scope, 3)
                   and all(any(path == target or path.startswith(target.rstrip("/") + "/")
                               for target in run["selectors"]) for path in record["selectors"])
                   for run in runs):
            raise RunEvidenceError("unresolved failed or unfinished test run: " + record["run_id"])


def derive_test_evidence(root: Path, feature_id: str, references: list[dict[str, str]]) -> dict:
    """Compute current obligations and results without persisting derived totals."""
    selection = build_selection(root, feature_id)
    # A valid manual plan can have no automated obligations. It still needs
    # human acceptance and must not hide failed runs on the current snapshot.
    needs_run = bool(selection["required"] or selection["affected"] or selection["full_suite"]["required"])
    if not isinstance(references, list) or (not references and needs_run):
        raise RunEvidenceError("no real test run result was supplied")
    snapshot = current_snapshot(root)
    verified = [verify_run(root, reference, selection, snapshot) for reference in references]
    runs = [run for run, _ in verified]
    if len({run["run_id"] for run in runs}) != len(runs):
        raise RunEvidenceError("duplicate run references")
    _require_resolved_failures(root, selection, snapshot, runs)
    cases = {case["id"]: case for _, records in verified for case in records}
    common = {**snapshot, "run_ids": sorted(run["run_id"] for run in runs)}
    result = {}
    for name, obligations in (("required_test_set", selection["required"]), ("affected_tests", selection["affected"])):
        ids = require_coverage(list(cases.values()), obligations)
        result[name] = {"status": "pass" if runs else "not_required",
                        "total": len(ids), "failed": 0, "test_ids": ids, **common}
    full = any(run["scope"] == "full" for run in runs)
    if selection["full_suite"]["required"] and not full:
        raise RunEvidenceError("required full-suite escalation has no successful full run")
    result["full_suite"] = {"status": "pass" if full else "not_required", **common,
                            "reasons": selection["full_suite"]["reasons"]}
    return result
