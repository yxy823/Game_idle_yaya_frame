"""Check plain-text path and heading references inside the prompt libraries."""
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest import mock


MODULE = Path(__file__).resolve().parents[2] / "maintenance/tools/check_repository_links.py"
_spec = importlib.util.spec_from_file_location("check_repository_links", MODULE)
links = sys.modules[_spec.name] = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(links)


class PromptTextReferenceTests(unittest.TestCase):
    def setUp(self):
        area = tempfile.TemporaryDirectory(prefix="prompt_refs_")
        self.addCleanup(area.cleanup)
        self.root = Path(area.name)
        self.write("AGENTS.md", "# 规则\n## 核心决策原则\n")
        self.write("framework/maintenance/sync.md", "# 同步\n## 授权在后续对话中的延续\n")
        self.write("project-source/addons/demo/plugin.cfg", "")

    def write(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def library(self, name, prompts):
        body = [{"project": "P", "categories": {"C": prompts}}]
        self.write(f"framework/prompt-scenarios/prompts/{name}", json.dumps(body, ensure_ascii=False, indent=2))

    def broken(self):
        return {(row["file"].rsplit("/", 1)[-1], row["target"], row["reason"])
                for row in links.check_prompt_references(self.root)[1]}

    def test_existing_paths_headings_and_globs_pass(self):
        self.library("yaya-maintenance-prompts.json", {
            "好": "读 AGENTS.md 的「核心决策原则」和 framework/maintenance/sync.md 的「授权在后续对话中的延续」。\n"
                  "- project-source/addons/*/plugin.cfg\n- 生成项目的 docs/progress.md 不核对",
        })
        self.assertEqual(self.broken(), set())

    def test_key_spacing_does_not_stop_the_check(self):
        body = '[{"project": "P", "categories": {"C": {"好" : "读 AGENTS.md 和 framework/maintenance/missing.md"}}}]'
        self.write("framework/prompt-scenarios/prompts/yaya-maintenance-prompts.json", body)
        self.assertEqual(self.broken(), {("yaya-maintenance-prompts.json", "好: framework/maintenance/missing.md", "target does not exist")})

    def test_missing_paths_and_headings_are_reported(self):
        self.library("yaya-maintenance-prompts.json", {
            "坏": "读 framework/maintenance/sync.md 的「后续用口语继续」、「授权在后续对话中的延续」，"
                  "AGENTS.md 的「不存在」，framework/maintenance/sync.md「无此节」，以及 framework/gone.md。",
        })
        self.assertEqual(self.broken(), {
            ("yaya-maintenance-prompts.json", "坏: framework/maintenance/sync.md 的「后续用口语继续」",
             "heading not found in target"),
            ("yaya-maintenance-prompts.json", "坏: AGENTS.md 的「不存在」", "heading not found in target"),
            ("yaya-maintenance-prompts.json", "坏: framework/maintenance/sync.md 的「无此节」",
             "heading not found in target"),
            ("yaya-maintenance-prompts.json", "坏: framework/gone.md", "target does not exist"),
        })

    def test_bare_file_names_in_godot_prompts_refer_to_the_project_and_are_skipped(self):
        self.library("godot-development-prompts.json", {"项目": "读 AGENTS.md 的「沟通与交付」。"})
        self.assertEqual(self.broken(), set())


class IncompleteCheckTests(unittest.TestCase):
    def test_copy_failure_returns_2_instead_of_broken_links(self):
        failure = ValueError("Project path must not contain Chinese characters or whitespace")
        errors = io.StringIO()
        with mock.patch.object(links, "run_checker", return_value={"broken": [], "files": 0, "links": 0}), \
                mock.patch.object(links, "copy_project", side_effect=failure), redirect_stderr(errors):
            self.assertEqual(links.main([]), 2)
        self.assertIn("whitespace", errors.getvalue())


if __name__ == "__main__":
    unittest.main()
