"""Check source fidelity, selection boundaries and read-only freshness checks."""

import json
from pathlib import Path
import tempfile
import unittest

from framework.commands.export_advisor_prompt_examples import (
    PROJECT, SELECTION, build_documents, export_examples,
)


class AdvisorPromptExamplesTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="advisor_prompt_examples_")
        self.addCleanup(self.area.cleanup)
        self.root = Path(self.area.name)
        self.source = self.root / "prompts.json"
        self.output = self.root / "references"
        categories = {
            category: {title: f"正文：{title}\n${{1:待填}}" for title in titles}
            for _, category, titles in SELECTION
        }
        self.data = [{"project": PROJECT, "categories": categories}]
        self.save()

    def save(self):
        self.source.write_text(json.dumps(self.data, ensure_ascii=False), encoding="utf-8")

    def test_preserves_source_text_and_nested_fences_without_exporting_other_entries(self):
        category, title = SELECTION[0][1], SELECTION[0][2][0]
        body = "原文 ${1:范围}\n```gdscript\nprint(1)\n```\n我授权本示例任务。"
        self.data[0]["categories"][category][title] = body
        self.data[0]["categories"][category]["未精选入口"] = "EXCLUDED_PROJECT_TEXT"
        self.data.append({"project": "Yaya 框架维护", "categories": {"维护": {"入口": "EXCLUDED_FRAMEWORK_TEXT"}}})
        docs = build_documents(self.data)
        combined = "".join(docs.values())
        self.assertIn(f"````text\n{body}\n````", docs["prompt-examples/product.md"])
        self.assertNotIn("EXCLUDED_PROJECT_TEXT", combined)
        self.assertNotIn("EXCLUDED_FRAMEWORK_TEXT", combined)

    def test_missing_selected_prompt_fails_before_any_output_write(self):
        export_examples(self.source, self.output)
        before = {p: p.read_bytes() for p in self.output.rglob("*.md")}
        first_category, first_title = SELECTION[0][1], SELECTION[0][2][0]
        self.data[0]["categories"][first_category][first_title] += "\n尚不可写入的新内容"
        category, title = SELECTION[-1][1], SELECTION[-1][2][-1]
        del self.data[0]["categories"][category][title]
        self.save()
        with self.assertRaisesRegex(ValueError, "Missing or empty prompt"):
            export_examples(self.source, self.output)
        self.assertEqual(before, {p: p.read_bytes() for p in self.output.rglob("*.md")})

    def test_check_detects_missing_and_stale_files_without_writing(self):
        self.assertTrue(export_examples(self.source, self.output, check=True))
        self.assertFalse(self.output.exists())
        export_examples(self.source, self.output)
        self.assertEqual(export_examples(self.source, self.output, check=True), [])
        category, title = SELECTION[0][1], SELECTION[0][2][0]
        self.data[0]["categories"][category][title] += "\n新要求"
        self.save()
        before = (self.output / "prompt-examples/product.md").read_bytes()
        self.assertEqual(export_examples(self.source, self.output, check=True), ["prompt-examples/product.md"])
        self.assertEqual((self.output / "prompt-examples/product.md").read_bytes(), before)
        self.assertEqual(export_examples(self.source, self.output), ["prompt-examples/product.md"])
        self.assertIn("新要求", (self.output / "prompt-examples/product.md").read_text(encoding="utf-8"))
        self.assertEqual(export_examples(self.source, self.output), [])

    def test_duplicate_source_keys_are_rejected(self):
        self.source.write_text('[{"project": "one", "project": "two"}]', encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Duplicate JSON key"):
            export_examples(self.source, self.output)
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
