# 试用副本必须改名并读回确认；改名失败时不同步，运行脚本也拒绝在未改名的副本里启动 Godot。
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import importlib.util
import io
import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from unittest import mock

TOOLS = PROJECT_ROOT / "yaya/tools/ui-trial"
PROJECT = '; Engine configuration file.\nconfig_version=5\n\n[application]\n\nconfig/name="Demo \\"Q\\""\n{extra}\n[display]\n\nwindow/size/viewport_width=800\n'


class UiTrialCopyTests(unittest.TestCase):
    def setUp(self) -> None:
        area = tempfile.TemporaryDirectory()
        self.addCleanup(area.cleanup)
        self.source = Path(area.name) / "game"
        self.copy = Path(area.name) / "game-trial"
        self.write(self.source / "project.godot", PROJECT.format(extra=""))
        self.write(self.source / "game/main.gd", "extends Node\n")
        self.write(self.source / ".godot/uid_cache.bin", "cache")
        self.write(self.source / ".git/HEAD", "ref: refs/heads/main\n")
        self.write(self.source / "reports/run.log", "source report")

    def write(self, path: Path, text: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def prepare(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "-B", str(TOOLS / "prepare-trial-copy.py"), "--project", str(self.source),
             "--copy", str(self.copy)], capture_output=True, encoding="utf-8", check=False)

    def run_trial(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "-B", str(TOOLS / "run-ui-trial.py"), "--copy", str(self.copy),
             "--script", "res://driver.gd"], capture_output=True, encoding="utf-8", check=False)

    def test_copy_is_renamed_read_back_and_synced(self) -> None:
        self.write(self.copy / "project.godot", PROJECT.format(extra=""))
        self.write(self.copy / "game/removed.gd", "extends Node\n")
        self.write(self.copy / "reports/ui-trial/drivers/walk.gd", "extends Node\n")
        result = self.prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('config/name="Demo \\"Q\\" trial"', (self.copy / "project.godot").read_text(encoding="utf-8"))
        self.assertIn("window/size/viewport_width=800", (self.copy / "project.godot").read_text(encoding="utf-8"))
        self.assertTrue((self.copy / "game/main.gd").is_file())
        self.assertTrue((self.copy / ".godot/uid_cache.bin").is_file())
        self.assertFalse((self.copy / ".git").exists())
        self.assertFalse((self.copy / "game/removed.gd").exists())
        self.assertFalse((self.copy / "reports/run.log").exists())
        self.assertTrue((self.copy / "reports/ui-trial/drivers/walk.gd").is_file())
        self.assertTrue((self.copy / "reports/.gdignore").is_file())
        self.assertIn('config/name="Demo \\"Q\\""', (self.source / "project.godot").read_text(encoding="utf-8"))

    def test_worktree_git_file_is_not_copied_and_a_copy_of_it_is_removed(self) -> None:
        shutil.rmtree(self.source / ".git")
        pointer = "gitdir: D:/repo/.git/worktrees/game\n"
        self.write(self.source / ".git", pointer)
        # A copy prepared before this fix holds the source worktree's pointer.
        self.write(self.copy / "project.godot", PROJECT.format(extra=""))
        self.write(self.copy / ".git", pointer)
        result = self.prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.copy / ".git").exists())
        # The copy's own Git data is kept on the next sync.
        own = "gitdir: D:/other/.git/worktrees/trial\n"
        self.write(self.copy / ".git", own)
        result = self.prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.copy / ".git").read_text(encoding="utf-8"), own)

    def test_an_unreadable_directory_stops_the_sync(self) -> None:
        locked = self.source / "game/locked"
        self.write(locked / "hidden.gd", "extends Node\n")
        spec = importlib.util.spec_from_file_location("prepare_trial_copy", TOOLS / "prepare-trial-copy.py")
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        self.addCleanup(sys.modules.pop, spec.name, None)
        spec.loader.exec_module(module)
        real = os.scandir

        def scandir(path="."):
            if Path(path) == locked:
                raise PermissionError(13, "Access is denied", str(path))
            return real(path)

        errors = io.StringIO()
        with mock.patch.object(os, "scandir", scandir), redirect_stderr(errors), redirect_stdout(io.StringIO()):
            code = module.main(["--project", str(self.source), "--copy", str(self.copy)])
        self.assertEqual(code, 1)
        self.assertIn("sync stopped", errors.getvalue())

    def test_failed_rename_aborts_before_sync_and_the_runner_refuses_the_copy(self) -> None:
        locked = self.copy / "project.godot"
        self.write(locked, PROJECT.format(extra=""))
        os.chmod(locked, stat.S_IREAD)
        self.addCleanup(os.chmod, locked, stat.S_IWRITE | stat.S_IREAD)
        result = self.prepare()
        self.assertEqual(result.returncode, 1)
        self.assertIn("cannot write", result.stderr)
        self.assertFalse((self.copy / "game/main.gd").exists())
        refused = self.run_trial()
        self.assertEqual(refused.returncode, 2)
        self.assertIn("does not end with ' trial'", refused.stderr)

    def test_projects_whose_user_data_cannot_be_separated_are_refused(self) -> None:
        self.write(self.source / "project.godot", PROJECT.format(extra="config/use_custom_user_dir=true\n"))
        result = self.prepare()
        self.assertEqual(result.returncode, 1)
        self.assertIn("use_custom_user_dir", result.stderr)
        self.write(self.source / "project.godot", "config_version=5\n\n[application]\n\nrun/main_scene=\"res://m.tscn\"\n")
        result = self.prepare()
        self.assertEqual(result.returncode, 1)
        self.assertIn("no [application] config/name", result.stderr)
        self.assertFalse((self.copy / "game/main.gd").exists())

    def test_copy_paths_that_could_overwrite_real_files_are_refused(self) -> None:
        self.write(self.source / "project.godot", PROJECT.format(extra="").replace('Q\\""', 'Q\\" trial"'))
        self.assertEqual(self.prepare().returncode, 2)
        self.write(self.source / "project.godot", PROJECT.format(extra=""))
        self.write(self.copy / "notes.txt", "not a project")
        self.assertEqual(self.prepare().returncode, 2)
        self.assertEqual((self.copy / "notes.txt").read_text(encoding="utf-8"), "not a project")
        self.copy = self.source / "game"
        self.assertEqual(self.prepare().returncode, 2)


if __name__ == "__main__":
    unittest.main()
