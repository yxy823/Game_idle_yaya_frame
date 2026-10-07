"""Run ui-trial drivers and the static scan in real Godot against a throwaway fixture project.

Usage: python -B framework/tests/external-project/ui-trial/test_ui_trial_engine.py --project <project>
The project supplies yaya/tools/ui-trial and docs/methodology-config.json (engine_executable); the
fixture project is created in the system temp directory and its name ends with " trial".
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT_FILE = """config_version=5

[application]

config/name="{name}"
config/features=PackedStringArray("4.7")

[display]

window/size/viewport_width=800
window/size/viewport_height=600
"""
EXPECTED_SCAN = {
    ("S01", "IconOnly"), ("S02", "Vague"), ("S03", "SaveA"), ("S04", "Tiny"),
    ("S05", "DeleteSave"), ("S05", "MarkedDanger"), ("S10", "LockedNoTip"),
}
PROJECT_ROOT: Path


class UiTrialEngineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tools = PROJECT_ROOT / "yaya/tools/ui-trial"
        config = json.loads((PROJECT_ROOT / "docs/methodology-config.json").read_text(encoding="utf-8"))
        cls.engine = str((PROJECT_ROOT / config["engine_executable"]).resolve())

    def setUp(self) -> None:
        area = tempfile.TemporaryDirectory(prefix="ui_trial_fixture_")
        self.addCleanup(area.cleanup)
        self.copy = Path(area.name)
        (self.copy / "project.godot").write_text(PROJECT_FILE.format(name="UI trial fixture trial"), encoding="utf-8")
        (self.copy / "docs").mkdir()
        (self.copy / "docs/methodology-config.json").write_text(
            json.dumps({"engine_executable": self.engine}), encoding="utf-8")
        target = self.copy / "yaya/tools/ui-trial"
        target.mkdir(parents=True)
        for script in self.tools.glob("*.gd"):
            shutil.copy2(script, target / script.name)
        for fixture in [*HERE.glob("*.gd"), HERE / "scan_cases.tscn"]:
            shutil.copy2(fixture, self.copy / fixture.name)

    def run_trial(self, script: str, *extra: str, timeout: str = "60", watchdog: str = "20"):
        started = time.monotonic()
        result = subprocess.run(
            [sys.executable, "-B", str(self.tools / "run-ui-trial.py"), "--copy", str(self.copy), "--script", script,
             "--timeout-seconds", timeout, "--watchdog-seconds", watchdog, *extra],
            capture_output=True, encoding="utf-8", errors="replace", check=False, timeout=float(timeout) + 60)
        output = next(Path(line.split(": ", 1)[1]) for line in result.stdout.splitlines() if line.startswith("output: "))
        steps = output / "steps.log"
        return result, (steps.read_text(encoding="utf-8") if steps.is_file() else ""), output, time.monotonic() - started

    def test_watchdog_ends_a_stuck_driver_with_exit_code_2(self) -> None:
        result, steps, _output, elapsed = self.run_trial("hang_driver.gd", watchdog="3")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("godot exit code: 2", result.stdout)
        self.assertIn("watchdog expired", steps)
        self.assertLess(elapsed, 40)

    def test_outer_timeout_ends_a_blocked_process_tree(self) -> None:
        result, steps, _output, _elapsed = self.run_trial("busy_driver.gd", timeout="8", watchdog="3")
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn("process tree ended", result.stdout)
        self.assertIn("none left running", result.stdout)
        self.assertNotIn("watchdog expired", steps)

    def test_script_error_stops_the_driver_immediately(self) -> None:
        result, steps, _output, elapsed = self.run_trial("error_driver.gd")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("godot exit code: 1", result.stdout)
        self.assertIn("FAIL: engine error: Out of bounds", steps)
        self.assertNotIn("all steps done", steps)
        self.assertLess(elapsed, 15)

    def test_actions_click_read_and_key_injection(self) -> None:
        result, steps, _output, _elapsed = self.run_trial("actions_driver.gd")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        for line in ("ok: click emits pressed once", "ok: press_key reaches _input once (pressed only)",
                     "ok: text_of reads the button text", "button LockedNoTip can be clicked; it is disabled"):
            self.assertIn(line, steps)

    def test_driver_refuses_a_project_without_the_trial_suffix(self) -> None:
        (self.copy / "project.godot").write_text(PROJECT_FILE.format(name="UI trial fixture"), encoding="utf-8")
        output = self.copy / "out"
        result = subprocess.run(
            [self.engine, "--headless", "--path", str(self.copy), "--script", "res://hang_driver.gd", "--",
             f"--ui-trial-out={output.as_posix()}", "--ui-trial-watchdog=5"],
            capture_output=True, encoding="utf-8", errors="replace", check=False, timeout=60)
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn("REFUSED", (output / "steps.log").read_text(encoding="utf-8"))

    def test_scan_reports_positive_cases_and_skips_negative_ones(self) -> None:
        result, _steps, output, _elapsed = self.run_trial(
            "res://yaya/tools/ui-trial/ui_scan.gd", "--", "--scenes=res://scan_cases.tscn")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        scan = json.loads((output / "scan.json").read_text(encoding="utf-8"))
        found = {(item["rule"], item["control"]) for item in scan["scenes"][0]["findings"]}
        self.assertEqual(found, EXPECTED_SCAN)


def main() -> int:
    global PROJECT_ROOT
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project", required=True, type=Path)
    args, rest = parser.parse_known_args()
    PROJECT_ROOT = args.project.resolve()
    if not (PROJECT_ROOT / "yaya/tools/ui-trial/run-ui-trial.py").is_file():
        parser.error(f"{PROJECT_ROOT} has no yaya/tools/ui-trial")
    program = unittest.main(argv=[sys.argv[0], *rest], exit=False)
    return 0 if program.result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
