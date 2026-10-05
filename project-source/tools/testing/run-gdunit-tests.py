#!/usr/bin/env python3
"""Run selected gdUnit tests and keep one result with the original reports."""
from __future__ import annotations

import argparse
import json
import math
import sys
import tempfile
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.atomic_json import write_json
from tools.lib.gdunit_process import run_owned_process
from tools.lib.gdunit_diagnostics import native_diagnostics
from tools.lib.test_run_evidence import start_run, finish_run, run_history_directory, derive_test_evidence
from tools.lib.test_selection import build_selection, deduplicate_selectors, execution_selectors, read_json

REPO_ROOT = Path(__file__).resolve().parents[3]
RUNNER_SCRIPT = "res://yaya/tools/testing/gdunit_evidence_runner.gd"
DEFAULT_TIMEOUT_SECONDS = 120.0
SUMMARY_FAILURES_PER_CASE = 5
SUMMARY_DETAIL_LINES = 6
SUMMARY_TAIL_LINES = 20


@dataclass(frozen=True)
class ProcessResult:
    returncode: int
    timed_out: bool
    pid: int
    output: str
    owned_pids: tuple[int, ...]


def _build_command(args: argparse.Namespace, report_root: Path) -> list[str]:
    engine = args.godot_binary
    if engine is None:
        engine = read_json(REPO_ROOT / "docs/methodology-config.json")["engine_executable"]
    if not isinstance(engine, str) or not engine.strip():
        raise ValueError("Godot executable must be configured or supplied with --godot-binary")
    command = [str((REPO_ROOT / engine).resolve()), "--path", str(REPO_ROOT),
               "--debug", "--ignore-error-breaks", "--script", RUNNER_SCRIPT,
               "-rd", str(report_root)]
    for target in args.targets:
        command.extend(["-a", target])
    if args.continue_run:
        command.append("-c")
    return command


def _run_process(command: list[str], log_path: Path, timeout: float) -> ProcessResult:
    return ProcessResult(*run_owned_process(command, REPO_ROOT, log_path, timeout))


# 控制台默认只给结论需要的信息；完整输出始终保存在运行目录的 engine.log。
def _summary(directory: Path, output: str) -> str:
    log_line = f"Engine log: {directory / 'engine.log'}"
    reports = list(directory.glob("report_*/results.xml"))
    if len(reports) != 1:
        tail = output.splitlines()[-SUMMARY_TAIL_LINES:]
        return "\n".join(["No single JUnit report; last engine output lines:", *tail, log_line])
    try:
        cases = list(ET.parse(reports[0]).getroot().iter("testcase"))
    except ET.ParseError as error:
        return f"Cannot read JUnit report {reports[0]}: {error}\n{log_line}"
    lines, not_passed = [], 0
    for case in cases:
        problems = [*case.iter("failure"), *case.iter("error")]
        skipped = case.find("skipped") is not None
        if not problems and not skipped:
            continue
        not_passed += 1
        label = "FAILED" if problems else "SKIPPED"
        lines.append(f"{label} {case.get('classname')}.{case.get('name')}")
        for problem in problems[:SUMMARY_FAILURES_PER_CASE]:
            detail = " ".join([line.strip() for line in (problem.text or "").splitlines()
                               if line.strip() and not line.strip().startswith("at '")][:SUMMARY_DETAIL_LINES])
            lines.append(f"  {problem.get('message', '').removeprefix('FAILED: ')}  {detail}")
        if len(problems) > SUMMARY_FAILURES_PER_CASE:
            lines.append(f"  ... {len(problems) - SUMMARY_FAILURES_PER_CASE} more")
    return "\n".join([f"Tests: {len(cases)} cases, {not_passed} not passed", *lines, log_line])


def _startup_diagnostics(output: str) -> list[str]:
    return [record.describe() for record in native_diagnostics(output)]


