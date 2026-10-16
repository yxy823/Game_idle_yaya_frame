#!/usr/bin/env python3
"""查找孤立文档：统计每个目标文档在哪些文件的哪一行被引用，并按引用方类别分档。

仅标准库、不联网、不执行被检查的代码；不修改扫描对象，仅在指定 --out 时写报告。
Windows 11 / Linux / macOS 均可运行。
脚本只回答“有没有被提到、被谁提到”，不判断那句话是否真的要求读取或写入该文档；
候选文档的实际入口与适用条件仍需人工核对，文本命中也可能误指其他文件。
默认不检查导航文件及已认可的路径，但仍搜索其中的引用；可用 --targets 显式选中这些文件。

引用类别（按优先级归类，一个引用方文件只属于一类）：
  self     目标文档自己
  history  历史材料（默认 reports 目录），提到不代表现行使用
  nav      按文件名规则归类（默认 README.md、index.md、*index.md），也可能承担条件读取路由
  reader   未匹配导航或历史规则的文件；存在引用不证明实际读取

判定档位：
  NONE          未识别到其他文件引用
  NAV_ONLY      仅导航类文件引用
  HISTORY_ONLY  有历史引用、无普通引用（可含导航引用）
  READ          存在普通文件引用

引用写法：markdown 链接（按相对路径解析）> 带路径的文本（至少两段路径后缀）> 仅文件名
（只在该文件名在整个仓库中唯一时才算）。路径比较不区分大小写，反斜杠按 / 处理。
"""
from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import sys
from pathlib import Path
from urllib.parse import unquote

DEFAULT_NAV = ["README.md", "index.md", "*index.md"]          # 无 "/" 的按文件名匹配
DEFAULT_HISTORY = ["reports/*", "*/reports/*"]                 # 含 "/" 的按完整相对路径匹配
DEFAULT_EXCLUDE = [".git/*", ".claude/*", ".godot/*", "tmp/*", "references/*", "node_modules/*", "*/__pycache__/*",
                   "__pycache__/*", ".cache/*", "*/.cache/*"]
DEFAULT_TARGET_EXCLUDE = [
    "project-source/agent-rules/*",
    "framework/prompt-scenarios/scenarios/*",
    "framework/qa/*",
    "project-source/addons/resources_spreadsheet_view/LICENSE.md",
]
DEFAULT_SEARCH_EXT = {".md", ".json", ".py", ".gd", ".toml", ".yaml", ".yml", ".tmpl",
                      ".txt", ".tscn", ".tres", ".cfg", ".ps1", ".js", ".gdshader"}
DEFAULT_TARGET_EXT = {".md"}
ACTION_HINT = re.compile(
    r"读取|阅读|读|更新|维护|写入|保存|记录|查阅|参见|使用|read|update|maintain|write|load|consult|see",
    re.IGNORECASE)
LINK_RE = re.compile(r"\]\(\s*(?:<([^>]+)>|([^)>\s]+))")

VERDICT_DESCRIPTIONS = {
    "NONE": "未识别到其他文件引用",
    "NAV_ONLY": "仅导航类文件引用",
    "HISTORY_ONLY": "有历史引用、无普通引用（可含导航引用）",
    "READ": "存在普通文件引用",
}
CATEGORY_DESCRIPTIONS = {"reader": "普通文件", "nav": "导航类文件", "history": "历史材料"}
KIND_DESCRIPTIONS = {"link": "Markdown 链接", "path": "路径文本", "name": "唯一文件名文本（子串匹配）"}
INTERPRETATION_NOTE = (
    "分类依据是引用来源文件的路径/名称，不是文档是否合格。README 可能承担条件读取路由，"
    "NAV_ONLY 需核对入口用途，已认可的对象按具体路径排除；READ 也不证明实际读取或执行。"
    "路径后缀和文件名子串可能误指其他文件，未命中也可能是引用写法未被识别。"
)


def norm(p: str) -> str:
    return p.replace("\\", "/").casefold()


def matches(rel: str, patterns: list[str]) -> bool:
    low = norm(rel)
    base = low.rsplit("/", 1)[-1]
    for pat in patterns:
        pat = norm(pat)
        if "/" in pat:
            if fnmatch.fnmatchcase(low, pat) or low == pat:
                return True
        elif fnmatch.fnmatchcase(base, pat):
            return True
    return False


