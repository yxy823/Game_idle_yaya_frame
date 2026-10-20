import { Button } from "@/components/ui/button";
import { useEffect, useRef, useState } from "react";
import { CodeIcon, PanelRightIcon, PinIcon, PinOffIcon, XIcon } from "lucide-react";
import DocView from "./DocView.jsx";
import { files, vscodeUrl } from "./docs.js";
import { useTooltip } from "./overlays.jsx";

// 浮窗，照思源笔记：悬停文档链接一段时间后弹出，显示那篇文档的全文；浮窗里的链接照样能再弹一层。
// 能弹浮窗的元素：正文里的文档链接，和写了 data-float（卡片编号）的元素，例如详情面板的文档链接、关系图的点。
// 每层最多一个没钉住的浮窗，新弹出的挤掉同层和更深层没钉住的。鼠标停下 256ms 后按位置关闭：在第 L 层浮窗里，关掉比 L 深的；
// 不在任何浮窗里，关掉全部没钉住的。钉住的浮窗不关，并保住同一串里比它浅的层，前提是鼠标还在浮窗里。
// 点钉住按钮、双击标题栏切换钉住；拖动标题栏或拖边角改大小后自动钉住。点哪个浮窗，哪个到最上面。
const MIN_W = 240, MIN_H = 120, CLOSE_DELAY = 256;
const triggerOf = (el) => {
  const t = el?.closest?.(".learn-body a[data-card], [data-float]");
  if (!t) return null;
  const card = Number(t.dataset.float ?? t.dataset.card);
  return Number.isInteger(card) && card >= 0 ? { el: t, card } : null;
};
const DIRS = ["n", "s", "e", "w", "ne", "nw", "se", "sw"];

