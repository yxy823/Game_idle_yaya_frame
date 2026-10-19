import { useEffect, useRef, useState } from "react";
import { mount } from "pele";
import data from "virtual:panorama-data";
import { files } from "./docs.js";
import { useToast } from "./overlays.jsx";

// 学习：按 Godot 项目手册 README 的顺序列出各章，点章节在右边显示正文（构建时由 tools/manual.js 转成 HTML）。
// 正文里指向其他章节的链接切换章节，指向其他文档的链接在详情面板显示那张卡片。
const chapters = data.manual;
const groups = [...new Set(chapters.map((c) => c.group))];

// 离开学习模块再回来时停在上次读的章节；首页的链接也用它指定章节
let lastChapter = 0;
export function openChapter(k) { lastChapter = k; }

export default function LearnModule({ onSelect }) {
  const [chapter, setChapter] = useState(lastChapter);
  const pending = useRef("");
  const body = useRef(null);
  const toast = useToast();

  const scrollTo = (anchor) => {
    const target = anchor && document.getElementById(anchor);
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
      const m = mount(el, text, { fontSize: 13 });
      if (m.error) { m.destroy(); el.textContent = text; toast("图渲染失败：" + m.error.message); }
      else mounted.push(m);
    }
    scrollTo(pending.current);
    pending.current = "";
    return () => mounted.forEach((m) => m.destroy());
  }, [chapter, toast]);

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
  );
}
