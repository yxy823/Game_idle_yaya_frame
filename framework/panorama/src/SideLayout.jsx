import { useContext, useEffect, useLayoutEffect, useRef, useState } from "react";
import { store } from "./store.js";
import { PickingContext } from "./overlays.jsx";
import { ResizablePanelGroup, ResizablePanel, ResizableHandle, dimension } from "@/components/ui/resizable";

// 左侧目录 + 右侧正文，学习和问答共用。目录右边的分隔条照详情面板：拖动或按 ←→ 改宽度，双击恢复默认；
// 两个模块共用一个宽度，并记住。目录顶端和正文第一行对齐；hasHead 为真时（学习页有“上一处”“下一处”的标题行）停在标题行下面
export default function SideLayout({ hasHead = false, label, ui, toc, children }) {
  const min = dimension("--toc-min"), max = dimension("--toc-max"), initial = dimension("--toc-default");
  const clamp = (w) => Math.round(Math.min(Math.max(min, w), max));
  const [width, setWidth] = useState(() => clamp(Number(store.get("toc-w")) || initial));
  const panel = useRef(null), picking = useContext(PickingContext);
  useEffect(() => store.set("toc-w", String(width)), [width]);
  useLayoutEffect(() => { panel.current.resize(width); }, [width]);
  const applyWidth = (w) => { const next = clamp(w); setWidth(next); panel.current.resize(next); };
  const key = (e) => {
    if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;
    e.preventDefault(); e.stopPropagation();
    applyWidth(panel.current.getSize().inPixels + (e.key === "ArrowRight" ? 1 : -1) * dimension("--resize-step"));
  };
  return <ResizablePanelGroup orientation="horizontal" disabled={picking} className={"side-layout" + (hasHead ? " has-head" : "")} style={{ overflow: "visible" }}
    resizeTargetMinimumSize={{ fine: dimension("--resize-hit"), coarse: dimension("--resize-hit") }}
    onLayoutChanged={(_, meta) => { if (meta.isUserInteraction) setWidth(Math.round(panel.current.getSize().inPixels)); }}>
    <ResizablePanel id={ui + "-toc"} panelRef={panel} minSize={min} maxSize={max} defaultSize={width} groupResizeBehavior="preserve-pixel-size" style={{ overflow: "visible" }}>
      <div className="side-toc-wrap"><nav className="side-toc" aria-label={label} data-ui={ui + ".toc"}>{toc}</nav></div>
    </ResizablePanel>
    <ResizableHandle disableDoubleClick onDoubleClick={() => applyWidth(initial)} onKeyDownCapture={key}
      aria-label="拖动改目录宽度" data-tip={`拖动或按 ←→ 改宽度，双击恢复 ${initial}px`} data-ui={ui + ".toc-resizer"} />
    <ResizablePanel id={ui + "-body"} minSize={0} style={{ overflow: "visible" }}>
      <div className="min-w-0 pl-6">{children}</div>
    </ResizablePanel>
  </ResizablePanelGroup>;
}