def _run_tests(args: argparse.Namespace) -> int:
    selection_error = None
    coverage_args = {}
    try:
        if args.feature:
            selection = build_selection(REPO_ROOT, args.feature, phase=args.phase)
            if args.scope == "auto":
                args.scope = "full" if selection["full_suite"]["required"] else "affected"
            print("Test selection: " + json.dumps(selection, ensure_ascii=False), flush=True)
            if (args.scope != "full" and not args.require_test
                    and not selection["required"] and not selection["affected"]
                    and not selection["full_suite"]["required"]):
                # Final selection validates manual acceptance; also retain unresolved failures.
                if args.phase == "final":
                    derive_test_evidence(REPO_ROOT, args.feature, [])
                print(json.dumps({"status": "not_required", "feature_id": args.feature,
                                  "phase": args.phase, "scope": args.scope,
                                  "reason": "no automated test obligations"}))
                return 0
            args.targets = execution_selectors(REPO_ROOT, selection, args.scope)
            coverage_args["obligations"] = selection["required" if args.scope == "required" else "affected"]
    except (ValueError, OSError, KeyError, TypeError, RuntimeError) as error:
        selection_error = error

    report_base = run_history_directory(REPO_ROOT, args.feature)
    report_base.mkdir(parents=True, exist_ok=True)
    directory = Path(tempfile.mkdtemp(prefix="run-", dir=report_base))
    print(f"Run result: {directory / 'result.json'}", flush=True)
    result = start_run(REPO_ROOT, directory, args.feature, args.phase, args.scope)
    if result["status"] == "failed":
        print("TEST VERDICT: FAIL - " + "; ".join(result["errors"]), file=sys.stderr)
        return 1
    process = None
    errors = []
    try:
        if selection_error is not None:
            raise selection_error
        result["command"] = _build_command(args, directory)
        result["selectors"] = args.targets
        write_json(directory / "result.json", result)
        if not Path(result["command"][0]).is_file():
            raise ValueError(f"Godot executable not found: {result['command'][0]}")
        if not (REPO_ROOT / RUNNER_SCRIPT.removeprefix("res://")).is_file():
            raise ValueError(f"GdUnit runner not found: {RUNNER_SCRIPT}")
        completed = _run_process(result["command"], directory / "engine.log", args.timeout_seconds)
        text = completed.output if args.verbose else _summary(directory, completed.output)
        print(text, end="" if text.endswith("\n") else "\n")
        process = {"returncode": completed.returncode, "timed_out": completed.timed_out,
                   "pid": completed.pid, "engine_pid": None}
        discovery = read_json(directory / "discovery.json")
        engine_pid = discovery.get("engine_pid")
        # OS membership is checked while executing; no ownership report or receipt chain.
        if type(engine_pid) is not int or engine_pid not in completed.owned_pids:
            raise ValueError("discovered engine was not part of this run's owned process tree")
        process["engine_pid"] = engine_pid
    except (ValueError, OSError, KeyError, TypeError, RuntimeError) as error:
        errors.append(str(error))
    result = finish_run(REPO_ROOT, directory, result, process=process, errors=errors,
                        required_test=args.require_test, **coverage_args)
    if result["status"] != "passed":
        print("TEST VERDICT: FAIL - " + "; ".join(result["errors"]), file=sys.stderr)
        return 1
    print(f"TEST VERDICT: PASS - {directory / 'result.json'}")
    return 0


def _positive_seconds(value: str) -> float:
    seconds = float(value)
    if not math.isfinite(seconds) or seconds <= 0:
        raise argparse.ArgumentTypeError("timeout must be finite and greater than zero")
    return seconds


def _parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot-binary", help="Override the configured Godot executable for this run")
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument("--target", action="append",
                           help="Suite file or directory; repeat to run several in one run (default: tests)")
    selection.add_argument("--feature", help="Read the current Feature/Test Registry directly")
    parser.add_argument("--phase", choices=("baseline", "final"), default="final")
    parser.add_argument("--scope", choices=("auto", "required", "affected", "full"), default="auto")
    parser.add_argument("--require-test")
    parser.add_argument("--continue", dest="continue_run", action="store_true")
    parser.add_argument("--verbose", action="store_true",
                        help="Print the full engine output instead of the summary; engine.log keeps it either way.")
    parser.add_argument(
        "--timeout-seconds", type=_positive_seconds, default=DEFAULT_TIMEOUT_SECONDS,
        help="Maximum test-process wall time (default: 120 seconds).",
    )
    args = parser.parse_args(list(argv))
    try:
        args.targets = [] if args.feature else deduplicate_selectors(REPO_ROOT, args.target or ["tests"])
        run_history_directory(REPO_ROOT, args.feature)
    except ValueError as error:
        parser.error(str(error))
    if args.godot_binary is not None and not args.godot_binary.strip():
        parser.error("--godot-binary must be a non-empty executable path")
    return args


def main() -> int:
    args = _parse_args(sys.argv[1:])
    return _run_tests(args)


if __name__ == "__main__":
    sys.exit(main())
