"""Audit graph node labels against prompt scenario names, ignoring line breaks only.

Print a JSON report with matched, missing, unexpected and duplicate names. JSON
pointers identify the exact graph field and prompt key; suggestions are evidence
for a repair, never an automatic rename. This command does not modify files.

Example: python -B framework/commands/prompts/check_workflow_graph_names.py --graph PATH
Exit codes: 0 = identical name multiset, 1 = differences, 2 = invalid input.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import difflib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
DEFAULT_GRAPH = ROOT / "framework/docs/relationship-maps/game-development-workflow.readable.json"


def normalize_label(value: str) -> str:
    """Remove CR/LF wrapping without concealing spaces, case or punctuation edits."""
    return value.replace("\r", "").replace("\n", "")


def pointer_token(value: str) -> str:
    return value.replace("~", "~0").replace("/", "~1")


def unique_object(pairs: list[tuple[str, object]]) -> dict:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8-sig"), object_pairs_hook=unique_object)


def prompt_names(data: object, project: str) -> list[dict]:
    """Preserve category and JSON-key locations without creating an ID mapping."""
    if not isinstance(data, list):
        raise ValueError("Prompt root must be a Project array")
    projects = [(i, p) for i, p in enumerate(data)
                if isinstance(p, dict) and p.get("project") == project]
    if len(projects) != 1:
        raise ValueError(f"Expected exactly one Project named {project!r}; found {len(projects)}")
    index, selected = projects[0]
    categories = selected.get("categories")
    if not isinstance(categories, dict) or not categories:
        raise ValueError(f"/{index}/categories must be a nonempty object")
    names = []
    for category, scenarios in categories.items():
        if not isinstance(scenarios, dict):
            raise ValueError(f"/{index}/categories/{pointer_token(category)} must be an object")
        for name in scenarios:
            if not name or "\r" in name or "\n" in name:
                raise ValueError(f"Prompt name must be nonempty and unwrapped: {name!r}")
            names.append({"name": name, "category": category,
                          "prompt_pointer": f"/{index}/categories/{pointer_token(category)}/{pointer_token(name)}"})
    if not names:
        raise ValueError(f"Project {project!r} has no scenarios")
    return names


def compare_names(prompts_path: Path, graph_path: Path, project: str) -> dict:
    """Compare names as a multiset; duplicated matches remain reported differences."""
    expected = prompt_names(read_json(prompts_path), project)
    graph = read_json(graph_path)
    if not isinstance(graph, dict) or graph.get("format") != "graph-map-core" or graph.get("version") != 1:
        raise ValueError("Graph must use format graph-map-core and version 1")
    if not isinstance(graph.get("nodes"), list):
        raise ValueError("/nodes must be an array")
    expected_by_name = defaultdict(list)
    for item in expected:
        expected_by_name[item["name"]].append(item)
    actual_by_name = defaultdict(list)
    actual_by_id = defaultdict(list)
    for index, node in enumerate(graph["nodes"]):
        if not isinstance(node, dict) or not isinstance(node.get("label"), str):
            raise ValueError(f"/nodes/{index}/label must be a string")
        if not isinstance(node.get("id"), str) or not node["id"].strip():
            raise ValueError(f"/nodes/{index}/id must be a nonempty string")
        row = {"node_id": node["id"], "graph_pointer": f"/nodes/{index}/label",
               "actual": node["label"], "normalized": normalize_label(node["label"])}
        actual_by_name[row["normalized"]].append(row)
        actual_by_id[node["id"]].append(f"/nodes/{index}/id")
    matched, unexpected = [], []
    for name, rows in actual_by_name.items():
        for row in rows:
            if name in expected_by_name:
                matched.append({**row, "expected": name,
                                "prompt_sources": expected_by_name[name],
                                "only_line_breaks_differ": row["actual"] != name})
            else:
                candidates = sorted(
                    ((difflib.SequenceMatcher(None, name, candidate, autojunk=False).ratio(), candidate)
                     for candidate in expected_by_name), reverse=True,
                )[:3]
                unexpected.append({**row, "candidates": [
                    {"expected": candidate, "similarity": round(score, 4),
                     "prompt_sources": expected_by_name[candidate]}
                    for score, candidate in candidates if score >= 0.45
                ]})
    missing = [item for item in expected if item["name"] not in actual_by_name]
    duplicate_nodes = [{"normalized": name, "nodes": rows}
                       for name, rows in actual_by_name.items() if len(rows) > 1]
    duplicate_prompts = [{"name": name, "prompt_sources": sources}
                         for name, sources in expected_by_name.items() if len(sources) > 1]
    duplicate_ids = [{"node_id": name, "graph_pointers": paths}
                     for name, paths in actual_by_id.items() if len(paths) > 1]
    same_multiset = Counter(item["name"] for item in expected) == Counter(
        name for name, rows in actual_by_name.items() for _ in rows
    )
    ok = same_multiset and not duplicate_nodes and not duplicate_prompts and not duplicate_ids
    return {
        "ok": ok, "project": project,
        "prompts_file": str(prompts_path.resolve()), "graph_file": str(graph_path.resolve()),
        "normalization": "Remove CR and LF only; preserve all other characters.",
        "summary": {"expected": len(expected), "actual": len(graph["nodes"]),
                    "matched": len(matched), "missing": len(missing),
                    "unexpected": len(unexpected), "duplicate_names": len(duplicate_nodes),
                    "duplicate_prompt_names": len(duplicate_prompts), "duplicate_ids": len(duplicate_ids)},
        "matched": matched, "missing": missing, "unexpected": unexpected,
        "duplicate_names": duplicate_nodes, "duplicate_prompt_names": duplicate_prompts,
        "duplicate_ids": duplicate_ids,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--prompts", type=Path, default=ROOT / "framework/prompt-scenarios/prompts/godot-development-prompts.json")
    parser.add_argument("--graph", type=Path, default=DEFAULT_GRAPH)
    parser.add_argument("--project", default="Godot 项目开发")
    parser.add_argument("--summary", action="store_true", help="Print counts only; default includes all field locations and candidates")
    args = parser.parse_args(argv)
    try:
        report = compare_names(args.prompts, args.graph, args.project)
    except (OSError, UnicodeError, ValueError) as error:
        print(json.dumps({"ok": False, "error": str(error)}, ensure_ascii=False), file=sys.stderr)
        return 2
    output = {key: value for key, value in report.items()
              if not args.summary or key in {"ok", "project", "prompts_file", "graph_file", "normalization", "summary"}}
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