// width 是设置里选的浮窗宽度，只影响新弹出的浮窗
export default function FloatLayer({ mode, delay, width, disabled, onSelect, font }) {
  const [floats, setFloats] = useState([]);
  const ref = useRef(floats), seq = useRef(0), layer = useRef(null);
  ref.current = floats;
  const { hideTip } = useTooltip();
  const update = (id, patch) => setFloats((fs) => fs.map((f) => (f.id === id ? { ...f, ...(typeof patch === "function" ? patch(f) : patch) } : f)));
  const close = (keep) => setFloats((fs) => fs.filter(keep));
  const raise = (id) => { if (ref.current.length > 1) update(id, { z: ++seq.current }); };

  useEffect(() => {
    if (mode === "off" || disabled) return undefined;
    let openTimer = 0, hideTimer = 0, hovered = null, last = null;
    const open = (t) => {
      const fs = ref.current;
      if (fs.some((f) => f.trigger === t.el || (f.pinned && f.card === t.card))) return;
      const parent = fs.find((f) => f.id === Number(t.el.closest("[data-float-id]")?.dataset.floatId));
      const level = parent ? parent.level + 1 : 1;
      // 放在链接下方 4px；下方放不下而上方更宽时放到上方；高度最多占窗口的 60%
      const r = t.el.getBoundingClientRect(), vh = innerHeight, below = vh - r.bottom - 12, above = r.top - 8;
      const down = below >= vh * 0.6 || below >= above;
      const id = ++seq.current;
      hideTip();
      setFloats((list) => [...list.filter((f) => f.pinned || f.level < level), {
        id, card: t.card, trigger: t.el, level, chain: parent ? parent.chain : id, pinned: false, z: id,
        left: Math.max(8, Math.min(r.left, innerWidth - width - 8)), width,
        ...(down ? { top: r.bottom + 4 } : { bottom: vh - r.top + 8 }), maxHeight: Math.min(vh * 0.6, down ? below : above),
      }]);
    };
    // 鼠标停下后按所在位置决定关哪些：停在能弹浮窗的元素上不关
    const settle = () => {
      if (!last || triggerOf(last)) return;
      const fs = ref.current, at = fs.find((f) => f.id === Number(last.closest?.("[data-float-id]")?.dataset.floatId));
      if (!at) { if (fs.some((f) => !f.pinned)) close((f) => f.pinned); return; }
      const pinnedTop = {};
      for (const f of fs) if (f.pinned) pinnedTop[f.chain] = Math.max(pinnedTop[f.chain] ?? 0, f.level);
      const drop = (f) => !f.pinned && f.level > at.level && f.level > (pinnedTop[f.chain] ?? 0);
      if (fs.some(drop)) close((f) => !drop(f));
    };
    const over = (e) => {
      last = e.target;
      clearTimeout(hideTimer);
      hideTimer = setTimeout(settle, CLOSE_DELAY);
      const t = triggerOf(e.target);
      if (t?.el === hovered?.el) return;
      clearTimeout(openTimer);
      hovered = t;
      if (!t || e.altKey) return;
      if (mode === "hover") openTimer = setTimeout(() => open(t), delay);
      else if (e.ctrlKey) open(t);
    };
    // Ctrl 模式下先悬停再按 Ctrl 也弹出
    const key = (e) => { if (mode === "ctrl" && e.key === "Control" && hovered && !e.altKey) open(hovered); };
    // 按下鼠标取消还没弹出的浮窗，要再移到别的链接上才重新计时
    const down = () => { clearTimeout(openTimer); hovered = null; };
    document.addEventListener("mouseover", over);
    document.addEventListener("keydown", key);
    document.addEventListener("pointerdown", down, true);
    return () => {
      clearTimeout(openTimer); clearTimeout(hideTimer);
      document.removeEventListener("mouseover", over);
      document.removeEventListener("keydown", key);
      document.removeEventListener("pointerdown", down, true);
    };
  }, [mode, delay, width, disabled, hideTip]);

  // 拖动标题栏移动，拖边角改大小；动过就钉住。拖动时位置统一换成 top，上方弹出的浮窗也能往下拖
  const drag = (f, dir) => (e) => {
    if (e.button !== 0 || (!dir && e.target.closest("button, a"))) return;
    e.preventDefault();
    const box = layer.current.querySelector(`[data-float-id="${f.id}"]`).getBoundingClientRect();
    const x0 = e.clientX, y0 = e.clientY;
    const move = (m) => {
      const dx = m.clientX - x0, dy = m.clientY - y0;
      let { left, top, width, height } = { left: box.left, top: box.top, width: box.width, height: box.height };
      // 移动时标题栏不出窗口，否则按钮够不着
      if (!dir) { left = Math.max(0, Math.min(left + dx, innerWidth - width)); top = Math.max(0, Math.min(top + dy, innerHeight - 40)); }
      else {
        if (dir.includes("e")) width = Math.max(MIN_W, box.width + dx);
        if (dir.includes("s")) height = Math.max(MIN_H, box.height + dy);
        if (dir.includes("w")) { width = Math.max(MIN_W, box.width - dx); left = box.right - width; }
        if (dir.includes("n")) { height = Math.max(MIN_H, box.height - dy); top = box.bottom - height; }
      }
      update(f.id, { left, top, bottom: undefined, width, ...(dir ? { height, maxHeight: undefined } : {}), pinned: true });
    };
    const up = () => { removeEventListener("pointermove", move); removeEventListener("pointerup", up); };
    addEventListener("pointermove", move);
    addEventListener("pointerup", up);
  };

  // 浮窗正文里点文档链接：在详情面板打开，关掉没钉住的浮窗；链到本文锚点时只滚动
  const link = (f) => (i, anchor) => {
    if (i === f.card) { update(f.id, { jump: { anchor } }); return; }
    onSelect(i);
    close((x) => x.pinned);
  };
  const btn = (ui, tip, Icon, onClick, extra = {}) => (
    <Button variant="ghost" size="icon" className="icon-btn" aria-label={tip} data-tip={tip} data-ui={ui} onClick={onClick} {...extra}><Icon aria-hidden="true" /></Button>
  );
  return (
    <div className="float-layer" ref={layer} data-ui="float-layer">
      {floats.map((f) => (
        <div key={f.id} className="float" data-float-id={f.id} data-ui="float" onPointerDown={() => raise(f.id)}
          style={{ left: f.left, top: f.top, bottom: f.bottom, width: f.width, height: f.height, maxHeight: f.maxHeight, zIndex: f.z, "--float-ring": `var(--g-${files[f.card].group})` }}>
          <div className="float-head" data-ui="float.head" onPointerDown={drag(f)}
            onDoubleClick={(e) => { if (!e.target.closest("button, a")) update(f.id, (x) => ({ pinned: !x.pinned })); }}>
            <span className="min-w-0 flex-1 truncate" data-tip-clip>{files[f.card].title}</span>
            {btn("float.open-panel", "在详情面板打开", PanelRightIcon, () => { onSelect(f.card); close((x) => x.id !== f.id); })}
            <Button asChild variant="ghost" size="icon" className="icon-btn"><a href={vscodeUrl(f.card)} aria-label="在 VSCode 里打开" data-tip="在 VSCode 里打开" data-ui="float.vscode"><CodeIcon aria-hidden="true" /></a></Button>
            {btn("float.pin", f.pinned ? "取消钉住" : "钉住（双击标题栏也可以）", f.pinned ? PinOffIcon : PinIcon, () => update(f.id, { pinned: !f.pinned }), { "aria-pressed": f.pinned })}
            {btn("float.close", "关闭", XIcon, () => close((x) => x.id !== f.id))}
          </div>
          <div className="float-body learn-body" data-ui="float.body">
            <DocView card={f.card} jump={f.jump} font={font} onLink={link(f)} />
          </div>
          {DIRS.map((d) => <div key={d} className={"float-resize float-resize-" + d} onPointerDown={drag(f, d)} aria-hidden="true" />)}
        </div>
      ))}
    </div>
  );
}
