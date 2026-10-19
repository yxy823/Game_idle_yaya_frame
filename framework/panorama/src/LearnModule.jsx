import { useEffect, useRef, useState } from "react";
import { mount } from "pele";
import data from "virtual:panorama-data";
import { files } from "./docs.js";
import { fontSize } from "./Diagram.jsx";
import PageSearch, { PageHead, words } from "./PageSearch.jsx";
import { useToast } from "./overlays.jsx";

// 学习：按 Godot 项目手册 README 的顺序列出各章，点章节在右边显示正文（构建时由 tools/manual.js 转成 HTML）。
// 正文里指向其他章节的链接切换章节，指向其他文档的链接在详情面板显示那张卡片。
const chapters = data.manual;
const groups = [...new Set(chapters.map((c) => c.group))];

// 离开学习模块再回来时停在上次读的章节；首页的链接也用它指定章节
let lastChapter = 0;
export function openChapter(k) { lastChapter = k; }

// 搜索用的纯文本：去掉标签，还原常见的转义字符
const plain = chapters.map((c) => c.html.replace(/<[^>]+>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&amp;/g, "&").toLowerCase());
const count = (text, w) => { let n = 0; for (let at = text.indexOf(w); at >= 0; at = text.indexOf(w, at + w.length)) n += 1; return n; };
const pattern = (ws) => new RegExp(ws.map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|"), "gi");
// 跳到第一处命中，用一个不会是锚点的值表示
const FIRST_MATCH = "#first-match";

// 给正文里的命中词加 <mark>，Mermaid 图里的文字不加；先去掉上一次加的
function highlight(root, ws) {
  for (const m of root.querySelectorAll("mark.hit")) m.replaceWith(m.textContent);
  root.normalize();
  if (!ws.length) return;
  const re = pattern(ws);
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, { acceptNode: (n) => (n.parentElement.closest(".manual-diagram") ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT) });
  const nodes = [];
  while (walker.nextNode()) nodes.push(walker.currentNode);
  for (const node of nodes) {
    const parts = node.nodeValue.split(new RegExp("(" + re.source + ")", "gi"));
    if (parts.length === 1) continue;
    node.replaceWith(...parts.map((t, i) => { if (i % 2 === 0) return t; const m = document.createElement("mark"); m.className = "hit"; m.textContent = t; return m; }));
  }
}

export default function LearnModule({ onSelect, font }) {
  const [query, setQuery] = useState("");
  const ws = words(query);
  const key = ws.join(" ");
  const results = chapters.map((c, k) => ({ k, n: ws.map((w) => count(plain[k], w)) })).filter((r) => ws.length && r.n.every((n) => n > 0))
    .map(({ k, n }) => ({ key: k, label: files[chapters[k].card].title, meta: n.reduce((a, b) => a + b, 0) + " 处" }));
  const [chapter, setChapter] = useState(lastChapter);
  const pending = useRef("");
  const queryRef = useRef(query);
  queryRef.current = query;
  const body = useRef(null);
  const toast = useToast();

  const scrollTo = (anchor) => {
    const target = anchor === FIRST_MATCH ? body.current.querySelector("mark.hit") : anchor && document.getElementById(anchor);
    if (target) target.scrollIntoView();
    else body.current.closest(".main").scrollTop = 0;
  };
  useEffect(() => {
    lastChapter = chapter;
    // 正文由这里写入，不交给 React：React 重新渲染时可能重写 innerHTML，冲掉已经渲染好的图
    body.current.innerHTML = chapters[chapter].html;
    const mounted = [];
    for (const el of body.current.querySelectorAll(".manual-diagram")) {
      const text = el.textContent;
      el.textContent = "";
      const m = mount(el, text, { fontSize: fontSize() });
      if (m.error) { m.destroy(); el.textContent = text; toast("图渲染失败：" + m.error.message); }
      else mounted.push(m);
    }
    highlight(body.current, words(queryRef.current));
    scrollTo(pending.current);
    pending.current = "";
    return () => mounted.forEach((m) => m.destroy());
  }, [chapter, toast, font]);
  useEffect(() => { highlight(body.current, key ? key.split(" ") : []); }, [key]);

  const go = (k, anchor = "") => {
    if (k === chapter) scrollTo(anchor);
    else { pending.current = anchor; setChapter(k); }
  };
  const click = (e) => {
    const a = e.target.closest("a");
    if (!a) return;
    const href = a.getAttribute("href");
    if (a.dataset.chapter !== undefined) { e.preventDefault(); go(Number(a.dataset.chapter), decodeURIComponent(a.dataset.anchor || "")); }
    else if (a.dataset.card !== undefined) { e.preventDefault(); onSelect(Number(a.dataset.card)); }
    else if (href.startsWith("#")) { e.preventDefault(); scrollTo(decodeURIComponent(href.slice(1))); }
  };
  const next = chapters[chapter + 1];
  return (
    <>
    <PageHead search={<PageSearch ui="learn.search" value={query} onChange={setQuery} placeholder="在手册各章里搜索" results={results} onPick={(r) => go(r.key, FIRST_MATCH)} />} />
    <div className="learn">
      <nav className="learn-toc" aria-label="章节" data-ui="learn.toc">
        {groups.map((g) => (
          <div key={g}>
            <div className="learn-group">{g}</div>
            {chapters.map((c, k) => c.group === g && (
              <button key={k} className="tree-row" aria-selected={k === chapter} onClick={() => go(k)}>
                <span className="tree-name">{files[c.card].title}</span>
              </button>
            ))}
          </div>
        ))}
      </nav>
      <article className="learn-body" data-ui="learn.body">
        <div ref={body} onClick={click} />
        {next && <button className="graph-btn learn-next" onClick={() => go(chapter + 1)}>下一章：{files[next.card].title}</button>}
      </article>
    </div>
    </>
  );
}
