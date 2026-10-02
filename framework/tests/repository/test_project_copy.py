"""复制器的少量边界回归；仅在明确执行测试时使用临时目录。"""

import json
import os
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path
from unittest.mock import patch

from framework.commands.create_project import copy_project, create_project


class ProjectCopyTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="project_copy_")
        self.addCleanup(self.area.cleanup)
        self.base = Path(self.area.name)
        self.source = self.base / "source"
        (self.source / "framework/commands").mkdir(parents=True)
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
        (self.source / "framework/commands/project-files.json").write_text(
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

    def test_nested_python_caches_are_skipped_without_filtering_source_or_assets(self):
        origin = self.source / "project-source/skills/example"
        cached = ("__pycache__/nested/cache.bin", ".pytest_cache/v/cache/nodeids",
                  "nested/__pycache__/helper.pyc", "nested/helper.pyc", "nested/helper.pyo")
        kept = ("helper.py", "nested/source.py", "icon.png", "icon.png.import",
                "helper.gd.uid", "LICENSE", "cache.json", "folder.pyc/source.txt")
        for relative in (*cached, *kept):
            path = origin / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"original bytes\r\n")
        output = self.base / "project"
        copy_project(self.source, output)
        copied = output / ".agents/skills/example"
        self.assertEqual({path.relative_to(copied).as_posix()
                          for path in copied.rglob("*") if path.is_file()},
                         {"SKILL.md", *kept})
        for relative in kept:
            self.assertEqual((copied / relative).read_bytes(), (origin / relative).read_bytes())
        for relative in cached:
            self.assertTrue((origin / relative).is_file())
        self.assertFalse((copied / "__pycache__").exists())
        self.assertFalse((copied / ".pytest_cache").exists())

    def test_ignored_cache_does_not_claim_a_target_during_preflight(self):
        origin = self.source / "project-source/skills/example"
        for relative in ("helper.pyc", "__pycache__/nested/cache.bin"):
            with self.subTest(relative=relative):
                path = origin / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"cache")
                self.entries.append({"source": "project-source/Project_AGENTS.md",
                                     "target": f".agents/skills/example/{relative}"})
                self.save_manifest()
                output = self.base / f"project-{len(self.entries)}"
                copy_project(self.source, output)
                self.assertEqual((output / ".agents/skills/example" / relative).read_text(),
                                 "Project rules")

    def test_empty_target_allowed_nonempty_preserved(self):
        output = self.base / "project"
        output.mkdir()
        copy_project(self.source, output)
        with self.assertRaises(ValueError):
            copy_project(self.source, output)
        self.assertEqual((output / "AGENTS.md").read_text(encoding="utf-8"), "Project rules")

    def test_creation_leaves_one_local_commit_and_clean_worktree(self):
        output = self.base / "project"
        environment = {
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_AUTHOR_NAME": "Creator Test",
            "GIT_AUTHOR_EMAIL": "creator@example.invalid",
            "GIT_COMMITTER_NAME": "Creator Test",
            "GIT_COMMITTER_EMAIL": "creator@example.invalid",
        }
        with patch.dict(os.environ, environment):
            self.assertEqual(create_project(self.source, output), len(self.entries))

        def git(*args):
            return subprocess.check_output(["git", *args], cwd=output, text=True).strip()

        self.assertEqual(git("rev-list", "--count", "HEAD"), "1")
        self.assertEqual(git("status", "--porcelain"), "")
        self.assertEqual(git("remote"), "")
        self.assertEqual(
            set(git("ls-tree", "-r", "--name-only", "HEAD").splitlines()),
            {"AGENTS.md", ".agents/skills/example/SKILL.md"},
        )

    def test_real_agent_mappings_preserve_roles_without_global_config(self):
        repository = Path(__file__).resolve().parents[3]
        manifest = json.loads((repository / "framework/commands/project-files.json").read_text(encoding="utf-8"))
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
        repository = Path(__file__).resolve().parents[3]
        output = self.base / "real-copy"
        copy_project(repository, output)
        config = json.loads((output / "docs/methodology-config.json").read_text(encoding="utf-8"))
        self.assertEqual(set(config), {"document_language", "engine_executable", "python_executable"})
        self.assertIsInstance(config["engine_executable"], str)
        settings = (output / "project.godot").read_text(encoding="utf-8")
        self.assertIn('run/main_scene="res://main/main.tscn"', settings)
        self.assertIn("window/size/viewport_width=1600", settings)
        self.assertIn("window/size/viewport_height=900", settings)
        for name in (".git", ".godot", "framework", "godot-development-prompts.json",
                     "yaya-maintenance-prompts.json"):
            self.assertFalse((output / name).exists(), name)
        writing_skill = output / ".agents/skills/technical-documentation-writing-godot"
        writing_sources = repository / "project-source/skills/technical-documentation-writing-godot"
        source_files = {path.relative_to(writing_sources).as_posix()
                        for path in writing_sources.rglob("*") if path.is_file()}
        required_files = {"SKILL.md", "agents/openai.yaml", "references/writing-guide.md",
                          "references/document-structure.md", "references/procedure-writing.md"}
        self.assertTrue(required_files <= source_files)
        self.assertEqual({path.relative_to(writing_skill).as_posix()
                          for path in writing_skill.rglob("*") if path.is_file()}, source_files)
        for relative in source_files:
            with self.subTest(writing_skill_file=relative):
                self.assertEqual((writing_skill / relative).read_bytes(),
                                 (writing_sources / relative).read_bytes())
        for name in ("technical-documentation-writing", "technical-documentation-writing-yaya"):
            self.assertFalse((output / ".agents/skills" / name).exists(), name)
        presentation_sources = repository / "project-source/skills/design-game-presentation"
        presentation_skill = output / ".agents/skills/design-game-presentation"
        presentation_files = {path.relative_to(presentation_sources).as_posix()
                              for path in presentation_sources.rglob("*") if path.is_file()}
        self.assertTrue({"SKILL.md", "agents/openai.yaml", "references/technique-selection.md",
                         "references/shader-requirements.md", "references/particle-requirements.md",
                         "references/presentation-example.md"} <= presentation_files)
        self.assertEqual({path.relative_to(presentation_skill).as_posix()
                          for path in presentation_skill.rglob("*") if path.is_file()},
                         presentation_files)
        for relative in presentation_files:
            with self.subTest(presentation_skill_file=relative):
                self.assertEqual((presentation_skill / relative).read_bytes(),
                                 (presentation_sources / relative).read_bytes())
        self.assertEqual({path.name for path in (output / "docs/presentation").iterdir()},
                         {"README.md"})
        self.assertEqual((output / "docs/presentation/README.md").read_bytes(),
                         (repository / "project-source/defaults/docs/presentation/README.md").read_bytes())
        self.assertFalse((output / "docs/resource-requirements").exists())
        self.assertFalse((output / "agent-rules/00-core/documentation").exists())
        self.assertEqual({path.name for path in (output / "tools").iterdir() if path.is_dir()},
                         {"checks", "features", "testing", "lib"})
        self.assertFalse((output / "examples").exists())
        self.assertEqual({path.name for path in (output / "asset_workbench").iterdir()},
                         {"ui", "analyzer", "examples"})
        self.assertFalse(any((output / ".agents/skills").glob("*-yaya")))
        self.assertFalse(any(output.rglob("__pycache__")))
        main_scene = output / "main/main.tscn"
        self.assertEqual(main_scene.read_bytes(),
                         (repository / "project-source/defaults/main/main.tscn").read_bytes())
        self.assertFalse((output / "main/main.gd").exists())
        for relative in ("game", "assets", "tests/unit", "tests/features", "tests/invariants"):
            with self.subTest(directory=relative):
                directory = output / relative
                self.assertEqual({path.name for path in directory.iterdir()}, {".gitkeep"})
        for relative in ("main", "game", "assets", "tests"):
            self.assertFalse(any((output / relative).rglob(".gdignore")), relative)
        for name, key in (("feature-list.json", "features"), ("test-registry.json", "tests")):
            self.assertEqual(json.loads((output / "docs" / name).read_text(encoding="utf-8"))[key], [])
        for relative in ("gdd/README.md", "gdd/open-questions.md", "product.md", "product/README.md"):
            self.assertEqual((output / "docs" / relative).read_bytes(),
                             (repository / "project-source/defaults/docs" / relative).read_bytes())
        for name, expected in (("gdd", {"README.md", "open-questions.md"}), ("product", {"README.md"})):
            self.assertEqual({path.name for path in (output / "docs" / name).iterdir()}, expected)
        for relative in (
            "asset_workbench/examples/single/example_workbench.tscn",
            "asset_workbench/examples/single/example_game.tscn",
            "asset_workbench/examples/composition/example_workbench.tscn",
            "asset_workbench/examples/composition/example_composition.tscn",
            "components/feedback/audio_playback.gd",
            "asset_workbench/ui/workbench.gd",
            "asset_workbench/analyzer/worker.py",
            "addons/sound_manager/abstract_audio_player_pool.gd",
        ):
            self.assertEqual((output / relative).read_bytes(),
                             (repository / "project-source" / relative).read_bytes())
        assets = list((output / "asset_workbench/examples/assets").iterdir())
        self.assertTrue(assets)
        self.assertTrue(all(path.name.startswith("example_") for path in assets))
        self.assertFalse((output / "asset_workbench/examples/example_workbench.tscn").exists())
        single = (output / "asset_workbench/examples/single/example_workbench.tscn").read_text()
        self.assertNotIn("composition", single)


if __name__ == "__main__":
    unittest.main()
