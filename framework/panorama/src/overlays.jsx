import { createContext, useCallback, useContext, useEffect, useLayoutEffect, useRef, useState } from "react";
import { toast as notify } from "sonner";
import { Toaster } from "@/components/ui/sonner";
import { Tooltip as UiTooltip, TooltipProvider, TooltipTrigger, TooltipContent } from "@/components/ui/tooltip";

// 浮在页面上的三样东西：底部提示、悬浮提示、元素选取框。都带 data-pick-ignore，选取时不会选中它们自己。
// 元素选取是否打开；打开时分隔条不响应拖动，点它只复制
export const PickingContext = createContext(false);
const ToastContext = createContext(() => {});
const TipContext = createContext(null);
export const useToast = () => useContext(ToastContext);
export const useTooltip = () => useContext(TipContext);

export function ToastProvider({ children, theme }) {
  const timer = useRef(0), id = useRef(null);
  const [tip, setTip] = useState(null);
  const showTip = useCallback((value) => setTip(value), []);
  const hideTip = useCallback(() => setTip(null), []);
  const toast = useCallback((value) => {
    id.current = notify(value, id.current === null ? {} : { id: id.current });
    clearTimeout(timer.current);
    timer.current = setTimeout(() => { notify.dismiss(id.current); id.current = null; }, 1800);
  }, []);
  useEffect(() => () => { clearTimeout(timer.current); }, []);
  return <ToastContext.Provider value={toast}>
    <TipContext.Provider value={{ tip, showTip, hideTip }}>{children}</TipContext.Provider>
    <div data-pick-ignore><Toaster theme={theme} /></div>
  </ToastContext.Provider>;
}

// 悬浮提示：元素上写 data-tip，这一个组件统一显示。400ms 延迟；300ms 内移到相邻元素时立即显示。活动栏的提示放在按钮右边，其余放在下方。
// 带 data-tip-clip 的元素只在文字被截断时提示，内容就是它的全文。
// 底层是一个 Radix Tooltip，锚在一个叠在目标元素上的代理 span 上，不逐个元素包 <Tooltip>
export function Tooltip({ disabled }) {
  const { tip, showTip, hideTip } = useTooltip();
  const proxy = useRef(null);
  useEffect(() => {
    let timer = 0, leftAt = 0, current = null, visible = false;
    const hide = () => { clearTimeout(timer); if (visible) leftAt = Date.now(); visible = false; current = null; hideTip(); };
    // 显示时量一次元素位置，代理锚点放到那里，由 Radix 摆放提示
    const show = () => {
      visible = true;
      const r = current.getBoundingClientRect();
      showTip({ text: current.dataset.tip ?? current.textContent, target: current,
        rect: { left: r.left, top: r.top, width: r.width, height: r.height }, side: current.closest(".activity") ? "right" : "bottom" });
    };
    const over = (e) => {
      let el = e.target.closest("[data-tip], [data-tip-clip]");
      if (el && !("tip" in el.dataset) && el.scrollWidth <= el.clientWidth) el = null;
      if (el === current) return;
      hide();
      if (!el || disabled) return;
      current = el;
      timer = setTimeout(show, Date.now() - leftAt < 300 ? 0 : 400);
    };
    const out = (e) => { if (!e.relatedTarget) hide(); };
    const focusOut = (e) => { if (!current?.contains(e.relatedTarget)) hide(); };
    const key = (e) => { if (e.key === "Escape") hide(); };
    document.addEventListener("mouseover", over);
    document.addEventListener("focusin", over);
    document.addEventListener("focusout", focusOut);
    document.addEventListener("mouseout", out);
    document.addEventListener("mousedown", hide);
    document.addEventListener("keydown", key);
    window.addEventListener("blur", hide);
    if (disabled) hide();
    return () => {
      hide();
      document.removeEventListener("mouseover", over); document.removeEventListener("focusin", over);
      document.removeEventListener("focusout", focusOut); document.removeEventListener("mouseout", out);
      document.removeEventListener("mousedown", hide); document.removeEventListener("keydown", key); window.removeEventListener("blur", hide);
    };
  }, [disabled, showTip, hideTip]);
  useLayoutEffect(() => {
    if (!tip?.target) return;
    const target = tip.target, previous = target.getAttribute("aria-describedby");
    const id = proxy.current.getAttribute("aria-describedby");
    target.setAttribute("aria-describedby", [previous, id].filter(Boolean).join(" "));
    return () => { if (previous === null) target.removeAttribute("aria-describedby"); else target.setAttribute("aria-describedby", previous); };
  }, [tip?.target]);
  const css = getComputedStyle(document.documentElement);
  return <TooltipProvider delayDuration={0} disableHoverableContent>
    <UiTooltip open={Boolean(tip) && !disabled} onOpenChange={(open) => { if (!open) hideTip(); }}>
      <TooltipTrigger asChild><span ref={proxy} aria-hidden="true" tabIndex={-1} data-pick-ignore
        className="pointer-events-none fixed" style={tip?.rect} /></TooltipTrigger>
      <TooltipContent side={tip?.side ?? "bottom"} sideOffset={parseFloat(css.getPropertyValue("--tip-offset"))} collisionPadding={parseFloat(css.getPropertyValue("--tip-edge"))}>{tip?.text}</TooltipContent>
    </UiTooltip>
  </TooltipProvider>;
}

