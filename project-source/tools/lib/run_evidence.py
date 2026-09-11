"""Verify test-run artifacts rather than accepting caller-supplied pass counts.

The manifest is a local audit chain, not a signature against a malicious actor
who can rewrite the repository and every artifact. The trusted boundary is the
checked-in wrapper that launches the runner and records its actual outputs.
"""
# 实际运行的证据读取端；manifest 是本地可审计引用链，不是对任意改写者的数字签名。
from __future__ import annotations

import hashlib
import os
import re
import time
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

from tools.lib.gate_evidence import current_snapshot, write_evidence
from tools.lib.test_selection import execution_selectors, normalized_path, read_json, build_selection


class RunEvidenceError(ValueError):
    """The recorded execution cannot prove the requested test obligations."""


def require_supported_adapter(root: Path) -> None:
    config = read_json(root / "docs/methodology-config.json")
    if config.get("test_framework") != "gdunit4":
        raise RunEvidenceError("artifact-backed execution currently supports only configured gdunit4")


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
        expected.extend({"path": relative, "case": name, "source_hash": file_hash(path)} for name in names)
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


def owned_engine_pid(ownership_path: Path, discovery_path: Path, launcher_pid: int) -> int:
    """Bind the engine's identity to processes observed by the wrapper's OS guard."""
    try:
        ownership, discovery = read_json(ownership_path), read_json(discovery_path)
    except ValueError as exc:
        raise RunEvidenceError(f"missing owned process evidence: {exc}") from exc
    owned = ownership.get("owned_pids")
    if (ownership.get("schema_version") != 1 or ownership.get("launcher_pid") != launcher_pid
            or ownership.get("source") != "windows-job"
            or not isinstance(owned, list) or not owned
            or any(type(pid) is not int or pid <= 0 for pid in owned)
            or launcher_pid not in owned):
        raise RunEvidenceError("invalid owned process evidence")
    engine_pid = discovery.get("engine_pid")
    if type(engine_pid) is not int or engine_pid not in owned:
        raise RunEvidenceError("discovered engine process was not observed in the owned process scope")
    return engine_pid


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


def artifact_reference(directory: Path, path: Path) -> dict[str, Any]:
    resolved = path.resolve()
    if not resolved.is_relative_to(directory.resolve()):
        raise RunEvidenceError("run artifact must be inside its own run directory")
    return {"path": resolved.relative_to(directory.resolve()).as_posix(),
            "sha256": file_hash(resolved), "mtime_ns": resolved.stat().st_mtime_ns}


def write_run_manifest(root: Path, directory: Path, *, feature_id: str, phase: str, scope: str,
                       snapshot_before: dict[str, str], started_ns: int, command: list[str],
                       wrapper_exit: int, junit_path: Path | None, expected: list[dict[str, str]]) -> Path:
    snapshot_after = current_snapshot(root)
    artifacts = {"verdict": artifact_reference(directory, directory / "verdict.json"),
                 "invocation": artifact_reference(directory, directory / "invocation.json"),
                 "engine_log": artifact_reference(directory, directory / "engine.log")}
    cases = []
    runtime_discovery = []
    discovery_path = directory / "discovery.json"
    if discovery_path.is_file():
        artifacts["discovery"] = artifact_reference(directory, discovery_path)
        try:
            runtime_discovery = read_json(discovery_path).get("cases", [])
        except ValueError:
            wrapper_exit = 1
    ownership_path = directory / "process-ownership.json"
    if ownership_path.is_file():
        artifacts["process_ownership"] = artifact_reference(directory, ownership_path)
    receipt_path = directory / "session-receipt.json"
    if receipt_path.is_file():
        artifacts["session_receipt"] = artifact_reference(directory, receipt_path)
    if junit_path is not None:
        artifacts["junit"] = artifact_reference(directory, junit_path)
        diagnostic_path = junit_path.parent / "diagnostics.jsonl"
        if diagnostic_path.is_file():
            artifacts["diagnostics"] = artifact_reference(directory, diagnostic_path)
        try:
            cases = read_junit_cases(junit_path)
        except RunEvidenceError:
            # Preserve invalid evidence as a failed run, never repair its report.
            wrapper_exit = 1
    from tools.lib.execution_attempts import run_attempt
    result = {"schema_version": 4, "run_id": directory.name, "adapter": "gdunit4",
              "attempt_hash": run_attempt(root, directory)["hash"],
              "started_ns": started_ns, "finished_ns": time.time_ns(), "command": command,
              "runner_identity": {"path": str(Path(command[0]).resolve()), "sha256": file_hash(Path(command[0]))},
              "snapshot_before": snapshot_before, "snapshot_after": snapshot_after,
              "feature_id": feature_id, "phase": phase, "scope": scope,
              "selectors": [command[index + 1] for index, arg in enumerate(command[:-1]) if arg == "-a"],
              "declared_cases": expected, "discovered_cases": cases,
              "runtime_discovery": runtime_discovery,
              "executed_ids": sorted(case["id"] for case in cases if case["status"] != "skipped"),
              "wrapper_exit": wrapper_exit, "artifacts": artifacts}
    path = directory / "manifest.json"
    write_evidence(path, result)
    return path


