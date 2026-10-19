import { useEffect, useRef } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { IconLayoutSidebarRight } from "@tabler/icons-react";
import { mount } from "pele";
import data from "virtual:panorama-data";
import { fontSize } from "./Diagram.jsx";
import { useToast } from "./overlays.jsx";

// 一份文档的正文：HTML 在构建时由 tools/manual.js 的 renderHtml 生成，Mermaid 图用 Pele 渲染。学习模块和文件全景的阅读视图共用。
// jump 是 { anchor } 或 { row } 对象，每次要滚动都换一个新对象：anchor 为空滚到开头，为 FIRST_MATCH 滚到第一处搜索命中；
// row 是表格某一行第一格的文字，滚到这一行并高亮（术语表、工具表的一行）。
// 正文里指向仓库文档的链接交给 onLink(卡片编号, 锚点)，由页面决定切换章节、打开文档还是滚动。
// inPanel(卡片编号) 为真的链接在详情面板打开，后面加面板图标，和页面内切换的链接区分。onHits(命中数) 在每次高亮后调用。
export const FIRST_MATCH = "#first-match";
const PANEL_ICON = renderToStaticMarkup(<IconLayoutSidebarRight className="link-icon" aria-hidden="true" />);
const pattern = (ws) => ws.map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|");

// 给正文里的命中词加 <mark>，Mermaid 图里的文字不加；先去掉上一次加的
function highlight(root, ws) {
  for (const m of root.querySelectorAll("mark.hit")) m.replaceWith(m.textContent);
  root.normalize();
  if (!ws.length) return;
  const re = new RegExp("(" + pattern(ws) + ")", "gi");
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, { acceptNode: (n) => (n.parentElement.closest(".manual-diagram") ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT) });
  const nodes = [];
  while (walker.nextNode()) nodes.push(walker.currentNode);
  for (const node of nodes) {
    const parts = node.nodeValue.split(re);
    if (parts.length === 1) continue;
    node.replaceWith(...parts.map((t, i) => { if (i % 2 === 0) return t; const m = document.createElement("mark"); m.className = "hit"; m.textContent = t; return m; }));
  }
}

export default function DocView({ card, jump, words = [], onLink, inPanel, onHits, font }) {
  const body = useRef(null);
  const hitsRef = useRef(onHits);
  hitsRef.current = onHits;
  const mark = (ws) => { highlight(body.current, ws); hitsRef.current?.(body.current.querySelectorAll("mark.hit").length); };
  const toast = useToast();
  const key = words.join(" ");
  const wordsRef = useRef(words);
  wordsRef.current = words;

  useEffect(() => {
    // 正文由这里写入，不交给 React：React 重新渲染时可能重写 innerHTML，冲掉已经渲染好的图
    body.current.innerHTML = data.html[card];
    if (inPanel) {
      for (const a of body.current.querySelectorAll("a[data-card]")) {
        if (inPanel(Number(a.dataset.card))) { a.insertAdjacentHTML("beforeend", PANEL_ICON); a.dataset.tip = "在详情面板打开"; }
      }
    }
    const mounted = [];
    for (const el of body.current.querySelectorAll(".manual-diagram")) {
      const text = el.textContent;
      el.textContent = "";
      const m = mount(el, text, { fontSize: fontSize() });
      if (m.error) { m.destroy(); el.textContent = text; toast("图渲染失败：" + m.error.message); }
      else mounted.push(m);
    }
    mark(wordsRef.current);
    return () => mounted.forEach((m) => m.destroy());
  }, [card, toast, font]);
  useEffect(() => { mark(key ? key.split(" ") : []); }, [key]);
  useEffect(() => {
    const anchor = jump?.anchor;
    const row = jump?.row && [...body.current.querySelectorAll("tr")].find((tr) => tr.cells[0]?.textContent.trim() === jump.row);
    row?.classList.add("hit-row");
    const target = row || (anchor === FIRST_MATCH ? body.current.querySelector("mark.hit") : anchor && document.getElementById(anchor));
    if (row) row.scrollIntoView({ block: "center" });
    else if (target) target.scrollIntoView();
    // 文件全景的阅读视图自己滚动（.doc-scroll），详情面板里随面板滚动，学习模块随主区域滚动
    else (body.current.closest(".doc-scroll, .panel, .main")).scrollTop = 0;
  }, [card, jump]);

  const click = (e) => {
    const a = e.target.closest("a[data-card]");
    if (!a) return;
    e.preventDefault();
    onLink(Number(a.dataset.card), decodeURIComponent(a.dataset.anchor || ""));
  };
  return <div ref={body} onClick={click} />;
}
