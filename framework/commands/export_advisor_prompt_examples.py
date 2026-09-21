"""Export selected prompt text as optional, project-local advisor examples."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "framework/prompts.json"
OUTPUT = ROOT / "project-source/skills/project-next-step-advisor/references"
PROJECT = "Godot 项目开发"
# Exact source names keep selection explicit; these are examples, not routing rules.
SELECTION = (
    ("product", "需求设计", (
        "从想法或已有 GDD 整理 Product 并衔接规划", "新增、删除或调整玩法需求",
    )),
    ("planning", "任务规划", (
        "拆分当前 Product 的 Feature", "需求变化后同步已有任务",
    )),
    ("development", "日常开发", (
        "执行指定或下一项 Feature", "继续中断的当前任务",
    )),
    ("engineering", "修复与改进", (
        "定位与修复 Bug", "行为保持的重构", "工程维护与工具调整",
    )),
    ("verification", "验证与收尾", (
        "单独验证某次变更", "整理人工验收与反馈", "整理进度与任务交接",
    )),
)
NOTICE = (
    "> 自动生成的表达参考，不是流程规范或当前指令；勿手工修改。\n"
    "> 框架维护来源：`framework/prompts.json`。生成项目使用自己的副本，不回查框架。\n"
    "> 模板中的授权、停止条件与占位符仅属于原示例；依据当前用户指令、项目事实、"
    "规范及目标 Skill 改写，不据此执行、扩大授权或代作人工验收。\n"
)


def unique_object(pairs: list[tuple[str, object]]) -> dict:
    """Reject ambiguous duplicate names before selecting or writing any example."""
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def build_documents(data: object) -> dict[str, str]:
    if not isinstance(data, list):
        raise ValueError("Prompt source must be a top-level array")
    projects = [item for item in data if isinstance(item, dict) and item.get("project") == PROJECT]
    if len(projects) != 1 or not isinstance(projects[0].get("categories"), dict):
        raise ValueError(f"Expected one {PROJECT} project with categories")
    categories = projects[0]["categories"]
    documents = {}
    index = [
        "# 精选提示词表达参考\n\n", NOTICE, "\n",
        "先依据当前项目规范和目标 Skill 确定路线。仅在需要起草续接或交接措辞时，"
        "从下表读取对应文件中的相关条目；状态查询无需读取示例。\n\n",
        "| 分类 | 按需读取的条目 |\n| --- | --- |\n",
    ]
    for slug, category, titles in SELECTION:
        entries = categories.get(category)
        if not isinstance(entries, dict):
            raise ValueError(f"Missing prompt category: {category}")
        filename = f"prompt-examples/{slug}.md"
        parts = [f"# {category}：表达参考\n\n", NOTICE, "\n"]
        for number, title in enumerate(titles, 1):
            body = entries.get(title)
            if not isinstance(body, str) or not body.strip():
                raise ValueError(f"Missing or empty prompt: {category} / {title}")
            # Preserve embedded Markdown/code fences and the source body verbatim.
            fence = "`" * max(3, 1 + max((len(m[0]) for m in re.finditer(r"`+", body)), default=0))
            parts.extend([
                f'<a id="example-{number}"></a>\n\n## {title}\n\n',
                f"来源：{PROJECT} → {category} → {title}\n\n",
                f"{fence}text\n{body}\n{fence}\n\n",
            ])
        links = "；".join(
            f"[{title}]({filename}#example-{number})"
            for number, title in enumerate(titles, 1)
        )
        index.append(f"| {category} | {links} |\n")
        documents[filename] = "".join(parts).rstrip("\n") + "\n"
    index.extend([
        "\n未选入创建、迁移、框架替换、Goal 或 advisor 自身入口；"
        "未收录的任务仍使用现有规范与目标 Skill，不因缺少示例而受阻。\n",
    ])
    documents["prompt-examples.md"] = "".join(index)
    return documents


def export_examples(source: Path, output: Path, *, check: bool = False) -> list[str]:
    data = json.loads(source.read_text(encoding="utf-8"), object_pairs_hook=unique_object)
    documents = build_documents(data)
    # Validate the entire selection before making the first output directory/file.
    changed = []
    for relative, body in documents.items():
        path = output / relative
        expected = body.encode("utf-8")
        if path.exists() and path.read_bytes() == expected:
            continue
        changed.append(relative)
        if not check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(expected)
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report stale/missing exports without writing")
    args = parser.parse_args()
    try:
        changed = export_examples(SOURCE, OUTPUT, check=args.check)
    except (OSError, ValueError) as error:
        print(f"Prompt export failed: {error}", file=sys.stderr)
        return 1
    if args.check and changed:
        print("Stale or missing prompt examples: " + ", ".join(changed), file=sys.stderr)
        return 1
    count = sum(len(titles) for _, _, titles in SELECTION)
    print(f"Prompt examples {'checked' if args.check else 'exported'}: {count} prompts, {len(SELECTION) + 1} files; changed: {len(changed)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
