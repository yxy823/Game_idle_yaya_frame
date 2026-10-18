"""Bind verification records to repository content without deciding completion."""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from tools.lib.feature_ids import FEATURE_ID

EXCLUDED_EXACT_PATHS = {
    "docs/progress.md",
    "dev/debug/adoption-log.md",
}
DEBUG_CONSOLE_SAVES_RE = re.compile(r"dev/debug/[^/]+/(?:slots/(?:[^/]+/)*presets|combos)/.+")
EVIDENCE_PATH_RE = re.compile(rf"docs/features/{FEATURE_ID}-evidence\.json")
PROCESS_FIELDS = {"notes", "status", "completed_at", "created_at", "updated_at", "recorded_at"}


class EvidenceError(RuntimeError):
    """Raised when repository evidence cannot be created or trusted."""


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def _run_git(repo_root: Path, *args: str) -> bytes:
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_root), *args],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except OSError as exc:
        raise EvidenceError(f"cannot execute git: {exc}") from exc
    if result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise EvidenceError(f"git {' '.join(args)} failed (exit {result.returncode}): {detail or 'unexpected result'}")
    return result.stdout


def git_revision(repo_root: Path) -> str:
    """Record the current commit; project creation supplies the initial baseline."""
    if _run_git(repo_root, "rev-parse", "--is-inside-work-tree").strip() != b"true":
        raise EvidenceError("snapshot requires a Git working repository")
    revision = _run_git(repo_root, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii", errors="strict").strip()
    if not revision:
        raise EvidenceError("git rev-parse HEAD^{commit} returned an empty revision")
    return revision


def project_paths(repo_root: Path) -> list[str]:
    """Tracked and non-ignored untracked paths; deleted paths still in the index are included."""
    raw_paths = _run_git(repo_root, "ls-files", "--cached", "--others", "--exclude-standard", "-z")
    return sorted({path for path in raw_paths.decode("utf-8", errors="surrogateescape").split("\0") if path})


def revision_texts(repo_root: Path, revision: str, paths: list[str]) -> dict[str, str]:
    """Read only requested files present at the revision; Git failures remain errors."""
    if not paths:
        return {}
    listed = _run_git(repo_root, "ls-tree", "-r", "--name-only", "-z", revision, "--", *paths)
    existing = set(listed.decode("utf-8", errors="surrogateescape").split("\0"))
    return {path: _run_git(repo_root, "show", f"{revision}:{path}").decode("utf-8", errors="replace")
            for path in paths if path in existing}


def commit_exists(repo_root: Path, revision: str) -> bool:
    return _git_succeeds(repo_root, "cat-file", "-e", f"{revision}^{{commit}}")


def is_ancestor(repo_root: Path, revision: str) -> bool:
    return _git_succeeds(repo_root, "merge-base", "--is-ancestor", revision, "HEAD")


def commit_recording(repo_root: Path, path: str, revision: str) -> str | None:
    """The first commit after ``revision`` in HEAD's history whose ``path`` records ``revision`` as its git_revision.

    Evidence is recorded before the Feature's work is committed, so this is the
    completion commit that contains the verified content.
    """
    commits = _run_git(repo_root, "rev-list", "--reverse", f"{revision}..HEAD", "--", path).decode("ascii").split()
    for commit in commits:
        try:
            recorded = json.loads(_run_git(repo_root, "show", f"{commit}:{path}"))
        except EvidenceError:
            continue  # the commit deleted the file
        if recorded.get("git_revision") == revision:
            return commit
    return None


def root_commit(repo_root: Path) -> str:
    """The oldest parentless commit reachable from HEAD."""
    return _run_git(repo_root, "rev-list", "--max-parents=0", "HEAD").decode("ascii").split()[-1]


def _git_succeeds(repo_root: Path, *args: str) -> bool:
    try:
        return subprocess.run(["git", "-C", str(repo_root), *args], check=False,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
    except OSError as exc:
        raise EvidenceError(f"cannot execute git: {exc}") from exc


def _is_fingerprint_input(relative_path: str) -> bool:
    normalized = relative_path.replace("\\", "/").removeprefix("./")
    if (normalized in EXCLUDED_EXACT_PATHS or EVIDENCE_PATH_RE.fullmatch(normalized)
            or DEBUG_CONSOLE_SAVES_RE.fullmatch(normalized)):
        return False
    if normalized.startswith("reports/"):
        return False
    if normalized.rsplit("/", 1)[-1].casefold() == "readme.md":
        return normalized.casefold().startswith((
            ".agents/", "yaya/agent-rules/", "yaya/methodology/", "docs/gdd/", "docs/product/", "docs/features/",
        ))
    return not (normalized.startswith(("docs/progress/", "docs/knowledge/", "docs/research/")) and normalized.endswith(".md"))


def semantic_json(relative_path: str, data: Any) -> Any:
    """Project workflow state is not verification semantics; nested contracts are.

    Deliberately do not recursively drop fields: a Registry test's status or an
    acceptance criterion's text/verification is part of the active contract.
    Unknown contract fields remain hashed rather than silently becoming exempt.
    """
    if not isinstance(data, dict):
        return data
    if relative_path.startswith("docs/features/"):
        return {key: value for key, value in data.items() if key not in PROCESS_FIELDS}
    result = dict(data)
    if relative_path == "docs/feature-list.json":
        result["features"] = [
            {key: value for key, value in feature.items() if key not in PROCESS_FIELDS}
            for feature in result.get("features", [])
        ]
    if relative_path in {"docs/feature-list.json", "docs/test-registry.json"}:
        if not isinstance(data.get("meta", {}), dict):
            raise EvidenceError(f"{relative_path} meta must be an object")
        result["meta"] = {key: value for key, value in data.get("meta", {}).items()
                          if key not in PROCESS_FIELDS and not key.endswith("_at")}
    if relative_path == "docs/feature-list-revisions.json":
        result["revision_log"] = [
            {key: value for key, value in entry.items()
             if key not in {"revised_at", "created_at", "updated_at", "recorded_at", "summary", "notes"}}
            for entry in data.get("revision_log", [])
        ]
    return result


def _hash_file(digest: Any, path: Path) -> None:
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)


def working_tree_fingerprint(repo_root: Path) -> str:
    """Hash tracked and non-ignored untracked content for the current code snapshot.

    Feature/Registry verification semantics are canonical JSON inputs. Only known
    process fields, evidence outputs, Progress/knowledge/research Markdown and usage README
    files outside contract directories are exempt. Deleted paths left in the
    index are absent content; staging their deletion must not change the hash.
    A Git commit is provenance, not an invalidation of identical content.
    """

    paths = project_paths(repo_root)
    digest = hashlib.sha256()
    digest.update(b"yaya-working-tree-v2\0")
    resolved_root = repo_root.resolve()

    for relative_path in paths:
        normalized = relative_path.replace("\\", "/")
        if not _is_fingerprint_input(normalized):
            continue
        candidate = (resolved_root / Path(normalized)).resolve(strict=False)
        try:
            candidate.relative_to(resolved_root)
        except ValueError as exc:
            raise EvidenceError(f"git reported a path outside the repository: {relative_path}") from exc

        # 未暂存的删除仍在索引中；当前内容不应包含这类残留路径。
        if not candidate.exists():
            continue
        digest.update(normalized.encode("utf-8", errors="surrogateescape"))
        digest.update(b"\0")
        if candidate.is_file():
            digest.update(b"file\0")
            if normalized.startswith("docs/features/") and normalized.endswith(".json") or normalized in {
                "docs/feature-list.json", "docs/test-registry.json", "docs/methodology-config.json",
                "docs/feature-list-revisions.json",
            }:
                try:
                    projected = semantic_json(normalized, json.loads(candidate.read_text(encoding="utf-8")))
                except (OSError, ValueError, TypeError) as exc:
                    raise EvidenceError(f"cannot fingerprint workflow contract {normalized}: {exc}") from exc
                digest.update(json.dumps(projected, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode("utf-8"))
            else:
                _hash_file(digest, candidate)
        else:
            digest.update(b"non-file\0")
        digest.update(b"\0")

    return f"sha256:{digest.hexdigest()}"


def changed_paths_since(repo_root: Path, revision: str, uncommitted_paths: list[str]) -> list[str]:
    """List possible changed fingerprint inputs since binding to a working tree.

    Include both current differences from the commit and the differences recorded
    at binding, so reverted edits and deleted untracked files are not missed.
    The union can include inputs whose content has not changed since binding.
    """
    tracked = _run_git(repo_root, "diff", "--name-only", "--no-renames", "-z", revision, "--")
    untracked = _run_git(repo_root, "ls-files", "--others", "--exclude-standard", "-z")
    paths = set(uncommitted_paths)
    for raw in (tracked, untracked):
        for path in raw.decode("utf-8", errors="surrogateescape").split("\0"):
            normalized = path.replace("\\", "/")
            if normalized and _is_fingerprint_input(normalized):
                paths.add(normalized)
    return sorted(paths)


def current_snapshot(repo_root: Path) -> dict[str, str]:
    return {
        "git_revision": git_revision(repo_root),
        "working_tree_fingerprint": working_tree_fingerprint(repo_root),
    }
