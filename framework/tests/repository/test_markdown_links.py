import json
import importlib.util
import io
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from contextlib import redirect_stderr, redirect_stdout
from unittest import mock


COMMAND = Path(__file__).resolve().parents[3] / "project-source/tools/checks/check-markdown-links.py"


class MarkdownLinkTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="markdown_links_")
        self.addCleanup(self.area.cleanup)
        self.root = Path(self.area.name)

    def write(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def run_cli(self, *args):
        process = subprocess.run(
            [sys.executable, "-B", str(COMMAND), "--root", str(self.root), "--json", *args],
            capture_output=True, encoding="utf-8", check=False, timeout=30,
        )
        self.assertIn(process.returncode, (0, 1), process.stderr)
        return process.returncode, json.loads(process.stdout)

    def broken(self, *args):
        return {(row["file"], row["target"], row["reason"]) for row in self.run_cli(*args)[1]["broken"]}

    def test_github_style_anchors_resolve_for_chinese_code_and_duplicate_headings(self):
        self.write("docs/guide.md",
                   "# 标题：Git 与提交\n## Stage 7 `record` 说明\n## 重复\n## 重复\n<a id=\"custom\"></a>\n")
        self.write("docs/with space/notes.md", "# Notes\n")
        self.write("index.md",
                   "[a](docs/guide.md#标题git-与提交) [b](docs/guide.md#stage-7-record-说明)\n"
                   "[c](docs/guide.md#重复-1) [d](docs/guide.md#custom) [e](#local)\n"
                   "[f](<docs/with space/notes.md#notes>) [g](docs/with%20space/) [h](https://example.com)\n"
                   "## Local\n")
        code, result = self.run_cli()
        self.assertEqual(code, 0, result["broken"])
        self.assertEqual(result["links"], 7)

    def test_angle_brackets_inside_inline_code_stay_in_the_anchor(self):
        self.write("docs/spec.md", "## `product/NN-<delivery>.md` 标准章节\n## 说明 <span>附注</span>\n")
        self.write("index.md", "[a](docs/spec.md#productnn-deliverymd-标准章节) [b](docs/spec.md#说明-附注)\n")
        code, result = self.run_cli()
        self.assertEqual(code, 0, result["broken"])
        self.write("index.md", "[a](docs/spec.md#productnn-md-标准章节)\n")
        self.assertEqual(self.broken(), {("index.md", "docs/spec.md#productnn-md-标准章节", "anchor not found in target")})

    def test_missing_targets_anchors_and_reference_definitions_are_reported(self):
        self.write("docs/guide.md", "# Guide\n")
        self.write("index.md",
                   "[a](docs/missing.md) [b](docs/guide.md#absent) [c](/docs/guide.md)\n"
                   "[ref]: docs/gone.md\n")
        self.assertEqual(self.broken(), {
            ("index.md", "docs/missing.md", "target does not exist"),
            ("index.md", "docs/guide.md#absent", "anchor not found in target"),
            ("index.md", "/docs/guide.md", "root-relative path is not portable"),
            ("index.md", "docs/gone.md", "target does not exist"),
        })

    def test_code_and_excluded_directories_are_not_scanned(self):
        self.write("index.md", "`[a](missing.md)`\n```\n[b](missing.md)\n```\n")
        self.write("addons/plugin/README.md", "[c](missing.md)\n")
        self.write("tmp/draft.md", "[d](missing.md)\n")
        self.write("reports/gdunit-wrapper/run-1/report.md", "[d](missing.md)\n")
        self.write("notes/old.md", "[e](missing.md)\n")
        self.assertEqual(self.broken("--exclude", "notes"), set())
        self.assertEqual(len(self.broken()), 1)

    def test_listed_files_are_the_only_ones_checked(self):
        self.write("a.md", "[x](missing-a.md)\n")
        self.write("b.md", "[y](missing-b.md)\n")
        self.assertEqual(self.broken(str(self.root / "b.md")),
                         {("b.md", "missing-b.md", "target does not exist")})

    def test_related_to_reports_only_links_in_or_into_listed_paths(self):
        self.write("staged.md", "[a](missing-a.md)\n")
        self.write("other.md", "[b](missing-b.md)\n[c](gone.md)\n")
        process = subprocess.run(
            [sys.executable, "-B", str(COMMAND), "--root", str(self.root), "--json", "--related-to", "-"],
            input="staged.md\ngone.md\n", capture_output=True, encoding="utf-8", check=False, timeout=30,
        )
        self.assertEqual(process.returncode, 1, process.stderr)
        self.assertEqual({(row["file"], row["target"]) for row in json.loads(process.stdout)["broken"]},
                         {("staged.md", "missing-a.md"), ("other.md", "gone.md")})

    def test_listed_file_outside_root_is_an_argument_error(self):
        with tempfile.TemporaryDirectory() as other:
            outside = Path(other) / "c.md"
            outside.write_text("text\n", encoding="utf-8")
            process = subprocess.run(
                [sys.executable, "-B", str(COMMAND), "--root", str(self.root), str(outside)],
                capture_output=True, encoding="utf-8", check=False, timeout=30,
            )
        self.assertEqual(process.returncode, 2, process.stderr)
        self.assertIn("not under --root", process.stderr)

    def test_unreadable_subdirectory_returns_2_and_names_path(self):
        self.write("readable/guide.md", "# Guide\n")
        self.write("locked/guide.md", "# Hidden\n")
        locked = self.root / "locked"
        spec = importlib.util.spec_from_file_location("markdown_links_cli", COMMAND)
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        self.addCleanup(sys.modules.pop, spec.name, None)
        spec.loader.exec_module(module)
        real = os.scandir

        def scandir(path="."):
            if Path(path) == locked:
                raise PermissionError(13, "Access is denied", str(path))
            return real(path)

        errors = io.StringIO()
        with mock.patch.object(os, "scandir", scandir), redirect_stderr(errors), redirect_stdout(io.StringIO()):
            code = module.main(["--root", str(self.root)])
        self.assertEqual(code, 2)
        self.assertIn(repr(str(locked)), errors.getvalue())


if __name__ == "__main__":
    unittest.main()
