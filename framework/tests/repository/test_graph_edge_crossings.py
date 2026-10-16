import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


COMMAND = (Path(__file__).resolve().parents[3]
           / "framework/relationship-maps/tools/check_graph_edge_crossings.py")


def node(node_id, x, y):
    return {"id": node_id, "x": x, "y": y, "width": 100, "height": 40, "label": node_id}


def edge(edge_id, source, target, vertices=(), source_port="right", target_port="left"):
    return {"id": edge_id, "source": {"kind": "node", "node": source, "port": source_port},
            "target": {"kind": "node", "node": target, "port": target_port},
            "vertices": [{"x": x, "y": y} for x, y in vertices]}


class GraphEdgeCrossingTests(unittest.TestCase):
    def setUp(self):
        area = tempfile.TemporaryDirectory(prefix="graph_crossings_")
        self.addCleanup(area.cleanup)
        self.graph = Path(area.name) / "graph.json"

    def run_check(self, nodes, edges):
        self.graph.write_text(json.dumps({"nodes": nodes, "edges": edges}), encoding="utf-8")
        return subprocess.run([sys.executable, "-B", str(COMMAND), "--graph", str(self.graph), "--json"],
                              capture_output=True, text=True, encoding="utf-8")

    def test_reports_only_segments_through_other_content_nodes(self):
        nodes = [node("a", 0, 0), node("middle", 200, 0), node("b", 400, 0),
                 node("legend-key", 150, -100) | {"width": 400, "height": 300}]
        edges = [
            edge("through", "a", "b"),
            edge("around", "a", "b", [(150, 20), (150, 0), (450, 0), (450, 20)], target_port="right"),
            edge("unaligned", "a", "b", [(300, 300)]),
        ]
        completed = self.run_check(nodes, edges)
        self.assertEqual(completed.returncode, 1, completed.stderr)
        result = json.loads(completed.stdout)[str(self.graph)]
        self.assertEqual([(item["edge"], item["node"]) for item in result["crossings"]],
                         [("through", "middle")])
        self.assertEqual(result["unaligned"], 2)

    def test_clean_graph_exits_0(self):
        completed = self.run_check([node("a", 0, 0), node("b", 200, 0)], [edge("direct", "a", "b")])
        self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_edge_to_missing_node_exits_2(self):
        completed = self.run_check([node("a", 0, 0)], [edge("dangling", "a", "gone")])
        self.assertEqual(completed.returncode, 2)
        self.assertIn("dangling", completed.stderr)

    def test_duplicate_key_left_by_a_merge_exits_2(self):
        source = json.dumps(edge("merged", "a", "b"))
        duplicated = source.replace('"vertices"', '"target": {"kind": "node", "node": "a", "port": "left"}, "vertices"')
        nodes = json.dumps([node("a", 0, 0), node("b", 200, 0)])
        self.graph.write_text(f'{{"nodes": {nodes}, "edges": [{duplicated}]}}', encoding="utf-8")
        completed = subprocess.run([sys.executable, "-B", str(COMMAND), "--graph", str(self.graph)],
                                   capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(completed.returncode, 2)
        self.assertIn("duplicate key 'target'", completed.stderr)


if __name__ == "__main__":
    unittest.main()
