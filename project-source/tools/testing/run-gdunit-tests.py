#!/usr/bin/env python3
"""Run GdUnit4 and enforce the project's structured test verdict contract."""
# 显式测试包装器：执行计划选择的实际测试，并将运行事实交给证据模块核对。
from __future__ import annotations

import argparse
import json
import math
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable

# 脚本在子目录直接启动时，显式加载本项目的共享包。
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.gdunit_process import run_owned_process
from tools.lib.gdunit_diagnostics import (
    DiagnosticEvidenceError, native_diagnostics, unexpected_diagnostics,
)
from tools.lib.gate_evidence import current_snapshot
from tools.lib.run_evidence import (
    RunEvidenceError, expected_gdunit_cases, owned_engine_pid, read_junit_cases, require_coverage,
    require_supported_adapter, verify_runtime_discovery, verify_session_receipt, write_run_manifest,
)
from tools.lib.test_selection import SelectionError, build_selection, execution_selectors
from tools.lib.execution_attempts import attempt


REPO_ROOT = Path(__file__).resolve().parents[2]
RUNNER_SCRIPT = "res://tools/testing/gdunit_evidence_runner.gd"
DEFAULT_TIMEOUT_SECONDS = 120.0


class VerdictError(ValueError):
    """Raised when a GdUnit report cannot prove a trustworthy verdict."""


@dataclass(frozen=True)
class ReportVerdict:
    discovered: int
    executed: int
    errors: int
    failures: int
    orphans: int
    flaky: int
    skipped: int
    required_matches: int
    required_executed: int


@dataclass(frozen=True)
class ProcessResult:
    returncode: int
    timed_out: bool
    pid: int
    output: str


def _build_command(args: argparse.Namespace, report_root: Path) -> list[str]:
    # Engine options precede the script path; the remainder belongs to GdUnit.
    command = [
        str((REPO_ROOT / args.godot_binary).resolve()),
        "--path", str(REPO_ROOT),
        "--debug", "--ignore-error-breaks", "--script", RUNNER_SCRIPT,
        "-rd", str(report_root),
    ]
    for target in getattr(args, "targets", [args.target]):
        command.extend(["-a", target])
    if args.continue_run:
        command.append("-c")
    return command


def _run_process(command: list[str], log_path: Path, timeout: float) -> ProcessResult:
    return ProcessResult(*run_owned_process(command, REPO_ROOT, log_path, timeout))


def _startup_diagnostics(output: str) -> list[str]:
    """Native-only check for startup callers without a GdUnit test session."""
    return [record.describe() for record in native_diagnostics(output)]


def _nonnegative_int(element: ET.Element, name: str) -> int:
    raw = element.get(name)
    if raw is None:
        raise VerdictError(f"missing {element.tag}.{name} attribute")
    try:
        value = int(raw)
    except ValueError as exc:
        raise VerdictError(
            f"invalid {element.tag}.{name} attribute: {raw!r}"
        ) from exc
    if value < 0:
        raise VerdictError(f"negative {element.tag}.{name} attribute: {value}")
    return value


def _optional_nonnegative_int(element: ET.Element, name: str) -> int:
    if element.get(name) is None:
        return 0
    return _nonnegative_int(element, name)


def _normalize_resource_path(path: str) -> str:
    normalized = path.replace("\\", "/").removeprefix("res://")
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized.strip("/")


def _suite_resource_path(suite: ET.Element) -> str:
    package = _normalize_resource_path(suite.get("package", ""))
    suite_name = suite.get("name", "")
    filename = suite_name if suite_name.endswith(".gd") else f"{suite_name}.gd"
    return f"{package}/{filename}" if package else filename


def _split_required_test(required_test: str | None) -> tuple[str, str] | None:
    if required_test is None:
        return None
    try:
        suite_path, case_name = required_test.rsplit("::", 1)
    except ValueError as exc:
        raise VerdictError(
            "required test must use <suite-path>::<test-case> syntax"
        ) from exc
    suite_path = _normalize_resource_path(suite_path)
    if not suite_path or not case_name:
        raise VerdictError(
            "required test must include a suite path and test-case name"
        )
    return suite_path, case_name


