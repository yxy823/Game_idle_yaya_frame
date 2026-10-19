import { useCallback, useEffect, useRef, useState } from "react";
import { IconLayoutSidebarRight, IconSettings } from "@tabler/icons-react";
import data from "virtual:panorama-data";
import godotIcon from "./assets/godot-icon.webp";
import DetailPanel, { titleOf } from "./DetailPanel.jsx";
import { openChapter } from "./LearnModule.jsx";
import SettingsMenu from "./SettingsMenu.jsx";
import { modules } from "./modules.jsx";
import { SearchSlot } from "./PageSearch.jsx";
import { Picker, ToastProvider, Tooltip, useToast } from "./overlays.jsx";
import { fonts, store } from "./store.js";

// 页面布局照 VSCode：顶栏、左侧活动栏、主区域、右侧详情面板、底部状态栏。
// 详情面板收起时只隐藏、不移走，其他元素的位置不变。
// 主题直接写到 <html> 上，不等 React 的副作用：子组件（图谱）的副作用先于 App 执行，会读到旧主题的颜色
function applyTheme(theme) {
  if (theme === "system") document.documentElement.removeAttribute("data-theme");
  else document.documentElement.dataset.theme = theme;
  store.set("theme", theme);
}
// 字号同理写到 <html> 上，样式里的 --fs 等变量跟着换
function applyFont(font) {
  document.documentElement.dataset.font = font;
  store.set("font", font);
}

// 详情面板收起时选中了对象，用底部提示告诉用户选中了什么、怎样展开面板；要放在 ToastProvider 里面才能用提示
function PanelNotice({ notice, panelOpen }) {
  const toast = useToast();
  useEffect(() => { if (notice && !panelOpen) toast("已在详情面板显示：" + titleOf(notice.value) + "（Alt+B 展开）"); }, [notice]);
  return null;
}

