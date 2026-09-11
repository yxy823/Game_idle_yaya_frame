"""One Windows-lifetime lease and ordered journal for final verification attempts.

The journal is written atomically before launch. The OS releases the byte lock
on process death; the persistent lock file is not a stale ownership claim.
"""
# 测试启动前日志；操作系统字节锁证明存活，磁盘上留有锁文件不等于仍被占用。
from __future__ import annotations

from contextlib import contextmanager
import hashlib
import json
import msvcrt
import os
from pathlib import Path
import subprocess

from tools.lib.gate_evidence import current_snapshot, utc_now, write_evidence


def canonical_hash(value: dict) -> str:
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def journal_path(root: Path) -> Path:
    result = subprocess.run(["git", "-C", str(root), "rev-parse", "--show-toplevel", "--absolute-git-dir"],
                            capture_output=True, text=True, encoding="utf-8", check=False)
    lines = result.stdout.splitlines()
    if result.returncode or len(lines) != 2 or Path(lines[0]).resolve() != root.resolve():
        raise ValueError("verification requires this project's own Git working repository")
    return Path(lines[1]) / "yaya-verification-attempts.json"


# 连续序号与前项哈希保存尝试顺序，不靠 st_mtime_ns 对启动时间排序。
def read_journal(path: Path) -> list[dict]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or data.get("schema_version") != 1 or not isinstance(data.get("records"), list):
        raise ValueError("verification journal is invalid; preserve it for diagnosis")
    records = []
    for record in data["records"]:
        if (not isinstance(record, dict) or record.get("sequence") != len(records) + 1
                or record.get("previous") != (records[-1]["hash"] if records else None)
                or record.get("hash") != canonical_hash({key: value for key, value in record.items() if key != "hash"})):
            raise ValueError("verification journal order/hash is invalid; preserve it for diagnosis")
        records.append(record)
    return records


@contextmanager
# 先落盘尝试再交出执行控制；进程异常退出也不能让后续校验看不到这次尝试。
def attempt(root: Path, kind: str, directory: Path, *, selection: dict | None = None, scope: str | None = None):
    """Serialize actual verification, without waiting or deleting failed records."""
    journal = journal_path(root)
    with journal.with_suffix(".lock").open("a+b") as lease:
        lease.seek(0)
        try:
            msvcrt.locking(lease.fileno(), msvcrt.LK_NBLCK, 1)
        except OSError as error:
            raise ValueError("another verification process holds the project lease; do not delete its lock file") from error
        try:
            records = read_journal(journal)
            # Invalid setup is still an attempt. Preserve a conservative scope
            # if an incomplete selection cannot supply its selection metadata.
            try:
                selectors = (selection["full_suite"]["selectors"] if scope == "full" else
                             sorted({item["path"] for item in selection[scope]})) if selection else []
                if not isinstance(selectors, list) or any(not isinstance(item, str) or not item for item in selectors):
                    raise ValueError("invalid selectors")
            except (KeyError, TypeError, ValueError):
                selectors, scope = [], "full"
            record = {"sequence": len(records) + 1, "previous": records[-1]["hash"] if records else None,
                      "kind": kind, "run_id": directory.name,
                      "directory": directory.resolve().relative_to(root.resolve()).as_posix(),
                      "wrapper_pid": os.getpid(), "started_at": utc_now(),
                      "snapshot": current_snapshot(root), "scope": scope,
                      "feature_id": selection.get("feature_id") if selection else None,
                      "selectors": selectors,
                      "phase": selection.get("phase", "final") if selection else "final"}
            record["hash"] = canonical_hash(record)
            write_evidence(journal, {"schema_version": 1, "records": [*records, record]})
            yield record
        finally:
            lease.seek(0)
            msvcrt.locking(lease.fileno(), msvcrt.LK_UNLCK, 1)


def run_attempt(root: Path, directory: Path) -> dict:
    relative = directory.resolve().relative_to(root.resolve()).as_posix()
    records = [record for record in read_journal(journal_path(root)) if record["directory"] == relative]
    if len(records) != 1:
        raise ValueError("run has no unique pre-launch verification attempt")
    return records[0]


def require_current_tests(root: Path, selection: dict, runs: list[dict]) -> None:
    """A later failing/unfinished final scope cannot be hidden by older PASS refs.

Affected includes required. Full must actually satisfy all obligations in the
normal run verifier; a subsequent narrow pass never clears an unresolved full.
    Baseline and other Feature/source snapshots are historical. Changing only
    selection options cannot erase an unresolved attempt on the same actual source.
"""
    rank = {"required": 1, "affected": 2, "full": 3}
    records = read_journal(journal_path(root))
    snapshot = current_snapshot(root)
    selected = []
    for run in runs:
        matches = [record for record in records if record["run_id"] == run["run_id"]
                   and record["hash"] == run.get("attempt_hash") and record["kind"] == "tests"
                   and record["feature_id"] == selection["feature_id"] and record["scope"] == run["scope"]
                   and record["snapshot"]["working_tree_fingerprint"] == snapshot["working_tree_fingerprint"]]
        if len(matches) != 1:
            raise ValueError("test run has no matching pre-launch attempt")
        selected.append(matches[0])
    for record in records:
        if (record["kind"] != "tests" or record["phase"] != "final"
                or record["snapshot"]["working_tree_fingerprint"] != snapshot["working_tree_fingerprint"]
                or record["feature_id"] not in (None, selection["feature_id"])):
            continue
        if not any(item["sequence"] >= record["sequence"]
                   and rank[item["scope"]] >= rank.get(record["scope"], 3)
                   and all(any(target == selector or target.startswith(selector.rstrip("/") + "/")
                               for selector in item["selectors"]) for target in record["selectors"])
                   for item in selected):
            raise ValueError("newer failed or unfinished final test attempt: " + record["run_id"])