def _evaluate_report_root(
    root: ET.Element,
    required_test: str | None,
) -> ReportVerdict:
    if root.tag != "testsuites":
        raise VerdictError(f"expected testsuites root, found {root.tag!r}")

    suites = root.findall("testsuite")
    discovered = _nonnegative_int(root, "tests")
    root_failures = _nonnegative_int(root, "failures")
    root_skipped = _nonnegative_int(root, "skipped")
    root_flaky = _nonnegative_int(root, "flaky")

    suite_tests = sum(_nonnegative_int(suite, "tests") for suite in suites)
    if suite_tests != discovered:
        raise VerdictError(
            "report test-count mismatch: "
            f"root={discovered}, suites={suite_tests}"
        )

    suite_failures = sum(
        _nonnegative_int(suite, "failures") for suite in suites
    )
    suite_errors = sum(_nonnegative_int(suite, "errors") for suite in suites)
    suite_skipped = sum(
        _nonnegative_int(suite, "skipped") for suite in suites
    )
    suite_flaky = sum(_nonnegative_int(suite, "flaky") for suite in suites)
    test_cases = [case for suite in suites for case in suite.findall("testcase")]
    failure_nodes = [node for case in test_cases for node in case.findall("failure")]
    error_nodes = [node for case in test_cases for node in case.findall("error")]
    skipped_nodes = [node for case in test_cases for node in case.findall("skipped")]
    orphan_nodes = [
        node
        for node in failure_nodes + error_nodes
        if node.get("type", "").upper() == "ORPHAN"
    ]

    failures = max(root_failures, suite_failures, len(failure_nodes))
    errors = max(suite_errors, len(error_nodes))
    skipped = max(root_skipped, suite_skipped, len(skipped_nodes))
    flaky = max(root_flaky, suite_flaky)
    executed = max(0, discovered - skipped)

    required_matches = 0
    required_executed = 0
    required = _split_required_test(required_test)
    if required is not None:
        required_path, required_case = required
        for suite in suites:
            if _suite_resource_path(suite) != required_path:
                continue
            for case in suite.findall("testcase"):
                if case.get("name") != required_case:
                    continue
                required_matches += 1
                if case.find("skipped") is None:
                    required_executed += 1

    return ReportVerdict(
        discovered=discovered,
        executed=executed,
        errors=errors,
        failures=failures,
        orphans=len(orphan_nodes),
        flaky=flaky,
        skipped=skipped,
        required_matches=required_matches,
        required_executed=required_executed,
    )


def _parse_report(path: Path, required_test: str | None) -> ReportVerdict:
    try:
        root = ET.parse(path).getroot()
    except (ET.ParseError, OSError) as exc:
        raise VerdictError(f"cannot parse GdUnit JUnit report {path}: {exc}") from exc
    return _evaluate_report_root(root, required_test)


def _failure_reasons(
    verdict: ReportVerdict,
    upstream_exit: int,
    required_test: str | None,
) -> list[str]:
    reasons: list[str] = []
    if upstream_exit != 0:
        reasons.append(f"upstream runner exited with {upstream_exit}")
    if verdict.discovered == 0:
        reasons.append("no tests were discovered")
    if verdict.executed == 0:
        reasons.append("no tests were executed")
    for label, count in (
        ("errors", verdict.errors),
        ("failures", verdict.failures),
        ("orphans", verdict.orphans),
        ("flaky tests", verdict.flaky),
    ):
        if count > 0:
            reasons.append(f"{label}: {count}")
    if required_test is not None:
        if verdict.required_matches == 0:
            reasons.append(f"required test was not discovered: {required_test}")
        elif verdict.required_executed == 0:
            reasons.append(f"required test was skipped: {required_test}")
    return reasons


def _locate_report(report_root: Path) -> Path:
    reports = list(report_root.glob("report_*/results.xml"))
    if len(reports) != 1:
        raise VerdictError(
            "expected exactly one report from this run, "
            f"found {len(reports)} under {report_root}"
        )
    return reports[0]


