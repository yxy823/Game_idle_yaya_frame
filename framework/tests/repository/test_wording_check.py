"""Check the distributed wording checker through its public CLI."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


COMMAND = Path(__file__).resolve().parents[3] / "project-source/tools/checks/check-wording.py"
WORDS_FILE = ".agents/skills/technical-documentation-writing-godot/references/writing-guide.md"

WORDS = (
    "# 写作指南\n"
    "\n"
    "## 措辞检查词表\n"
    "\n"
    "| 词 | 级别 | 适用范围 | 推荐写法 |\n"
    "| --- | --- | --- | --- |\n"
    "| 应 | 硬性 | 规则文件 | 改用“必须”或“默认” |\n"
    "| 宜 | 硬性 | 规则文件 | 改用“必须”或“默认” |\n"
    "| 进行 | 待复核 | 全部文档 | 直接写动作 |\n"
)


class WordingCheckTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="wording_check_")
        self.addCleanup(self.area.cleanup)
        self.root = Path(self.area.name)
        self.write(WORDS_FILE, WORDS)

    def write(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def run_cli(self, *args, stdin=None):
        return subprocess.run(
            [sys.executable, "-B", str(COMMAND), "--root", str(self.root), *args],
            capture_output=True, encoding="utf-8", check=False, timeout=30, input=stdin,
        )

    def hard_rows(self, process):
        return [line for line in process.stdout.splitlines() if ": [WORDING-HARD]" in line]

    def test_hard_word_in_rule_file_exits_1_and_compounds_are_not_reported(self):
        self.write("AGENTS.md", "# 规则\n\n提交前应运行检查。\n应用设置后对应的面板、相应的按钮和适宜的颜色不变。\n不宜跳过。\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 1, process.stderr)
        rows = self.hard_rows(process)
        self.assertEqual(len(rows), 2, process.stdout)
        self.assertTrue(rows[0].startswith("AGENTS.md:3:4: [WORDING-HARD] 「应」"), rows[0])
        self.assertIn(f"{WORDS_FILE}:7", rows[0])
        self.assertTrue(rows[0].endswith("| 提交前应运行检查。"), rows[0])
        self.assertTrue(rows[1].startswith("AGENTS.md:5:2: [WORDING-HARD] 「宜」"), rows[1])

    def test_hard_word_outside_rule_files_is_not_reported(self):
        self.write("docs/guide.md", "这里应运行检查。\n")
        for rule_file in ("yaya/agent-rules/00-core/rule.md", "yaya/methodology/03.md", "docs/project-rules.md",
                          ".agents/skills/demo/SKILL.md", ".agents/skills/demo/references/a.md"):
            self.write(rule_file, "这里应运行检查。\n")
        process = self.run_cli("--level", "hard")
        self.assertEqual(process.returncode, 1, process.stderr)
        reported = {row.split(":", 1)[0] for row in self.hard_rows(process)}
        self.assertNotIn("docs/guide.md", reported)
        self.assertEqual(len(reported), 5, process.stdout)

    def test_words_to_review_are_listed_without_failing(self):
        self.write("docs/guide.md", "对日志进行压缩。\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertIn("docs/guide.md:1:4: [WORDING-REVIEW] 「进行」", process.stdout)
        hard_only = self.run_cli("--level", "hard")
        self.assertEqual(hard_only.returncode, 0, hard_only.stderr)
        self.assertNotIn("[WORDING-REVIEW] 「", hard_only.stdout)

    def test_code_quotes_link_targets_and_the_table_rows_are_skipped(self):
        self.write("AGENTS.md",
                   "不写 `应`，也不写「应」、“宜”或 \"应\"，见[说明](docs/应.md)。\n"
                   "```\n应\n```\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertNotIn("[WORDING-HARD] 「", process.stdout)

    def test_json_string_values_of_prompt_libraries_are_checked_and_keys_are_not(self):
        self.write("prompts/library.json",
                   '{\n  "应该": {\n    "说明": "第一行\\n先应确认目标，不写「应」。"\n  }\n}\n')
        process = self.run_cli("--include", "*.json", "--json")
        self.assertEqual(process.returncode, 1, process.stderr)
        result = json.loads(process.stdout)
        hard = [row for row in result["findings"] if row["rule"] == "WORDING-HARD"]
        self.assertEqual(len(hard), 1, process.stdout)
        self.assertEqual((hard[0]["path"], hard[0]["line"], hard[0]["column"]), ("prompts/library.json", 3, 6))
        self.assertEqual(result["summary"]["hard"], 1)

    def test_listed_files_and_files_from_check_only_those_files(self):
        self.write("AGENTS.md", "提交前应运行检查。\n")
        self.write("docs/AGENTS.md", "提交前应运行检查。\n")
        listed = self.run_cli("AGENTS.md")
        self.assertEqual([row.split(":", 1)[0] for row in self.hard_rows(listed)], ["AGENTS.md"])
        from_stdin = self.run_cli("--files-from", "-", stdin="docs/AGENTS.md\n")
        self.assertEqual([row.split(":", 1)[0] for row in self.hard_rows(from_stdin)], ["docs/AGENTS.md"])
        empty = self.run_cli("--files-from", "-", stdin="")
        self.assertEqual(empty.returncode, 0, empty.stdout)

    def test_missing_table_or_unknown_level_exits_2(self):
        self.write(WORDS_FILE, "# 写作指南\n\n没有词表。\n")
        self.assertEqual(self.run_cli().returncode, 2)
        self.write(WORDS_FILE, WORDS.replace("| 进行 | 待复核 |", "| 进行 | 建议 |"))
        process = self.run_cli()
        self.assertEqual(process.returncode, 2, process.stdout)
        self.assertIn(f"{WORDS_FILE}:9:", process.stderr)


if __name__ == "__main__":
    unittest.main()
