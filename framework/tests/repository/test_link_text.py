"""Check the distributed link text checker through its public CLI."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


COMMAND = Path(__file__).resolve().parents[3] / "project-source/tools/checks/check-link-text.py"


class LinkTextTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="link_text_")
        self.addCleanup(self.area.cleanup)
        self.root = Path(self.area.name)

    def write(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def run_cli(self, *args, stdin=None):
        return subprocess.run(
            [sys.executable, "-B", str(COMMAND), "--root", str(self.root), "--json", *args],
            capture_output=True, encoding="utf-8", input=stdin, check=False, timeout=30,
        )

    def findings(self, *args):
        process = self.run_cli(*args)
        self.assertIn(process.returncode, (0, 1), process.stderr)
        result = json.loads(process.stdout)
        self.assertEqual(process.returncode, 1 if result["findings"] else 0)
        return [(row["file"], row["line"], row["text"], row["rule"]) for row in result["findings"]]

    def test_text_must_contain_target_heading_or_file_title(self):
        self.write("docs/08-testing.md", "# 08 · 测试与验证\n## 测试影响评估\n")
        self.write("index.md",
                   "[返回](docs/08-testing.md) · [规范](docs/08-testing.md#测试影响评估)\n"
                   "08 号规范的[测试影响评估](docs/08-testing.md#测试影响评估)，"
                   "见[测试与验证](docs/08-testing.md)和[`测试影响评估`](docs/08-testing.md#测试影响评估)。\n"
                   "按[测试规范](docs/08-testing.md#测试影响评估)执行，[本页](#本页说明)另述。\n"
                   "## 本页说明\n")
        self.assertEqual(self.findings(), [("index.md", 3, "测试规范", "LINK-TEXT"), ("index.md", 3, "本页", "LINK-TEXT")])

    def test_target_skill_file_and_directory_names_are_accepted_without_anchor(self):
        self.write("skills/task-handoff/SKILL.md", "# 准备任务交接\n## 输出\n")
        self.write("research/README.md", "# 外部调研目录\n")
        self.write("docs/02-schema.md", "# 02 · 数据结构\n")
        self.write("index.md",
                   "用 [task-handoff](skills/task-handoff/SKILL.md)、[`$task-handoff`](skills/task-handoff/SKILL.md)、"
                   "[research/](research/README.md)、[02-schema.md](docs/02-schema.md)、[02-schema](docs/02-schema.md)、"
                   "[docs/02-schema.md](docs/02-schema.md)。\n"
                   "见 [task-handoff](skills/task-handoff/SKILL.md#输出)、[handoff](skills/task-handoff/SKILL.md)、"
                   "[schema.md](docs/02-schema.md)。\n")
        self.assertEqual(self.findings(), [
            ("index.md", 2, "task-handoff", "LINK-TEXT"),
            ("index.md", 2, "handoff", "LINK-TEXT"),
            ("index.md", 2, "schema.md", "LINK-TEXT"),
        ])

    def test_listed_files_limit_the_scan_and_missing_files_fail(self):
        self.write("docs/guide.md", "# 指南\n")
        self.write("a.md", "见[说明](docs/guide.md)。\n")
        self.write("b.md", "见[说明](docs/guide.md)。\n")
        self.write("notes.json", "\"见[说明](docs/guide.md)。\"\n")
        self.assertEqual(self.findings("a.md", "notes.json"), [("a.md", 1, "说明", "LINK-TEXT")])
        process = self.run_cli("--files-from", "-", stdin="b.md\n")
        self.assertEqual([row["file"] for row in json.loads(process.stdout)["findings"]], ["b.md"])
        process = self.run_cli("--files-from", "-", stdin="")
        self.assertEqual((process.returncode, json.loads(process.stdout)["files"]), (0, 0))
        self.assertEqual(self.run_cli("missing.md").returncode, 2)


if __name__ == "__main__":
    unittest.main()
