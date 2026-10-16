#!/usr/bin/env python3
"""Run a ui-trial driver script inside a renamed trial copy with an outer timeout."""
# 外层超时与进程树清理沿用 gdunit_process：只结束本次创建的进程，不按进程名全局结束。
from __future__ import annotations

import argparse
import json
import math
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.lib.engine_executable import engine_executable_path
from tools.lib.gdunit_process import run_owned_process
from ui_trial_project import TRIAL_SUFFIX, read_project_name

DEFAULT_TIMEOUT_SECONDS = 180.0
WATCHDOG_MARGIN_SECONDS = 15.0
DRIVER_EXIT_MEANINGS = {0: "finished", 1: "step failed or engine error", 2: "watchdog expired",
                        3: "refused: project name does not end with ' trial'"}


def _positive(text: str) -> float:
    value = float(text)
    if not math.isfinite(value) or value <= 0:
        raise argparse.ArgumentTypeError("must be a finite number greater than 0")
    return value


def _parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--copy", required=True, type=Path, help="Trial copy prepared by prepare-trial-copy.py")
    parser.add_argument("--script", required=True, help="Driver script: res:// path or file inside the copy")
    parser.add_argument("--window", action="store_true", help="Open a real window (allows PNG screenshots)")
    parser.add_argument("--timeout-seconds", type=_positive, default=DEFAULT_TIMEOUT_SECONDS,
                        help="Outer wall-clock limit; the process tree is ended when it expires")
    parser.add_argument("--watchdog-seconds", type=_positive, default=None,
                        help=f"Driver watchdog (default: timeout minus {WATCHDOG_MARGIN_SECONDS:g})")
    parser.add_argument("script_args", nargs="*", help="Arguments after -- go to the driver script")
    args = parser.parse_args(argv)
    if args.watchdog_seconds is None:
        args.watchdog_seconds = max(1.0, args.timeout_seconds - WATCHDOG_MARGIN_SECONDS)
    if args.watchdog_seconds >= args.timeout_seconds:
        parser.error("--watchdog-seconds must be smaller than --timeout-seconds")
    return args


def _resource_path(copy: Path, script: str) -> str | None:
    if script.startswith("res://"):
        return script
    path = Path(script)
    path = (path if path.is_absolute() else copy / path).resolve()
    if not path.is_file() or not path.is_relative_to(copy):
        return None
    return "res://" + path.relative_to(copy).as_posix()


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    copy = args.copy.resolve()
    project_file = copy / "project.godot"
    if not project_file.is_file():
        print(f"ERROR: no project.godot in {copy}", file=sys.stderr)
        return 2
    name = read_project_name(project_file)
    if not name or not name.endswith(TRIAL_SUFFIX):
        print(f"ERROR: config/name {name!r} does not end with {TRIAL_SUFFIX!r}; run prepare-trial-copy.py first",
              file=sys.stderr)
        return 2
    script = _resource_path(copy, args.script)
    if script is None:
        print(f"ERROR: driver script {args.script} is not a file inside {copy}", file=sys.stderr)
        return 2
    try:
        engine = json.loads((copy / "docs/methodology-config.json").read_text(encoding="utf-8"))["engine_executable"]
    except (OSError, ValueError, KeyError) as error:
        print(f"ERROR: cannot read engine_executable from the copy's docs/methodology-config.json: {error}",
              file=sys.stderr)
        return 2
    executable = engine_executable_path(copy, engine)
    if executable is None or not executable.is_file():
        print(f"ERROR: Godot executable not found: {engine!r}", file=sys.stderr)
        return 2
    base = copy / "reports/ui-trial" / f"{Path(script).stem}-{datetime.now():%Y%m%d-%H%M%S}"
    output, number = base, 1
    while output.exists():
        number += 1
        output = base.with_name(f"{base.name}-{number}")
    output.mkdir(parents=True)
    command = [str(executable), *([] if args.window else ["--headless"]), "--path", str(copy),
               "--script", script, "--", f"--ui-trial-out={output.as_posix()}",
               f"--ui-trial-watchdog={args.watchdog_seconds:g}", *args.script_args]
    try:
        code, timed_out, _pid, log, owned = run_owned_process(
            command, copy, output / "engine.log", args.timeout_seconds)
    except TimeoutError as error:
        print(f"ERROR: Godot processes left running after the trial: {error}", file=sys.stderr)
        return 4
    print(f"output: {output}")
    print(f"processes ended: {len(owned)} owned, none left running")
    if timed_out:
        print(f"FAIL: outer timeout {args.timeout_seconds:g}s expired; process tree ended")
        return 3
    script_errors = [line for line in log.splitlines() if "SCRIPT ERROR" in line]
    print(f"godot exit code: {code} ({DRIVER_EXIT_MEANINGS.get(code, 'engine failure')})")
    for line in script_errors[:5]:
        print(line)
    if code != 0 or script_errors:
        print("FAIL: see steps.log and engine.log in the output directory")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