def _verified_artifact(directory: Path, reference: dict[str, Any]) -> Path:
    path = (directory / reference["path"]).resolve()
    if not path.is_relative_to(directory.resolve()) or not path.is_file():
        raise RunEvidenceError("artifact missing or outside its originating run directory")
    # File timestamps can be rounded, copied or adjusted independently of the
    # wrapper clock. They remain audit metadata, never proof of run provenance.
    if file_hash(path) != reference["sha256"]:
        raise RunEvidenceError(f"run artifact changed after execution: {path.name}")
    return path


# 本次进程/session、发现集合、JUnit 引用及哈希共同约束新鲜度，避免依赖低精度 mtime。
def verify_session_receipt(directory: Path, files: dict[str, Path], engine_pid: int) -> None:
    """Verify hashes sealed by the actual engine after its reporters completed."""
    if files.get("session_receipt") != directory / "session-receipt.json":
        raise RunEvidenceError("actual engine session receipt is missing")
    try:
        receipt = read_json(files["session_receipt"])
    except (ValueError, OSError) as exc:
        raise RunEvidenceError(f"cannot read actual engine session receipt: {exc}") from exc
    if (receipt.get("schema_version") != 1 or receipt.get("run_id") != directory.name
            or receipt.get("engine_pid") != engine_pid or receipt.get("exit_code") != 0):
        raise RunEvidenceError("engine session receipt belongs to a different or failed run")
    if receipt.get("invocation_sha256") != file_hash(files["invocation"]):
        raise RunEvidenceError("engine session receipt does not match this invocation")
    sealed = receipt.get("artifacts")
    if not isinstance(sealed, dict) or set(sealed) != {"discovery", "junit", "diagnostics"}:
        raise RunEvidenceError("engine session receipt has an incomplete artifact set")
    for name, reference in sealed.items():
        if (not isinstance(reference, dict) or set(reference) != {"path", "sha256"}
                or any(not isinstance(value, str) or not value for value in reference.values())):
            raise RunEvidenceError("malformed engine session artifact receipt")
        path = (directory / reference["path"]).resolve()
        if path != files.get(name) or file_hash(path) != reference["sha256"]:
            raise RunEvidenceError(f"artifact differs from actual engine session: {name}")