export default function App() {
  const [module, setModule] = useState(() => (modules.some((m) => m.id === store.get("module")) ? store.get("module") : "home"));
  const [panelWidth, setPanelWidth] = useState(() => Number(store.get("panel-w")) || 320);
  const [panelOpen, setPanelOpen] = useState(() => store.get("panel") !== "closed");
  const [theme, setTheme] = useState(() => { const t = store.get("theme") || "system"; applyTheme(t); return t; });
  const [font, setFont] = useState(() => { const f = fonts.some(([id]) => id === store.get("font")) ? store.get("font") : "m"; applyFont(f); return f; });
  const [picking, setPicking] = useState(() => store.get("picking") === "on");
  const [menuOpen, setMenuOpen] = useState(false);
  // 每个模块各记自己的选中历史：切回一个模块时，详情面板显示它上次选中的；没选过就是空状态。
  // 选中新对象时丢掉当前位置之后的记录，详情面板的后退、前进在本模块的记录里移动。
  // setSelected 只随模块变，图谱靠它不变来避免重建
  const [selection, setSelection] = useState({});
  const [notice, setNotice] = useState(null);
  const trail = selection[module] ?? { list: [null], at: 0 };
  const selected = trail.list[trail.at];
  const setSelected = useCallback((value) => {
    setSelection((s) => {
      const t = s[module] ?? { list: [null], at: 0 };
      if (t.list[t.at] === value) return s;
      return { ...s, [module]: { list: [...t.list.slice(0, t.at + 1), value], at: t.at + 1 } };
    });
    if (value !== null) setNotice({ value });
  }, [module]);
  const step = (d) => setSelection((s) => ({ ...s, [module]: { ...trail, at: trail.at + d } }));
  const settings = useRef(null);
  const [searchSlot, setSearchSlot] = useState(null);
  const closeMenu = useCallback(() => setMenuOpen(false), []);

  useEffect(() => store.set("module", module), [module]);
  useEffect(() => store.set("panel", panelOpen ? "open" : "closed"), [panelOpen]);
  useEffect(() => store.set("panel-w", String(panelWidth)), [panelWidth]);
  // 窗口窄到主区域不足 480px 时先收起面板（按默认 320px 宽算），开关状态和实际一致；之后要看面板可以再展开
  useEffect(() => {
    const narrow = matchMedia("(max-width: 844px)");
    const fold = () => { if (narrow.matches) setPanelOpen(false); };
    fold();
    narrow.addEventListener("change", fold);
    return () => narrow.removeEventListener("change", fold);
  }, []);
  // 分隔条也能用键盘改宽度：←→ 每次 16px
  const resizeKey = (e) => {
    if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;
    e.preventDefault();
    const ws = e.currentTarget.parentElement.getBoundingClientRect();
    setPanelWidth((w) => Math.min(Math.max(240, w + (e.key === "ArrowLeft" ? 16 : -16)), ws.width - 44 - 480));
  };
  // 拖面板左边缘改宽度：最窄 240px，最宽留给主区域 480px（同「窄窗口」一条）
  const drag = (e) => {
    const ws = e.currentTarget.parentElement.getBoundingClientRect();
    e.currentTarget.setPointerCapture(e.pointerId);
    const move = (ev) => setPanelWidth(Math.round(Math.min(Math.max(240, ws.right - ev.clientX), ws.width - 44 - 480)));
    const up = () => { e.target.removeEventListener("pointermove", move); e.target.removeEventListener("pointerup", up); };
    e.target.addEventListener("pointermove", move);
    e.target.addEventListener("pointerup", up);
  };
  useEffect(() => store.set("picking", picking ? "on" : "off"), [picking]);
  // 学习模块的章节切换写进浏览器历史；在别的模块按浏览器后退回到上一章时，切回学习模块
  useEffect(() => {
    const pop = (e) => { if (e.state && "chapter" in e.state) { openChapter(e.state.chapter); setModule("learn"); } };
    addEventListener("popstate", pop);
    return () => removeEventListener("popstate", pop);
  }, []);

  useEffect(() => {
    const key = (e) => {
      if (e.altKey && e.key.toLowerCase() === "x") { e.preventDefault(); setPicking((on) => !on); }
      else if (e.altKey && e.key.toLowerCase() === "b") { e.preventDefault(); setPanelOpen((open) => !open); }
      // Esc 先关元素选取，没在选取时取消选中的文档
      else if (e.key === "Escape") { if (picking) setPicking(false); else setSelected(null); }
    };
    document.addEventListener("keydown", key);
    return () => document.removeEventListener("keydown", key);
  }, [picking, setSelected]);

  const panelLabel = panelOpen ? "收起详情面板" : "展开详情面板";
  const current = modules.find((m) => m.id === module);
  return (
    <ToastProvider>
      <header className="topbar" data-ui="topbar">
        <img className="brand" src={godotIcon} alt="框架全景" data-tip="框架全景" data-ui="topbar.brand" />
        <span className="title" data-ui="topbar.title">{current.label}</span>
        <span className="search-slot" ref={setSearchSlot}></span>
        <span className="spacer"></span>
        <button className="icon-btn" aria-label={panelLabel} data-tip={panelLabel + "（Alt+B）"} data-ui="topbar.panel-toggle"
          onClick={() => setPanelOpen(!panelOpen)}>
          <IconLayoutSidebarRight aria-hidden="true" />
        </button>
        <span className="divider"></span>
        <button className="icon-btn" ref={settings} aria-label="设置" aria-haspopup="menu" aria-expanded={menuOpen} data-tip="设置" data-ui="topbar.settings"
          onClick={() => setMenuOpen(!menuOpen)}>
          <IconSettings aria-hidden="true" />
        </button>
      </header>

      <div className={"workspace" + (panelOpen ? "" : " panel-closed")} style={{ "--panel-w": panelWidth + "px" }}>
        <nav className="activity" aria-label="模块" data-ui="activity">
          {modules.map((m) => (
            <button key={m.id} className="icon-btn" aria-label={m.label} data-tip={m.tip} data-ui={"activity." + m.id}
              aria-current={m.id === module ? "page" : undefined} onClick={() => setModule(m.id)}>
              <m.Icon aria-hidden="true" />
            </button>
          ))}
        </nav>
        <main className="main">
          <section className="module" data-ui={"module." + module}>
            <SearchSlot.Provider value={searchSlot}>
              {current.render({ selected, onSelect: setSelected, theme, font, onModule: setModule })}
            </SearchSlot.Provider>
          </section>
        </main>
        {panelOpen && <div className="panel-resizer" style={{ right: panelWidth - 3 }} onPointerDown={drag} onDoubleClick={() => setPanelWidth(320)} onKeyDown={resizeKey} tabIndex={0}
          role="separator" aria-orientation="vertical" aria-label="拖动改详情面板宽度" data-tip="拖动或按 ←→ 改宽度，双击恢复 320px" data-ui="panel.resizer" />}
        <DetailPanel file={selected} onSelect={setSelected} font={font}
          onBack={trail.at > 0 ? () => step(-1) : null} onForward={trail.at < trail.list.length - 1 ? () => step(1) : null} />
      </div>

      <footer className="statusbar" data-ui="statusbar">
        <span data-ui="statusbar.generated">生成于 {data.generatedAt}，{data.files.length} 份文档</span>
        <span className="pick-state" data-ui="statusbar.pick-state">
          {picking ? "元素选取：开，点击元素即复制，按 Esc 关闭" : "元素选取：关（Alt+X）"}
        </span>
      </footer>

      {menuOpen && (
        <SettingsMenu anchor={settings} onClose={closeMenu} picking={picking} onTogglePicking={() => setPicking(!picking)}
          theme={theme} onTheme={(t) => { applyTheme(t); setTheme(t); }}
          font={font} onFont={(f) => { applyFont(f); setFont(f); }} />
      )}
      <PanelNotice notice={notice} panelOpen={panelOpen} />
      <Tooltip disabled={picking || menuOpen} />
      <Picker on={picking} />
    </ToastProvider>
  );
}
