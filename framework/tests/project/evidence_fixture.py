"""Synthetic run artifacts used only to test the evidence verifier."""
# 为证据校验器构造可控工件；合成通过/失败记录只供测试断言，不能用于实际 Feature 验收。
from __future__ import annotations

import json
import sys
import time
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

from tools.lib.gate_evidence import current_snapshot
from tools.lib.run_evidence import expected_gdunit_cases, file_hash, write_run_manifest
from tools.lib.test_selection import build_selection, execution_selectors


def make_run(root: Path, *, scope: str = "full", skipped: bool = False,
             omit: str | None = None, exit_code: int = 0, phase: str = "final") -> tuple[dict, Path]:
    plan = build_selection(root, "F001", phase=phase)
    selectors = execution_selectors(root, plan, scope)
    expected = expected_gdunit_cases(root, selectors)
    directory = root / "reports" / ("run-" + uuid.uuid4().hex)
    directory.mkdir(parents=True)
    from tools.lib.execution_attempts import attempt
    # Synthetic pre-launch record only; these fixtures never claim a real run.
    with attempt(root, "tests", directory, selection=plan, scope=scope):
        pass
    snapshot = current_snapshot(root)
    started = time.time_ns()
    command = [sys.executable]
    for selector in selectors:
        command.extend(["-a", selector])
    cases = [case for case in expected if case["case"] != omit]
    discovery = [{"id": f"{case['path']}::{case['case']}", "path": case["path"],
                  "case": case["case"], "method": case["case"]} for case in expected]
    (directory / "discovery.json").write_text(json.dumps({
        "schema_version": 1, "engine_pid": 123, "cases": discovery}), encoding="utf-8")
    (directory / "process-ownership.json").write_text(json.dumps({
        "schema_version": 1, "launcher_pid": 123, "owned_pids": [123], "source": "windows-job"}), encoding="utf-8")
    xml = ET.Element("testsuites", tests=str(len(cases)), failures="0", skipped=str(int(skipped)), flaky="0",
                     timestamp=directory.name)
    for index, case in enumerate(cases):
        path = Path(case["path"])
        suite = ET.SubElement(xml, "testsuite", name=path.stem, package=path.parent.as_posix(),
                              tests="1", failures="0", errors="0", skipped=str(int(skipped and index == 0)), flaky="0")
        node = ET.SubElement(suite, "testcase", name=case["case"])
        if skipped and index == 0:
            ET.SubElement(node, "skipped")
    report_path = directory / "report_1" / "results.xml"
    report_path.parent.mkdir()
    ET.ElementTree(xml).write(report_path, encoding="utf-8")
    (report_path.parent / "diagnostics.jsonl").write_text(
        json.dumps({"event": "session_start", "schema_version": 1,
                    "report_path": str(report_path.parent), "engine_pid": 123}) + "\n"
        + json.dumps({"event": "session_end"}) + "\n", encoding="utf-8")
    (directory / "engine.log").write_text("", encoding="utf-8")
    (directory / "invocation.json").write_text(json.dumps({"command": command,
        "run_id": directory.name, "feature_id": "F001",
        "working_tree_fingerprint": snapshot["working_tree_fingerprint"]}), encoding="utf-8")
    (directory / "verdict.json").write_text(json.dumps({
        "returncode": exit_code, "pid": 123, "engine_pid": 123, "timed_out": False,
        "failure_reasons": [], "startup_diagnostics": [],
        "report": {"discovered": len(cases), "executed": len(cases) - int(skipped), "errors": 0,
                   "failures": 0, "orphans": 0, "flaky": 0, "skipped": int(skipped)}}), encoding="utf-8")
    (directory / "session-receipt.json").write_text(json.dumps({
        "schema_version": 1, "run_id": directory.name, "engine_pid": 123, "exit_code": exit_code,
        "invocation_sha256": file_hash(directory / "invocation.json"),
        "artifacts": {name: {"path": path.relative_to(directory).as_posix(), "sha256": file_hash(path)}
            for name, path in {"discovery": directory / "discovery.json", "junit": report_path,
                               "diagnostics": report_path.parent / "diagnostics.jsonl"}.items()},
    }), encoding="utf-8")
    manifest = write_run_manifest(root, directory, feature_id="F001", phase=phase, scope=scope, snapshot_before=snapshot,
        started_ns=started, command=command, wrapper_exit=0, junit_path=report_path, expected=expected)
    return plan, manifest