def walk(root: Path, exclude: list[str]) -> list[str]:
    files = []
    def fail(error: OSError) -> None:
        raise error

    for cur, dirs, names in os.walk(root, followlinks=False, onerror=fail):
        rel_dir = Path(cur).relative_to(root).as_posix()
        dirs[:] = [d for d in dirs
                   if not matches(f"{'' if rel_dir == '.' else rel_dir + '/'}{d}/x", exclude)]
        for n in names:
            rel = n if rel_dir == "." else f"{rel_dir}/{n}"
            if not matches(rel, exclude):
                files.append(rel)
    return sorted(files)


def read_lines(path: Path) -> list[str] | None:
    try:
        return path.read_text(encoding="utf-8-sig").splitlines()
    except (UnicodeDecodeError, OSError):
        return None


def suffixes(rel: str) -> list[str]:
    """至少两段的路径后缀，由长到短；文档只有一段时返回空。"""
    parts = rel.split("/")
    return ["/".join(parts[i:]) for i in range(len(parts) - 1)]


def main() -> int:
    ap = argparse.ArgumentParser(description="查找孤立文档并列出引用位置。",
                                 formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog=__doc__)
    ap.add_argument("--root", type=Path, default=Path.cwd(), help="仓库根目录，默认当前目录")
    ap.add_argument("--targets", nargs="+", default=None,
                    help="要检查的文档：文件名、相对路径或通配；显式指定可选中导航文件及默认不检查的路径")
    ap.add_argument("--search-in", nargs="+", default=None,
                    help="只在这些路径/通配内找引用；默认整个根目录的文本文件")
    ap.add_argument("--exclude", nargs="*", default=None,
                    help=f"排除的路径/通配（替换默认值 {DEFAULT_EXCLUDE}）")
    ap.add_argument("--nav", nargs="*", default=None,
                    help=f"导航文件：默认不作检查目标，仍作引用来源（替换默认值 {DEFAULT_NAV}）")
    ap.add_argument("--history", nargs="*", default=None,
                    help=f"历史材料（替换默认值 {DEFAULT_HISTORY}）")
    ap.add_argument("--max-refs", type=int, default=8, help="每个文档最多显示的引用数")
    ap.add_argument("--show-read", action="store_true", help="同时展示已被 reader 引用的文档")
    ap.add_argument("--json", action="store_true", help="输出 JSON")
    ap.add_argument("--out", type=Path, help="把结果写入该文件（UTF-8），避免终端编码问题")
    ap.add_argument("--fail-on-orphan", action="store_true", help="存在 NONE 档文档时退出码为 1")
    args = ap.parse_args()

    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except (AttributeError, OSError):
        pass

    root = args.root.resolve()
    if not root.is_dir():
        print(f"根目录不存在：{root.as_posix()}", file=sys.stderr)
        return 2
    exclude = DEFAULT_EXCLUDE if args.exclude is None else args.exclude
    nav = DEFAULT_NAV if args.nav is None else args.nav
    history = DEFAULT_HISTORY if args.history is None else args.history

    try:
        all_files = walk(root, exclude)
    except OSError as error:
        print(f"无法读取目录：{error}", file=sys.stderr)
        return 2
    base_count: dict[str, int] = {}
    for f in all_files:
        b = norm(f).rsplit("/", 1)[-1]
        base_count[b] = base_count.get(b, 0) + 1

    target_exclusions = [*nav, *DEFAULT_TARGET_EXCLUDE] if args.targets is None else []
    if args.targets is None:
        targets = [f for f in all_files
                   if Path(f).suffix.lower() in DEFAULT_TARGET_EXT and not matches(f, target_exclusions)]
    else:
        targets = [f for f in all_files if matches(f, args.targets)]
    if not targets:
        print("没有匹配的目标文档。", file=sys.stderr)
        return 2

    search_files = [f for f in all_files if Path(f).suffix.lower() in DEFAULT_SEARCH_EXT]
    if args.search_in:
        search_files = [f for f in search_files if matches(f, args.search_in)]

    contents: dict[str, list[str]] = {}
    skipped = 0
    for f in search_files:
        lines = read_lines(root / f)
        if lines is None:
            skipped += 1
        else:
            contents[f] = lines
    lowered = {f: [norm(x) for x in lines] for f, lines in contents.items()}
    joined = {f: "\n".join(v) for f, v in lowered.items()}

    def category(referrer: str, target: str) -> str:
        if norm(referrer) == norm(target):
            return "self"
        if matches(referrer, history):
            return "history"
        if matches(referrer, nav):
            return "nav"
        return "reader"

    results = []
    for t in targets:
        tl = norm(t)
        base = tl.rsplit("/", 1)[-1]
        sufs = [norm(s) for s in suffixes(t)]
        name_ok = base_count.get(base, 0) == 1
        needles = sufs + ([base] if name_ok else [])
        refs = []
        for f, text in joined.items():
            if not any(n in text for n in needles) and "](" not in text:
                continue
            rdir = f.rsplit("/", 1)[0] if "/" in f else ""
            for i, line in enumerate(lowered[f]):
                kind = None
                for m in LINK_RE.finditer(contents[f][i]):
                    target = unquote((m.group(1) or m.group(2)).split("#")[0])
                    if not target or re.match(r"^[a-z][a-z0-9+.-]*:", target, re.I):
                        continue
                    resolved = os.path.normpath(os.path.join(rdir, target)).replace("\\", "/")
                    if norm(resolved) == tl:
                        kind = "link"
                        break
                if kind is None and any(s in line for s in sufs):
                    kind = "path"
                if kind is None and name_ok and base in line:
                    kind = "name"
                if kind is None:
                    continue
                cat = category(f, t)
                if cat == "self":
                    continue
                snippet = contents[f][i].strip()
                refs.append({"file": f, "line": i + 1, "kind": kind, "category": cat,
                             "action_hint": bool(ACTION_HINT.search(snippet)),
                             "snippet": snippet[:160]})
        counts = {c: sum(1 for r in refs if r["category"] == c) for c in ("reader", "nav", "history")}
        if counts["reader"]:
            verdict = "READ"
        elif counts["history"]:
            verdict = "HISTORY_ONLY"
        elif counts["nav"]:
            verdict = "NAV_ONLY"
        else:
            verdict = "NONE"
        results.append({"target": t, "verdict": verdict, "counts": counts, "refs": refs})

    order = {"NONE": 0, "NAV_ONLY": 1, "HISTORY_ONLY": 2, "READ": 3}
    results.sort(key=lambda r: (order[r["verdict"]], r["target"]))
    summary = {v: sum(1 for r in results if r["verdict"] == v) for v in order}

    if args.json:
        output = json.dumps({"root": root.as_posix(), "summary": summary, "skipped_unreadable": skipped,
                             "target_exclusions": target_exclusions,
                             "explanations": {"verdict": VERDICT_DESCRIPTIONS,
                                              "category": CATEGORY_DESCRIPTIONS,
                                              "kind": KIND_DESCRIPTIONS,
                                              "note": INTERPRETATION_NOTE},
                             "results": results}, ensure_ascii=False, indent=2)
    else:
        out = [f"根目录：{root.as_posix()}", f"目标 {len(results)} 个；搜索 {len(contents)} 个文件"
               f"（不可读已跳过 {skipped}）"]
        if target_exclusions:
            out.append("不作为检查目标的路径规则（仍保留为引用来源）：")
            out.extend(f"  {pattern}" for pattern in target_exclusions)
        out.append("汇总：")
        out.extend(f"  {code}（{VERDICT_DESCRIPTIONS[code]}）：{count}"
                   for code, count in summary.items())
        out.append("引用来源（按命中行计数）：" + "；".join(
            f"{code}={description}" for code, description in CATEGORY_DESCRIPTIONS.items()))
        out.append("引用写法：" + "；".join(
            f"{code}={description}" for code, description in KIND_DESCRIPTIONS.items()))
        out.extend([f"结果说明：{INTERPRETATION_NOTE}", ""])
        for r in results:
            if r["verdict"] == "READ" and not args.show_read:
                continue
            c = r["counts"]
            out.append(f"{r['target']}  [{r['verdict']}：{VERDICT_DESCRIPTIONS[r['verdict']]}]  "
                       f"reader={c['reader']} nav={c['nav']} "
                       f"history={c['history']}")
            shown = sorted(r["refs"], key=lambda x: {"reader": 0, "nav": 1, "history": 2}[x["category"]])
            for x in shown[:args.max_refs]:
                hint = "*" if x["action_hint"] else " "
                out.append(f"   [{x['category']:<7}] {x['kind']:<4}{hint} {x['file']}:{x['line']}  {x['snippet']}")
            if len(r["refs"]) > args.max_refs:
                out.append(f"   … 另有 {len(r['refs']) - args.max_refs} 条")
            out.append("")
        out.append("说明：kind 后的 * 表示该行含读取/更新类动作词，仅作提示，不是结论。")
        output = "\n".join(out)

    if args.out:
        args.out.write_text(output + "\n", encoding="utf-8")
        print(f"已写入 {args.out.resolve().as_posix()}")
    else:
        print(output)
    return 1 if args.fail_on_orphan and summary["NONE"] else 0


if __name__ == "__main__":
    sys.exit(main())
