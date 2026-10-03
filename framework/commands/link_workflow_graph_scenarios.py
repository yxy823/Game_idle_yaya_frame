"""Add or refresh local scenario-file links on workflow graph nodes.

Match prompt names after removing node-label CR/LF, verify every scenario file,
then atomically update only node links. Existing links are replaced by canonical
scenario paths. --check reports pending changes without writing. Graph_Map shows
and copies local references; these links do not make the browser open local files.

Exit codes: 0 = synchronized, 1 = name/file differences or pending --check changes,
2 = invalid input or an I/O error. Output follows Graph_Map's two-space JSON
format without a trailing newline and preserves existing field order.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
import tempfile

if __package__:
    from .check_workflow_graph_names import (
        DEFAULT_GRAPH, ROOT, compare_names, normalize_label, unique_object,
    )
else:
    from check_workflow_graph_names import (
        DEFAULT_GRAPH, ROOT, compare_names, normalize_label, unique_object,
    )


def scenario_path(root: Path, project: str, category: str, name: str) -> Path:
    """Resolve an exact scenario path without allowing a name to escape its root."""
    for part in (project, category, name):
        if not part or part in {".", ".."} or any(c in part for c in '/\\:'):
            raise ValueError(f"Invalid scenario path component: {part!r}")
    target = (root / project / category / f"{name}.md").resolve()
    if not target.is_relative_to(root.resolve()):
        raise ValueError(f"Scenario path escapes root: {target}")
    return target


def update_links(prompts: Path, graph_path: Path, scenarios: Path,
                 project: str, *, check: bool = False) -> dict:
    """Preflight the complete mapping before replacing the graph file."""
    original = graph_path.read_bytes()
    audit = compare_names(prompts, graph_path, project)
    if not audit["ok"]:
        return {"ok": False, "written": False, "reason": "name_mismatch", "name_audit": audit}
    graph = json.loads(original.decode("utf-8-sig"), object_pairs_hook=unique_object)
    sources = {row["expected"]: row["prompt_sources"][0] for row in audit["matched"]}
    changes, missing = [], []
    for index, node in enumerate(graph["nodes"]):
        source = sources[normalize_label(node["label"])]
        target = scenario_path(scenarios, project, source["category"], source["name"])
        location = {"node_id": node["id"], "graph_pointer": f"/nodes/{index}/link",
                    "prompt_pointer": source["prompt_pointer"], "target": target.as_posix()}
        if not target.is_file():
            missing.append(location)
            continue
        address = target.as_posix()
        if len(address) > 8192 or any(ord(c) < 32 or ord(c) == 127 for c in address):
            raise ValueError(f"Unsupported local link target: {address!r}")
        expected = {"kind": "local", "target": address}
        if node.get("link") != expected:
            changes.append({**location, "before": node.get("link"), "after": expected})
            node["link"] = expected
            # Graph_Map serializes an optional link before node appearance.
            if "appearance" in node:
                node["appearance"] = node.pop("appearance")
    report = {"ok": not missing and (not check or not changes), "written": False,
              "graph_file": str(graph_path.resolve()), "nodes": len(graph["nodes"]),
              "changed": len(changes), "unchanged": len(graph["nodes"]) - len(changes) - len(missing),
              "missing_files": missing, "changes": changes}
    if missing or check or not changes:
        return report
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", newline="\n",
                                         dir=graph_path.parent, prefix=f".{graph_path.name}.",
                                         suffix=".tmp", delete=False) as handle:
            temporary = Path(handle.name)
            json.dump(graph, handle, ensure_ascii=False, indent=2)
        if graph_path.read_bytes() != original:
            raise ValueError("Graph changed during preflight; no replacement was made")
        os.replace(temporary, graph_path)
        report["written"] = True
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--prompts", type=Path, default=ROOT / "framework/prompt-scenarios/prompts/godot-development-prompts.json")
    parser.add_argument("--graph", type=Path, default=DEFAULT_GRAPH)
    parser.add_argument("--scenarios", type=Path, default=ROOT / "framework/prompt-scenarios/scenarios")
    parser.add_argument("--project", default="Godot 项目开发")
    parser.add_argument("--check", action="store_true", help="Report missing/stale links without writing")
    args = parser.parse_args(argv)
    try:
        report = update_links(args.prompts, args.graph, args.scenarios, args.project, check=args.check)
    except (OSError, UnicodeError, ValueError, KeyError) as error:
        print(json.dumps({"ok": False, "written": False, "error": str(error)}, ensure_ascii=False), file=sys.stderr)
        return 2
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
