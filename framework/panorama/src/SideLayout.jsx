import { useEffect, useState } from "react";
import { store } from "./store.js";

// 左侧目录 + 右侧正文，学习和问答共用。目录右边的分隔条照详情面板：拖动或按 ←→ 改宽度，双击恢复默认；
// 两个模块共用一个宽度，并记住。目录顶端和正文第一行对齐；hasHead 为真时（学习页有“上一处”“下一处”的标题行）停在标题行下面
const DEFAULT = 220, MIN = 160, MAX = 480;
const clamp = (w) => Math.round(Math.min(Math.max(MIN, w), MAX));

export default function SideLayout({ hasHead = false, label, ui, toc, children }) {
  const [width, setWidth] = useState(() => clamp(Number(store.get("toc-w")) || DEFAULT));
  useEffect(() => store.set("toc-w", String(width)), [width]);
  const drag = (e) => {
    const left = e.currentTarget.parentElement.getBoundingClientRect().left;
    e.currentTarget.setPointerCapture(e.pointerId);
    const move = (ev) => setWidth(clamp(ev.clientX - left));
    const up = () => { e.target.removeEventListener("pointermove", move); e.target.removeEventListener("pointerup", up); };
    e.target.addEventListener("pointermove", move);
    e.target.addEventListener("pointerup", up);
  };
  const key = (e) => {
    if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;
    e.preventDefault();
    setWidth((w) => clamp(w + (e.key === "ArrowRight" ? 16 : -16)));
  };
  return (
    <div className={"side-layout" + (hasHead ? " has-head" : "")} style={{ "--toc-w": width + "px" }}>
      <div className="side-toc-wrap">
        <nav className="side-toc" aria-label={label} data-ui={ui + ".toc"}>{toc}</nav>
        <div className="panel-resizer side-resizer" onPointerDown={drag} onDoubleClick={() => setWidth(DEFAULT)} onKeyDown={key} tabIndex={0}
          role="separator" aria-orientation="vertical" aria-label="拖动改目录宽度" data-tip={`拖动或按 ←→ 改宽度，双击恢复 ${DEFAULT}px`} data-ui={ui + ".toc-resizer"} />
      </div>
      {children}
    </div>
  );
}
