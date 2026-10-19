import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkGfm from "remark-gfm";
import remarkFrontmatter from "remark-frontmatter";
import YAML from "yaml";

// 读取仓库里纳入 Git 的 Markdown，得到卡片、段落和链接三张表，交给页面。
// 关系只从 Markdown 链接读出：场景页的下一步清单记为“下一步”，问答的「依据」段记为“依据”，其余记为“引用”。

// 分组按路径前缀匹配，先匹配的优先；图谱按分组上色
export const groups = [
  ["scenes", "场景页", "framework/prompt-scenarios/scenarios/"],
  ["prompts", "提示词与场景", "framework/prompt-scenarios/"],
  ["manual", "Godot 项目手册", "framework/godot-project-manual/"],
  ["maintenance", "框架维护", "framework/maintenance/"],
  ["qa", "问答", "framework/qa/"],
  ["framework", "框架入口与其他", "framework/"],
  ["yaya-skills", "框架 Skill", ".agents/skills/"],
  ["skills", "分发 Skill", "project-source/skills/"],
  ["rules", "工程规则", "project-source/agent-rules/"],
  ["methodology", "方法规范", "project-source/methodology/"],
  ["defaults", "项目初始文件", "project-source/defaults/"],
  ["source", "分发源其他", "project-source/"],
  ["root", "仓库根目录", ""],
].map(([id, name, prefix]) => ({ id, name, prefix }));

// 不做卡片的目录：.claude/skills 是 .agents/skills 的副本，addons 是第三方插件自带的说明
const excluded = [".claude/", "project-source/addons/"];

const parser = unified().use(remarkParse).use(remarkGfm).use(remarkFrontmatter, ["yaml"]);

function git(repo, args) {
  return execFileSync("git", ["-c", "core.quotepath=off", ...args], { cwd: repo, encoding: "utf-8", maxBuffer: 64 << 20 });
}

function text(node) {
  if (node.type === "text" || node.type === "inlineCode") return node.value;
  return node.children ? node.children.map(text).join("") : "";
}

// 只由链接、“·”和空白组成的段落是导航行，不当作用途
function isNav(node) {
  // 导航行只有链接、分隔点和“上一篇：”“下一篇：”这类前缀
  return node.children.every((c) => c.type === "link" || (c.type === "text" && /^[\s·]*([上下]一篇[：:])?\s*$/.test(c.value)));
}

function history(repo) {
  const result = new Map();
  let date = "";
  for (const line of git(repo, ["log", "--name-only", "--format=@%cs", "--", "*.md"]).split("\n")) {
    if (line.startsWith("@")) date = line.slice(1);
    else if (line) {
      const h = result.get(line);
      if (h) h.changes += 1; else result.set(line, { changed: date, changes: 1 });
    }
  }
  return result;
}

// 术语表和工具表的每一行单独做成搜索条目：表头第一列是“术语”，或是“工具”“脚本”“命令”且有“用途”列
function readEntries(node, file, entries) {
  if (node.type === "table") {
    const head = node.children[0].children.map(text);
    const kind = head[0] === "术语" ? "term" : ["工具", "脚本", "命令"].includes(head[0]) && head.includes("用途") ? "tool" : null;
    if (!kind) return;
    const desc = kind === "term" ? 1 : head.indexOf("用途");
    for (const row of node.children.slice(1)) {
      const cells = row.children.map(text);
      entries.push({ kind, name: cells[0], desc: cells[desc] || "", aliases: kind === "term" ? cells[2] || "" : "", file, line: row.position.start.line });
    }
    return;
  }
  for (const child of node.children || []) readEntries(child, file, entries);
}

// 问答主题文件里每个二级标题是一个问题；问答页按出现顺序给它们编号 A、B、C……，打开页面时跳到 #panel-字母
function readQa(tree, file, qa, resolve) {
  let current = null, order = 0;
  for (const node of tree.children) {
    if (node.type === "heading" && node.depth === 2) {
      current = { file, title: text(node), line: node.position.start.line, panel: String.fromCharCode(65 + order++), conclusion: "", why: "", basis: [] };
      qa.push(current);
    } else if (current && node.type === "paragraph" && node.children[0]?.type === "strong") {
      const label = text(node.children[0]), rest = text({ children: node.children.slice(1) }).replace(/^[：:]\s*/, "");
      if (label === "结论") current.conclusion = rest;
      else if (label === "为什么") current.why = rest;
      else if (label === "依据") {
        const found = [];
        const find = (n) => { if (n.type === "link") { const hit = resolve(n.url); if (hit && !found.includes(hit.to)) found.push(hit.to); } (n.children || []).forEach(find); };
        find(node);
        current.basis = found;
      }
    }
  }
}

