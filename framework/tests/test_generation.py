"""复制器的少量边界回归；仅在明确执行测试时使用临时目录。"""

import json
import tempfile
import unittest
from pathlib import Path

from framework.commands.create_project import copy_project


class GenerationTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="project_copy_")
        self.addCleanup(self.area.cleanup)
        self.base = Path(self.area.name)
        self.source = self.base / "source"
        (self.source / "framework").mkdir(parents=True)
        (self.source / "project-source/skills/example").mkdir(parents=True)
        (self.source / "AGENTS.md").write_text("Maintenance rules", encoding="utf-8")
        (self.source / "project-source/Project_AGENTS.md").write_text("Project rules", encoding="utf-8")
        (self.source / "project-source/skills/example/SKILL.md").write_text("Keep original", encoding="utf-8")
        self.entries = [
            {"source": "project-source/Project_AGENTS.md", "target": "AGENTS.md"},
            {"source": "project-source/skills", "target": ".agents/skills"},
        ]
        self.save_manifest()

    def save_manifest(self):
        (self.source / "framework/project-files.json").write_text(
            json.dumps(self.entries), encoding="utf-8"
        )

    def test_selected_bytes_and_renamed_rule_only(self):
        output = self.base / "project"
        copy_project(self.source, output)
        files = {p.relative_to(output).as_posix() for p in output.rglob("*") if p.is_file()}
        self.assertEqual(files, {"AGENTS.md", ".agents/skills/example/SKILL.md"})
        self.assertEqual((output / "AGENTS.md").read_text(encoding="utf-8"), "Project rules")
        self.assertEqual(
            (output / ".agents/skills/example/SKILL.md").read_bytes(),
            (self.source / "project-source/skills/example/SKILL.md").read_bytes(),
        )

    def test_empty_target_allowed_nonempty_preserved(self):
        output = self.base / "project"
        output.mkdir()
        copy_project(self.source, output)
        with self.assertRaises(ValueError):
            copy_project(self.source, output)
        self.assertEqual((output / "AGENTS.md").read_text(encoding="utf-8"), "Project rules")

    def test_bad_destination_fails_before_source_read(self):
        for name in ["Bad Project", "中文项目", "Parent Space/Child", "父目录/Child"]:
            with self.subTest(name=name), self.assertRaises(ValueError):
                copy_project(self.base / "absent_source", self.base / name)
            self.assertFalse((self.base / name).exists())

    def test_missing_source_and_escape_leave_target_unwritten(self):
        output = self.base / "project"
        for change in [
            {"source": "project-source/absent.md", "target": "missing.md"},
            {"source": "project-source/Project_AGENTS.md", "target": "../outside.md"},
        ]:
            self.entries = [change]
            self.save_manifest()
            with self.assertRaises((OSError, ValueError)):
                copy_project(self.source, output)
            self.assertFalse(output.exists())
            self.assertFalse((self.base / "outside.md").exists())

    def test_destination_must_be_external(self):
        with self.assertRaises(ValueError):
            copy_project(self.source, self.source / "project")


if __name__ == "__main__":
    unittest.main()
