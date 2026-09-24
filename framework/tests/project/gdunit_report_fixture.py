"""Synthetic original reports for result-verifier tests; never real Feature evidence."""
from __future__ import annotations

import json
import sys
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

from tools.lib.test_run_evidence import expected_gdunit_cases, start_run, finish_run
from tools.lib.test_selection import build_selection, execution_selectors


def make_run(root: Path, *, scope: str = "full", skipped: bool = False,
             omit: str | None = None, exit_code: int = 0, phase: str = "final") -> tuple[dict, Path]:
    selection = build_selection(root, "F001", phase=phase)
    selectors = execution_selectors(root, selection, scope)
    expected = expected_gdunit_cases(root, selectors)
    directory = root / "reports/gdunit-wrapper/F001" / ("run-" + uuid.uuid4().hex)
    directory.mkdir(parents=True)
    result = start_run(root, directory, "F001", phase, scope)
    result.update(command=[sys.executable], selectors=selectors)
    cases = [case for case in expected if case["case"] != omit]
    discovery = [{"id": f"{case['path']}::{case['case']}", "path": case["path"],
                  "case": case["case"], "method": case["case"]} for case in expected]
    (directory / "discovery.json").write_text(json.dumps({
        "schema_version": 1, "run_id": directory.name, "engine_pid": 123, "cases": discovery}), encoding="utf-8")
    xml = ET.Element("testsuites", tests=str(len(cases)), failures="0", skipped=str(int(skipped)), flaky="0")
    for index, case in enumerate(cases):
        path = Path(case["path"])
        suite = ET.SubElement(xml, "testsuite", name=path.stem, package=path.parent.as_posix(),
                              tests="1", failures="0", errors="0", skipped=str(int(skipped and index == 0)), flaky="0")
        node = ET.SubElement(suite, "testcase", name=case["case"])
        if skipped and index == 0:
            ET.SubElement(node, "skipped")
    report_path = directory / "report_1/results.xml"
    report_path.parent.mkdir()
    ET.ElementTree(xml).write(report_path, encoding="utf-8")
    (report_path.parent / "diagnostics.jsonl").write_text(
        json.dumps({"event": "session_start", "schema_version": 1,
                    "report_path": str(report_path.parent), "engine_pid": 123}) + "\n"
        + json.dumps({"event": "session_end"}) + "\n", encoding="utf-8")
    (directory / "engine.log").write_text("", encoding="utf-8")
    finish_run(root, directory, result, process={"returncode": exit_code, "pid": 123,
                                                "engine_pid": 123, "timed_out": False})
    return selection, directory / "result.json"