def verify_run(root: Path, reference: dict[str, str], selection: dict[str, Any]) -> dict[str, Any]:
    require_supported_adapter(root)
    path = (root / reference["path"]).resolve()
    if not path.is_relative_to((root / "reports").resolve()) or not path.is_file():
        raise RunEvidenceError("run manifest must exist under repository reports/")
    if file_hash(path) != reference["sha256"]:
        raise RunEvidenceError("run manifest changed after recording")
    manifest = read_json(path)
    if manifest.get("schema_version") != 4 or manifest.get("adapter") != "gdunit4":
        raise RunEvidenceError("unsupported run manifest schema/adapter")
    if manifest.get("feature_id") != selection["feature_id"]:
        raise RunEvidenceError("run belongs to a different Feature")
    if manifest.get("phase") != "final":
        raise RunEvidenceError("baseline runs cannot authorize completion")
    fingerprint = current_snapshot(root)["working_tree_fingerprint"]
    if any(manifest[key].get("working_tree_fingerprint") != fingerprint for key in ("snapshot_before", "snapshot_after")):
        raise RunEvidenceError("source changed before/during/after the recorded run")
    if manifest["wrapper_exit"] != 0:
        raise RunEvidenceError("test wrapper did not pass")
    if manifest["run_id"] != path.parent.name or not isinstance(manifest["started_ns"], int) or not isinstance(manifest["finished_ns"], int):
        raise RunEvidenceError("invalid run identity/timestamps")
    if manifest["started_ns"] <= 0 or manifest["finished_ns"] <= 0:
        raise RunEvidenceError("invalid run timestamps")
    files = {name: _verified_artifact(path.parent, item)
             for name, item in manifest["artifacts"].items()}
    verdict = read_json(files["verdict"])
    if verdict.get("returncode") != 0 or verdict.get("timed_out") is not False or verdict.get("failure_reasons") != []:
        raise RunEvidenceError("wrapper verdict records process/timeout/diagnostic failure")
    if verdict.get("startup_diagnostics") != []:
        raise RunEvidenceError("wrapper verdict records unexpected diagnostics")
    invocation = read_json(files["invocation"])
    if invocation.get("command") != manifest["command"]:
        raise RunEvidenceError("manifest command differs from actual invocation")
    if (invocation.get("run_id") != manifest["run_id"]
            or invocation.get("feature_id") != selection["feature_id"]
            or invocation.get("working_tree_fingerprint") != fingerprint):
        raise RunEvidenceError("actual invocation belongs to a different run, selection or snapshot")
    binary = Path(manifest["command"][0]).resolve()
    if manifest.get("runner_identity") != {"path": str(binary), "sha256": file_hash(binary)}:
        raise RunEvidenceError("runner executable changed after verification")
    selectors = execution_selectors(root, selection, manifest["scope"])
    if selectors != manifest["selectors"]:
        raise RunEvidenceError("run selectors differ from planned scope")
    actual_selectors = [manifest["command"][index + 1] for index, arg in enumerate(manifest["command"][:-1]) if arg == "-a"]
    if actual_selectors != selectors:
        raise RunEvidenceError("runner invocation did not consume selected paths")
    cases = read_junit_cases(files["junit"])
    if cases != manifest["discovered_cases"]:
        raise RunEvidenceError("discovered tests differ from actual JUnit testcase set")
    executed = sorted(case["id"] for case in cases if case["status"] != "skipped")
    if executed != manifest["executed_ids"]:
        raise RunEvidenceError("executed test IDs differ from actual JUnit")
    if any(case["status"] != "passed" for case in cases):
        raise RunEvidenceError("run contains failed or skipped tests")
    discovery_path = files.get("discovery")
    if discovery_path != path.parent / "discovery.json":
        raise RunEvidenceError("actual runtime discovery evidence is missing")
    if files.get("process_ownership") != path.parent / "process-ownership.json":
        raise RunEvidenceError("actual owned process evidence is missing")
    engine_pid = owned_engine_pid(files["process_ownership"], discovery_path, verdict.get("pid"))
    if verdict.get("engine_pid") != engine_pid:
        raise RunEvidenceError("wrapper verdict has a different actual engine identity")
    verify_session_receipt(path.parent, files, engine_pid)
    cases = verify_runtime_discovery(discovery_path, engine_pid, cases)
    if read_json(discovery_path)["cases"] != manifest["runtime_discovery"]:
        raise RunEvidenceError("manifest runtime discovery differs from originating runner data")
    report = verdict.get("report") or {}
    if report.get("discovered") != len(cases) or report.get("executed") != len(executed):
        raise RunEvidenceError("wrapper verdict counts disagree with actual JUnit sets")
    if any(report.get(name) != 0 for name in ("errors", "failures", "orphans", "flaky", "skipped")):
        raise RunEvidenceError("wrapper verdict records unsuccessful tests")
    declared = expected_gdunit_cases(root, selectors)
    if declared != manifest["declared_cases"]:
        raise RunEvidenceError("declared test inventory changed")
    require_coverage(cases, declared)
    # Also require a nonempty actual discovery for every selector, including a
    # directory that contains no statically recognizable test declarations.
    require_coverage(cases, [{"path": selector, "case": None} for selector in selectors])
    from tools.lib.gdunit_diagnostics import DiagnosticEvidenceError, unexpected_diagnostics
    if files.get("diagnostics") != files["junit"].parent / "diagnostics.jsonl":
        raise RunEvidenceError("current run diagnostic evidence is missing")
    import json
    try:
        session_start = json.loads(files["diagnostics"].read_text(encoding="utf-8").splitlines()[0])
    except (ValueError, IndexError) as exc:
        raise RunEvidenceError("invalid diagnostic session identity") from exc
    if not isinstance(session_start, dict) or session_start.get("engine_pid") != engine_pid:
        raise RunEvidenceError("diagnostic evidence belongs to a different engine process")
    try:
        if unexpected_diagnostics(files["engine_log"].read_text(encoding="utf-8"), files["junit"]):
            raise RunEvidenceError("actual engine log contains unexpected diagnostics")
    except DiagnosticEvidenceError as exc:
        raise RunEvidenceError(str(exc)) from exc
    return manifest


