#!/usr/bin/env python3
"""Run selected gdUnit tests and keep one result with the original reports."""
from __future__ import annotations

import argparse
import json
import math
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.feature_completion_evidence import write_evidence
from tools.lib.gdunit_process import run_owned_process
from tools.lib.gdunit_diagnostics import native_diagnostics
from tools.lib.test_run_evidence import start_run, finish_run, run_history_directory
from tools.lib.test_selection import build_selection, execution_selectors, read_json

REPO_ROOT = Path(__file__).resolve().parents[2]
RUNNER_SCRIPT = "res://tools/testing/gdunit_evidence_runner.gd"
DEFAULT_TIMEOUT_SECONDS = 120.0


@dataclass(frozen=True)
class ProcessResult:
    returncode: int
    timed_out: bool
    pid: int
    output: str
    owned_pids: tuple[int, ...]


def _build_command(args: argparse.Namespace, report_root: Path) -> list[str]:
    command = [str((REPO_ROOT / args.godot_binary).resolve()), "--path", str(REPO_ROOT),
               "--debug", "--ignore-error-breaks", "--script", RUNNER_SCRIPT,
               "-rd", str(report_root)]
    for target in getattr(args, "targets", [args.target]):
        command.extend(["-a", target])
    if args.continue_run:
        command.append("-c")
    return command


def _run_process(command: list[str], log_path: Path, timeout: float) -> ProcessResult:
    return ProcessResult(*run_owned_process(command, REPO_ROOT, log_path, timeout))


def _startup_diagnostics(output: str) -> list[str]:
    return [record.describe() for record in native_diagnostics(output)]


def _run_tests(args: argparse.Namespace) -> int:
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
        if args.feature:
            selection = build_selection(REPO_ROOT, args.feature, phase=args.phase)
            if args.scope == "auto":
                args.scope = "full" if selection["full_suite"]["required"] else "affected"
            args.targets = execution_selectors(REPO_ROOT, selection, args.scope)
            result["scope"] = args.scope
            print("Test selection: " + json.dumps(selection, ensure_ascii=False), flush=True)
        result["command"] = _build_command(args, directory)
        result["selectors"] = getattr(args, "targets", [args.target])
        write_evidence(directory / "result.json", result)
        if not Path(result["command"][0]).is_file():
            raise ValueError(f"Godot executable not found: {result['command'][0]}")
        if not (REPO_ROOT / RUNNER_SCRIPT.removeprefix("res://")).is_file():
            raise ValueError(f"GdUnit runner not found: {RUNNER_SCRIPT}")
        completed = _run_process(result["command"], directory / "engine.log", args.timeout_seconds)
        print(completed.output, end="" if completed.output.endswith("\n") else "\n")
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
                        required_test=args.require_test)
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
    selection.add_argument("--target", default="tests")
    selection.add_argument("--feature", help="Read the current Feature/Test Registry directly")
    parser.add_argument("--phase", choices=("baseline", "final"), default="final")
    parser.add_argument("--scope", choices=("auto", "required", "affected", "full"), default="auto")
    parser.add_argument("--require-test")
    parser.add_argument("--continue", dest="continue_run", action="store_true")
    parser.add_argument(
        "--timeout-seconds", type=_positive_seconds, default=DEFAULT_TIMEOUT_SECONDS,
        help="Maximum test-process wall time (default: 120 seconds).",
    )
    args = parser.parse_args(list(argv))
    try:
        run_history_directory(REPO_ROOT, args.feature)
    except ValueError as error:
        parser.error(str(error))
    if args.godot_binary is None:
        try:
            config = read_json(REPO_ROOT / "docs/methodology-config.json")
            args.godot_binary = config["environment_bootstrap"]["engine_executable"]
        except (OSError, ValueError, KeyError, TypeError) as error:
            parser.error(f"cannot read configured Godot executable: {error}")
    if not isinstance(args.godot_binary, str) or not args.godot_binary.strip():
        parser.error("Godot executable must be configured or supplied with --godot-binary")
    return args


def main() -> int:
    args = _parse_args(sys.argv[1:])
    return _run_tests(args)


if __name__ == "__main__":
    sys.exit(main())