# 进程启动前登记尝试；启动失败或中断仍需留下可追踪失败，不能沿用旧绿灯。
def _run_tests(args: argparse.Namespace) -> int:
    # Record Feature attempts before executable/configuration checks. Even a
    # launch failure with no final manifest must invalidate an earlier PASS.
    report_base = REPO_ROOT / "reports" / "gdunit-wrapper"
    report_base.mkdir(parents=True, exist_ok=True)
    report_root = Path(tempfile.mkdtemp(prefix="run-", dir=report_base))
    print(f"Artifact directory: {report_root}", flush=True)
    if not getattr(args, "feature", None):
        return _execute_tests(args, report_root)
    try:
        selection = build_selection(REPO_ROOT, args.feature, phase=args.phase)
    except (ValueError, OSError, KeyError, TypeError) as error:
        args.selection_error = str(error)
        selection = {"feature_id": args.feature, "phase": args.phase}
    scope = args.scope
    if scope == "auto":
        full = selection.get("full_suite") if selection else None
        scope = "affected" if isinstance(full, dict) and full.get("required") is False else "full"
    try:
        with attempt(REPO_ROOT, "tests", report_root, selection=selection, scope=scope):
            code = _execute_tests(args, report_root, selection)
            if code and not (report_root / "verdict.json").exists():
                (report_root / "startup-failure.txt").write_text(
                    f"Verification setup failed with exit {code}; see original command output.\n", encoding="utf-8")
            return code
    except (OSError, ValueError) as error:
        print(f"TEST ATTEMPT: BLOCKED - {error}", file=sys.stderr)
        return 2


