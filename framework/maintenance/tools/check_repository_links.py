"""检查维护仓库与按复制清单生成后的项目中的 Markdown 链接和锚点。"""
# 分发材料里的链接按生成项目的目录写成，所以先复制到临时目录再检查，结果映射回源路径。
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
CHECKER = REPO_ROOT / "project-source/tools/checks/check-markdown-links.py"
MANIFEST = REPO_ROOT / "framework/project-creation/project-files.json"
sys.path.insert(0, str(REPO_ROOT / "framework/project-creation/tools"))

from create_project import copy_project  # noqa: E402


def run_checker(root: Path, *extra: str) -> dict:
    completed = subprocess.run(
        [sys.executable, "-B", str(CHECKER), "--root", str(root), "--json", *extra],
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if completed.returncode not in (0, 1):
        raise RuntimeError(completed.stderr.strip() or f"checker exited with {completed.returncode}")
    return json.loads(completed.stdout)


def source_path(project_relative: str, entries: list[dict]) -> str:
    """Map a generated-project path back to its source by the longest matching target."""
    path = Path(project_relative)
    best = None
    for entry in entries:
        target = Path(entry["target"])
        if (path == target or target in path.parents) and (best is None or len(target.parts) > len(best[0].parts)):
            best = (target, Path(entry["source"]))
    if best is None:
        return project_relative
    return (best[1] / path.relative_to(best[0])).as_posix()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args(argv)
    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))

    maintenance = run_checker(REPO_ROOT, "--exclude", "project-source")
    with tempfile.TemporaryDirectory(prefix="yaya-link-check-") as directory:
        project = Path(directory) / "project"
        copy_project(REPO_ROOT, project)
        generated = run_checker(project)

    broken = list(maintenance["broken"])
    for item in generated["broken"]:
        broken.append({**item, "file": source_path(item["file"], entries)})
    for item in broken:
        print(f"{item['file']}:{item['line']}  {item['target']}  {item['reason']}")
    print(
        f"维护侧 {maintenance['files']} 个文件、{maintenance['links']} 个本地链接；"
        f"生成项目 {generated['files']} 个文件、{generated['links']} 个本地链接；失效 {len(broken)} 个"
    )
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