export function readDocs(repo) {
  const paths = git(repo, ["ls-files", "-z", "--", "*.md"]).split("\0")
    .filter((p) => p && !excluded.some((e) => p.startsWith(e)));
  const index = new Map(paths.map((p, i) => [p, i]));
  const changes = history(repo);
  const files = [], paras = [], links = [], entries = [], qa = [];

  // 链接目标换成卡片编号：相对当前文件解析，指向目录时取目录下的 README.md；不是 Markdown 卡片的目标返回 null
  const resolve = (from, url) => {
    if (/^[a-z][a-z0-9+.-]*:/i.test(url) || url.startsWith("#")) return url.startsWith("#") ? { to: index.get(from), anchor: url.slice(1) } : null;
    const [raw, anchor = ""] = url.split("#");
    let target = path.posix.normalize(path.posix.join(path.posix.dirname(from), decodeURI(raw)));
    if (raw.endsWith("/") || !index.has(target)) target = path.posix.join(target, "README.md");
    return index.has(target) ? { to: index.get(target), anchor } : null;
  };

  paths.forEach((file, fi) => {
    const source = fs.readFileSync(path.join(repo, file), "utf-8");
    const tree = parser.parse(source);
    const front = tree.children[0]?.type === "yaml" ? YAML.parse(tree.children[0].value) : null;
    const h1 = tree.children.find((n) => n.type === "heading" && n.depth === 1);
    const afterTitle = h1 ? tree.children.slice(tree.children.indexOf(h1) + 1) : tree.children;
    const first = afterTitle.find((n) => n.type === "paragraph" && !isNav(n));
    files.push({
      path: file,
      title: front?.name || front?.title || (h1 ? text(h1) : path.posix.basename(file)),
      group: groups.find((g) => file.startsWith(g.prefix)).id,
      purpose: front?.description || (first ? text(first) : ""),
      outline: tree.children.filter((n) => n.type === "heading" && n.depth === 2).map(text),
      ...(changes.get(file) || { changed: "", changes: 0 }),
    });

    // 一个段落、标题或表格行算一段；段内链接按出现顺序拆成文字和链接
    const walk = (node, kind) => {
      if (node.type === "paragraph" && /^下一步：$/.test(text(node).trim())) return "next-intro";
      if (["paragraph", "heading", "tableRow"].includes(node.type)) {
        collect(node, kind);
        return undefined;
      }
      let state;
      for (const child of node.children || []) {
        if (state === "next-intro" && child.type === "list") { child.children.forEach((item) => collect(item, "next")); state = undefined; continue; }
        state = walk(child, kind);
      }
      return undefined;
    };
    const collect = (node, kind) => {
      const parts = [];
      const found = [];
      const basis = node.type === "paragraph" && node.children[0]?.type === "strong" && text(node.children[0]) === "依据";
      const flatten = (n) => {
        if (n.type === "link") {
          const hit = resolve(file, n.url);
          if (hit) { found.push(hit); parts.push({ text: text(n), to: hit.to, anchor: hit.anchor }); return; }
        }
        if (n.type === "text" || n.type === "inlineCode") { parts.push(n.value); return; }
        if (n.type === "break") { parts.push(" "); return; }
        (n.children || []).forEach((c, i) => { if (i && n.type === "tableRow") parts.push(" | "); flatten(c); });
      };
      flatten(node);
      // 链到本文件的链接不算关系；下一步清单例外，因为场景可以接着进入自己，例如“下一个 Feature 可开始”
      const external = found.filter((f) => f.to !== fi || kind === "next");
      if (!external.length) return;
      const para = paras.push({ file: fi, line: node.position.start.line, parts }) - 1;
      let cond = "", main = false;
      if (kind === "next") {
        const lead = (typeof parts[0] === "string" ? parts[0] : "").trim();
        main = lead.startsWith("主线：");
        cond = lead.replace(/^主线：/, "").replace(/：$/, "");
      }
      for (const f of external) links.push({ from: fi, to: f.to, kind: kind === "next" ? "next" : basis ? "basis" : "ref", main, cond, para });
    };
    walk(tree, "ref");
    readEntries(tree, fi, entries);
    if (/^framework\/qa\/[^/]+\.md$/.test(file) && !file.endsWith("/README.md")) readQa(tree, fi, qa, (url) => resolve(file, url));
  });

  return { groups: groups.map(({ id, name }) => ({ id, name })), files, paras, links, entries, qa };
}