# 进程退出码、JUnit、诊断和 session/discovery 共同判定；不能只看终端一句成功。
def _execute_tests(args: argparse.Namespace, report_root: Path, selection: dict | None = None) -> int:
    godot_binary = (REPO_ROOT / args.godot_binary).resolve()
    if not godot_binary.is_file():
        print(f"ERROR: Godot executable not found: {godot_binary}", file=sys.stderr)
        return 2
    if not (REPO_ROOT / RUNNER_SCRIPT.removeprefix("res://")).is_file():
        print(f"ERROR: GdUnit runner not found: {RUNNER_SCRIPT}", file=sys.stderr)
        return 2

    expected: list[dict[str, str]] = []
    if getattr(args, "feature", None):
        try:
            require_supported_adapter(REPO_ROOT)
            if not selection or "required" not in selection:
                raise SelectionError(getattr(args, "selection_error", "Feature/Catalog cannot supply the requested test selection"))
            if args.scope == "auto":
                args.scope = "full" if selection["full_suite"]["required"] else "affected"
            args.targets = execution_selectors(REPO_ROOT, selection, args.scope)
            expected = expected_gdunit_cases(REPO_ROOT, args.targets)
            print(f"Test selection: scope={args.scope}; selectors={json.dumps(args.targets)}; "
                  f"full_suite_reasons={json.dumps(selection['full_suite']['reasons'])}", flush=True)
            print("Test obligations: " + json.dumps(
                {key: selection[key] for key in ("required", "affected")}, ensure_ascii=False), flush=True)
        except (SelectionError, RunEvidenceError, OSError, KeyError, TypeError) as exc:
            print(f"TEST SELECTION: BLOCKED - {exc}", file=sys.stderr)
            return 2

    snapshot_before = current_snapshot(REPO_ROOT) if selection else None
    started_ns = time.time_ns()
    command = _build_command(args, report_root)
    (report_root / "invocation.json").write_text(
        json.dumps({"command": command, "timeout_seconds": args.timeout_seconds,
                    "run_id": report_root.name, "feature_id": args.feature if selection else None,
                    "working_tree_fingerprint": snapshot_before["working_tree_fingerprint"] if selection else None}, indent=2)
        + "\n", encoding="utf-8",
    )
    try:
        completed = _run_process(command, report_root / "engine.log", args.timeout_seconds)
    except OSError as exc:
        message = f"test process failed: {exc}"
        (report_root / "verdict.json").write_text(
            json.dumps({
                "returncode": None, "timed_out": None, "pid": None,
                "startup_diagnostics": [], "failure_reasons": [message], "report": None,
            }, indent=2) + "\n", encoding="utf-8"
        )
        (report_root / "engine.log").write_text(message + "\n", encoding="utf-8")
        if selection:
            write_run_manifest(REPO_ROOT, report_root, feature_id=args.feature, phase=args.phase, scope=args.scope,
                               snapshot_before=snapshot_before, started_ns=started_ns,
                               command=command, wrapper_exit=1, junit_path=None, expected=expected)
        print(f"TEST VERDICT: FAIL - {message}", file=sys.stderr)
        return 1

    print(completed.output, end="" if completed.output.endswith("\n") else "\n")
    diagnostics = _startup_diagnostics(completed.output)
    reasons: list[str] = []
    if completed.timed_out:
        reasons.append(f"test process {completed.pid} timed out after {args.timeout_seconds:g}s")
    if completed.returncode != 0:
        reasons.append(f"upstream runner exited with {completed.returncode}")
    verdict: ReportVerdict | None = None
    engine_pid: int | None = None
    report_path: Path | None = None
    try:
        report_path = _locate_report(report_root)
        verdict = _parse_report(report_path, args.require_test)
        reasons.extend(_failure_reasons(verdict, 0, args.require_test))
        diagnostics = unexpected_diagnostics(completed.output, report_path)
        actual_cases = read_junit_cases(report_path)
        if selection:
            engine_pid = owned_engine_pid(report_root / "process-ownership.json",
                                          report_root / "discovery.json", completed.pid)
            verify_session_receipt(report_root, {
                "session_receipt": report_root / "session-receipt.json",
                "invocation": report_root / "invocation.json", "discovery": report_root / "discovery.json",
                "junit": report_path, "diagnostics": report_path.parent / "diagnostics.jsonl",
            }, engine_pid)
            actual_cases = verify_runtime_discovery(report_root / "discovery.json", engine_pid, actual_cases)
            require_coverage(actual_cases, expected)
            require_coverage(actual_cases, [{"path": target, "case": None} for target in args.targets])
            if current_snapshot(REPO_ROOT)["working_tree_fingerprint"] != snapshot_before["working_tree_fingerprint"]:
                reasons.append("source snapshot changed during test execution")
    except DiagnosticEvidenceError as exc:
        reasons.append(str(exc))
    except (VerdictError, RunEvidenceError) as exc:
        reasons.append(str(exc))
    reasons.extend(f"unexpected Godot diagnostic: {message}" for message in diagnostics)

    (report_root / "verdict.json").write_text(
        json.dumps({
            "returncode": completed.returncode, "timed_out": completed.timed_out,
            # Retain this existing artifact key for consumers; it now covers
            # unexpected native diagnostics across the complete lifecycle.
            "pid": completed.pid, "engine_pid": engine_pid, "startup_diagnostics": diagnostics,
            "failure_reasons": reasons, "report": asdict(verdict) if verdict else None,
        }, indent=2, ensure_ascii=False) + "\n", encoding="utf-8",
    )
    if selection:
        manifest_path = write_run_manifest(
            REPO_ROOT, report_root, feature_id=args.feature, phase=args.phase, scope=args.scope,
            snapshot_before=snapshot_before, started_ns=started_ns, command=command,
            wrapper_exit=1 if reasons else 0, junit_path=report_path, expected=expected,
        )
        print(f"Run manifest: {manifest_path}")
    if verdict is not None:
        summary = (
            f"discovered={verdict.discovered} executed={verdict.executed} "
            f"errors={verdict.errors} failures={verdict.failures} "
            f"orphans={verdict.orphans} flaky={verdict.flaky} "
            f"skipped={verdict.skipped}"
        )
        print(f"GdUnit report: {summary}")
    if reasons:
        print(f"TEST VERDICT: FAIL - {'; '.join(reasons)}", file=sys.stderr)
        return 1
    print(f"TEST VERDICT: PASS - {summary}")
    return 0


