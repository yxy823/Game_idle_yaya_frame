"""用中立临时 Git 夹具验证知识文档的指纹边界，不创建或运行游戏项目。"""

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path


SOURCE = Path(__file__).resolve().parents[2] / "project-source/tools/lib/feature_completion_evidence.py"
SPEC = importlib.util.spec_from_file_location("knowledge_feature_completion_evidence", SOURCE)
feature_completion_evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(feature_completion_evidence)


class KnowledgeFingerprintTests(unittest.TestCase):
    def setUp(self):
        area = tempfile.TemporaryDirectory(prefix="yaya-knowledge-")
        self.addCleanup(area.cleanup)
        self.root = Path(area.name)
        self.git("init", "--quiet")
        self.write("main.gd", "extends Node\n")

    def git(self, *args):
        result = subprocess.run(
            ["git", "-C", str(self.root), *args], capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def write(self, relative_path, content):
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def fingerprint(self):
        return feature_completion_evidence.working_tree_fingerprint(self.root)

    def test_knowledge_capture_edit_and_reorganization_preserve_source_binding(self):
        before = self.fingerprint()
        self.write("docs/knowledge/README.md", "Topic index\n")
        note = self.write("docs/knowledge/godot-runtime/ui.md", "Observed approach\n")
        self.write("docs/knowledge/debugging-testing/reproduction.md", "Useful diagnosis\n")
        self.assertEqual(before, self.fingerprint())
        self.git("add", "docs/knowledge")
        self.assertEqual(before, self.fingerprint())
        note.write_text("Updated applicability and evidence\n", encoding="utf-8")
        self.assertEqual(before, self.fingerprint())
        destination = self.root / "docs/knowledge/godot-runtime/ui/focus.md"
        destination.parent.mkdir(parents=True)
        note.rename(destination)
        self.assertEqual(before, self.fingerprint())
        destination.unlink()
        self.assertEqual(before, self.fingerprint())

    def test_non_markdown_inside_knowledge_still_invalidates(self):
        for name, content in (
            ("helper.gd", "extends Node\n"),
            ("fixture.json", '{"value": 1}\n'),
            ("run.ps1", "Write-Output 1\n"),
        ):
            with self.subTest(name=name):
                before = self.fingerprint()
                self.write(f"docs/knowledge/tools-pipeline/{name}", content)
                self.assertNotEqual(before, self.fingerprint())

    def test_contracts_and_source_outside_knowledge_still_invalidate(self):
        for name, content in (
            ("main.gd", "extends Node\nvar changed: bool = true\n"),
            ("tests/example.gd", "extends Node\n"),
            ("docs/product.md", "New required behavior\n"),
            ("agent-rules/rule.md", "New mandatory contract\n"),
            ("docs/knowledge-other/note.md", "Outside the knowledge boundary\n"),
            ("docs/features/F001.json", json.dumps({
                "acceptance_criteria": [{"id": "AC01", "text": "Changed requirement"}]
            })),
            ("docs/test-registry.json", '{"tests": [{"id": "changed", "status": "active"}]}'),
            ("docs/methodology-config.json", '{"test_cmd": "changed"}'),
        ):
            with self.subTest(name=name):
                before = self.fingerprint()
                self.write(name, content)
                self.assertNotEqual(before, self.fingerprint())


if __name__ == "__main__":
    unittest.main()
