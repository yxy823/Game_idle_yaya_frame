import { createContext, useContext, useEffect, useLayoutEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { IconSearch, IconX } from "@tabler/icons-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Command, CommandInput, CommandList, CommandEmpty, CommandItem } from "@/components/ui/command";
import { Popover, PopoverAnchor, PopoverContent } from "@/components/ui/popover";

// 关键词用空格分开，每个词都要出现才算命中；不分大小写
export const words = (query) => query.toLowerCase().split(/\s+/).filter(Boolean);
export const matches = (ws, ...texts) => { const t = texts.join("　").toLowerCase(); return ws.every((w) => t.includes(w)); };

// 顶栏页面名称右边留给当前页面搜索的位置，由 App 提供
export const SearchSlot = createContext(null);

// 页面内搜索：顶栏页面名称右边的放大镜，点了在原处展开输入框；Esc 收起并清空，输入框为空时点到别处也收起。
// 搜的是当前页面的内容，组件写在各页面里，用 portal 显示到顶栏，所以主区域不为它多占一行。
// results 不为空时在输入框下的弹出列表（Popover + Command）列出命中项，名称命中的排前面；↑↓ 移动高亮，点一项或按 Enter 选高亮项交给 onPick。
// 卡片页直接按 value 筛选，不传 results。open 为真时一直展开，并留在页面里（全局搜索页）。
export default function PageSearch(props) {
  const slot = useContext(SearchSlot);
  const node = <SearchBox {...props} />;
  return props.open || !slot ? node : createPortal(node, slot);
}

function SearchBox({ ui, value, onChange, placeholder, results, onPick, open: always = false }) {
  const [open, setOpen] = useState(always || value !== "");
  const [listOpen, setListOpen] = useState(true);
  const [active, setActive] = useState("");
  const ws = words(value);
  const ranked = results && [...results].sort((a, b) => matches(ws, b.label) - matches(ws, a.label)).slice(0, 50);
  const input = useRef(null), box = useRef(null), content = useRef(null), button = useRef(null), refocus = useRef(false);
  // 用 Esc 或关闭按钮收起时，焦点交回搜索按钮，键盘接着从这里走；点别处收起时焦点留在点的位置
  useLayoutEffect(() => {
    if (open) input.current.focus();
    else if (refocus.current) { refocus.current = false; button.current.focus(); }
  }, [open]);
  // 带着关键词切到有结果列表的视图（例如文件全景从列表切到图谱）时，直接列出结果
  useEffect(() => { if (results) setListOpen(true); }, [Boolean(results)]);
  useEffect(() => {
    const click = (e) => {
      if (box.current?.contains(e.target) || content.current?.contains(e.target)) return;
      setListOpen(false);
      if (!always && !input.current?.value) setOpen(false);
    };
    document.addEventListener("mousedown", click);
    return () => document.removeEventListener("mousedown", click);
  }, [always]);

  const close = () => {
    onChange("");
    setListOpen(false);
    if (!always) { refocus.current = true; setOpen(false); }
  };
  const pick = (r) => { setListOpen(false); onPick(r); };
  const current = ranked?.find((r) => String(r.key) === active) ?? ranked?.[0];
  // 键盘在输入框上捕获处理，焦点一直留在输入框里；Esc 只收起搜索，不再传到全局去取消选中
  const key = (e) => {
    if (e.key === "Escape") { e.preventDefault(); e.stopPropagation(); close(); }
    else if (e.key === "Enter" && current) { e.preventDefault(); e.stopPropagation(); pick(current); }
    else if ((e.key === "ArrowDown" || e.key === "ArrowUp") && ranked?.length) {
      e.preventDefault(); e.stopPropagation(); setListOpen(true);
      const at = ranked.indexOf(current);
      setActive(String(ranked[(at + (e.key === "ArrowDown" ? 1 : ranked.length - 1)) % ranked.length].key));
    }
  };
  const change = (next) => { onChange(next); setListOpen(true); setActive(""); };
  const inputProps = { ref: input, className: "search w-(--search-input-w) pl-7", type: "text", placeholder, "aria-label": placeholder,
    value, onKeyDownCapture: key, onFocus: () => setListOpen(true) };
  const shown = Boolean(open && ranked && value.trim() && listOpen);
  return (
    <Popover modal={false} open={shown} onOpenChange={setListOpen}>
      <Command shouldFilter={false} value={String(current?.key ?? "")} onValueChange={setActive}>
        <div className={"page-search" + (open ? " open" : "")} ref={box}>
          {!open ? (
            <Button ref={button} variant="ghost" size="icon" className="icon-btn" aria-label="搜索本页" data-tip="搜索本页" data-ui={ui} onClick={() => setOpen(true)}><IconSearch aria-hidden="true" /></Button>
          ) : <>
            <PopoverAnchor asChild><div className="relative flex items-center">
              <IconSearch className="page-search-icon" aria-hidden="true" />
              {ranked ? <CommandInput {...inputProps} data-ui={ui} onValueChange={change} /> : <Input {...inputProps} data-ui={ui} onChange={(e) => change(e.target.value)} />}
            </div></PopoverAnchor>
            {!always && <Button variant="ghost" size="icon" className="icon-btn" aria-label="关闭搜索" data-tip="关闭搜索（Esc）" onClick={close}><IconX aria-hidden="true" /></Button>}
          </>}
        </div>
        {/* 弹出列表不抢焦点，点列表外也不由 Radix 关闭：收起规则由上面的 mousedown 统一处理 */}
        <PopoverContent ref={content} className="search-list" onOpenAutoFocus={(e) => e.preventDefault()} onCloseAutoFocus={(e) => e.preventDefault()}
          onInteractOutside={(e) => e.preventDefault()} onEscapeKeyDown={(e) => { e.preventDefault(); e.stopPropagation(); close(); }}>
          <CommandList>
            <CommandEmpty>没有匹配的内容</CommandEmpty>
            {ranked?.map((r) => <CommandItem key={r.key} value={String(r.key)} onSelect={() => pick(r)}
              onMouseEnter={() => setActive(String(r.key))} onMouseDown={(e) => e.preventDefault()}>
              <span className="search-label truncate">{r.label}</span><span className="count">{r.meta}</span>
            </CommandItem>)}
          </CommandList>
        </PopoverContent>
      </Command>
    </Popover>
  );
}

// 页面标题行：左边是说明或页面工具；没有说明和工具时不占一行。
// 搜索始终放在同一个位置：标题行出现或消失时搜索框不重新挂载，否则正在输入的字会丢
export function PageHead({ children, search }) {
  return <>{children && <div className="page-head"><div className="page-head-main">{children}</div></div>}{search}</>;
}
