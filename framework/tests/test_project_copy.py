"""复制器的少量边界回归；仅在明确执行测试时使用临时目录。"""

import json
import tempfile
import tomllib
import unittest
from pathlib import Path

from framework.commands.create_project import copy_project


class ProjectCopyTests(unittest.TestCase):
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

    def test_real_agent_mappings_preserve_roles_without_global_config(self):
        repository = Path(__file__).resolve().parents[2]
        manifest = json.loads((repository / "framework/project-files.json").read_text(encoding="utf-8"))
        entries = []
        for name in ("independent-reviewer", "researcher"):
            entry = next(item for item in manifest
                         if item["target"] == f".codex/agents/{name}.toml")
            source_bytes = (repository / entry["source"]).read_bytes()
            fixture_role = self.source / entry["source"]
            fixture_role.parent.mkdir(parents=True, exist_ok=True)
            fixture_role.write_bytes(source_bytes)
            self.entries.append(entry)
            entries.append((name, entry, source_bytes))
        self.save_manifest()
        output = self.base / "project"
        copy_project(self.source, output)
        for name, entry, source_bytes in entries:
            with self.subTest(role=name):
                copied = output / entry["target"]
                self.assertEqual(copied.read_bytes(), source_bytes)
                role = tomllib.loads(copied.read_text(encoding="utf-8"))
                self.assertEqual(role["name"], name)
                self.assertTrue(role["description"])
                self.assertTrue(role["developer_instructions"])
        self.assertFalse((output / ".codex/config.toml").exists())

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

    def test_conflicting_targets_fail_before_writing_in_either_order(self):
        file_source = "project-source/Project_AGENTS.md"
        directory_source = "project-source/skills/example"
        conflicts = [
            [(file_source, "rules.md"), (file_source, "rules.md")],
            [(file_source, "rules.md"), (file_source, "RULES.md")],
            [(file_source, "docs"), (file_source, "docs/rules.md")],
            [(file_source, "docs"), (directory_source, "docs")],
            [(directory_source, "docs"), (file_source, "docs/SKILL.md")],
            [(directory_source, "docs"), (directory_source, "docs")],
        ]
        output = self.base / "project"
        for pair in conflicts:
            for ordered in (pair, list(reversed(pair))):
                with self.subTest(entries=ordered):
                    self.entries = [{"source": source, "target": target}
                                    for source, target in ordered]
                    self.save_manifest()
                    with self.assertRaisesRegex(ValueError, "Copy target conflict"):
                        copy_project(self.source, output)
                    self.assertFalse(output.exists())

    def test_directory_merge_and_separate_children_are_allowed(self):
        (self.source / "project-source/defaults").mkdir()
        (self.source / "project-source/defaults/product.md").write_text("Product", encoding="utf-8")
        self.entries = [
            {"source": "project-source/Project_AGENTS.md", "target": "docs/rules.md"},
            {"source": "project-source/defaults", "target": "docs"},
            {"source": "project-source/skills/example", "target": "docs"},
        ]
        self.save_manifest()
        output = self.base / "project"
        copy_project(self.source, output)
        self.assertEqual({path.name for path in (output / "docs").iterdir()},
                         {"rules.md", "product.md", "SKILL.md"})
        self.assertEqual((output / "docs/rules.md").read_text(encoding="utf-8"), "Project rules")

    def test_real_distribution_keeps_examples_separate_from_project_initialization(self):
        repository = Path(__file__).resolve().parents[2]
        output = self.base / "real-copy"
        copy_project(repository, output)
        config = json.loads((output / "docs/methodology-config.json").read_text(encoding="utf-8"))
        self.assertEqual(config["environment_bootstrap"]["status"], "incomplete")
        self.assertEqual(config["environment_bootstrap"]["engine_version"], "")
        self.assertEqual(config["test_cmd"], "")
        self.assertNotIn("run/main_scene", (output / "project.godot").read_text(encoding="utf-8"))
        for name in (".git", ".godot", "framework", "tests", "prompts.json"):
            self.assertFalse((output / name).exists(), name)
        for name, key in (("feature-list.json", "features"), ("test-registry.json", "tests")):
            self.assertEqual(json.loads((output / "docs" / name).read_text(encoding="utf-8"))[key], [])
        for relative in (
            "examples/asset_workbench/example-workbench.tscn",
            "examples/asset_workbench/example-game.tscn",
            "components/feedback/audio_playback.gd",
            "tools/asset_workbench/workbench.gd",
            "addons/sound_manager/abstract_audio_player_pool.gd",
        ):
            self.assertEqual((output / relative).read_bytes(),
                             (repository / "project-source" / relative).read_bytes())
        assets = list((output / "examples/asset_workbench/assets").iterdir())
        self.assertTrue(assets)
        self.assertTrue(all(path.name.startswith("example-") for path in assets))


if __name__ == "__main__":
    unittest.main()