def _fixture_xml(
    *,
    tests: int = 1,
    failures: int = 0,
    errors: int = 0,
    skipped: int = 0,
    flaky: int = 0,
    child: str = "",
) -> ET.Element:
    case = (
        '<testcase name="test_case" classname="test_suite" time="0.001">'
        f"{child}</testcase>"
    )
    xml = (
        f'<testsuites tests="{tests}" failures="{failures}" '
        f'skipped="{skipped}" flaky="{flaky}" time="0.001">'
        f'<testsuite name="test_suite" package="tests/invariants" '
        f'tests="{tests}" failures="{failures}" errors="{errors}" '
        f'skipped="{skipped}" flaky="{flaky}" time="0.001">'
        f"{case if tests else ''}</testsuite></testsuites>"
    )
    return ET.fromstring(xml)


# 这里只是包装器内部合成数据检查，不证明真实 Godot、项目测试或宿主集成通过。
def _run_self_test() -> int:
    required = "tests/invariants/test_suite.gd::test_case"
    fixtures = {
        "pass": (_fixture_xml(), False),
        "zero": (_fixture_xml(tests=0), True),
        "failure": (
            _fixture_xml(
                failures=1,
                child='<failure type="FAILURE">failed</failure>',
            ),
            True,
        ),
        "error": (
            _fixture_xml(
                errors=1,
                child='<error type="UNKNOWN">error</error>',
            ),
            True,
        ),
        "orphan": (
            _fixture_xml(
                failures=1,
                child='<failure type="ORPHAN">orphan</failure>',
            ),
            True,
        ),
        "flaky": (_fixture_xml(flaky=1), True),
        "required-skipped": (
            _fixture_xml(skipped=1, child="<skipped />"),
            True,
        ),
    }
    for name, (root, should_fail) in fixtures.items():
        verdict = _evaluate_report_root(root, required)
        failed = bool(_failure_reasons(verdict, 0, required))
        if failed != should_fail:
            print(f"SELF-TEST FAIL: {name}", file=sys.stderr)
            return 1

    verdict = _evaluate_report_root(_fixture_xml(), required)
    if not _failure_reasons(verdict, 7, required):
        print("SELF-TEST FAIL: upstream nonzero", file=sys.stderr)
        return 1
    missing = "tests/invariants/test_suite.gd::missing_case"
    verdict = _evaluate_report_root(_fixture_xml(), missing)
    if not _failure_reasons(verdict, 0, missing):
        print("SELF-TEST FAIL: missing required test", file=sys.stderr)
        return 1

    print(f"GdUnit verdict parser self-test: PASS ({len(fixtures) + 2} cases)")
    return 0


def _positive_seconds(value: str) -> float:
    seconds = float(value)
    if not math.isfinite(seconds) or seconds <= 0:
        raise argparse.ArgumentTypeError("timeout must be finite and greater than zero")
    return seconds


def _parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot-binary")
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument("--target", default="tests")
    selection.add_argument("--feature", help="Read the current Feature/Test Catalog directly")
    parser.add_argument("--phase", choices=("baseline", "final"), default="final")
    parser.add_argument("--scope", choices=("auto", "required", "affected", "full"), default="auto")
    parser.add_argument("--require-test")
    parser.add_argument("--continue", dest="continue_run", action="store_true")
    parser.add_argument(
        "--timeout-seconds", type=_positive_seconds, default=DEFAULT_TIMEOUT_SECONDS,
        help="Maximum test-process wall time (default: 120 seconds).",
    )
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args(list(argv))
    if not args.self_test and not args.godot_binary:
        parser.error("--godot-binary is required unless --self-test is used")
    return args


def main() -> int:
    args = _parse_args(sys.argv[1:])
    if args.self_test:
        return _run_self_test()
    return _run_tests(args)


if __name__ == "__main__":
    sys.exit(main())
