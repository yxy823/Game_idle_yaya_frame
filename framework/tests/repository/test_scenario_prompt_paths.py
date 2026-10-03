"""Path correspondence must not silently accept renamed or unread scenario pages."""
import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

from framework.commands.prompts.check_scenario_prompt_paths import compare_paths, expected_paths, main


class ScenarioPromptPathTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="scenario_paths_")
        self.addCleanup(self.area.cleanup)
        self.root = Path(self.area.name)
        self.prompts = self.root / "godot-development-prompts.json"
        self.scenarios = self.root / "scenarios"
        self.scenarios.mkdir()
        self.data = [{"project": "Godot 项目开发", "categories": {
            "修复与改进": {"Feature 交付前发现 Bug": "在当前任务内处理缺陷。"}}}]
        self.save()

    def save(self):
        self.prompts.write_text(json.dumps(self.data, ensure_ascii=False), encoding="utf-8")

    def page(self, relative, contents=b"\xff"):
        path = self.scenarios / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(contents)

    def test_exact_paths_need_no_readable_body_or_metadata(self):
        self.page("Godot 项目开发/修复与改进/Feature 交付前发现 Bug.md")
        self.page("README.md")
        self.page("scenario-index.md")
        self.assertEqual(compare_paths([self.prompts], self.scenarios), {
            "expected": 1, "matched": 1, "missing": [], "unexpected": []})

    def test_wrong_category_and_legacy_paths_are_reported(self):
        self.page("Godot 项目开发/其他分类/Feature 交付前发现 Bug.md")
        self.page("issues/current-feature/bug-after-tests.md")
        report = compare_paths([self.prompts], self.scenarios)
        self.assertEqual(report["matched"], 0)
        self.assertEqual(report["missing"], ["Godot 项目开发/修复与改进/Feature 交付前发现 Bug.md"])
        self.assertEqual(len(report["unexpected"]), 2)

    def test_only_root_navigation_is_excluded(self):
        self.page("Godot 项目开发/README.md")
        self.page("unlisted.md")
        self.assertEqual(compare_paths([self.prompts], self.scenarios)["unexpected"],
                         ["Godot 项目开发/README.md", "unlisted.md"])

    def test_duplicate_json_keys_are_rejected_before_overwrite(self):
        self.prompts.write_text('[{"project":"A","project":"B","categories":{}}]', encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Duplicate JSON key"):
            compare_paths([self.prompts], self.scenarios)

    def test_separate_catalogs_are_checked_together(self):
        maintenance = self.root / "yaya-maintenance-prompts.json"
        maintenance.write_text(json.dumps([{"project": "Yaya 框架维护", "categories": {
            "维护与复盘": {"修复框架": "修复已确认的问题。"}}}], ensure_ascii=False), encoding="utf-8")
        self.page("Godot 项目开发/修复与改进/Feature 交付前发现 Bug.md")
        self.page("Yaya 框架维护/维护与复盘/修复框架.md")
        report = compare_paths([maintenance, self.prompts], self.scenarios)
        self.assertEqual(report, {"expected": 2, "matched": 2, "missing": [], "unexpected": []})
        args = ["--prompts", str(maintenance), str(self.prompts), "--scenarios", str(self.scenarios)]
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main(args), 0)

    def test_duplicate_project_across_files_is_rejected(self):
        duplicate = self.root / "duplicate.json"
        duplicate.write_bytes(self.prompts.read_bytes())
        with self.assertRaisesRegex(ValueError, "Duplicate name in Projects"):
            compare_paths([self.prompts, duplicate], self.scenarios)

    def test_each_file_must_contain_one_project(self):
        for data in ([], {}, self.data * 2):
            with self.subTest(data=data):
                self.prompts.write_text(json.dumps(data), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "exactly one Project"):
                    compare_paths([self.prompts], self.scenarios)

    def test_missing_second_catalog_is_an_input_error(self):
        args = ["--prompts", str(self.prompts), str(self.root / "missing.json"),
                "--scenarios", str(self.scenarios)]
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(main(args), 2)

    def test_same_project_titles_cannot_be_hidden_in_different_categories(self):
        self.data[0]["categories"] = {"first": {"Bug": "one"}, "second": {"bug": "two"}}
        with self.assertRaisesRegex(ValueError, "Duplicate name"):
            expected_paths(self.data)

    def test_invalid_windows_names_fail_without_renaming(self):
        for name in ["../outside", "bad/name", "name.", "CON", "NUL.txt", " trailing "]:
            with self.subTest(name=name):
                self.data[0]["categories"] = {"修复": {name: "text"}}
                with self.assertRaises(ValueError):
                    expected_paths(self.data)

    def test_nested_categories_are_not_silently_flattened(self):
        self.data[0]["categories"] = {"修复": {"状态": {"标题": "正文"}}}
        with self.assertRaisesRegex(ValueError, "Expected prompt text"):
            expected_paths(self.data)

    def test_exit_status_distinguishes_mismatch_from_invalid_input(self):
        args = ["--prompts", str(self.prompts), "--scenarios", str(self.scenarios)]
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main(args), 1)
            self.page("Godot 项目开发/修复与改进/Feature 交付前发现 Bug.md")
            self.assertEqual(main(args), 0)
        self.prompts.write_text("{", encoding="utf-8")
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(main(args), 2)


if __name__ == "__main__":
    unittest.main()