// 元素选取：开关打开后，悬停显示元素名称、文字和源文件行号，点击直接复制。
function target(el) {
  const hit = el.closest("[data-ui]");
  return hit && !hit.closest("[data-pick-ignore]") ? hit : null;
}

function describe(el) {
  const raw = (el.matches("input") ? el.placeholder : el.innerText || "").replace(/\s+/g, " ").trim();
  const text = raw.length > 24 ? raw.slice(0, 24) + "…" : raw;
  return el.dataset.ui + (text ? "「" + text + "」" : "") + "（" + el.dataset.src + "）";
}

// 先用 navigator.clipboard；它被拒绝时（例如没有剪贴板权限）改用选中文本框再复制
function copyByTextarea(text) {
  const area = Object.assign(document.createElement("textarea"), { value: text });
  document.body.append(area); area.select();
  const ok = document.execCommand("copy"); area.remove();
  return ok ? Promise.resolve() : Promise.reject(new Error("copy"));
}
function copyText(text) {
  return navigator.clipboard ? navigator.clipboard.writeText(text).catch(() => copyByTextarea(text)) : copyByTextarea(text);
}

export function Picker({ on }) {
  const box = useRef(null), label = useRef(null);
  const toast = useToast();
  useEffect(() => {
    document.body.classList.toggle("picking", on);
    box.current.hidden = true; label.current.hidden = true;
    if (!on) return undefined;
    const move = (e) => {
      const el = target(e.target);
      if (!el) { box.current.hidden = true; label.current.hidden = true; return; }
      const r = el.getBoundingClientRect();
      Object.assign(box.current.style, { left: r.left + "px", top: r.top + "px", width: r.width + "px", height: r.height + "px" });
      box.current.hidden = false; label.current.textContent = describe(el); label.current.hidden = false;
      label.current.style.left = Math.max(4, Math.min(r.left, innerWidth - label.current.offsetWidth - 4)) + "px";
      label.current.style.top = (r.top >= 22 ? r.top - 20 : r.bottom + 2) + "px";
    };
    // 设置按钮照常打开菜单，否则选取时无法从菜单关掉开关
    const click = (e) => {
      if (e.target.closest("[data-pick-ignore], [data-ui='topbar.settings']")) return;
      const el = target(e.target);
      if (!el) return;
      e.preventDefault(); e.stopPropagation();
      const text = describe(el);
      copyText(text).then(() => toast("已复制：" + text), () => toast("复制失败：" + text));
    };
    const press = (e) => {
      if (e.target.closest("[data-pick-ignore], [data-ui='topbar.settings']") || !target(e.target)) return;
      e.preventDefault(); e.stopPropagation();
    };
    document.addEventListener("pointerdown", press, true);
    document.addEventListener("mousedown", press, true);
    document.addEventListener("mousemove", move);
    document.addEventListener("click", click, true);
    return () => {
      document.body.classList.remove("picking");
      document.removeEventListener("pointerdown", press, true);
      document.removeEventListener("mousedown", press, true);
      document.removeEventListener("mousemove", move);
      document.removeEventListener("click", click, true);
    };
  }, [on, toast]);
  return (
    <>
      <div className="pick-box" hidden ref={box} data-pick-ignore />
      <div className="pick-label" hidden ref={label} data-pick-ignore />
    </>
  );
}
