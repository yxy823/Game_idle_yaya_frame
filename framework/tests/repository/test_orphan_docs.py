"""Check orphan candidates through the public CLI, including ambiguous file names."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


COMMAND = Path(__file__).resolve().parents[3] / "framework/maintenance/tools/find_orphan_docs.py"


class OrphanDocsTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="orphan_docs_")
        self.addCleanup(self.area.cleanup)
        self.root = Path(self.area.name)

    def write(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def run_cli(self, *args):
        return subprocess.run(
            [sys.executable, "-B", str(COMMAND), "--root", str(self.root), "--json", *args],
            capture_output=True, encoding="utf-8", check=False, timeout=30,
        )

    def results(self, *args):
        process = self.run_cli(*args)
        self.assertEqual(process.returncode, 0, process.stderr)
        return {row["target"]: row for row in json.loads(process.stdout)["results"]}

    def test_spaced_and_encoded_links_resolve_without_unique_basename_fallback(self):
        self.write("docs/with space/Guide notes.md", "# Notes")
        self.write("other/Guide notes.md", "# Other")
        self.write("docs/with space/workflow.md",
                   "Read [notes](<Guide notes.md#notes>).\n"
                   "Read [notes](Guide%20notes.md#notes).\n")
        rows = self.results()
        target = rows["docs/with space/Guide notes.md"]
        self.assertEqual(target["verdict"], "READ")
        self.assertEqual([(ref["line"], ref["kind"]) for ref in target["refs"]],
                         [(1, "link"), (2, "link")])
        self.assertEqual(rows["other/Guide notes.md"]["verdict"], "NONE")

    def test_navigation_history_self_and_excluded_generated_references(self):
        for name in ("used", "navigation", "historical", "alone"):
            self.write(f"docs/{name}.md", "# Document")
        self.write("docs/alone.md", "[Self](alone.md)")
        self.write("README.md", "docs/navigation.md\ndocs/historical.md")
        self.write("reports/old.md", "docs/historical.md")
        self.write("workflow.py", "# Read docs/used.md")
        self.write(".cache/output.py", "# Read docs/alone.md")
        self.write("generated.html", "docs/alone.md")
        rows = self.results()
        self.assertEqual({name: rows[f"docs/{name}.md"]["verdict"]
                          for name in ("used", "navigation", "historical", "alone")},
                         {"used": "READ", "navigation": "NAV_ONLY",
                          "historical": "HISTORY_ONLY", "alone": "NONE"})

    def test_claude_files_are_neither_targets_nor_reference_sources(self):
        self.write("docs/current.md", "# Current")
        self.write(".claude/worktrees/old/docs/obsolete.md", "Read docs/current.md")
        self.write(".claude/notes.md", "Read docs/current.md")
        rows = self.results()
        self.assertEqual(set(rows), {"docs/current.md"})
        self.assertEqual(rows["docs/current.md"]["verdict"], "NONE")
        self.assertEqual(rows["docs/current.md"]["refs"], [])

    def test_bare_file_names_only_count_when_unique(self):
        self.write("first/shared.md", "# First")
        self.write("second/shared.md", "# Second")
        self.write("docs/unique.md", "# Unique")
        self.write("workflow.py", "# Read shared.md and UNIQUE.md")
        rows = self.results()
        self.assertEqual(rows["first/shared.md"]["verdict"], "NONE")
        self.assertEqual(rows["second/shared.md"]["verdict"], "NONE")
        self.assertEqual(rows["docs/unique.md"]["refs"][0]["kind"], "name")

    def test_default_targets_skip_navigation_but_keep_its_references(self):
        navigation = ("README.md", "docs/readme.MD", "docs/index.md",
                      "docs/scenario-index.md")
        self.write("docs/guide.md", "# Guide")
        for path in navigation:
            self.write(path, "Read docs/guide.md")
        rows = self.results()
        self.assertEqual(set(rows), {"docs/guide.md"})
        self.assertEqual(rows["docs/guide.md"]["verdict"], "NAV_ONLY")
        self.assertEqual({ref["file"] for ref in rows["docs/guide.md"]["refs"]},
                         set(navigation))
        self.assertEqual(set(self.results("--targets", "README.md")),
                         {"README.md", "docs/readme.MD"})
        self.assertIn("docs/guide.md", self.results("--nav", "guide.md", "--targets", "docs/guide.md"))

    def test_accepted_paths_skip_targets_without_hiding_their_outgoing_references(self):
        accepted = (
            "project-source/agent-rules/10-gdscript/accepted-rule.md",
            "framework/prompt-scenarios/scenarios/Example/Category/Accepted scenario.md",
            "project-source/addons/sound_manager/UPSTREAM.md",
            "project-source/asset_workbench/examples/effects_composition/example_brackeys_license.md",
            "project-source/addons/resources_spreadsheet_view/LICENSE.md",
        )
        self.write("docs/used.md", "# Used")
        self.write("docs/navigation.md", "# Still needs review")
        self.write("README.md", "[Navigation](docs/navigation.md)")
        for path in accepted:
            self.write(path, "Read docs/used.md")
        rows = self.results()
        self.assertEqual(set(rows), {"docs/used.md", "docs/navigation.md"})
        self.assertEqual(rows["docs/used.md"]["verdict"], "READ")
        self.assertEqual({ref["file"] for ref in rows["docs/used.md"]["refs"]}, set(accepted))
        self.assertEqual(rows["docs/navigation.md"]["verdict"], "NAV_ONLY")
        self.assertEqual(set(self.results("--targets", *accepted)), set(accepted))
        data = json.loads(self.run_cli("--targets", *accepted).stdout)
        self.assertEqual(data["target_exclusions"], [])
        data = json.loads(self.run_cli().stdout)
        self.assertIn("project-source/agent-rules/*", data["target_exclusions"])
        rows = self.results("--targets", *accepted, "--exclude", "project-source/agent-rules/*")
        self.assertNotIn(accepted[0], rows)

    def test_optional_report_and_failure_exit_preserve_scanned_files(self):
        self.write("docs/unreferenced.md", "# Unreferenced")
        self.write("docs/navigation.md", "# Navigation")
        self.write("README.md", "[Navigation](docs/navigation.md)")
        before = {p: p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        report = self.root / "result.json"
        process = self.run_cli("--targets", "docs/*.md", "--out", str(report),
                               "--fail-on-orphan")
        self.assertEqual(process.returncode, 1, process.stderr)
        data = json.loads(report.read_text(encoding="utf-8"))
        self.assertEqual(data["summary"]["NONE"], 1)
        self.assertEqual(data["root"], self.root.as_posix())
        self.assertEqual({p: p.read_bytes() for p in before}, before)
        self.assertEqual({p for p in self.root.rglob("*") if p.is_file()}, set(before) | {report})
        process = self.run_cli("--targets", "docs/navigation.md", "--search-in", "README.md",
                               "--fail-on-orphan")
        self.assertEqual(process.returncode, 0, process.stderr)
        self.assertEqual(json.loads(process.stdout)["summary"]["NAV_ONLY"], 1)


if __name__ == "__main__":
    unittest.main()
