import { Button } from "@/components/ui/button";
import { useEffect, useRef, useState } from "react";
import { IconChevronDown, IconChevronUp } from "@tabler/icons-react";
import data from "virtual:panorama-data";
import { files } from "./docs.js";
import DocView, { FIRST_MATCH } from "./DocView.jsx";
import PageSearch, { PageHead, words } from "./PageSearch.jsx";
import SideLayout from "./SideLayout.jsx";

// 学习：按 Godot 项目手册 README 的顺序列出各章，点章节在右边显示正文。
// 正文里指向其他章节的链接切换章节，指向其他文档的链接在详情面板显示那张卡片。
// 切换章节写进浏览器历史，浏览器的后退、前进在读过的章节之间移动。
const chapters = data.manual;
const groups = [...new Set(chapters.map((c) => c.group))];
const chapterOf = new Map(chapters.map((c, k) => [c.card, k]));

// 离开学习模块再回来时停在上次读的章节；首页的链接也用它指定章节。在别的模块按浏览器后退回来时带上锚点，回到原来的小节
let lastChapter = 0, lastAnchor = "";
export function openChapter(k, anchor = "") { lastChapter = k; lastAnchor = anchor; }

// 搜索用的纯文本：交给浏览器解析 HTML 再取文字，全部转义字符都还原。
// 去掉 Mermaid 图的原文，因为正文里图中的文字不高亮，算进来时列表里的条数和正文里能定位的对不上
const parser = new DOMParser();
const plain = chapters.map((c) => {
  const doc = parser.parseFromString(data.html[c.card], "text/html");
  doc.querySelectorAll(".manual-diagram").forEach((el) => el.remove());
  return doc.body.textContent.toLowerCase();
});
const count = (text, w) => { let n = 0; for (let at = text.indexOf(w); at >= 0; at = text.indexOf(w, at + w.length)) n += 1; return n; };

export default function LearnModule({ onSelect, font }) {
  const [query, setQuery] = useState("");
  const ws = words(query);
  const results = chapters.map((c, k) => ({ k, n: ws.map((w) => count(plain[k], w)) })).filter((r) => ws.length && r.n.every((n) => n > 0))
    .map(({ k, n }) => ({ key: k, label: files[chapters[k].card].title, meta: n.reduce((a, b) => a + b, 0) + " 处" }));
  const [chapter, setChapter] = useState(lastChapter);
  const [jump, setJump] = useState(() => { const anchor = lastAnchor; lastAnchor = ""; return { anchor }; });
  // 本章的命中数和当前看的是第几处，“上一处”“下一处”在本章的命中之间移动
  const [hits, setHits] = useState(0);
  const [at, setAt] = useState(0);
  const body = useRef(null);

  const show = (k, anchor) => { lastChapter = k; setChapter(k); setJump({ anchor }); setAt(0); };
  const go = (k, anchor = "") => { history.pushState({ chapter: k, anchor }, ""); show(k, anchor); };
  useEffect(() => {
    if (!history.state || !("chapter" in history.state)) history.replaceState({ chapter, anchor: "" }, "");
    const pop = (e) => { if (e.state && "chapter" in e.state) show(e.state.chapter, e.state.anchor); };
    addEventListener("popstate", pop);
    return () => removeEventListener("popstate", pop);
  }, []);
  useEffect(() => setAt(0), [query]);
  // 当前一处加 current 样式并滚到屏幕中间
  const move = (d) => {
    const marks = body.current.querySelectorAll("mark.hit");
    const k = (at + d + marks.length) % marks.length;
    marks.forEach((m, i) => m.classList.toggle("current", i === k));
    marks[k].scrollIntoView({ block: "center" });
    setAt(k);
  };
  const link = (card, anchor) => { if (chapterOf.has(card)) go(chapterOf.get(card), anchor); else onSelect(card); };
  const next = chapters[chapter + 1];
  const hitNav = ws.length > 0 && hits > 0;
  // 外面再包一层：.module 只有主区域高，固定的标题行要放在和正文一样高的容器里才能一直固定
  return (
    <div>
    {/* 标题行（搜索和上一处、下一处）固定在主区域顶部，跳到命中后仍能继续搜索 */}
    <div className="sticky -top-(--page-pad-y) z-4 -mt-(--page-pad-y) bg-background pt-(--page-pad-y)">
      <PageHead search={<PageSearch ui="learn.search" value={query} onChange={setQuery} placeholder="在手册各章里搜索" results={results} onPick={(r) => go(r.key, FIRST_MATCH)} />}>
        {hitNav && (
          <div className="flex items-center justify-end gap-0.5" data-ui="learn.hit-nav">
            <span className="count mr-1">本章第 {at + 1}/{hits} 处</span>
            <Button variant="ghost" size="icon" className="icon-btn" aria-label="上一处" data-tip="上一处" onClick={() => move(-1)}><IconChevronUp aria-hidden="true" /></Button>
            <Button variant="ghost" size="icon" className="icon-btn" aria-label="下一处" data-tip="下一处" onClick={() => move(1)}><IconChevronDown aria-hidden="true" /></Button>
          </div>
        )}
      </PageHead>
    </div>
    <SideLayout hasHead={hitNav} label="章节" ui="learn" toc={
      groups.map((g) => (
        <div key={g}>
          <div className="px-2 pt-2 pb-0.5 text-xs text-muted-foreground">{g}</div>
          {chapters.map((c, k) => c.group === g && (
            <Button key={k} variant="row" size="none" className="tree-row" aria-selected={k === chapter} onClick={() => go(k)}>
              <span className="tree-name" data-tip-clip>{files[c.card].title}</span>
            </Button>
          ))}
        </div>
      ))}>
      <article className="learn-body" data-ui="learn.body" ref={body}>
        <DocView card={chapters[chapter].card} jump={jump} words={ws} onLink={link} inPanel={(card) => !chapterOf.has(card)} onHits={setHits} font={font} />
        {next && <Button variant="outline" className="graph-btn mt-4 mb-8" onClick={() => go(chapter + 1)}>下一章：{files[next.card].title}</Button>}
      </article>
    </SideLayout>
    </div>
  );
}
