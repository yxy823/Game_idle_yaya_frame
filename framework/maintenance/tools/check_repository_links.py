"""检查维护仓库与按复制清单生成后的项目中的 Markdown 链接和锚点，以及两份提示词库正文中的纯文本路径与「标题」引用。"""
# 分发源里的链接按生成项目的目录写成，所以先复制到临时目录再检查，结果映射回源路径。
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
CHECKER = REPO_ROOT / "project-source/tools/checks/check-markdown-links.py"
TEXT_CHECKER = REPO_ROOT / "project-source/tools/checks/check-link-text.py"
MANIFEST = REPO_ROOT / "framework/project-creation/project-files.json"
PROMPT_DIR = "framework/prompt-scenarios/prompts"
# 提示词正文中的框架仓库路径；生成项目内的路径（docs/、yaya/ 等）不在这里核对。
PROMPT_PATH = re.compile(r"(?<![\w/.-])((?:framework|project-source|\.agents)/[\w./*\-一-鿿]+)")
# 「<文件> 的「标题」、「标题」」写法（“的”可省略）；不带目录的文件名只在维护提示词库中按仓库根目录解析。
PROMPT_HEADING = re.compile(r"((?:(?:framework|project-source|\.agents)/[\w./\-]+)?[\w\-]+\.md) ?(?:的 ?)?((?:「[^」]+」、?)+)")
sys.path.insert(0, str(REPO_ROOT / "framework/project-creation/tools"))
sys.path.insert(0, str(REPO_ROOT / "project-source"))

from create_project import copy_project  # noqa: E402
from tools.lib.markdown_links import heading_slug, scan  # noqa: E402


def run_checker(root: Path, *extra: str, checker: Path = CHECKER) -> dict:
    completed = subprocess.run(
        [sys.executable, "-B", str(checker), "--root", str(root), "--json", *extra],
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


def check_prompt_references(root: Path) -> tuple[int, list[dict]]:
    """Check plain-text paths and 「heading」 references inside the prompt libraries' bodies."""
    count = 0
    broken: list[dict] = []
    for library in sorted((root / PROMPT_DIR).glob("*.json")):
        display = library.relative_to(root).as_posix()
        lines = library.read_text(encoding="utf-8").splitlines()
        bare_names_at_root = library.name == "yaya-maintenance-prompts.json"
        for project in json.loads("\n".join(lines)):
            for items in project["categories"].values():
                for name, text in items.items():
                    # 行号只用于显示；JSON 排版不同（如冒号前有空格）时退回 0，不中断检查。
                    line = next((i for i, row in enumerate(lines, start=1)
                                 if re.search(re.escape(json.dumps(name, ensure_ascii=False)) + r"\s*:", row)), 0)

                    def report(target: str, reason: str) -> None:
                        broken.append({"file": display, "line": line, "target": f"{name}: {target}", "reason": reason})

                    for match in PROMPT_PATH.finditer(text):
                        path = match.group(1).rstrip(".")
                        count += 1
                        exists = any(root.glob(path)) if "*" in path else (root / path).exists()
                        if not exists:
                            report(path, "target does not exist")
                    for match in PROMPT_HEADING.finditer(text):
                        path = match.group(1)
                        if "/" not in path and not bare_names_at_root:
                            continue
                        target = root / path
                        if not target.is_file():
                            continue
                        anchors = scan(target).anchors
                        for heading in re.findall(r"「([^」]+)」", match.group(2)):
                            count += 1
                            if heading_slug(heading) not in anchors:
                                report(f"{path} 的「{heading}」", "heading not found in target")
    return count, broken


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check-link-text",
        action="store_true",
        help="also run check-link-text.py on both parts; mismatching link text then fails the check",
    )
    args = parser.parse_args(argv)
    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))

    maintenance = run_checker(REPO_ROOT, "--exclude", "project-source")
    if args.check_link_text:
        maintenance_text = run_checker(REPO_ROOT, "--exclude", "project-source", checker=TEXT_CHECKER)
    with tempfile.TemporaryDirectory(prefix="yaya-link-check-") as directory:
        project = Path(directory) / "project"
        copy_project(REPO_ROOT, project)
        generated = run_checker(project)
        if args.check_link_text:
            generated_text = run_checker(project, checker=TEXT_CHECKER)

    prompt_references, prompt_broken = check_prompt_references(REPO_ROOT)

    broken = list(maintenance["broken"])
    for item in generated["broken"]:
        broken.append({**item, "file": source_path(item["file"], entries)})
    broken.extend(prompt_broken)
    for item in broken:
        print(f"{item['file']}:{item['line']}  {item['target']}  {item['reason']}")
    summary = (
        f"维护侧 {maintenance['files']} 个文件、{maintenance['links']} 个本地链接；"
        f"生成项目 {generated['files']} 个文件、{generated['links']} 个本地链接；"
        f"提示词正文 {prompt_references} 处路径与标题引用；失效 {len(broken)} 个"
    )
    mismatched: list[dict] = []
    if args.check_link_text:
        mismatched = maintenance_text["findings"] + [
            {**item, "file": source_path(item["file"], entries)} for item in generated_text["findings"]
        ]
        for item in mismatched:
            print(f"{item['file']}:{item['line']}  [{item['rule']}] [{item['text']}]({item['target']})  标题：{item['expected']}")
        summary += f"；链接文字与标题不符 {len(mismatched)} 个"
    print(summary)
    return 1 if broken or mismatched else 0


if __name__ == "__main__":
    sys.exit(main())
