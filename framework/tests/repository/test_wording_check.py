import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


COMMAND = Path(__file__).resolve().parents[3] / "project-source/tools/checks/check-wording.py"
CONFIG = "wording-check.json"

CHECKS = [
    {"name": "应", "level": "hard", "scope": "rule-files",
     "pattern": "(?<![对相])应(?![用])", "suggestion": "改用“必须”或“默认”"},
    {"name": "进行", "level": "review", "scope": "all", "pattern": "进行", "suggestion": "直接写动作"},
]


class WordingCheckTests(unittest.TestCase):
    def setUp(self):
        self.area = tempfile.TemporaryDirectory(prefix="wording_check_")
        self.addCleanup(self.area.cleanup)
        self.root = Path(self.area.name)

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

    def test_temporary_config_drives_the_check(self):
        self.write(CONFIG, json.dumps({"checks": CHECKS}, ensure_ascii=False))
        self.write("AGENTS.md", "# 规则\n\n提交前应运行检查。\n应用设置后对应的面板不变。\n对日志进行压缩。\n")
        process = self.run_cli("--config", CONFIG)
        self.assertEqual(process.returncode, 1, process.stderr)
        rows = self.hard_rows(process)
        self.assertEqual(len(rows), 1, process.stdout)
        self.assertTrue(rows[0].startswith("AGENTS.md:3:4: [WORDING-HARD] 「应」（应）"), rows[0])
        self.assertTrue(rows[0].endswith("| 提交前应运行检查。"), rows[0])
        self.assertIn("AGENTS.md:5:4: [WORDING-REVIEW] 「进行」（进行）待复核：直接写动作", process.stdout)

    def test_default_config_skips_compounds_task_and_recommendation_items(self):
        self.write("AGENTS.md",
                   "应用设置后对应的面板、相应的按钮和适宜的颜色不变。\n"
                   "这项任务必须先完成。\n"
                   "- 建议：先读入口文档。\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertEqual(self.hard_rows(process), [], process.stdout)
        self.assertNotIn("「建议", process.stdout)

    def test_hard_and_review_findings_at_the_same_place_are_both_reported(self):
        self.write("docs/guide.md", "这里尽量写清楚。\n")
        self.write("AGENTS.md", "务必先运行检查，不宜跳过。\n")
        process = self.run_cli("--json")
        self.assertEqual(process.returncode, 1, process.stderr)
        result = json.loads(process.stdout)
        found = {(row["path"], row["found"], row["level"]) for row in result["findings"]}
        self.assertIn(("AGENTS.md", "务必", "hard"), found)
        self.assertIn(("AGENTS.md", "宜", "hard"), found)
        self.assertIn(("docs/guide.md", "尽量", "review"), found)

    def test_review_findings_do_not_change_the_exit_code(self):
        self.write("docs/guide.md", "对日志进行压缩，尽量保留适当的行数。\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertIn("[WORDING-REVIEW] 「尽量」", process.stdout)
        hard_only = self.run_cli("--level", "hard")
        self.assertEqual(hard_only.returncode, 0, hard_only.stderr)
        self.assertNotIn("[WORDING-REVIEW] 「", hard_only.stdout)

    def test_hard_check_applies_only_to_rule_files(self):
        self.write("docs/guide.md", "这里应运行检查。\n")
        self.write("framework/prompt-scenarios/scenarios/demo/page.md", "这里应运行检查。\n")
        rule_files = ("yaya/agent-rules/00-core/rule.md", "yaya/methodology/03.md", "docs/project-rules.md",
                      "project-source/defaults/docs/project-rules.md", ".agents/skills/demo/SKILL.md",
                      ".agents/skills/demo/references/a.md", "framework/prompt-scenarios/scenarios/README.md",
                      "framework/maintenance/design-guidelines/README.md")
        for rule_file in rule_files:
            self.write(rule_file, "这里应运行检查。\n")
        process = self.run_cli("--level", "hard")
        self.assertEqual(process.returncode, 1, process.stderr)
        reported = {row.split(":", 1)[0] for row in self.hard_rows(process)}
        self.assertEqual(reported, set(rule_files), process.stdout)

    def test_code_and_quotes_are_skipped(self):
        self.write("AGENTS.md",
                   "不写 `应`，也不写「应」、“宜”或 \"应\"，见[说明](docs/应.md)。\n"
                   "```\n应\n```\n")
        process = self.run_cli()
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)

    def test_json_string_values_of_prompt_libraries_are_checked_and_keys_are_not(self):
        self.write("prompts/library.json",
                   '{\n  "应该": {\n    "说明": "第一行\\n先应确认目标，不写「应」。"\n  }\n}\n')
        process = self.run_cli("--include", "*.json", "--json", "--level", "hard")
        self.assertEqual(process.returncode, 1, process.stderr)
        result = json.loads(process.stdout)
        hard = result["findings"]
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

    def test_list_prints_every_check_and_verbose_adds_patterns(self):
        self.write(CONFIG, json.dumps({"checks": CHECKS}, ensure_ascii=False))
        process = self.run_cli("--config", CONFIG, "--list")
        self.assertEqual(process.returncode, 0, process.stderr)
        self.assertIn("| 名称 | 级别 | 范围 | 推荐写法 |", process.stdout)
        self.assertIn("| 应 | 硬性 | 规则文件 | 改用“必须”或“默认” |", process.stdout)
        self.assertIn("| 进行 | 待复核 | 全部文档 | 直接写动作 |", process.stdout)
        self.assertNotIn("(?<!", process.stdout)
        verbose = self.run_cli("--config", CONFIG, "--list", "--verbose")
        self.assertIn("`(?<![对相])应(?![用])`", verbose.stdout)

    def test_missing_config_or_invalid_pattern_exits_2(self):
        self.assertEqual(self.run_cli("--config", "missing.json").returncode, 2)
        broken = [dict(CHECKS[0], pattern="应(")]
        self.write(CONFIG, json.dumps({"checks": broken}, ensure_ascii=False))
        process = self.run_cli("--config", CONFIG)
        self.assertEqual(process.returncode, 2, process.stdout)
        self.assertIn("「应」的 pattern 不是合法的正则", process.stderr)

    def test_sentences_over_the_limit_are_listed_for_review(self):
        limits = {"descriptive": 10, "procedural": 5}
        self.write(CONFIG, json.dumps({"sentence_length": limits, "checks": CHECKS}, ensure_ascii=False))
        self.write("SKILL.md", "---\ndescription: 元数据里的长说明不按句子长度检查。\n---\n短句。\n")
        self.write("guide.md", "# 标题超过十个字也不算句子长度\n\n短句。这一句一共有十一个字吧。\n"
                               "1. 运行六个字句\n2. 运行五个字\n| 表格里的长内容不按句子检查 |\n")
        process = self.run_cli("--config", CONFIG)
        self.assertEqual(process.returncode, 0, process.stderr)
        self.assertIn("guide.md:3:4: [WORDING-REVIEW] 「11 字」（句长）待复核：描述句超过 10 字", process.stdout)
        self.assertIn("guide.md:4:4: [WORDING-REVIEW] 「6 字」（句长）待复核：步骤句超过 5 字", process.stdout)
        self.assertEqual(process.stdout.count("（句长）"), 2, process.stdout)
        self.assertNotIn("（句长）", self.run_cli("--config", CONFIG, "--level", "hard").stdout)

    def test_invalid_sentence_length_exits_2(self):
        self.write(CONFIG, json.dumps({"sentence_length": {"descriptive": 0, "procedural": 5}, "checks": CHECKS}))
        self.write("guide.md", "短句。\n")
        process = self.run_cli("--config", CONFIG)
        self.assertEqual(process.returncode, 2)
        self.assertIn("sentence_length 必须正好包含正整数的", process.stderr)


if __name__ == "__main__":
    unittest.main()