def manifest_reference(root: Path, path: Path) -> dict[str, str]:
    resolved = path.resolve()
    if not resolved.is_relative_to(root.resolve()):
        raise RunEvidenceError("manifest is outside the repository")
    return {"path": resolved.relative_to(root.resolve()).as_posix(), "sha256": file_hash(resolved)}


# 从报告工件和计划推导结论；不信任调用者手填的通过数量或 scope 标签。
def derive_test_evidence(root: Path, feature_id: str, references: list[dict[str, str]]) -> dict[str, Any]:
    # Selection is computed from current contracts, never imported from a plan file.
    selection = build_selection(root, feature_id)
    if not references or not isinstance(references, list):
        raise RunEvidenceError("no real test run manifest was supplied")
    runs = [verify_run(root, reference, selection) for reference in references]
    if len({run["run_id"] for run in runs}) != len(runs):
        raise RunEvidenceError("duplicate run references")
    from tools.lib.execution_attempts import require_current_tests
    try:
        require_current_tests(root, selection, runs)
    except ValueError as error:
        raise RunEvidenceError(str(error)) from error
    combined: dict[str, dict[str, str]] = {}
    for run in runs:
        methods = {case["id"]: case["method"] for case in run["runtime_discovery"]}
        combined.update({case["id"]: {**case, "method": methods[case["id"]]} for case in run["discovered_cases"]})
    snapshot = current_snapshot(root)
    common = {**snapshot, "run_ids": sorted(run["run_id"] for run in runs),
              "recorded_at": str(max(run["finished_ns"] for run in runs))}
    result = {}
    for name, obligations in (("required_test_set", selection["required"]), ("affected_tests", selection["affected"])):
        ids = require_coverage(list(combined.values()), obligations)
        result[name] = {"status": "pass", "total": len(ids), "failed": 0, "test_ids": ids, **common}
    full_runs = [run for run in runs if run["scope"] == "full"]
    if selection["full_suite"]["required"] and not full_runs:
        raise RunEvidenceError("required full-suite escalation has no successful full run")
    result["full_suite"] = {"status": "pass" if full_runs else "not_required", **common,
                            "reasons": selection["full_suite"]["reasons"]}
    return result
