import { useEffect, useRef, useState } from "react";
import { IconSearch, IconX } from "@tabler/icons-react";

// 关键词用空格分开，每个词都要出现才算命中；不分大小写
export const words = (query) => query.toLowerCase().split(/\s+/).filter(Boolean);
export const matches = (ws, ...texts) => { const t = texts.join("　").toLowerCase(); return ws.every((w) => t.includes(w)); };

// 页面内搜索：页面标题行最右端的放大镜，点了在原处展开输入框；Esc 收起并清空，输入框为空时点到别处也收起。
// results 不为空时在输入框下列出命中项，名称命中的排前面；↑↓ 移动高亮，点一项或按 Enter 选高亮项交给 onPick。卡片页直接按 value 筛选，不传 results。
// open 为真时一直展开（全局搜索页）。
export default function PageSearch({ ui, value, onChange, placeholder, results, onPick, open: always = false }) {
  const [open, setOpen] = useState(always || value !== "");
  const [listOpen, setListOpen] = useState(true);
  const [active, setActive] = useState(0);
  const ws = words(value);
  const ranked = results && [...results].sort((a, b) => matches(ws, b.label) - matches(ws, a.label)).slice(0, 50);
  const input = useRef(null), box = useRef(null);
  useEffect(() => { if (open) input.current.focus(); }, [open]);
  // 带着关键词切到有结果列表的视图（例如文件全景从列表切到图谱）时，直接列出结果
  useEffect(() => { if (results) setListOpen(true); }, [Boolean(results)]);
  useEffect(() => {
    const click = (e) => { if (!box.current.contains(e.target)) { setListOpen(false); if (!always && !input.current?.value) setOpen(false); } };
    document.addEventListener("mousedown", click);
    return () => document.removeEventListener("mousedown", click);
  }, [always]);

  const close = () => { onChange(""); if (!always) setOpen(false); };
  const pick = (r) => { setListOpen(false); onPick(r); };
  const key = (e) => {
    // Esc 只收起搜索，不再传到全局去取消选中
    if (e.key === "Escape") { e.stopPropagation(); close(); }
    else if (e.key === "Enter" && ranked?.length) pick(ranked[Math.min(active, ranked.length - 1)]);
    else if ((e.key === "ArrowDown" || e.key === "ArrowUp") && ranked?.length) {
      e.preventDefault(); setListOpen(true);
      setActive((a) => (a + (e.key === "ArrowDown" ? 1 : ranked.length - 1)) % ranked.length);
    }
  };
  if (!open) {
    return (
      <div className="page-search" ref={box}>
        <button className="icon-btn" aria-label="搜索本页" data-tip="搜索本页" data-ui={ui} onClick={() => setOpen(true)}><IconSearch aria-hidden="true" /></button>
      </div>
    );
  }
  return (
    <div className="page-search open" ref={box}>
      <IconSearch className="page-search-icon" aria-hidden="true" />
      <input ref={input} className="search" type="text" placeholder={placeholder} aria-label={placeholder} data-ui={ui} value={value}
        onChange={(e) => { onChange(e.target.value); setListOpen(true); setActive(0); }} onKeyDown={key} onFocus={() => setListOpen(true)} />
      {!always && <button className="icon-btn" aria-label="关闭搜索" data-tip="关闭搜索（Esc）" onClick={close}><IconX aria-hidden="true" /></button>}
      {ranked && value.trim() && listOpen && (
        <ul className="search-list" role="listbox">
          {ranked.length ? ranked.map((r, i) => (
            <li key={r.key}><button role="option" aria-selected={i === active} ref={(el) => { if (el && i === active) el.scrollIntoView({ block: "nearest" }); }}
              onMouseEnter={() => setActive(i)} onClick={() => pick(r)}><span className="search-label">{r.label}</span><span className="count">{r.meta}</span></button></li>
          )) : <li className="empty-line">没有匹配的内容</li>}
        </ul>
      )}
    </div>
  );
}

// 页面标题行：左边是说明或页面工具，右边是搜索
export function PageHead({ children, search }) {
  return <div className="page-head"><div className="page-head-main">{children}</div>{search}</div>;
}
