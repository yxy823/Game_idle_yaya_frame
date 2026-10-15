// 生成架构文档的页面：docs/architecture.md 和 docs/architecture/ 下的子系统说明（不含 adr-*.md）各自生成同目录同名的 .html。
// 生成前检查表格里的阅读入口：同一格里既有 .gd 文件链接、又写了 `函数名()` 时，文件必须存在，函数必须在其中一个链接的文件里定义。
// 有一处不符就不写任何页面，退出码 1。生成的页面里，点击与表格某行第一格同名的图节点，弹出这一行。用法：node arch-build.mjs [docs 目录]，在项目根目录运行，默认 docs。
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
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

// 图上的节点名和页面里某张表格某行的第一格相同时，点击节点弹出这一行的其余各列（阅读入口、职责等）。
// 内容在打开页面时从表格读取，表格仍是唯一正文；没有对应行的节点不可点击。
const NODE_DETAIL = `<style>
.am-node[data-detail] { cursor: pointer; }
.am-node[data-detail]:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.am-arch-pop {
  position: fixed; z-index: 1001; width: min(440px, calc(100vw - 32px)); max-height: 60vh; overflow: auto;
  padding: 12px 16px; font-size: 14px; color: var(--ink); background: var(--paper);
  border: 1px solid var(--line-2); border-radius: var(--radius); box-shadow: 0 8px 24px rgb(0 0 0 / 0.18);
}
.am-arch-pop h3 { margin: 0; margin-inline-end: 32px; font-size: 16px; }
.am-arch-pop dt { margin-top: 10px; font-size: 12px; color: var(--ink-2); }
.am-arch-pop dd { margin: 2px 0 0; }
.am-arch-pop-close { position: absolute; top: 8px; inset-inline-end: 8px; }
@media print { .am-arch-pop { display: none !important; } }
</style>
<script>
(() => {
  const rows = new Map();
  for (const table of document.querySelectorAll('.am-md table')) {
    const heads = [...table.querySelectorAll('thead th')].map((th) => th.textContent.trim());
    for (const tr of table.querySelectorAll('tbody tr')) {
      const key = tr.children[0]?.textContent.trim();
      if (key && !rows.has(key)) rows.set(key, { heads, cells: [...tr.children] });
    }
  }
  const nodes = [...document.querySelectorAll('.am-node[data-key]')].filter((n) => rows.has(n.dataset.key));
  if (!nodes.length) return;
  for (const n of nodes) { n.setAttribute('data-detail', ''); n.setAttribute('tabindex', '0'); n.setAttribute('role', 'button'); }
  const pop = document.createElement('div');
  pop.className = 'am-arch-pop am-md';
  pop.setAttribute('role', 'dialog');
  pop.hidden = true;
  document.body.append(pop);
  let from = null;
  const close = () => {
    if (pop.hidden) return;
    pop.hidden = true;
    from?.focus();
    from = null;
  };
  const open = (node) => {
    const { heads, cells } = rows.get(node.dataset.key);
    pop.innerHTML = '<button type="button" class="am-btn am-arch-pop-close" aria-label="Close">✕</button><h3></h3><dl></dl>';
    pop.querySelector('h3').textContent = node.dataset.key;
    const dl = pop.querySelector('dl');
    cells.slice(1).forEach((cell, i) => {
      const dt = document.createElement('dt');
      dt.textContent = heads[i + 1] ?? '';
      const dd = document.createElement('dd');
      dd.innerHTML = cell.innerHTML;
      dl.append(dt, dd);
    });
    pop.querySelector('button').addEventListener('click', close);
    pop.hidden = false;
    const r = node.getBoundingClientRect(), w = pop.offsetWidth, h = pop.offsetHeight, gap = 8;
    const left = r.right + gap + w <= innerWidth - 16 ? r.right + gap : r.left - gap - w >= 16 ? r.left - gap - w : (innerWidth - w) / 2;
    pop.style.left = left + 'px';
    pop.style.top = Math.max(16, Math.min(r.top, innerHeight - h - 16)) + 'px';
    from = node;
    pop.querySelector('button').focus();
  };
  document.addEventListener('click', (e) => {
    const node = e.target.closest('.am-node[data-detail]');
    if (node) open(node);
    else if (!pop.contains(e.target)) close();
  });
  document.addEventListener('keydown', (e) => {
    const node = e.target.closest?.('.am-node[data-detail]');
    if (node && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); open(node); }
    else if (e.key === 'Escape' && !pop.hidden) { e.stopPropagation(); close(); }
  }, true);
  document.addEventListener('scroll', (e) => { if (!pop.contains(e.target)) close(); }, true);
})();
</script>
`;

let ok = true;
for (const path of files) {
  const out = path.replace(/\.md$/, ".html");
  const r = spawnSync(process.execPath, [AM, "render", "-", "-o", out, "--no-open"], { input: withDocTemplate(texts.get(path)), encoding: "utf8" });
  process.stdout.write(r.stdout);
  process.stderr.write(r.stderr);
  if (r.status === 0) {
    const html = readFileSync(out, "utf8");
    const end = html.lastIndexOf("</body>");
    writeFileSync(out, html.slice(0, end) + NODE_DETAIL + html.slice(end));
  }
  ok = r.status === 0 && ok;
}
process.exit(ok ? 0 : 1);
