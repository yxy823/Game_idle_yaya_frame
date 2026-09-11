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
ENGINE_FIELDS = ("engine_executable", "engine_version")


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


# 此函数只处理带参数命令；纯可执行文件路径走下面的路径解析契约。
def _command_head(command: str) -> str:
    """Read the executable from a Windows command field, preserving backslashes."""
    stripped = command.strip()
    head: list[str] = []
    quoted = False
    for character in stripped:
        if character == '"':
            quoted = not quoted
        elif character in " \t" and not quoted:
            break
        else:
            head.append(character)
    return "" if quoted else "".join(head)


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


def _command_exists(command: str, repo_root: Path) -> bool:
    head = _command_head(command)
    if not head:
        return False
    return _executable_exists(head, repo_root)


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
    for key in ("document_language",):
        if not _nonempty_string(config.get(key)):
            errors.append(f"{key} must be a configured non-empty string")
    try:
        _python_executable(config)
    except ValueError as error:
        errors.append(str(error))

    for key in ("test_cmd",):
        if not isinstance(config.get(key), str):
            errors.append(f"{key} must be a string")
    if config.get("full_test_cmd") is not None and not _nonempty_string(config.get("full_test_cmd")):
        errors.append("full_test_cmd must be null or a non-empty command string")

    bootstrap = config.get("environment_bootstrap")
    if not isinstance(bootstrap, dict):
        return errors + ["environment_bootstrap must be an object"]
    if bootstrap.get("status") not in {"incomplete", "ready"}:
        errors.append("environment_bootstrap.status must be incomplete or ready")
    # 固定技术栈与本机就绪分开：未安装工具合法，切换引擎不属于框架配置。
    for key, expected in {"engine": "Godot 4.7", "language": "GDScript", "test_framework": "gdunit4"}.items():
        if config.get(key) != expected:
            errors.append(f"{key} must be {expected!r}")

    # 只保存需要复用的路径和实际版本；缺项与阻塞原因由检查即时报告。
    for key in ENGINE_FIELDS:
        if key not in bootstrap:
            errors.append(f"environment_bootstrap.{key} is required")
        elif not isinstance(bootstrap[key], str):
            errors.append(f"environment_bootstrap.{key} must be a string")
    if bootstrap.get("status") == "ready":
        for key in ENGINE_FIELDS:
            if not _nonempty_string(bootstrap.get(key)):
                errors.append(f"ready environment_bootstrap.{key} must be configured")
    return errors


# 读取已确认配置并核对实际工具；不在每个 Feature 中重新选择环境或写回配置。
def _readiness_errors(config: dict[str, Any], repo_root: Path) -> list[str]:
    bootstrap = config["environment_bootstrap"]
    errors: list[str] = []
    if bootstrap.get("status") != "ready":
        errors.append("environment_bootstrap.status is incomplete")
    try:
        python_executable = _python_executable(config)
    except ValueError as error:
        errors.append(str(error))
    else:
        if not _executable_exists(python_executable, repo_root):
            errors.append(f"Python executable is unavailable: {python_executable!r}")

    engine_executable = bootstrap.get("engine_executable")
    if not _nonempty_string(engine_executable):
        errors.append("engine executable is not configured")
    elif not _executable_exists(engine_executable, repo_root):
        errors.append(f"engine executable is unavailable: {engine_executable!r}")
    elif _nonempty_string(bootstrap.get("engine_version")):
        observed_version, version_error = _read_engine_version(
            _resolve_executable_path(engine_executable, repo_root),
            repo_root,
        )
        if version_error is not None:
            errors.append(version_error)
        elif observed_version != bootstrap["engine_version"]:
            errors.append(
                "engine version mismatch: "
                f"recorded {bootstrap['engine_version']!r}, observed {observed_version!r}"
            )
        elif not re.match(r"^4\.7\.\d+(?:\.|$)", observed_version):
            errors.append("engine executable must report Godot 4.7.x")

    required_commands = {
        "primary test runner": config.get("test_cmd"),
    }
    if config.get("full_test_cmd") is not None:
        required_commands["full test runner"] = config["full_test_cmd"]
    for label, value in required_commands.items():
        if not _nonempty_string(value):
            errors.append(f"{label} is not configured")
        elif not _command_exists(value, repo_root):
            errors.append(f"{label} executable is unavailable: {_command_head(value)!r}")

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

    bootstrap = config["environment_bootstrap"]
    if not args.require_ready:
        print(
            "Project environment configuration: "
            f"{bootstrap['status'].upper()} ({config['engine']} / {config['language']})"
        )
        return 0

    errors = _readiness_errors(config, repo_root)
    if errors:
        detail = "\n- ".join(errors)
        print("BLOCKED: Project Environment Bootstrap is not ready:\n- " + detail, file=sys.stderr)
        return 2

    print(f"Project Environment Bootstrap: READY ({config['engine']} / {config['language']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
