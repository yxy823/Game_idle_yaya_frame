import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile
import tomllib
import unittest
from pathlib import Path
from unittest.mock import patch

CREATOR = Path(__file__).resolve().parents[2] / "project-creation/tools/create_project.py"
GIT_ENVIRONMENT = {
    "GIT_CONFIG_GLOBAL": os.devnull,
    "GIT_CONFIG_NOSYSTEM": "1",
    "GIT_AUTHOR_NAME": "Creator Test",
    "GIT_AUTHOR_EMAIL": "creator@example.invalid",
    "GIT_COMMITTER_NAME": "Creator Test",
    "GIT_COMMITTER_EMAIL": "creator@example.invalid",
}
_SPEC = importlib.util.spec_from_file_location("create_project", CREATOR)
create_project_module = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(create_project_module)
copy_project, create_project = create_project_module.copy_project, create_project_module.create_project


class ProjectCopyTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="project_copy_")
        self.addCleanup(self.area.cleanup)
        self.base = Path(self.area.name)
        self.source = self.base / "source"
        (self.source / "framework/project-creation").mkdir(parents=True)
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
        (self.source / "framework/project-creation/project-files.json").write_text(
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
        with patch.dict(os.environ, GIT_ENVIRONMENT):
            self.assertEqual(create_project(self.source, output), len(self.entries))

        def git(*args):
            return subprocess.check_output(["git", *args], cwd=output, text=True).strip()

        self.assertEqual(git("rev-list", "--count", "HEAD"), "1")
        self.assertEqual(git("status", "--porcelain"), "")
        self.assertEqual(git("remote"), "")
        self.assertEqual(git("config", "--local", "core.hooksPath"), ".githooks")
        self.assertEqual(
            set(git("ls-tree", "-r", "--name-only", "HEAD").splitlines()),
            {"AGENTS.md", ".agents/skills/example/SKILL.md"},
        )

    def test_real_creation_hook_rejects_wording_problems_until_they_are_fixed(self):
        repository = Path(__file__).resolve().parents[3]
        output = self.base / "hooked"
        # 钩子调用 PATH 中的 python；让它与运行测试的解释器一致。
        path = os.pathsep.join((str(Path(sys.executable).parent), os.environ.get("PATH", "")))
        with patch.dict(os.environ, {**GIT_ENVIRONMENT, "PATH": path}):
            create_project(repository, output)

            def commit():
                subprocess.run(["git", "add", "-A"], cwd=output, check=True)
                return subprocess.run(["git", "commit", "-m", "docs: 登记术语"], cwd=output,
                                      capture_output=True, encoding="utf-8", check=False)

            terminology = output / "docs/terminology.md"
            with terminology.open("a", encoding="utf-8", newline="\n") as handle:
                handle.write("| 晶石 | 游戏中唯一的资源 | 水晶 |\n")
            (output / "docs/guide.md").write_text("# 指南\n\n收集水晶。\n\n见[词表](terminology.md)。\n",
                                                 encoding="utf-8", newline="\n")
            rules = output / "docs/project-rules.md"
            rules.write_text(rules.read_text(encoding="utf-8") + "\n提交前应运行检查。\n", encoding="utf-8", newline="\n")
            rejected = commit()
            self.assertNotEqual(rejected.returncode, 0, rejected.stdout)
            report = rejected.stdout + rejected.stderr
            self.assertIn("docs/guide.md:3:3: [TERM-FORBIDDEN]", report)
            self.assertIn("docs/project-rules.md:", report)
            self.assertIn("[WORDING-HARD]", report)
            self.assertIn("docs/guide.md:5  [LINK-TEXT]", report)
            self.assertIn("链接文字检查", report)
            self.assertIn("提交被拒绝", report)

            (output / "docs/guide.md").write_text("# 指南\n\n收集晶石。\n\n见[项目术语](terminology.md)。\n",
                                                 encoding="utf-8", newline="\n")
            rules.write_text(rules.read_text(encoding="utf-8").replace("提交前应运行检查。", "提交前运行检查。"),
                             encoding="utf-8", newline="\n")
            # 框架副本按框架术语写，项目登记的不用说法不拦它。
            copied = output / "yaya/methodology/05-document-language.md"
            copied.write_text(copied.read_text(encoding="utf-8") + "\n收集水晶。\n",
                              encoding="utf-8", newline="\n")
            accepted = commit()
            self.assertEqual(accepted.returncode, 0, accepted.stdout + accepted.stderr)
        count = subprocess.check_output(["git", "rev-list", "--count", "HEAD"], cwd=output, text=True).strip()
        self.assertEqual(count, "2")

    def test_real_creation_hook_rejects_editor_connection_and_lists_relaxed_checks(self):
        repository = Path(__file__).resolve().parents[3]
        output = self.base / "rule-checks"
        path = os.pathsep.join((str(Path(sys.executable).parent), os.environ.get("PATH", "")))
        with patch.dict(os.environ, {**GIT_ENVIRONMENT, "PATH": path}):
            create_project(repository, output)

            def commit():
                subprocess.run(["git", "add", "-A"], cwd=output, check=True)
                return subprocess.run(["git", "commit", "-m", "feat: 加棋盘"], cwd=output,
                                      capture_output=True, encoding="utf-8", check=False)

            scene = output / "game/board/board.tscn"
            scene.parent.mkdir(parents=True)
            scene.write_text('[gd_scene format=3 uid="uid://board"]\n\n[node name="Root" type="Node"]\n\n'
                             '[connection signal="ready" from="." to="." method="_on_ready"]\n',
                             encoding="utf-8", newline="\n")
            rejected = commit()
            self.assertNotEqual(rejected.returncode, 0, rejected.stdout)
            # Git 把钩子的标准输出也转到标准错误。
            self.assertIn("game/board/board.tscn:5: adds an editor signal connection", rejected.stderr)
            self.assertIn("增量检查", rejected.stderr)

            scene.write_text('[gd_scene format=3 uid="uid://board"]\n\n[node name="Root" type="Node"]\n',
                             encoding="utf-8", newline="\n")
            button = output / "game/shared/ui/game_button.gd"
            button.write_text('@warning_ignore("unused_variable")\n' + button.read_text(encoding="utf-8"),
                              encoding="utf-8", newline="\n")
            accepted = commit()
            self.assertEqual(accepted.returncode, 0, accepted.stdout + accepted.stderr)
            self.assertIn('- game/shared/ui/game_button.gd:1: adds `@warning_ignore("unused_variable")`', accepted.stderr)

    def test_real_creation_hook_rejects_skill_change_until_both_copies_match(self):
        repository = Path(__file__).resolve().parents[3]
        output = self.base / "skill-copies"
        path = os.pathsep.join((str(Path(sys.executable).parent), os.environ.get("PATH", "")))
        with patch.dict(os.environ, {**GIT_ENVIRONMENT, "PATH": path}):
            create_project(repository, output)

            def commit():
                subprocess.run(["git", "add", "-A"], cwd=output, check=True)
                return subprocess.run(["git", "commit", "-m", "chore: 调整 Skill 配置"], cwd=output,
                                      capture_output=True, encoding="utf-8", check=False)

            relative = "bug-diagnosis/agents/openai.yaml"
            codex_copy = output / ".agents/skills" / relative
            codex_copy.write_bytes(codex_copy.read_bytes() + b"\n# local note\n")
            rejected = commit()
            self.assertNotEqual(rejected.returncode, 0, rejected.stdout)
            self.assertIn("Skill 目录一致性检查", rejected.stderr)

            (output / ".claude/skills" / relative).write_bytes(codex_copy.read_bytes())
            accepted = commit()
            self.assertEqual(accepted.returncode, 0, accepted.stdout + accepted.stderr)

    def test_real_agent_mappings_preserve_roles_without_global_config(self):
        repository = Path(__file__).resolve().parents[3]
        manifest = json.loads((repository / "framework/project-creation/project-files.json").read_text(encoding="utf-8"))
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

    def test_codex_and_claude_roles_share_name_description_and_instructions(self):
        repository = Path(__file__).resolve().parents[3]
        manifest = json.loads((repository / "framework/project-creation/project-files.json").read_text(encoding="utf-8"))
        targets = {item["source"]: item["target"] for item in manifest}
        roles = sorted((repository / "project-source/agents").glob("*.toml"))
        self.assertTrue(roles)
        for toml_path in roles:
            with self.subTest(role=toml_path.stem):
                codex = tomllib.loads(toml_path.read_text(encoding="utf-8"))
                claude_path = toml_path.with_suffix(".md")
                frontmatter, body = re.fullmatch(r"---\n(.*?)\n---\n\n(.*)",
                                                 claude_path.read_text(encoding="utf-8"), re.S).groups()
                fields = dict(re.findall(r"^(name|description): (.*)$", frontmatter, re.M))
                self.assertEqual(fields["name"], codex["name"])
                self.assertEqual(json.loads(fields["description"]), codex["description"])
                self.assertEqual(body.strip(), codex["developer_instructions"].strip())
                self.assertEqual(targets[f"project-source/agents/{toml_path.name}"], f".codex/agents/{toml_path.name}")
                self.assertEqual(targets[f"project-source/agents/{claude_path.name}"], f".claude/agents/{claude_path.name}")

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

    def assert_link_rejected_without_writing(self):
        for existing in (False, True):
            output = self.base / ("empty-project" if existing else "absent-project")
            if existing:
                output.mkdir()
            with self.subTest(existing=existing), self.assertRaisesRegex(ValueError, "source link"):
                copy_project(self.source, output)
            if existing:
                self.assertEqual(list(output.iterdir()), [])
            else:
                self.assertFalse(output.exists())

    @unittest.skipUnless(os.name == "nt", "Windows junction contract")
    def test_junction_and_mapping_through_junction_are_rejected(self):
        outside = self.base / "outside"
        outside.mkdir()
        (outside / "private.txt").write_text("not distribution material", encoding="utf-8")
        link = self.source / "project-source/skills/example/linked"
        result = subprocess.run(
            ["pwsh", "-NoProfile", "-Command",
             "New-Item -ItemType Junction -Path $env:YAYA_COPY_LINK "
             "-Target $env:YAYA_COPY_TARGET -ErrorAction Stop | Out-Null"],
            env={**os.environ, "YAYA_COPY_LINK": str(link), "YAYA_COPY_TARGET": str(outside)},
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(link.is_junction())
        try:
            self.assert_link_rejected_without_writing()
            (self.base / "empty-project").rmdir()
            self.entries = [{"source": "project-source/skills/example/linked/private.txt",
                             "target": "private.txt"}]
            self.save_manifest()
            with self.assertRaisesRegex(ValueError, "source link|leaves its root"):
                copy_project(self.source, self.base / "mapped-project")
            self.assertFalse((self.base / "mapped-project").exists())
        finally:
            link.rmdir()
        self.assertEqual((outside / "private.txt").read_text(encoding="utf-8"),
                         "not distribution material")

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
        self.assertEqual(set(config), {"document_language", "engine_executable", "python_executable",
                                       "audio_analyzer_python_executable",
                                       "audio_production_dir", "image_production_dir", "model_production_dir",
                                       "java_executable", "tla_tools_jar"})
        self.assertIsInstance(config["engine_executable"], str)
        settings = (output / "project.godot").read_text(encoding="utf-8")
        self.assertIn('run/main_scene="res://main/main.tscn"', settings)
        self.assertIn("window/size/viewport_width=1600", settings)
        self.assertIn("window/size/viewport_height=900", settings)
        self.assertEqual((output / ".githooks/pre-commit").read_bytes(),
                         (repository / "project-source/defaults/.githooks/pre-commit").read_bytes())
        self.assertEqual((output / ".githooks/commit-msg").read_bytes(),
                         (repository / "project-source/defaults/.githooks/commit-msg").read_bytes())
        self.assertEqual((output / ".claude/settings.json").read_bytes(),
                         (repository / "project-source/defaults/.claude/settings.json").read_bytes())
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
        codex_skills, claude_skills = output / ".agents/skills", output / ".claude/skills"
        self.assertEqual({path.relative_to(claude_skills).as_posix(): path.read_bytes()
                          for path in claude_skills.rglob("*") if path.is_file()},
                         {path.relative_to(codex_skills).as_posix(): path.read_bytes()
                          for path in codex_skills.rglob("*") if path.is_file()})
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
        self.assertFalse((output / "yaya/agent-rules/00-core/documentation").exists())
        self.assertEqual({path.name for path in (output / "yaya/tools").iterdir() if path.is_dir()},
                         {"checks", "features", "godot", "testing", "lib", "ui-trial"})
        self.assertFalse((output / "examples").exists())
        for removed in ("yaya/asset_workbench", "components/feedback", "addons/sound_manager"):
            self.assertFalse((output / removed).exists(), removed)
        self.assertFalse(any((output / ".agents/skills").glob("*-yaya")))
        self.assertFalse(any(output.rglob("__pycache__")))
        main_scene = output / "main/main.tscn"
        self.assertEqual(main_scene.read_bytes(),
                         (repository / "project-source/defaults/main/main.tscn").read_bytes())
        self.assertFalse((output / "main/main.gd").exists())
        for relative in ("assets", "components", "tests/features"):
            with self.subTest(directory=relative):
                directory = output / relative
                self.assertEqual({path.name for path in directory.iterdir()}, {".gitkeep"})
        for relative in ("game", "tests/unit"):
            self.assertEqual({path.name for path in (output / relative).iterdir()}, {"shared"})
        self.assertEqual({path.name for path in (output / "tests/invariants").iterdir()},
                         {"debug_dependency_test.gd", "debug_dependency_test.gd.uid"})
        self.assertTrue((output / "dev/debug/debug_main.tscn").is_file())
        self.assertTrue((output / "dev/debug/_shared/README.md").is_file())
        for relative in ("main", "game", "assets", "tests"):
            self.assertFalse(any((output / relative).rglob(".gdignore")), relative)
        self.assertEqual(json.loads((output / "docs/feature-list.json").read_text(encoding="utf-8"))["features"], [])
        registry = json.loads((output / "docs/test-registry.json").read_text(encoding="utf-8"))
        self.assertEqual([component["id"] for component in registry["components"]], ["debug_console", "asset_validation"])
        self.assertEqual([test["id"] for test in registry["tests"]], ["INV-DEBUG_CONSOLE-01"])
        for relative in ("gdd/README.md", "gdd/open-questions.md", "product.md", "product/README.md"):
            self.assertEqual((output / "docs" / relative).read_bytes(),
                             (repository / "project-source/defaults/docs" / relative).read_bytes())
        for name, expected in (("gdd", {"README.md", "open-questions.md"}), ("product", {"README.md"})):
            self.assertEqual({path.name for path in (output / "docs" / name).iterdir()}, expected)
        self.assertTrue(Path(config["audio_analyzer_python_executable"]).is_absolute())

    def test_distribution_resources_have_uids_and_scanned_addon_images_have_imports(self):
        source = Path(__file__).resolve().parents[3] / "project-source"
        uids = set()
        for path in sorted(source.rglob("*")):
            if path.suffix not in {".tscn", ".tres"} or path.relative_to(source).parts[0] == "addons":
                continue
            with self.subTest(resource=path.relative_to(source).as_posix()):
                text = path.read_text(encoding="utf-8")
                self.assertNotRegex(text, r"\bload_steps\s*=")
                lines = text.splitlines()
                uid = re.search(r'\buid="(uid://[a-z0-9]+)"', lines[0])
                self.assertIsNotNone(uid)
                self.assertNotIn(uid[1], uids)
                uids.add(uid[1])
                for line in lines:
                    if line.startswith("[ext_resource "):
                        self.assertRegex(line, r'\buid="uid://[a-z0-9]+"')
        for directory, children, files in os.walk(source / "addons"):
            if ".gdignore" in files:
                children.clear()
                continue
            children[:] = [name for name in children if not name.startswith(".")]
            for name in files:
                path = Path(directory) / name
                if path.suffix.lower() in {".png", ".svg", ".jpg", ".jpeg", ".webp", ".bmp",
                                           ".tga", ".hdr", ".exr", ".dds", ".ktx"}:
                    with self.subTest(image=path.relative_to(source).as_posix()):
                        self.assertTrue(path.with_name(path.name + ".import").is_file())


if __name__ == "__main__":
    unittest.main()
