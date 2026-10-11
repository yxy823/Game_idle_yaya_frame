# 用中立配置和受控探针检查 真实工具可用性；这些单测不代表宿主工具实际可用。
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import importlib.util
import subprocess
import tempfile
import unittest
from unittest import mock

TOOLS_DIR = (PROJECT_ROOT / "yaya/tools")
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
        runner = self.repo_root / "yaya/tools/testing/run-gdunit-tests.py"
        runner.parent.mkdir(parents=True)
        runner.write_text("# Runner path fixture\n", encoding="utf-8")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _config(self, engine_executable: str = "") -> dict[str, object]:
        return {
            "document_language": "en",
            "python_executable": sys.executable,
            "engine_executable": engine_executable,
        }

    def test_schema_allows_unconfigured_engine(self) -> None:
        errors = check_project_environment._schema_errors(
            self._config(), self.repo_root
        )
        self.assertEqual(errors, [])

    def test_document_language_accepts_common_and_best_effort_forms_without_normalizing(self) -> None:
        for tag in ("en", "zh-CN", "zh-Hant-TW", "es-419", "sr-Latn",
                    "en-US-u-ca-gregory", "x-private", "i-klingon", "EN-us"):
            with self.subTest(tag=tag):
                config = self._config()
                config["document_language"] = tag
                self.assertEqual(check_project_environment._schema_errors(config, self.repo_root), [])
                self.assertEqual(config["document_language"], tag)

    def test_document_language_rejects_invalid_characters_and_subtag_boundaries(self) -> None:
        for tag in (None, [], {}, 0, True, "", " ", "unconfigured", "zh_CN",
                    " zh-CN", "zh-CN ", "zh CN", "zh\tCN", "zh-\nCN", "zh-CN\n",
                    "-en", "en-", "zh--CN", "zh–CN", "123", "e", "x", "i",
                    "中文", "éñ", "abcdefghij", "en-abcdefghi", "en-US.UTF-8", "en/US"):
            with self.subTest(tag=tag):
                config = self._config()
                config["document_language"] = tag
                errors = check_project_environment._schema_errors(config, self.repo_root)
                self.assertTrue(any(error.startswith("document_language") for error in errors), errors)

    def test_engine_path_field_is_required_and_typed(self) -> None:
        for value in (None, 7, [], {}):
            with self.subTest(value=value):
                config = self._config()
                config["engine_executable"] = value
                self.assertIn("engine_executable must be a string",
                              check_project_environment._schema_errors(config, self.repo_root))
        config.pop("engine_executable")
        self.assertIn("engine_executable must be a string",
                      check_project_environment._schema_errors(config, self.repo_root))

    def test_ready_configuration_needs_no_duplicate_plugin_metadata(self) -> None:
        errors = check_project_environment._schema_errors(
            self._config(sys.executable), self.repo_root
        )
        self.assertEqual(errors, [])

    def test_empty_path_does_not_grant_readiness(self) -> None:
        errors = check_project_environment._readiness_errors(self._config(), self.repo_root)
        self.assertIn("engine executable is not configured", errors)

    def test_missing_fixed_runner_blocks_readiness(self) -> None:
        (self.repo_root / "yaya/tools/testing/run-gdunit-tests.py").unlink()
        with mock.patch.object(check_project_environment, "_read_engine_version",
                               return_value=("4.7.1.stable", None)):
            errors = check_project_environment._readiness_errors(
                self._config(sys.executable), self.repo_root
            )
        self.assertEqual(errors, ["test runner is missing: yaya/tools/testing/run-gdunit-tests.py"])

    def test_unsupported_engine_version_is_rejected(self) -> None:
        config = self._config(sys.executable)
        for version in ("4.8.0.stable", "4.70.stable", "4.6.9.stable", "4.7foo"):
            with self.subTest(version=version), mock.patch.object(
                    check_project_environment, "_read_engine_version", return_value=(version, None)):
                errors = check_project_environment._readiness_errors(config, self.repo_root)
                self.assertIn("engine executable must report Godot 4.7.x", errors)

    def test_zero_patch_version_uses_godot_branch_only_format(self) -> None:
        with mock.patch.object(check_project_environment, "_read_engine_version",
                               return_value=("4.7.stable.official.example", None)):
            self.assertEqual(check_project_environment._readiness_errors(
                self._config(sys.executable), self.repo_root), [])

    def test_optional_gva_python_accepts_empty_and_checks_absolute_path(self) -> None:
        config = self._config(sys.executable)
        config["visual_analyzer_python_executable"] = ""
        self.assertEqual(check_project_environment._schema_errors(config, self.repo_root), [])
        config["visual_analyzer_python_executable"] = "relative/gva-python.exe"
        self.assertTrue(check_project_environment._schema_errors(config, self.repo_root))
        config["visual_analyzer_python_executable"] = str(self.repo_root / "missing-gva.exe")
        self.assertEqual(check_project_environment._schema_errors(config, self.repo_root), [])
        with mock.patch.object(check_project_environment, "_read_engine_version",
                               return_value=("4.7.1.stable", None)):
            errors = check_project_environment._readiness_errors(config, self.repo_root)
        self.assertTrue(any("GVA Python executable is unavailable" in error for error in errors))

    def test_optional_gaa_python_accepts_empty_and_checks_absolute_path(self) -> None:
        config = self._config(sys.executable)
        for value in ("", sys.executable):
            config["audio_analyzer_python_executable"] = value
            self.assertEqual(check_project_environment._schema_errors(config, self.repo_root), [])
            with mock.patch.object(check_project_environment, "_read_engine_version",
                                   return_value=("4.7.1.stable", None)):
                self.assertEqual(check_project_environment._readiness_errors(config, self.repo_root), [])
        for value in (None, 4, [], "python", "relative/python.exe", " "):
            config["audio_analyzer_python_executable"] = value
            self.assertTrue(check_project_environment._schema_errors(config, self.repo_root), value)
        config["audio_analyzer_python_executable"] = str(self.repo_root / "missing-gaa.exe")
        self.assertEqual(check_project_environment._schema_errors(config, self.repo_root), [])
        with mock.patch.object(check_project_environment, "_read_engine_version",
                               return_value=("4.7.1.stable", None)):
            errors = check_project_environment._readiness_errors(config, self.repo_root)
        self.assertTrue(any("GAA Python executable is unavailable" in error for error in errors))

    def test_readiness_uses_observed_engine_version(self) -> None:
        config = self._config(sys.executable)
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

    def test_probe_failures_block_readiness(self) -> None:
        for completed in (
            subprocess.CompletedProcess([], 1, stdout="", stderr="failed"),
            subprocess.CompletedProcess([], 0, stdout="", stderr=""),
        ):
            with self.subTest(completed=completed), mock.patch.object(
                check_project_environment.subprocess, "run", return_value=completed
            ):
                self.assertTrue(check_project_environment._readiness_errors(
                    self._config(sys.executable), self.repo_root))
        with mock.patch.object(check_project_environment.subprocess, "run",
                               side_effect=subprocess.TimeoutExpired("godot", 30)):
            self.assertTrue(check_project_environment._readiness_errors(
                self._config(sys.executable), self.repo_root))

    def test_new_supported_patch_version_needs_no_recorded_version(self) -> None:
        with mock.patch.object(check_project_environment, "_read_engine_version",
                               return_value=("4.7.2.stable", None)):
            self.assertEqual(check_project_environment._readiness_errors(
                self._config(sys.executable), self.repo_root), [])

    def test_godot_requires_a_file_path_while_python_still_accepts_a_path_command(self) -> None:
        config = self._config(sys.executable)
        config["python_executable"] = "python-on-path"
        config["engine_executable"] = "godot-on-path"
        with mock.patch.object(check_project_environment.shutil, "which", return_value=sys.executable), \
                mock.patch.object(check_project_environment, "_read_engine_version",
                                  return_value=("4.7.1.stable", None)) as probe:
            errors = check_project_environment._readiness_errors(config, self.repo_root)
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("engine executable is unavailable", errors[0])
        probe.assert_not_called()


if __name__ == "__main__":
    unittest.main()
