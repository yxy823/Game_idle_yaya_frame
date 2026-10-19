import { useState } from "react";
import data from "virtual:panorama-data";
import { files } from "./docs.js";
import DocView, { FIRST_MATCH } from "./DocView.jsx";
import PageSearch, { PageHead, words } from "./PageSearch.jsx";

// 学习：按 Godot 项目手册 README 的顺序列出各章，点章节在右边显示正文。
// 正文里指向其他章节的链接切换章节，指向其他文档的链接在详情面板显示那张卡片。
const chapters = data.manual;
const groups = [...new Set(chapters.map((c) => c.group))];
const chapterOf = new Map(chapters.map((c, k) => [c.card, k]));

// 离开学习模块再回来时停在上次读的章节；首页的链接也用它指定章节
let lastChapter = 0;
export function openChapter(k) { lastChapter = k; }

// 搜索用的纯文本：去掉标签，还原常见的转义字符
const plain = chapters.map((c) => data.html[c.card].replace(/<[^>]+>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&amp;/g, "&").toLowerCase());
const count = (text, w) => { let n = 0; for (let at = text.indexOf(w); at >= 0; at = text.indexOf(w, at + w.length)) n += 1; return n; };

export default function LearnModule({ onSelect, font }) {
  const [query, setQuery] = useState("");
  const ws = words(query);
  const results = chapters.map((c, k) => ({ k, n: ws.map((w) => count(plain[k], w)) })).filter((r) => ws.length && r.n.every((n) => n > 0))
    .map(({ k, n }) => ({ key: k, label: files[chapters[k].card].title, meta: n.reduce((a, b) => a + b, 0) + " 处" }));
  const [chapter, setChapter] = useState(lastChapter);
  const [jump, setJump] = useState({ anchor: "" });

  const go = (k, anchor = "") => { lastChapter = k; setChapter(k); setJump({ anchor }); };
  const link = (card, anchor) => { if (chapterOf.has(card)) go(chapterOf.get(card), anchor); else onSelect(card); };
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
        <DocView card={chapters[chapter].card} jump={jump} words={ws} onLink={link} font={font} />
        {next && <button className="graph-btn learn-next" onClick={() => go(chapter + 1)}>下一章：{files[next.card].title}</button>}
      </article>
    </div>
    </>
  );
}
