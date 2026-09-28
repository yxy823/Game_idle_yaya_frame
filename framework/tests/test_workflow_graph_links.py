"""Protect exact scenario mapping, read-only checks and all-or-nothing updates."""

import copy
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from framework.commands.link_workflow_graph_scenarios import main, update_links


class WorkflowGraphLinksTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="workflow_graph_links_")
        self.addCleanup(self.area.cleanup)
        self.root = Path(self.area.name)
        self.prompts = self.root / "prompts.json"
        self.graph = self.root / "graph.json"
        self.scenarios = self.root / "scenarios"
        self.project = "Godot 项目开发"
        self.names = ["已有要求，现在实施", "实际体验，需要记录"]
        catalog = [{"project": self.project, "categories": {"日常开发": {n: "正文" for n in self.names}}}]
        self.prompts.write_text(json.dumps(catalog, ensure_ascii=False), encoding="utf-8")
        self.targets = []
        for name in self.names:
            target = self.scenarios / self.project / "日常开发" / f"{name}.md"
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("# " + name, encoding="utf-8")
            self.targets.append(target)
        self.data = {"format": "graph-map-core", "version": 1,
                     "nodes": [{"id": str(i), "label": name.replace("，", "，\r\n"),
                                "x": 42, "text": {"fontSize": 16}}
                               for i, name in enumerate(self.names)],
                     "edges": [{"id": "edge", "source": {"node": "0"}, "target": {"node": "1"}}],
                     "canvas": {"gridVisible": False}}
        self.save_graph()

    def save_graph(self):
        self.graph.write_text(json.dumps(self.data, ensure_ascii=False), encoding="utf-8")

    def run_update(self, **kwargs):
        return update_links(self.prompts, self.graph, self.scenarios, self.project, **kwargs)

    def test_updates_only_links_and_second_run_preserves_bytes(self):
        self.data["nodes"][0]["link"] = {"kind": "local", "target": "old-location.md"}
        self.save_graph()
        expected = copy.deepcopy(self.data)
        for node, target in zip(expected["nodes"], self.targets):
            node["link"] = {"kind": "local", "target": target.resolve().as_posix()}
        self.assertTrue(self.run_update()["written"])
        self.assertEqual(json.loads(self.graph.read_text(encoding="utf-8")), expected)
        before = self.graph.read_bytes()
        self.assertEqual(self.run_update()["changed"], 0)
        self.assertEqual(before, self.graph.read_bytes())

    def test_check_has_no_side_effects_and_exit_code_changes_after_update(self):
        args = ["--prompts", str(self.prompts), "--graph", str(self.graph),
                "--scenarios", str(self.scenarios), "--check"]
        before = self.graph.read_bytes()
        with redirect_stdout(io.StringIO()) as output:
            self.assertEqual(main(args), 1)
        self.assertEqual(json.loads(output.getvalue())["changed"], 2)
        self.assertEqual(before, self.graph.read_bytes())
        self.run_update()
        with redirect_stdout(io.StringIO()):
            self.assertEqual(main(args), 0)

    def test_missing_late_target_prevents_all_writes(self):
        self.targets[-1].unlink()
        before = self.graph.read_bytes()
        result = self.run_update()
        self.assertFalse(result["ok"])
        self.assertEqual(result["missing_files"][0]["graph_pointer"], "/nodes/1/link")
        self.assertEqual(before, self.graph.read_bytes())

    def test_name_mismatch_reports_location_without_writing(self):
        self.data["nodes"][0]["label"] += "错字"
        self.save_graph()
        before = self.graph.read_bytes()
        result = self.run_update()
        self.assertEqual(result["reason"], "name_mismatch")
        self.assertEqual(result["name_audit"]["unexpected"][0]["graph_pointer"], "/nodes/0/label")
        self.assertEqual(before, self.graph.read_bytes())

    def test_replace_failure_preserves_original_and_removes_temporary(self):
        before = self.graph.read_bytes()
        with patch("framework.commands.link_workflow_graph_scenarios.os.replace", side_effect=OSError("replace denied")):
            with self.assertRaisesRegex(OSError, "replace denied"):
                self.run_update()
        self.assertEqual(before, self.graph.read_bytes())
        self.assertEqual(list(self.root.glob(".graph.json.*.tmp")), [])


if __name__ == "__main__":
    unittest.main()
