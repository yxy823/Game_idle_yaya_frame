"""Check the distributed terminology checker through its public CLI."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


COMMAND = Path(__file__).resolve().parents[3] / "project-source/tools/checks/check-terminology.py"

TERMS = (
    "# 术语\n"
    "\n"
    "| 术语 | 含义与边界 | 不用的说法 |\n"
    "| --- | --- | --- |\n"
    "| 分发源 / `project-source/` | 复制到新项目的源材料 | 分发材料、分发包 |\n"
    "| 复制清单 | 决定复制什么 |  |\n"
    "| Feature | 一项功能 |  |\n"
)


class TerminologyCheckTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="terminology_check_")
        self.addCleanup(self.area.cleanup)
        self.root = Path(self.area.name)
        self.write("docs/terminology.md", TERMS)

    def write(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def run_cli(self, *args):
        return subprocess.run(
            [sys.executable, "-B", str(COMMAND), "--root", str(self.root), *args],
            capture_output=True, encoding="utf-8", check=False, timeout=30,
        )

    def test_forbidden_wording_is_reported_with_position_and_exit_code_1(self):
        self.write("guide.md", "# 指南\n\n修改分发材料时同步说明。\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 1, process.stderr)
        first = process.stdout.splitlines()[0]
        self.assertTrue(first.startswith("guide.md:3:3: [TERM-FORBIDDEN] "), first)
        self.assertIn("「分发材料」", first)
        self.assertIn("「分发源」", first)
        self.assertIn("docs/terminology.md:5", first)
        self.assertTrue(first.endswith("| 修改分发材料时同步说明。"), first)

    def test_code_quotes_and_the_definition_row_are_not_reported(self):
        self.write("guide.md",
                   "不要写 `分发材料`，也不写「分发包」、“分发材料”或 \"分发包\"。\n"
                   "```\n分发材料\n```\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 0, process.stdout)
        self.assertNotIn(": [TERM-FORBIDDEN]", process.stdout)

    def test_clean_documents_exit_0(self):
        self.write("guide.md", "修改分发源时同步复制清单。\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)

    def test_discover_lists_same_prefix_variants_without_failing(self):
        self.write("guide.md",
                   "分发配置在这里。\n另见分发配置。\n分发源包和分发源包。\n复制映射只出现一次。\n"
                   "两个 features 与 features，feature-execute 与 feature-execute。\n")
        process = self.run_cli("--discover")
        self.assertEqual(process.returncode, 0, process.stderr)
        self.assertIn("分发源 → 分发配置（2）\n", process.stdout)
        self.assertIn("guide.md:2:3: [TERM-CANDIDATE] ", process.stdout)
        self.assertIn("Feature → features（2）\n", process.stdout)
        for absent in ("「分发源包」", "「复制映射」", "「feature-execute」"):
            self.assertNotIn(absent, process.stdout)
        compounds = self.run_cli("--discover", "--include-compounds")
        self.assertIn("分发源包（2）", compounds.stdout)

    def test_json_output_has_every_field(self):
        self.write("guide.md", "分发包和分发配置。\n分发配置。\n")
        process = self.run_cli("--json", "--discover")
        self.assertEqual(process.returncode, 1, process.stderr)
        result = json.loads(process.stdout)
        fields = {"path", "line", "column", "rule", "term", "found", "suggestion", "definition", "context"}
        self.assertEqual({row["rule"] for row in result["findings"]}, {"TERM-FORBIDDEN", "TERM-CANDIDATE"})
        for row in result["findings"]:
            self.assertLessEqual(fields, row.keys())
        self.assertEqual(result["summary"]["forbidden"], 1)

    def test_json_string_values_are_checked_and_keys_are_not(self):
        self.write("prompts.json",
                   '{\n  "分发材料": {\n    "说明": "第一行\\n修改分发材料时，不写「分发包」。"\n  }\n}\n')
        process = self.run_cli("--include", "*.json")
        self.assertEqual(process.returncode, 1, process.stderr)
        rows = [line for line in process.stdout.splitlines() if ": [TERM-FORBIDDEN]" in line]
        self.assertEqual(len(rows), 1, process.stdout)
        self.assertTrue(rows[0].startswith("prompts.json:3:7: [TERM-FORBIDDEN] "), rows[0])
        self.assertIn("「分发材料」", rows[0])
        self.assertTrue(rows[0].endswith("| 修改分发材料时，不写「分发包」。"), rows[0])

    def test_invalid_json_exits_2(self):
        self.write("prompts.json", '{"说明": "分发材料",}\n')
        process = self.run_cli("--include", "*.json")
        self.assertEqual(process.returncode, 2, process.stdout)
        self.assertIn("prompts.json:1:", process.stderr)

    def test_terms_written_as_headings_exit_2(self):
        self.write("docs/terminology.md", "# 项目术语\n\n用途说明。\n\n## 资源\n\n### 晶石\n\n游戏中唯一的资源。\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 2, process.stdout)
        self.assertIn("docs/terminology.md:5: 术语文件无法解析", process.stderr)

    def test_purpose_text_with_empty_table_header_exits_0(self):
        self.write("docs/terminology.md",
                   "# 项目术语\n\n用途说明。\n\n| 术语 | 含义与边界 | 不用的说法 |\n| --- | --- | --- |\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)


if __name__ == "__main__":
    unittest.main()
