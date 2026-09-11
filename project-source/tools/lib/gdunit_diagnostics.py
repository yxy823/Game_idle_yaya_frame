"""Reconcile native Godot records with invocation-local scoped-match evidence."""
# 对照原生诊断与本次明确消费记录；按实际出现次数匹配，避免宽泛忽略错误。
from __future__ import annotations

import json
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


ANSI_CSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
HEADER = re.compile(r"^\s*(SCRIPT ERROR|SHADER ERROR|ERROR|WARNING): (.*)$")
LOCATION = re.compile(r"^\s+at: (.+) \((.+):(\d+)\)\s*$")
KINDS = {"ERROR": "error", "WARNING": "warning", "SCRIPT ERROR": "script_error",
         "SHADER ERROR": "shader_error"}


class DiagnosticEvidenceError(ValueError):
    """The current diagnostic sidecar cannot prove a scoped exemption."""


@dataclass(frozen=True)
class Diagnostic:
    kind: str
    message: str
    file: str
    line: int
    function: str

    def describe(self) -> str:
        return f"{self.kind}: {self.message} at {self.function} ({self.file}:{self.line})"


def native_diagnostics(output: str) -> list[Diagnostic]:
    """Parse engine header + source-location records across the entire lifecycle.

    Error words, test names and JUnit summaries are not native records. A native
    message may contain newlines; only a corresponding source location completes
    its record. No case/suite banner disables this parser.
    """
    records: list[Diagnostic] = []
    pending: tuple[str, list[str]] | None = None
    for line in ANSI_CSI.sub(" ", output).splitlines():
        header = HEADER.fullmatch(line)
        location = LOCATION.fullmatch(line)
        if header:
            pending = (KINDS[header[1]], [header[2]])
        elif pending is not None and location:
            records.append(Diagnostic(
                pending[0], "\n".join(pending[1]).rstrip(),
                location[2].replace("\\", "/"), int(location[3]), location[1],
            ))
            pending = None
        elif pending is not None:
            pending[1].append(line)
    return records


def _diagnostic_record(event: dict) -> Diagnostic:
    if event.get("kind") not in KINDS.values():
        raise DiagnosticEvidenceError("invalid diagnostic kind")
    if any(not isinstance(event.get(key), str) for key in ("message", "file", "function")):
        raise DiagnosticEvidenceError("invalid diagnostic text/source")
    if type(event.get("line")) is not int or event["line"] < 0:
        raise DiagnosticEvidenceError("invalid diagnostic source line")
    return Diagnostic(
        event["kind"], event["message"].rstrip(), event["file"].replace("\\", "/"),
        event["line"], event["function"],
    )


def _load_evidence(path: Path) -> tuple[list[Diagnostic], set[int]]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
        events = [json.loads(line) for line in lines]
    except (OSError, ValueError) as exc:
        raise DiagnosticEvidenceError(f"cannot read current diagnostic evidence: {exc}") from exc
    if not events or any(not isinstance(event, dict) for event in events):
        raise DiagnosticEvidenceError("empty or malformed diagnostic evidence")
    start = events[0]
    if (start.get("event") != "session_start" or type(start.get("schema_version")) is not int
            or start["schema_version"] != 1):
        raise DiagnosticEvidenceError("missing supported diagnostic session start")
    report_path = start.get("report_path")
    if not isinstance(report_path, str) or Path(report_path).resolve() != path.parent.resolve():
        raise DiagnosticEvidenceError("diagnostic evidence belongs to another report directory")
    if type(start.get("engine_pid")) is not int or start["engine_pid"] <= 0:
        raise DiagnosticEvidenceError("missing diagnostic engine identity")
    records: list[Diagnostic] = []
    expected: set[int] = set()
    ended = False
    for event in events[1:]:
        if ended:
            raise DiagnosticEvidenceError("diagnostic evidence continues after session end")
        kind = event.get("event")
        if kind == "diagnostic":
            if type(event.get("id")) is not int or event["id"] != len(records) + 1:
                raise DiagnosticEvidenceError("nonsequential diagnostic identity")
            records.append(_diagnostic_record(event))
        elif kind == "expected":
            identity = event.get("id")
            if type(identity) is not int or not 1 <= identity <= len(records) or identity in expected:
                raise DiagnosticEvidenceError("invalid or duplicate scoped diagnostic identity")
            expected.add(identity)
        elif kind == "session_end":
            ended = True
        else:
            raise DiagnosticEvidenceError(f"unknown diagnostic event: {kind!r}")
    if not ended:
        raise DiagnosticEvidenceError("diagnostic session did not complete")
    return records, expected


# 缺失、重复或无对应消费证据的诊断都保留为异常，不能只按消息文本全局放行。
def unexpected_diagnostics(output: str, report_path: Path) -> list[str]:
    """Fail closed on unmatched records, extra occurrences or incomplete evidence.

    IDs authorize individual occurrences in this invocation, never global text
    patterns. Native output covers startup and the tail after the hook closes;
    the independent logger also catches records absent from native output.
    """
    native = native_diagnostics(output)
    records, expected_ids = _load_evidence(report_path.parent / "diagnostics.jsonl")
    expected = Counter(record for identity, record in enumerate(records, 1)
                       if identity in expected_ids)
    observed = Counter(native)
    missing = expected - observed
    if missing:
        raise DiagnosticEvidenceError("scoped diagnostic evidence has no matching native record")
    # Taking the larger count preserves unobserved-by-one-channel occurrences.
    all_records = observed | Counter(records)
    unexpected = all_records - expected
    return [record.describe() for record, count in unexpected.items() for _ in range(count)]
