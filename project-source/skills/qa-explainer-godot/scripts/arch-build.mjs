// 生成架构文档的页面：docs/architecture.md 和 docs/architecture/ 下的子系统说明（不含 adr-*.md）各自生成同目录同名的 .html。
// 生成前检查表格里的阅读入口：同一格里既有 .gd 文件链接、又写了 `函数名()` 时，文件必须存在，函数必须在其中一个链接的文件里定义。
// 有一处不符就不写任何页面，退出码 1。用法：node arch-build.mjs [docs 目录]，在项目根目录运行，默认 docs。
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const AM = fileURLToPath(new URL("./am.mjs", import.meta.url));
const docs = process.argv[2] ?? "docs";

const main = join(docs, "architecture.md");
if (!existsSync(main)) {
  console.error(`没有找到 ${main}。在项目根目录运行：node arch-build.mjs [docs 目录]`);
  process.exit(2);
}
const sub = join(docs, "architecture");
const files = [main, ...(existsSync(sub) ? readdirSync(sub).filter((f) => f.endsWith(".md") && !f.startsWith("adr-")).sort().map((f) => join(sub, f)) : [])];

const LINK = /\[[^\]]*\]\(<?([^)\s>]+)>?\)/g;
const FUNC = /`([A-Za-z_]\w*)\(\)`/g;

// 只看表格行；代码块里的表格不算。
const shown = (p) => relative(process.cwd(), resolve(p)).replaceAll("\\", "/");

function entryProblems(path, text) {
  const problems = [];
  const at = (i) => `${shown(path)}:L${i + 1}`;
  let fence = false;
  text.split(/\r?\n/).forEach((line, i) => {
    if (/^\s*(```|~~~)/.test(line)) fence = !fence;
    if (fence || !line.trimStart().startsWith("|")) return;
    for (const cell of line.split(/(?<!\\)\|/)) {
      const scripts = [...cell.matchAll(LINK)].map((m) => decodeURI(m[1].split("#")[0])).filter((p) => p.endsWith(".gd"));
      const funcs = [...cell.matchAll(FUNC)].map((m) => m[1]);
      if (!scripts.length || !funcs.length) continue;
      const targets = scripts.map((s) => resolve(dirname(path), s));
      const sources = [];
      for (const target of targets) {
        if (existsSync(target)) sources.push(readFileSync(target, "utf8"));
        else problems.push(`${at(i)} 链接的脚本不存在：${shown(target)}`);
      }
      for (const name of funcs) {
        const defined = new RegExp(`^\\s*(static\\s+)?func\\s+${name}\\s*\\(`, "m");
        if (sources.length && !sources.some((s) => defined.test(s))) problems.push(`${at(i)} ${targets.map(shown).join("、")} 里没有 func ${name}`);
      }
    }
  });
  return problems;
}

const texts = new Map(files.map((p) => [p, readFileSync(p, "utf8")]));
const problems = files.flatMap((p) => entryProblems(p, texts.get(p)));
if (problems.length) {
  for (const p of problems) console.error(`✗ ${p}`);
  console.error("改正阅读入口后重新运行；这次没有写出页面。");
  process.exit(1);
}

// 固定用 doc 模板：写进 frontmatter 再渲染，源文件不变。
function withDocTemplate(text) {
  if (!text.startsWith("---")) return `---\ntemplate: doc\n---\n${text}`;
  return /^template:/m.test(text.split(/\r?\n---/)[0]) ? text : text.replace(/^---\r?\n/, "---\ntemplate: doc\n");
}

let ok = true;
for (const path of files) {
  const r = spawnSync(process.execPath, [AM, "render", "-", "-o", path.replace(/\.md$/, ".html"), "--no-open"], { input: withDocTemplate(texts.get(path)), encoding: "utf8" });
  process.stdout.write(r.stdout);
  process.stderr.write(r.stderr);
  ok = r.status === 0 && ok;
}
process.exit(ok ? 0 : 1);
