"""检查关系图连线是否从别的节点上穿过；只读、显式调用，不改图。

连线按“起点端口 → 各折点 → 终点端口”连成折线。水平或竖直的线段（误差 1 像素内）
逐个和节点矩形比较，穿进矩形内部才算；只贴着边框走不算。起点和终点自己的节点、
以及 legend-、caption- 这类阅读辅助不参与比较。两端既不同行也不同列的线段，
查看器会自己补拐点，脚本不知道实际走法，只计数、不判断。
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_GRAPHS = (
    "framework/relationship-maps/document-system.readable.json",
)
AID_PREFIXES = ("legend-", "caption-")
ALIGN_TOLERANCE = 1.0


class GraphError(ValueError):
    """图文件读不出来、有重复键，或连线指向不存在的节点、端口。"""


def unique_keys(pairs: list[tuple[str, object]]) -> dict:
    # 合并冲突解决不当会在同一对象里留下两个同名键；json 默认只保留后一个，错误会被掩盖。
    result: dict = {}
    for key, value in pairs:
        if key in result:
            raise GraphError(f"duplicate key {key!r}")
        result[key] = value
    return result


def port_point(node: dict, port: str) -> tuple[float, float]:
    x, y, width, height = node["x"], node["y"], node["width"], node["height"]
    points = {
        "left": (x, y + height / 2),
        "right": (x + width, y + height / 2),
        "top": (x + width / 2, y),
        "bottom": (x + width / 2, y + height),
    }
    if port not in points:
        raise GraphError(f"unknown port {port!r} on node {node['id']}")
    return points[port]


def crosses(start: tuple[float, float], end: tuple[float, float], node: dict) -> bool:
    left, top = node["x"], node["y"]
    right, bottom = left + node["width"], top + node["height"]
    (x1, y1), (x2, y2) = start, end
    if abs(x1 - x2) <= ALIGN_TOLERANCE:
        return left < x1 < right and min(y1, y2) < bottom and max(y1, y2) > top
    return top < y1 < bottom and min(x1, x2) < right and max(x1, x2) > left


def check_graph(document: dict) -> dict:
    nodes = {node["id"]: node for node in document["nodes"]}
    obstacles = [node for node in document["nodes"] if not node["id"].startswith(AID_PREFIXES)]
    crossings: list[dict] = []
    segments = unaligned = 0
    for edge in document["edges"]:
        ends = []
        for side in ("source", "target"):
            end = edge[side]
            if end.get("kind") != "node" or end.get("node") not in nodes:
                raise GraphError(f"edge {edge['id']} {side} does not point to a node")
            ends.append(end)
        points = [port_point(nodes[ends[0]["node"]], ends[0]["port"])]
        points += [(vertex["x"], vertex["y"]) for vertex in edge["vertices"]]
        points.append(port_point(nodes[ends[1]["node"]], ends[1]["port"]))
        own = {ends[0]["node"], ends[1]["node"]}
        for start, end in zip(points, points[1:]):
            segments += 1
            if abs(start[0] - end[0]) > ALIGN_TOLERANCE and abs(start[1] - end[1]) > ALIGN_TOLERANCE:
                unaligned += 1
                continue
            for node in obstacles:
                if node["id"] not in own and crosses(start, end, node):
                    crossings.append({"edge": edge["id"], "node": node["id"],
                                      "label": node.get("label", "").replace("\n", ""),
                                      "start": list(start), "end": list(end)})
    return {"edges": len(document["edges"]), "segments": segments,
            "unaligned": unaligned, "crossings": crossings}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--graph", action="append",
                        help="图文件，相对仓库根目录；可重复，默认检查文档系统关系图")
    parser.add_argument("--json", action="store_true", help="输出 JSON")
    args = parser.parse_args(argv)
    results = {}
    try:
        for name in args.graph or DEFAULT_GRAPHS:
            path = Path(name) if Path(name).is_absolute() else REPO_ROOT / name
            try:
                document = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_keys)
            except GraphError as error:
                raise GraphError(f"{name}: {error}") from None
            results[name] = check_graph(document)
    except (OSError, KeyError, TypeError, ValueError) as error:
        print(f"关系图无法检查：{error}", file=sys.stderr)
        return 2
    if args.json:
        print(json.dumps(results, ensure_ascii=False, indent=2))
    else:
        for name, result in results.items():
            for item in result["crossings"]:
                print(f"{name}: {item['edge']} 穿过 {item['node']}（{item['label']}）")
            print(f"{name}：连线 {result['edges']} 条、线段 {result['segments']} 段；"
                  f"穿过节点 {len(result['crossings'])} 处；"
                  f"两端不同行也不同列、由查看器补拐点的 {result['unaligned']} 段未检查")
    return 1 if any(result["crossings"] for result in results.values()) else 0


if __name__ == "__main__":
    sys.exit(main())
