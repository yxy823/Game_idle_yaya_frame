#!/usr/bin/env python3
"""Check project configuration and, on request, actual tool availability."""
# 显式检查已有配置；不生成配置、不安装依赖、不初始化 Git。就绪检查会启动 Godot 版本探针。
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any, Iterable

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = REPO_ROOT / "docs" / "methodology-config.json"
UNCONFIGURED = {"", "unconfigured"}
# Lexical screening only; full BCP 47 validity and unusual tags remain an Agent check.
DOCUMENT_LANGUAGE_SHAPE = re.compile(
    r"(?:[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*|[iIxX](?:-[A-Za-z0-9]{1,8})+)"
)


def _read_config(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ValueError(f"configuration file is missing: {path}") from exc
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read configuration {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ValueError("methodology configuration root must be an object")
    return data


def _nonempty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip()) and value.strip().lower() not in UNCONFIGURED


def _python_executable(config: dict[str, Any]) -> str:
    """The executable field is a complete path/name, never a command line."""
    value = config.get("python_executable")
    if not _nonempty_string(value):
        raise ValueError("python_executable must be a configured non-empty executable path or name")
    return value


# 先把完整字符串当作文件路径，保留空格和非 ASCII 文件名。
def _resolve_executable_path(executable: str, repo_root: Path) -> Path:
    """Preserve an executable field whole, resolving relative paths at the root.

    PATH lookup applies only to a bare executable name. A missing configured
    path must not silently select a different installation from PATH. Shell
    quoting, variable expansion and appended arguments are not path syntax.
    """
    candidate = Path(executable)
    if candidate.is_absolute():
        return candidate
    repository_candidate = repo_root / candidate
    if repository_candidate.is_file():
        return repository_candidate
    separators = (os.sep,) if os.altsep is None else (os.sep, os.altsep)
    if any(separator in executable for separator in separators) or candidate.drive:
        return repository_candidate
    path_candidate = shutil.which(executable)
    return Path(path_candidate) if path_candidate is not None else repository_candidate


def _executable_exists(executable: str, repo_root: Path) -> bool:
    if not _nonempty_string(executable):
        return False
    candidate = _resolve_executable_path(executable, repo_root)
    return candidate.is_file()


def _read_engine_version(engine_executable: Path, repo_root: Path) -> tuple[str | None, str | None]:
    try:
        completed = subprocess.run(
            [str(engine_executable), "--version"],
            cwd=repo_root,
            capture_output=True,
            text=True,
            check=False,
            timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return None, f"could not execute engine --version: {exc}"
    if completed.returncode != 0:
        return None, f"engine --version exited with {completed.returncode}"
    version = completed.stdout.strip()
    if not version:
        return None, "engine --version returned no version"
    return version, None


def _schema_errors(config: dict[str, Any], repo_root: Path) -> list[str]:
    errors: list[str] = []
    document_language = config.get("document_language")
    if not _nonempty_string(document_language):
        errors.append("document_language must be a configured non-empty string")
    elif DOCUMENT_LANGUAGE_SHAPE.fullmatch(document_language) is None:
        errors.append("document_language must use a basic ASCII language-tag form such as en or zh-CN; "
                      "no whitespace, underscores, empty subtags or subtags longer than eight characters")
    try:
        _python_executable(config)
    except ValueError as error:
        errors.append(str(error))

    if not isinstance(config.get("engine_executable"), str):
        errors.append("engine_executable must be a string")
    return errors


# 读取已确认配置并核对实际工具；不在每个 Feature 中重新选择环境或写回配置。
def _readiness_errors(config: dict[str, Any], repo_root: Path) -> list[str]:
    errors: list[str] = []
    try:
        python_executable = _python_executable(config)
    except ValueError as error:
        errors.append(str(error))
    else:
        if not _executable_exists(python_executable, repo_root):
            errors.append(f"Python executable is unavailable: {python_executable!r}")

    engine_executable = config.get("engine_executable")
    if not _nonempty_string(engine_executable):
        errors.append("engine executable is not configured")
    # The gdUnit runner treats Godot as an absolute/project-relative file path;
    # readiness must probe that same file instead of accepting a PATH substitute.
    elif not (repo_root / engine_executable).resolve().is_file():
        errors.append(f"engine executable is unavailable: {engine_executable!r}; use an absolute or project-relative file path, not PATH lookup")
    else:
        observed_version, version_error = _read_engine_version(
            (repo_root / engine_executable).resolve(),
            repo_root,
        )
        if version_error is not None:
            errors.append(version_error)
        else:
            print(f"Observed Godot version: {observed_version}")
            if not re.match(r"^4\.7(?:\.\d+)?(?:\.|$)", observed_version):
                errors.append("engine executable must report Godot 4.7.x")

    if not (repo_root / "tools/testing/run-gdunit-tests.py").is_file():
        errors.append("test runner is missing: tools/testing/run-gdunit-tests.py")

    return errors


def _parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--require-ready", action="store_true")
    return parser.parse_args(list(argv))


def main() -> int:
    args = _parse_args(sys.argv[1:])
    config_path = args.config.resolve()
    repo_root = config_path.parent.parent
    try:
        config = _read_config(config_path)
        errors = _schema_errors(config, repo_root)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    if errors:
        print("ERROR: Invalid project environment configuration:\n- " + "\n- ".join(errors), file=sys.stderr)
        return 2

    if not args.require_ready:
        print("Project environment configuration: VALID (tools not probed)")
        return 0

    errors = _readiness_errors(config, repo_root)
    if errors:
        detail = "\n- ".join(errors)
        print("BLOCKED: Project Environment Bootstrap is not ready:\n- " + detail, file=sys.stderr)
        return 2

    print("Project Environment Bootstrap: READY")
    return 0


if __name__ == "__main__":
    sys.exit(main())
