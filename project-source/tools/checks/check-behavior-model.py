#!/usr/bin/env python3
"""Run a TLA+ behavior model with TLC: the correct version, every injected error and every witness."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path

DEFAULT_REPO_ROOT = Path(__file__).resolve().parents[3]
CONFIG_PATH = Path("docs/methodology-config.json")
REPORT_ROOT = Path("reports/model-checks")
NAME_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
VIOLATION_RES = (
    re.compile(r"Invariant (\w+) is violated"),
    re.compile(r"Action property (\w+) is violated"),
)


class ModelCheckError(Exception):
    pass


def _names(manifest: dict, key: str, required: bool) -> list[str]:
    value = manifest.get(key, [])
    if not isinstance(value, list) or (required and not value) \
            or not all(isinstance(item, str) and NAME_RE.fullmatch(item) for item in value):
        raise ModelCheckError(f"{key} must be a {'non-empty ' if required else ''}list of TLA+ names")
    return value


def read_manifest(path: Path) -> dict:
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ModelCheckError(f"cannot read {path.name}: {exc}") from exc
    if not isinstance(manifest, dict):
        raise ModelCheckError(f"{path.name} must be a JSON object")
    for key in ("spec", "constraint"):
        value = manifest.get(key, "Spec" if key == "spec" else None)
        if value is not None and not (isinstance(value, str) and NAME_RE.fullmatch(value)):
            raise ModelCheckError(f"{key} must be a TLA+ name")
    if not isinstance(manifest.get("check_deadlock", True), bool):
        raise ModelCheckError("check_deadlock must be true or false")
    invariants = _names(manifest, "invariants", False)
    properties = _names(manifest, "properties", False)
    if not invariants and not properties:
        raise ModelCheckError("invariants and properties are both empty")
    _names(manifest, "witnesses", True)
    mutations = manifest.get("mutations")
    if not isinstance(mutations, list) or not mutations:
        raise ModelCheckError("mutations must be a non-empty list")
    checked = set(invariants) | set(properties)
    seen = set()
    for mutation in mutations:
        name = mutation.get("name") if isinstance(mutation, dict) else None
        if not isinstance(name, str) or not NAME_RE.fullmatch(name) or name == "none" or name in seen:
            raise ModelCheckError("each mutation needs a unique TLA+ name other than none")
        seen.add(name)
        caught_by = _names(mutation, "caught_by", True)
        if not set(caught_by) <= checked:
            raise ModelCheckError(f"mutation {name}: caught_by names must be listed invariants or properties")
    covers = manifest.get("covers", [])
    if not isinstance(covers, list) or not all(
            isinstance(item, str) and item and not Path(item).is_absolute() and ".." not in Path(item).parts
            for item in covers):
        raise ModelCheckError("covers must be a list of paths relative to the project root")
    return manifest


def _git(repo_root: Path, *args: str) -> str | None:
    try:
        completed = subprocess.run(["git", "-C", str(repo_root), *args], capture_output=True, text=True,
                                   encoding="utf-8", errors="replace", check=False)
    except OSError:
        return None
    return completed.stdout if completed.returncode == 0 else None


def covered_changes(repo_root: Path, model: Path, manifest: dict) -> dict:
    """List changes to the covered code made after the last commit that changed the model."""
    covers = manifest.get("covers", [])
    if not covers:
        return {"status": "no_covers"}
    model_files = [model.relative_to(repo_root).as_posix(),
                   model.with_suffix(".checks.json").relative_to(repo_root).as_posix()]
    since = (_git(repo_root, "log", "-1", "--format=%H", "--", *model_files) or "").strip()
    if not since:
        return {"status": "untracked"}
    commits = _git(repo_root, "log", "--format=%h %s", f"{since}..HEAD", "--", *covers)
    uncommitted = _git(repo_root, "status", "--porcelain", "--", *covers)
    if commits is None or uncommitted is None:
        return {"status": "untracked"}
    return {"status": "checked", "since": since[:12], "commits": commits.splitlines(),
            "uncommitted": [line[3:] for line in uncommitted.splitlines()]}


def read_tools(repo_root: Path) -> tuple[Path, Path]:
    try:
        config = json.loads((repo_root / CONFIG_PATH).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ModelCheckError(f"cannot read {CONFIG_PATH.as_posix()}: {exc}") from exc
    paths = []
    for key in ("java_executable", "tla_tools_jar"):
        value = config.get(key)
        if not isinstance(value, str) or not value.strip():
            raise ModelCheckError(f"{key} is not configured in {CONFIG_PATH.as_posix()}")
        path = (repo_root / value).resolve()
        if not path.is_file():
            raise ModelCheckError(f"{key} does not exist: {path}")
        paths.append(path)
    return paths[0], paths[1]


def plan_runs(manifest: dict) -> list[dict]:
    invariants = manifest.get("invariants", [])
    properties = manifest.get("properties", [])
    runs = [{"name": "correct", "kind": "correct", "mutation": "none",
             "invariants": invariants, "properties": properties}]
    # TLC 只报告第一个查到的违反，所以错误版本的每条 caught_by 单独运行，只检查这一条。
    runs += [{"name": f"mutation-{item['name']}-{name}", "kind": "mutation", "mutation": item["name"],
              "invariants": [name] if name in invariants else [],
              "properties": [name] if name in properties else [], "caught_by": [name]}
             for item in manifest["mutations"] for name in item["caught_by"]]
    runs += [{"name": f"witness-{name}", "kind": "witness", "mutation": "none",
              "invariants": [name], "properties": []}
             for name in manifest["witnesses"]]
    return runs


def config_text(manifest: dict, run: dict) -> str:
    lines = [f"SPECIFICATION {manifest.get('spec', 'Spec')}", f'CONSTANT Mutation = "{run["mutation"]}"']
    if manifest.get("constraint"):
        lines.append(f"CONSTRAINT {manifest['constraint']}")
    if not manifest.get("check_deadlock", True) or run["kind"] != "correct":
        lines.append("CHECK_DEADLOCK FALSE")
    lines += [f"INVARIANT {name}" for name in run["invariants"]]
    lines += [f"PROPERTY {name}" for name in run["properties"]]
    return "\n".join(lines) + "\n"


def parse_output(text: str) -> dict:
    """Classify one TLC log: completed, violated (with the property name) or error."""
    states = re.findall(r"([\d,]+) distinct states found", text)
    result = {"distinct_states": int(states[-1].replace(",", "")) if states else None}
    for pattern in VIOLATION_RES:
        match = pattern.search(text)
        if match:
            return {**result, "outcome": "violated", "violated": match.group(1)}
    if "Temporal properties were violated" in text:
        return {**result, "outcome": "violated", "violated": "temporal"}
    if "Deadlock reached" in text:
        return {**result, "outcome": "violated", "violated": "deadlock"}
    if "Model checking completed. No error has been found." in text:
        return {**result, "outcome": "completed", "violated": None}
    error = re.search(r"^Error: .*$", text, re.MULTILINE)
    return {**result, "outcome": "error", "violated": None, "error": error.group(0) if error else None}


def judge(run: dict, parsed: dict) -> bool:
    if run["kind"] == "correct":
        return parsed["outcome"] == "completed"
    if parsed["outcome"] != "violated":
        return False
    if run["kind"] == "witness":
        return parsed["violated"] == run["invariants"][0]
    # 错误版本的运行只检查一条性质，时序违反就是这一条。
    return parsed["violated"] in (run["caught_by"][0], "temporal" if run["properties"] else None)


def run_tlc(java: Path, jar: Path, model: Path, cfg: str, log: Path, timeout: float) -> dict:
    with tempfile.TemporaryDirectory(prefix="model-check-") as temporary:
        work = Path(temporary)
        for module in model.parent.glob("*.tla"):
            shutil.copy2(module, work / module.name)
        (work / f"{model.stem}.cfg").write_text(cfg, encoding="utf-8")
        # TLC 按模型所在目录解析配置文件名，所以配置和模型放在同一个临时目录。
        command = [str(java), "-XX:+UseParallelGC", "-cp", str(jar), "tlc2.TLC", "-workers", "auto",
                   "-config", f"{model.stem}.cfg", "-metadir", str(work / "states"), str(work / model.name)]
        try:
            completed = subprocess.run(command, capture_output=True, text=True, encoding="utf-8",
                                       errors="replace", check=False, timeout=timeout)
        except OSError as exc:
            raise ModelCheckError(f"cannot start java: {exc}") from exc
        except subprocess.TimeoutExpired:
            log.write_text(f"TLC timed out after {timeout:.0f} seconds\n", encoding="utf-8")
            return {**parse_output(""), "exit_code": None, "timed_out": True}
    output = completed.stdout + completed.stderr
    log.write_text(output, encoding="utf-8")
    return {**parse_output(output), "exit_code": completed.returncode}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", help="the .tla file, relative to the project root; <name>.checks.json sits next to it")
    parser.add_argument("--repo-root", type=Path, default=DEFAULT_REPO_ROOT)
    parser.add_argument("--timeout-minutes", type=float, default=30,
                        help="stop one TLC run after this many minutes and report an error (default 30)")
    args = parser.parse_args(argv)
    repo_root = args.repo_root.resolve()
    model = (repo_root / args.model).resolve()
    try:
        if not model.is_relative_to(repo_root) or model.suffix != ".tla" or not model.is_file():
            raise ModelCheckError(f"model not found: {model}")
        manifest = read_manifest(model.with_suffix(".checks.json"))
        java, jar = read_tools(repo_root)
        drift = covered_changes(repo_root, model, manifest)
        run_dir = repo_root / REPORT_ROOT / model.stem / f"run-{datetime.now():%Y%m%d-%H%M%S-%f}"
        (run_dir / "logs").mkdir(parents=True, exist_ok=False)
        results = []
        for run in plan_runs(manifest):
            log = run_dir / "logs" / f"{run['name']}.log"
            parsed = run_tlc(java, jar, model, config_text(manifest, run), log, args.timeout_minutes * 60)
            results.append({**run, **parsed, "passed": judge(run, parsed),
                            "log": log.relative_to(repo_root).as_posix()})
    except ModelCheckError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    checked = set(manifest.get("invariants", [])) | set(manifest.get("properties", []))
    caught = {name for item in manifest["mutations"] for name in item["caught_by"]}
    summary = {
        "model": model.relative_to(repo_root).as_posix(),
        "model_sha256": hashlib.sha256(model.read_bytes()).hexdigest(),
        "manifest": manifest,
        "tla_tools_jar": str(jar),
        "properties_without_mutation": sorted(checked - caught),
        "covered_changes": drift,
        "runs": results,
    }
    (run_dir / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for item in results:
        expected = "completed" if item["kind"] == "correct" else f"violates {(item['invariants'] + item['properties'])[0]}"
        actual = f"violates {item['violated']}" if item["outcome"] == "violated" else item["outcome"]
        if item.get("error"):
            actual += f" ({item['error']})"
        print(f"{'PASS' if item['passed'] else 'FAIL'}  {item['name']}: expected {expected}; "
              f"actual {actual}; distinct states {item['distinct_states']}")
    if summary["properties_without_mutation"]:
        print("properties without an injected error: " + ", ".join(summary["properties_without_mutation"]))
    if drift["status"] == "no_covers":
        print("covers is empty: changes to the modeled code are not tracked")
    elif drift["status"] == "checked" and (drift["commits"] or drift["uncommitted"]):
        # 覆盖的代码改了而模型没改时，通过只说明旧的描述仍成立，要逐个读这些改动判断模型是否还描述代码。
        print(f"covered code changed after the model was last committed ({drift['since']}):")
        for line in drift["commits"]:
            print(f"  commit {line}")
        for path in drift["uncommitted"]:
            print(f"  uncommitted {path}")
    print(f"summary: {(run_dir / 'summary.json').relative_to(repo_root).as_posix()}")
    if any(item["outcome"] == "error" for item in results):
        return 2
    return 0 if all(item["passed"] for item in results) else 1


if __name__ == "__main__":
    sys.exit(main())
