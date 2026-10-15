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

// 图上的节点名和页面里某张表格某行的第一格相同时，节点右上角显示 i 标记，点击节点弹出这一行的其余各列（阅读入口、职责等）。
// 内容在打开页面时从表格读取，表格仍是唯一正文；没有对应行的节点不可点击。可以同时打开多个弹窗，按住标题栏拖动，用 ✕ 或 Esc 关闭。
const NODE_DETAIL = `<style>
/* 架构页面整体放大 12.5%：正文、目录和图一起缩放；弹窗挂在 body 上，字号单独放大 */
.am-doc { zoom: 1.125; }
.am-node[data-detail] { cursor: pointer; }
.am-node[data-detail]:hover .am-node-shape { stroke-width: 2.5px; }
.am-node[data-detail]:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.am-detail-mark circle { fill: var(--paper); stroke: var(--kind, var(--accent)); stroke-width: 1.5px; }
.am-diagram .am-detail-mark text { font: 700 12px var(--font-sans); fill: color-mix(in srgb, var(--kind, var(--accent)) 45%, var(--ink)); }
.am-detail-hint { display: inline-flex; align-items: center; gap: 6px; }
.am-detail-hint b {
  display: inline-flex; align-items: center; justify-content: center; width: 16px; height: 16px; font-size: 12px;
  border: 1.5px solid var(--ink-2); border-radius: 50%; color: var(--ink-2);
}
.am-arch-pop:not([class*="am-node--k-"]) { --kind: var(--accent); }
.am-arch-pop {
  position: fixed; z-index: 1001; display: flex; flex-direction: column;
  width: min(470px, calc(100vw - 32px)); max-height: min(70vh, 630px);
  font-size: 16px; color: var(--ink); background: var(--paper);
  border: 1px solid color-mix(in srgb, var(--kind) 45%, var(--line-2)); border-top: 4px solid var(--kind); border-radius: 10px;
  box-shadow: 0 16px 40px rgb(0 0 0 / 0.22), 0 2px 8px rgb(0 0 0 / 0.12); overflow: hidden;
}
.am-arch-pop-head {
  flex: none; display: flex; align-items: flex-start; gap: 10px; padding: 12px 10px 10px 16px;
  background: color-mix(in srgb, var(--kind) 12%, var(--paper)); border-bottom: 1px solid var(--line);
  cursor: grab; user-select: none; touch-action: none;
}
.am-arch-pop.is-dragging .am-arch-pop-head { cursor: grabbing; }
.am-arch-pop-title { flex: 1; min-width: 0; }
.am-arch-pop-title h3 { margin: 0; font-size: 18px; line-height: 1.4; }
.am-arch-pop-sub { margin-top: 2px; font: 13.5px/1.4 var(--font-mono, monospace); color: var(--ink-2); overflow-wrap: anywhere; }
.am-arch-pop-chip {
  flex: none; margin-top: 2px; padding: 2px 8px; font-size: 13.5px; line-height: 1.5; border-radius: 999px;
  color: color-mix(in srgb, var(--kind) 45%, var(--ink)); background: color-mix(in srgb, var(--kind) 22%, var(--paper));
  border: 1px solid color-mix(in srgb, var(--kind) 60%, var(--paper));
}
.am-arch-pop-close {
  flex: none; width: 28px; height: 28px; padding: 0; font-size: 14px; line-height: 1; color: var(--ink-2);
  background: transparent; border: 1px solid transparent; border-radius: 6px; cursor: pointer;
}
.am-arch-pop-close:hover { color: var(--ink); background: color-mix(in srgb, var(--ink) 8%, transparent); }
.am-arch-pop-close:focus-visible { outline: 2px solid var(--accent); outline-offset: 1px; }
.am-arch-pop dl { flex: 1 1 auto; min-height: 0; margin: 0; padding: 4px 16px 12px; overflow: auto; overscroll-behavior: contain; }
.am-arch-pop dt { padding-top: 10px; font-size: 13.5px; font-weight: 700; color: var(--ink-2); }
.am-arch-pop dd { margin: 2px 0 0; padding-bottom: 10px; line-height: 1.6; }
.am-arch-pop dd + dt { border-top: 1px dashed var(--line); }
@media print { .am-arch-pop, .am-detail-mark { display: none !important; } }
</style>
<script>
(() => {
  const SVG = 'http://www.w3.org/2000/svg';
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
  for (const n of nodes) {
    n.setAttribute('data-detail', '');
    n.setAttribute('tabindex', '0');
    n.setAttribute('role', 'button');
    const box = (n.querySelector('.am-node-shape') ?? n).getBBox();
    const mark = document.createElementNS(SVG, 'g');
    mark.setAttribute('class', 'am-detail-mark');
    mark.setAttribute('transform', 'translate(' + (box.x + box.width) + ',' + box.y + ')');
    mark.innerHTML = '<circle r="8"/><text text-anchor="middle" dominant-baseline="central">i</text>';
    n.append(mark);
  }
  for (const fig of new Set(nodes.map((n) => n.closest('figure')).filter(Boolean))) {
    let legend = fig.querySelector('.am-flow-legend');
    if (!legend) {
      legend = document.createElement('div');
      legend.className = 'am-flow-legend';
      fig.append(legend);
    }
    const hint = document.createElement('span');
    hint.className = 'am-detail-hint';
    hint.innerHTML = '<b>i</b>点击节点查看阅读入口';
    legend.append(hint);
  }

  const open = new Map();
  let top = 1001;
  const front = (pop) => { pop.style.zIndex = ++top; };
  const place = (pop, left, t) => {
    pop.style.left = Math.max(8, Math.min(left, innerWidth - pop.offsetWidth - 8)) + 'px';
    pop.style.top = Math.max(8, Math.min(t, innerHeight - pop.offsetHeight - 8)) + 'px';
  };
  const close = (key) => {
    const pop = open.get(key);
    if (!pop) return;
    pop.remove();
    open.delete(key);
    const last = [...open.values()].sort((a, b) => b.style.zIndex - a.style.zIndex)[0];
    (last?.querySelector('.am-arch-pop-close') ?? nodes.find((n) => n.dataset.key === key))?.focus();
  };
  const build = (node) => {
    const key = node.dataset.key;
    const { heads, cells } = rows.get(key);
    const kind = [...node.classList].find((c) => c.startsWith('am-node--k-'));
    const pop = document.createElement('div');
    pop.className = 'am-arch-pop am-md' + (kind ? ' ' + kind : '');
    pop.setAttribute('role', 'dialog');
    pop.innerHTML = '<div class="am-arch-pop-head"><div class="am-arch-pop-title"><h3></h3><div class="am-arch-pop-sub"></div></div>'
      + '<span class="am-arch-pop-chip"></span><button type="button" class="am-arch-pop-close" aria-label="Close">✕</button></div><dl></dl>';
    pop.querySelector('h3').textContent = key;
    const sub = node.querySelector('.am-node-sub');
    pop.querySelector('.am-arch-pop-sub').textContent = sub ? sub.textContent : '';
    pop.querySelector('.am-arch-pop-sub').hidden = !sub;
    const chip = pop.querySelector('.am-arch-pop-chip');
    chip.textContent = kind ? document.querySelector('.am-flow-legend .' + kind)?.textContent ?? '' : '';
    chip.hidden = !chip.textContent;
    const dl = pop.querySelector('dl');
    cells.slice(1).forEach((cell, i) => {
      const dt = document.createElement('dt');
      dt.textContent = heads[i + 1] ?? '';
      const dd = document.createElement('dd');
      dd.innerHTML = cell.innerHTML;
      dl.append(dt, dd);
    });
    pop.querySelector('.am-arch-pop-close').addEventListener('click', () => close(key));
    pop.addEventListener('pointerdown', () => front(pop));
    pop.addEventListener('focusin', () => front(pop));
    pop.addEventListener('wheel', (e) => { if (dl.scrollHeight <= dl.clientHeight || !dl.contains(e.target)) e.preventDefault(); }, { passive: false });
    const head = pop.querySelector('.am-arch-pop-head');
    head.addEventListener('pointerdown', (e) => {
      if (e.button !== 0 || e.target.closest('button')) return;
      const r = pop.getBoundingClientRect(), dx = e.clientX - r.left, dy = e.clientY - r.top;
      head.setPointerCapture(e.pointerId);
      pop.classList.add('is-dragging');
      const move = (ev) => place(pop, ev.clientX - dx, ev.clientY - dy);
      const up = () => {
        head.removeEventListener('pointermove', move);
        pop.classList.remove('is-dragging');
      };
      head.addEventListener('pointermove', move);
      head.addEventListener('pointerup', up, { once: true });
      head.addEventListener('pointercancel', up, { once: true });
    });
    return pop;
  };
  const show = (node, byKey) => {
    const key = node.dataset.key;
    let pop = open.get(key);
    if (!pop) {
      pop = build(node);
      document.body.append(pop);
      open.set(key, pop);
      const r = node.getBoundingClientRect(), w = pop.offsetWidth, gap = 12;
      let left = r.right + gap + w <= innerWidth - 8 ? r.right + gap : r.left - gap - w, t = r.top;
      const taken = () => [...open.values()].some((p) => p !== pop && Math.abs(parseFloat(p.style.left) - left) < 24 && Math.abs(parseFloat(p.style.top) - t) < 24);
      for (let i = 0; i < 20 && taken(); i++) { left += 28; t += 28; }
      place(pop, left, t);
    }
    front(pop);
    if (byKey) pop.querySelector('.am-arch-pop-close').focus();
  };
  document.addEventListener('click', (e) => {
    const node = e.target.closest('.am-node[data-detail]');
    if (node) show(node);
  });
  document.addEventListener('keydown', (e) => {
    const node = e.target.closest?.('.am-node[data-detail]');
    if (node && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); show(node, true); return; }
    if (e.key !== 'Escape' || !open.size) return;
    const inPop = e.target.closest?.('.am-arch-pop');
    const target = inPop ?? [...open.values()].sort((a, b) => b.style.zIndex - a.style.zIndex)[0];
    e.stopPropagation();
    close([...open].find(([, p]) => p === target)[0]);
  }, true);
  window.addEventListener('resize', () => { for (const p of open.values()) place(p, parseFloat(p.style.left), parseFloat(p.style.top)); });
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
