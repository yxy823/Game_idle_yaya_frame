"""按文档图备注中的路径检查覆盖范围；只读、显式调用，不改图或文档。

“文件： 路径”相对框架仓库，“项目文件： 路径”相对生成项目。
分发源通过唯一复制清单换算为项目路径；不要求按需产物已经存在。
路径支持逐段 glob：*、?、[0-9] 不跨目录，** 匹配任意层目录。
"""
from __future__ import annotations

import argparse
import fnmatch
import json
import os
import sys
from functools import lru_cache
from pathlib import Path, PurePosixPath


DEFAULT_GRAPH = "framework/docs/relationship-maps/document-system.readable.json"
MANIFEST = "framework/commands/project-files.json"
SKIP_DIRECTORIES = {".git", ".godot", ".cache", "__pycache__", ".pytest_cache", "node_modules"}
JSON_DIRECTORIES = (
    "framework/docs/", "framework/prompt-scenarios/prompts/",
    "project-source/defaults/docs/", "project-source/defaults/reports/",
)


def is_document(path: str) -> bool:
    """文档、文档模板及文档性 JSON；代码配置、素材数据和生成 HTML 不在范围内。"""
    lower = path.lower()
    return (
        lower.endswith((".md", ".md.tmpl", ".json.tmpl"))
        or path in {MANIFEST, "project-source/Project_Workflow_Config.json"}
        or (lower.endswith(".json") and path.startswith(JSON_DIRECTORIES)
            and not PurePosixPath(path).name.startswith("graph-usage."))
    )


def document_files(root: Path) -> list[str]:
    def fail_on_walk_error(error: OSError) -> None:
        raise error

    result = []
    for current, directories, names in os.walk(root, followlinks=False, onerror=fail_on_walk_error):
        relative = Path(current).relative_to(root)
        directories[:] = [name for name in directories
                          if name not in SKIP_DIRECTORIES
                          and (relative / name).as_posix() != "tmp"
                          and (relative / name).as_posix() != "project-source/addons"]
        for name in names:
            path = (relative / name).as_posix()
            if is_document(path):
                result.append(path)
    return sorted(result)


def checked_path(value: str) -> str:
    if (not isinstance(value, str) or not value or value.startswith("/") or "\\" in value or ":" in value
            or any(part in {"", ".", ".."} for part in value.split("/"))):
        raise ValueError(f"路径必须是使用 / 的相对文件路径或模式：{value!r}")
    return value


@lru_cache(maxsize=None)
def match_parts(path: tuple[str, ...], pattern: tuple[str, ...]) -> bool:
    if not pattern:
        return not path
    if pattern[0] == "**":
        return match_parts(path, pattern[1:]) or bool(path and match_parts(path[1:], pattern))
    return bool(path and fnmatch.fnmatchcase(path[0], pattern[0])
                and match_parts(path[1:], pattern[1:]))


def matches(path: str, pattern: str) -> bool:
    return match_parts(tuple(path.split("/")), tuple(pattern.split("/")))


def graph_patterns(graph: dict) -> list[tuple[str, str, str]]:
    if (not isinstance(graph, dict) or graph.get("format") != "graph-map-core"
            or graph.get("version") != 1 or not isinstance(graph.get("nodes"), list)):
        raise ValueError("需要 Graph_Map v1 文档图")
    patterns = []
    identifiers = set()
    for node in graph["nodes"]:
        if not isinstance(node, dict) or not isinstance(node.get("id"), str):
            raise ValueError("节点需要字符串 ID")
        identifier = node["id"]
        if identifier in identifiers:
            raise ValueError(f"节点 ID 重复：{identifier}")
        identifiers.add(identifier)
        if not identifier.startswith("doc-"):
            continue
        if not isinstance(node.get("note"), str):
            raise ValueError(f"{identifier} 需要字符串备注")
        found = False
        for line in node.get("note", "").splitlines():
            for prefix, scope in (("文件：", "repository"), ("项目文件：", "project")):
                if line.startswith(prefix):
                    if not line[len(prefix):].startswith(" "):
                        raise ValueError(f"{identifier} 的 {prefix} 后需一个空格")
                    patterns.append((scope, checked_path(line[len(prefix):].strip()), identifier))
                    found = True
        if not found:
            raise ValueError(f"{identifier} 缺少文件路径登记")
    if not patterns:
        raise ValueError("图中没有文档路径登记")
    return patterns


def document_inventory(root: Path) -> list[dict]:
    """一份源模板可能复制到两个位置，分别核对两个位置的职责覆盖。"""
    entries = json.loads((root / MANIFEST).read_text(encoding="utf-8"))
    mappings = []
    for entry in entries:
        source, target = checked_path(entry["source"]), checked_path(entry["target"])
        origin = root / source
        if not origin.exists():
            raise ValueError(f"复制源不存在：{source}")
        mappings.append((source, target, origin.is_dir()))
    inventory = []
    for source in document_files(root):
        destinations = []
        for origin, target, directory in mappings:
            if source == origin:
                destinations.append(target)
            elif directory and source.startswith(origin + "/"):
                destinations.append(target + source[len(origin):])
        if destinations:
            inventory.extend({"scope": "project", "path": target, "source": source}
                             for target in destinations)
        else:
            inventory.append({"scope": "repository", "path": source, "source": source})
    return inventory


def check_coverage(root: Path, graph: Path) -> dict:
    patterns = graph_patterns(json.loads(graph.read_text(encoding="utf-8")))
    rows = document_inventory(root)
    for row in rows:
        row["nodes"] = sorted({identifier for scope, pattern, identifier in patterns
                               if scope == row["scope"] and matches(row["path"], pattern)})
    return {
        "summary": {"documents": len(rows),
                    "covered": sum(bool(row["nodes"]) for row in rows),
                    "uncovered": sum(not row["nodes"] for row in rows)},
        "results": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2],
                        help="框架仓库，默认从脚本位置定位")
    parser.add_argument("--graph", type=Path, default=Path(DEFAULT_GRAPH),
                        help="文档图；相对路径以 --root 为基准")
    parser.add_argument("--json", action="store_true", help="输出全部文件及其覆盖节点")
    args = parser.parse_args()
    root = args.root.resolve()
    graph = args.graph if args.graph.is_absolute() else root / args.graph
    try:
        report = check_coverage(root, graph)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"检查失败：{error}", file=sys.stderr)
        return 2
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        summary = report["summary"]
        print(f"文档 {summary['documents']} 个；已覆盖 {summary['covered']}；未覆盖 {summary['uncovered']}")
        for row in report["results"]:
            if not row["nodes"]:
                scope = "仓库" if row["scope"] == "repository" else "项目"
                print(f"未覆盖 [{scope}] {row['path']}（源：{row['source']}）")
    return 1 if report["summary"]["uncovered"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
