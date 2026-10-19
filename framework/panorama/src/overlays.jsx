import { createContext, useCallback, useContext, useEffect, useRef, useState } from "react";

// 浮在页面上的三样东西：底部提示、悬浮提示、元素选取框。都带 data-pick-ignore，选取时不会选中它们自己。

const ToastContext = createContext(() => {});
export const useToast = () => useContext(ToastContext);

export function ToastProvider({ children }) {
  const [text, setText] = useState("");
  const timer = useRef(0);
  const toast = useCallback((value) => {
    setText(value);
    clearTimeout(timer.current);
    timer.current = setTimeout(() => setText(""), 1800);
  }, []);
  return (
    <ToastContext.Provider value={toast}>
      {children}
      <div className="toast" role="status" hidden={!text} data-pick-ignore>{text}</div>
    </ToastContext.Provider>
  );
}

// 悬浮提示：400ms 延迟；300ms 内移到相邻元素时立即显示。活动栏的提示放在按钮右边，其余放在下方。
export function Tooltip({ disabled }) {
  const ref = useRef(null);
  useEffect(() => {
    const tip = ref.current;
    let timer = 0, leftAt = 0, current = null;
    const hide = () => { clearTimeout(timer); if (!tip.hidden) leftAt = Date.now(); tip.hidden = true; current = null; };
    const place = (el) => {
      const r = el.getBoundingClientRect();
      tip.textContent = el.dataset.tip; tip.hidden = false;
      let left = r.left + r.width / 2 - tip.offsetWidth / 2, top = r.bottom + 6;
      left = Math.max(8, Math.min(left, innerWidth - tip.offsetWidth - 8));
      if (top + tip.offsetHeight > innerHeight - 8) top = r.top - 6 - tip.offsetHeight;
      if (el.closest(".activity")) { left = r.right + 6; top = r.top + r.height / 2 - tip.offsetHeight / 2; }
      tip.style.left = left + "px"; tip.style.top = top + "px";
    };
    const over = (e) => {
      const el = e.target.closest("[data-tip]");
      if (el === current) return;
      hide();
      if (!el || disabled) return;
      current = el;
      timer = setTimeout(() => place(el), Date.now() - leftAt < 300 ? 0 : 400);
    };
    const key = (e) => { if (e.key === "Escape") hide(); };
    document.addEventListener("mouseover", over);
    document.addEventListener("mousedown", hide);
    document.addEventListener("keydown", key);
    return () => {
      hide();
      document.removeEventListener("mouseover", over);
      document.removeEventListener("mousedown", hide);
      document.removeEventListener("keydown", key);
    };
  }, [disabled]);
  return <div className="tip" role="tooltip" hidden ref={ref} data-pick-ignore />;
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
    document.addEventListener("mousemove", move);
    document.addEventListener("click", click, true);
    return () => {
      document.body.classList.remove("picking");
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
