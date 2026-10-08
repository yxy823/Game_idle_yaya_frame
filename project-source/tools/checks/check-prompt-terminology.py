#!/usr/bin/env python3
"""Claude Code UserPromptSubmit hook: point out forbidden wordings from the terms file in the user's message."""
# 只提示，不拦截也不记录：无论命中与否、出什么错，都以退出码 0 结束；退出码 2 会拦下用户消息。
# 命中时 stdout 的文字由 Claude Code 作为附加上下文交给 Agent；没有命中或出错时不输出。
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

CHECKER = Path(__file__).resolve().with_name("check-terminology.py")


def hint(prompt: str, root: Path, terms: str) -> str:
    process = subprocess.run(
        [sys.executable, "-B", str(CHECKER), "--root", str(root), "--terms", terms, "--stdin-text", "--json"],
        input=prompt.encode("utf-8"), capture_output=True, timeout=20, check=False,
        env={**os.environ, "PYTHONUTF8": "1"},
    )
    if process.returncode != 1:
        return ""
    findings = json.loads(process.stdout.decode("utf-8"))["findings"]
    items = [f"{row['found']} → {row['suggestion']}（第 {row['line']} 行，定义见 {row['definition']}）"
             for row in findings if row["rule"] == "TERM-FORBIDDEN"]
    if not items:
        return ""
    return f"用户消息中有已登记的不用说法：{'；'.join(items)}。按用词对照规则，在回复最前面列出对照表。\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--terms", default="docs/terminology.md",
                        help="terms file, relative to the project directory unless absolute (default: docs/terminology.md)")
    try:
        args = parser.parse_args()
        root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or Path.cwd())
        prompt = json.loads(sys.stdin.buffer.read().decode("utf-8"))["prompt"]
        text = hint(prompt, root, args.terms)
        if text:
            sys.stdout.buffer.write(text.encode("utf-8"))
    except BaseException:  # noqa: BLE001 - 钩子出任何错都不能影响用户发消息
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
