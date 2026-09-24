"""用中立临时 Git 夹具验证使用说明、知识/调研文档与验证契约的指纹边界。"""

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path


SOURCE = Path(__file__).resolve().parents[2] / "project-source/tools/lib/feature_completion_evidence.py"
SPEC = importlib.util.spec_from_file_location("documentation_feature_completion_evidence", SOURCE)
feature_completion_evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(feature_completion_evidence)


class DocumentationFingerprintTests(unittest.TestCase):
    def setUp(self):
        area = tempfile.TemporaryDirectory(prefix="yaya-documentation-")
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

    def test_usage_readme_add_edit_remove_and_staging_preserve_source_binding(self):
        before = self.fingerprint()
        for name in (
            "README.md", "scenarios/reset_sequence/README.md", "tools/README.md",
            "docs/README.md", "docs/guides/readme.md", "modules/counter/ReadMe.md",
        ):
            with self.subTest(name=name):
                readme = self.write(name, "Usage instructions\n")
                self.assertEqual(before, self.fingerprint())
                self.git("add", name)
                self.assertEqual(before, self.fingerprint())
                readme.write_text("Clarified usage instructions\n", encoding="utf-8")
                self.assertEqual(before, self.fingerprint())
                readme.unlink()
                self.assertEqual(before, self.fingerprint())

    def test_readme_moved_into_product_becomes_verification_input(self):
        readme = self.write("scenarios/reset_sequence/README.md", "Document text\n")
        before = self.fingerprint()
        requirement = self.root / "docs/product/README.md"
        requirement.parent.mkdir(parents=True)
        readme.rename(requirement)
        self.assertNotEqual(before, self.fingerprint())

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

    def test_research_prose_preserves_binding_until_adopted_as_a_requirement(self):
        before = self.fingerprint()
        report = self.write("docs/research/save-format.md", "Versioned sources and tentative recommendation\n")
        self.assertEqual(before, self.fingerprint())
        self.git("add", "docs/research")
        report.write_text("Revised recommendation; runtime not verified\n", encoding="utf-8")
        self.assertEqual(before, self.fingerprint())
        destination = self.root / "docs/research/storage/save-format.md"
        destination.parent.mkdir(parents=True)
        report.rename(destination)
        self.assertEqual(before, self.fingerprint())
        self.write("docs/features/F001-design.md", "Adopted save-format requirement\n")
        self.assertNotEqual(before, self.fingerprint())

    def test_research_exemption_does_not_hide_executable_or_neighboring_content(self):
        for name, content in (
            ("docs/research/probe.gd", "extends Node\n"),
            ("docs/research/fixture.json", '{"value": 1}\n'),
            ("docs/research-other/note.md", "Outside research directory\n"),
        ):
            with self.subTest(name=name):
                before = self.fingerprint()
                self.write(name, content)
                self.assertNotEqual(before, self.fingerprint())

    def test_professional_edits_invalidate_but_isolated_review_outputs_do_not(self):
        for name in (
            "docs/art/art-bible.md", "docs/audio/sound-bible.md",
            "docs/ui/inventory-design.md", "docs/localization/localization-spec.md",
            "docs/resource-requirements/inventory.md",
        ):
            with self.subTest(name=name):
                source = self.write(name, "Confirmed requirement\nStatus: supplied\n")
                self.git("add", name)
                before = self.fingerprint()
                source.write_text("Confirmed requirement\nStatus: inspected\n", encoding="utf-8")
                self.assertNotEqual(before, self.fingerprint())
        before = self.fingerprint()
        self.write("reports/features/F001/art-review.md", "Bounded review findings\n")
        self.write("reports/scratch/art-review/run.json", '{"observed": true}')
        self.write("reports/scratch/art-review/cache.bin", "Isolated cache")
        self.git("add", "reports")
        self.assertEqual(before, self.fingerprint())

    def test_process_notes_cannot_bind_a_professional_constraint(self):
        detail = self.write("docs/features/F001.json", json.dumps({
            "source": "product/01-inventory.md", "notes": "See Art Bible"
        }))
        before = self.fingerprint()
        detail.write_text(json.dumps({
            "source": "product/01-inventory.md", "notes": "Icons must be readable at 24px"
        }), encoding="utf-8")
        self.assertEqual(before, self.fingerprint())
        self.write("docs/features/F001-design.md", "Icons must be readable at 24px\n")
        self.assertNotEqual(before, self.fingerprint())

    def test_contracts_and_source_outside_knowledge_still_invalidate(self):
        for name, content in (
            ("main.gd", "extends Node\nvar changed: bool = true\n"),
            ("tests/example.gd", "extends Node\n"),
            ("docs/product.md", "New required behavior\n"),
            ("docs/product/README.md", "Required module behavior\n"),
            ("docs/features/README.md", "Feature contract\n"),
            ("agent-rules/rule.md", "New mandatory contract\n"),
            ("agent-rules/70-tests/README.md", "Required test rules\n"),
            ("methodology/templates/README.md", "Required template contract\n"),
            (".agents/skills/task/README.md", "Required Skill behavior\n"),
            ("docs/knowledge-other/note.md", "Outside the knowledge boundary\n"),
            ("docs/features/F001.json", json.dumps({
                "acceptance_criteria": [{"id": "AC01", "text": "Changed requirement"}]
            })),
            ("docs/test-registry.json", '{"tests": [{"id": "changed", "status": "active"}]}'),
            ("docs/methodology-config.json", '{"python_executable": "tools/changed-python.exe"}'),
        ):
            with self.subTest(name=name):
                before = self.fingerprint()
                self.write(name, content)
                self.assertNotEqual(before, self.fingerprint())


if __name__ == "__main__":
    unittest.main()
