# 用中立配置和受控探针检查 incomplete / ready 边界；这些单测不代表宿主工具实际可用。
from __future__ import annotations
from project_context import PROJECT_ROOT

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

TOOLS_DIR = (PROJECT_ROOT / "tools")
SPEC = importlib.util.spec_from_file_location(
    "check_project_environment", TOOLS_DIR / "checks/check-project-environment.py"
)
assert SPEC is not None and SPEC.loader is not None
check_project_environment = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(check_project_environment)


class ProjectEnvironmentTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.repo_root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _config(self, status: str) -> dict[str, object]:
        return {
            "document_language": "en",
            "test_cmd": sys.executable,
            "test_framework": "gdunit4",
            "engine": "Godot 4.7",
            "language": "GDScript",
            "python_executable": sys.executable,
            "environment_bootstrap": {
                "status": status,
                "engine_executable": "",
                "engine_version": "",
            },
        }

    def _ready_config(self, engine_version: str) -> dict[str, object]:
        config = self._config("ready")
        config["test_framework"] = "gdunit4"
        bootstrap = config["environment_bootstrap"]
        assert isinstance(bootstrap, dict)
        bootstrap.update(engine_executable=sys.executable, engine_version=engine_version)
        return config

    def test_incomplete_allows_unconfigured_engine(self) -> None:
        errors = check_project_environment._schema_errors(
            self._config("incomplete"), self.repo_root
        )
        self.assertEqual(errors, [])

    def test_engine_version_field_is_required(self) -> None:
        config = self._config("incomplete")
        bootstrap = config["environment_bootstrap"]
        assert isinstance(bootstrap, dict)
        del bootstrap["engine_version"]

        errors = check_project_environment._schema_errors(config, self.repo_root)

        self.assertIn("environment_bootstrap.engine_version is required", errors)

    def test_ready_requires_recorded_engine_path_and_version(self) -> None:
        errors = check_project_environment._schema_errors(
            self._config("ready"), self.repo_root
        )

        self.assertIn(
            "ready environment_bootstrap.engine_version must be configured", errors
        )
        self.assertIn(
            "ready environment_bootstrap.engine_executable must be configured", errors
        )

    def test_ready_configuration_needs_no_duplicate_plugin_metadata(self) -> None:
        errors = check_project_environment._schema_errors(
            self._ready_config("4.7.1.stable"), self.repo_root
        )
        self.assertEqual(errors, [])

    def test_fixed_stack_is_required_even_before_machine_setup(self) -> None:
        for status in ("incomplete", "ready"):
            for key, value in (("engine", "unconfigured"), ("engine", "other-engine"),
                               ("language", "Python"), ("test_framework", "other-runner")):
                with self.subTest(status=status, key=key, value=value):
                    config = self._config(status)
                    config[key] = value
                    errors = check_project_environment._schema_errors(config, self.repo_root)
                    self.assertTrue(any(error.startswith(key + " must be") for error in errors), errors)

    def test_incomplete_does_not_grant_readiness(self) -> None:
        errors = check_project_environment._readiness_errors(self._config("incomplete"), self.repo_root)
        self.assertIn("environment_bootstrap.status is incomplete", errors)

    def test_matching_recorded_version_cannot_authorize_a_different_engine_version(self) -> None:
        config = self._ready_config("4.8.0.stable")
        with mock.patch.object(check_project_environment, "_read_engine_version",
                               return_value=("4.8.0.stable", None)):
            errors = check_project_environment._readiness_errors(config, self.repo_root)
        self.assertIn("engine executable must report Godot 4.7.x", errors)

    def test_readiness_accepts_matching_engine_version(self) -> None:
        config = self._ready_config("4.7.1.stable")
        completed = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="4.7.1.stable\n", stderr=""
        )

        with mock.patch.object(
            check_project_environment.subprocess, "run", return_value=completed
        ):
            errors = check_project_environment._readiness_errors(
                config, self.repo_root
            )

        self.assertEqual(errors, [])

    def test_readiness_rejects_engine_version_mismatch(self) -> None:
        config = self._ready_config("4.7.1.stable")
        completed = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="4.8.0.stable\n", stderr=""
        )

        with mock.patch.object(
            check_project_environment.subprocess, "run", return_value=completed
        ):
            errors = check_project_environment._readiness_errors(
                config, self.repo_root
            )

        self.assertIn(
            "engine version mismatch: recorded '4.7.1.stable', observed '4.8.0.stable'",
            errors,
        )


if __name__ == "__main__":
    unittest.main()
