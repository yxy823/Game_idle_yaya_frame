"""Executable fields are paths; command fields use the host command grammar."""
# 路径夹具区分纯可执行文件路径与带参数命令；版本探针的实机结果须另行记录。
from __future__ import annotations
from project_context import PROJECT_ROOT

import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

TOOLS = (PROJECT_ROOT / "tools")
SPEC = importlib.util.spec_from_file_location("environment_path_contract", TOOLS / "checks/check-project-environment.py")
environment = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(environment)


class ExecutablePathContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="yaya path contract ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.executable = self.root / "Tool Folder" / "工具 python.exe"
        self.executable.parent.mkdir()
        shutil.copy2(sys.executable, self.executable)
        # A copied CPython executable still needs its installed runtime. This is
        # an executable-path fixture, not a copied independent Python install.
        runtime = str(Path(sys.executable).parent)
        self.runtime_env = patch.dict(os.environ, {
            "PATH": runtime + os.pathsep + os.environ.get("PATH", ""),
            "PYTHONHOME": sys.prefix,
        })
        self.runtime_env.start()
        self.addCleanup(self.runtime_env.stop)
        result = subprocess.run([str(self.executable), "--version"], cwd=self.root,
                                capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.version = result.stdout.strip()
        self.assertTrue(self.version.startswith("Python "), self.version)

    def config(self, executable: str) -> dict:
        command = subprocess.list2cmdline([str(self.executable), "--version"])
        bootstrap = {"status": "ready", "engine_executable": executable,
                     "engine_version": self.version}
        return {"document_language": "en", "python_executable": executable,
                "test_cmd": command,
                "engine": "Godot 4.7", "language": "GDScript", "test_framework": "gdunit4",
                "environment_bootstrap": bootstrap}

    def test_actual_absolute_space_and_unicode_path_is_not_split(self) -> None:
        config = self.config(str(self.executable))
        self.assertEqual(environment._schema_errors(config, self.root), [])
        # 实际 Python 探针证明完整路径可启动，但不能冒充 Godot 就绪。
        self.assertEqual(environment._readiness_errors(config, self.root),
                         ["engine executable must report Godot 4.7.x"])
        observed, error = environment._read_engine_version(
            environment._resolve_executable_path(config["environment_bootstrap"]["engine_executable"], self.root), self.root)
        self.assertIsNone(error)
        self.assertEqual(observed, self.version)

    def test_actual_relative_space_and_unicode_path_resolves_from_project_root(self) -> None:
        config = self.config(self.executable.relative_to(self.root).as_posix())
        # 实际 Python 探针证明完整路径可启动，但不能冒充 Godot 就绪。
        self.assertEqual(environment._readiness_errors(config, self.root),
                         ["engine executable must report Godot 4.7.x"])
        observed, error = environment._read_engine_version(
            environment._resolve_executable_path(config["environment_bootstrap"]["engine_executable"], self.root), self.root)
        self.assertIsNone(error)
        self.assertEqual(observed, self.version)

    def test_actual_probe_detects_version_mismatch_at_complete_path(self) -> None:
        config = self.config(str(self.executable))
        config["environment_bootstrap"]["engine_version"] = "different recorded version"
        errors = environment._readiness_errors(config, self.root)
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("engine version mismatch", errors[0])
        self.assertIn(self.version, errors[0])

    def test_missing_file_is_not_rescued_by_a_similarly_named_path_command(self) -> None:
        config = self.config("Missing Folder/工具 python.exe")
        with patch.object(environment.shutil, "which", return_value=sys.executable):
            errors = environment._readiness_errors(config, self.root)
        self.assertTrue(any("Python executable is unavailable" in error for error in errors), errors)
        self.assertTrue(any("engine executable is unavailable" in error for error in errors), errors)

    def test_executable_fields_do_not_accept_appended_arguments_or_shell_quotes(self) -> None:
        for value in (str(self.executable) + " --version", '"' + str(self.executable) + '"'):
            with self.subTest(value=value):
                errors = environment._readiness_errors(self.config(value), self.root)
                self.assertTrue(any("engine executable is unavailable" in error for error in errors), errors)

    def test_python_executable_is_required(self) -> None:
        config = self.config(str(self.executable))
        config.pop("python_executable")
        self.assertTrue(environment._schema_errors(config, self.root))

    def test_command_head_preserves_windows_path_quoting(self) -> None:
        cases = (('"C:\\Tool Folder\\工具.exe" --version', "C:\\Tool Folder\\工具.exe"),
                 ("C:\\Tools\\工具.exe --version", "C:\\Tools\\工具.exe"))
        for command, expected in cases:
            with self.subTest(command=command):
                self.assertEqual(environment._command_head(command), expected)

    def test_malformed_command_quote_is_unavailable(self) -> None:
        self.assertEqual(environment._command_head('"unfinished executable'), "")


if __name__ == "__main__":
    unittest.main()
