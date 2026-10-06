"""Exercise document coverage through its read-only CLI and real temporary files."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


COMMAND = (Path(__file__).resolve().parents[3]
           / "framework/relationship-maps/tools/check_document_graph_coverage.py")
GRAPH = "framework/relationship-maps/document-system.readable.json"
MANIFEST = "framework/project-creation/project-files.json"


class DocumentGraphCoverageTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="document_graph_")
        self.addCleanup(self.area.cleanup)
        self.root = Path(self.area.name)
        self.write(MANIFEST, "[]")

    def write(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def manifest(self, *entries):
        self.write(MANIFEST, json.dumps([{"source": source, "target": target}
                                       for source, target in entries]))

    def graph(self, *notes):
        nodes = []
        for index, note in enumerate((f"文件： {MANIFEST}\n文件： {GRAPH}", *notes)):
            nodes.append({
                "id": f"doc-{index}", "shape": "rounded-rect", "x": index * 300, "y": 0,
                "width": 270, "height": 88, "label": "Documents", "zIndex": 1,
                "fill": "#FFFFFF", "stroke": {"color": "#000000", "width": 1, "dash": "solid"},
                "text": {"fontSize": 18, "color": "#000000", "align": "center"}, "note": note,
            })
        self.write(GRAPH, json.dumps({
            "format": "graph-map-core", "version": 1,
            "documentId": "163c207d-a618-4953-8219-095116dbb0a2",
            "nodes": nodes, "edges": [],
            "canvas": {"gridSize": 20, "gridVisible": True, "snapToGrid": True},
        }, ensure_ascii=False, indent=2))

    def run_cli(self):
        return subprocess.run(
            [sys.executable, "-B", str(COMMAND), "--root", str(self.root), "--json"],
            capture_output=True, encoding="utf-8", check=False, timeout=30,
        )

    def results(self, exit_code=0):
        process = self.run_cli()
        self.assertEqual(process.returncode, exit_code, process.stderr)
        return json.loads(process.stdout)["results"]

    def test_exact_scope_and_feature_patterns_find_unregistered_files(self):
        self.write("README.md", "Framework")
        self.write("project-source/Project_README.md", "Project")
        for name in ("F001.json", "F100.json", "FABC.json", "nested/F009.json"):
            self.write(f"project-source/defaults/docs/features/{name}", "{}")
        self.write("framework/relationship-maps/with space/notes.md", "Notes")
        self.write("framework/relationship-maps/unregistered.MD", "Unregistered")
        self.manifest(("project-source/Project_README.md", "README.md"),
                      ("project-source/defaults/docs", "docs"))
        self.graph("文件： README.md\n文件： framework/relationship-maps/with space/notes.md",
                   "项目文件： docs/features/F[0-9][0-9][0-9].json")
        rows = self.results(exit_code=1)
        self.assertEqual({(r["scope"], r["path"]) for r in rows if not r["nodes"]}, {
            ("repository", "framework/relationship-maps/unregistered.MD"),
            ("project", "README.md"), ("project", "docs/features/FABC.json"),
            ("project", "docs/features/nested/F009.json"),
        })
        self.assertTrue(next(r for r in rows if r["path"] == "docs/features/F100.json")["nodes"])

    def test_recursive_patterns_cover_navigation_and_skip_non_document_outputs(self):
        included = {"framework/relationship-maps/README.md", "framework/relationship-maps/scenario-index.md",
                    "framework/relationship-maps/sub/deeper/guide.md", "framework/relationship-maps/settings.json"}
        excluded = {"framework/relationship-maps/guide.html", "framework/relationship-maps/graph-usage.personal.json",
                    "framework/relationship-maps/.cache/cache.md", "project-source/addons/plugin/README.md",
                    "project-source/tools/config.json", "project-source/defaults/gdlint.json",
                    "project-source/tools/analyzer/capabilities.json"}
        for path in included | excluded:
            self.write(path, "{}")
        self.graph("文件： framework/relationship-maps/**/*.md\n文件： framework/relationship-maps/settings.json",
                   "项目文件： docs/features/F[0-9][0-9][0-9].json")
        rows = self.results()
        self.assertEqual({r["source"] for r in rows}, included | {MANIFEST, GRAPH})

    def test_copy_manifest_expands_both_template_destinations_without_writing(self):
        source = "project-source/methodology/templates/feature-list.json.tmpl"
        self.write(source, "{}")
        self.manifest(("project-source/methodology", "yaya/methodology"),
                      (source, "docs/feature-list.json"))
        self.graph("项目文件： yaya/methodology/templates/*.tmpl")
        before = {p: p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        rows = self.results(exit_code=1)
        self.assertEqual([r["path"] for r in rows if not r["nodes"]], ["docs/feature-list.json"])
        self.assertEqual({r["path"] for r in rows if r["source"] == source},
                         {"yaya/methodology/templates/feature-list.json.tmpl", "docs/feature-list.json"})
        self.assertEqual({p: p.read_bytes() for p in self.root.rglob("*") if p.is_file()}, before)
        self.graph("项目文件： yaya/methodology/templates/*.tmpl\n项目文件： docs/feature-list.json")
        self.results()

    def test_invalid_registration_and_wrong_graph_fail_instead_of_reporting_coverage(self):
        for note in ("文件：../outside.md", "文件： ../outside.md", "文件： C:/outside.md",
                     "文件： framework\\docs\\guide.md", "职责：没有路径登记"):
            with self.subTest(note=note):
                self.graph(note)
                process = self.run_cli()
                self.assertEqual(process.returncode, 2, process.stderr)
                self.assertNotIn("Traceback", process.stderr)
                self.assertEqual(process.stdout, "")
        self.write(GRAPH, "[]")
        self.assertEqual(self.run_cli().returncode, 2)


if __name__ == "__main__":
    unittest.main()
