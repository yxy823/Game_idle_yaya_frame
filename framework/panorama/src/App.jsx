import { useCallback, useEffect, useRef, useState } from "react";
import { IconLayoutSidebarRight, IconSettings } from "@tabler/icons-react";
import data from "virtual:panorama-data";
import DetailPanel from "./DetailPanel.jsx";
import SettingsMenu from "./SettingsMenu.jsx";
import { modules } from "./modules.jsx";
import { Picker, ToastProvider, Tooltip } from "./overlays.jsx";
import { store } from "./store.js";

// 页面布局照 VSCode：顶栏、左侧活动栏、主区域、右侧详情面板、底部状态栏。
// 详情面板收起时只隐藏、不移走，其他元素的位置不变。
// 主题直接写到 <html> 上，不等 React 的副作用：子组件（图谱）的副作用先于 App 执行，会读到旧主题的颜色
function applyTheme(theme) {
  if (theme === "system") document.documentElement.removeAttribute("data-theme");
  else document.documentElement.dataset.theme = theme;
  store.set("theme", theme);
}

export default function App() {
  const [module, setModule] = useState(() => (modules.some((m) => m.id === store.get("module")) ? store.get("module") : "home"));
  const [panelOpen, setPanelOpen] = useState(() => store.get("panel") !== "closed");
  const [theme, setTheme] = useState(() => { const t = store.get("theme") || "system"; applyTheme(t); return t; });
  const [picking, setPicking] = useState(() => store.get("picking") === "on");
  const [menuOpen, setMenuOpen] = useState(false);
  const [selected, setSelected] = useState(null);
  const [query, setQuery] = useState("");
  const settings = useRef(null);
  const closeMenu = useCallback(() => setMenuOpen(false), []);

  useEffect(() => store.set("module", module), [module]);
  useEffect(() => store.set("panel", panelOpen ? "open" : "closed"), [panelOpen]);
  useEffect(() => store.set("picking", picking ? "on" : "off"), [picking]);

  useEffect(() => {
    const key = (e) => {
      if (e.altKey && e.key.toLowerCase() === "x") { e.preventDefault(); setPicking((on) => !on); }
      else if (e.altKey && e.key.toLowerCase() === "b") { e.preventDefault(); setPanelOpen((open) => !open); }
      // Esc 先关元素选取，没在选取时取消选中的文档
      else if (e.key === "Escape") { if (picking) setPicking(false); else setSelected(null); }
    };
    document.addEventListener("keydown", key);
    return () => document.removeEventListener("keydown", key);
  }, [picking]);

  const panelLabel = panelOpen ? "收起详情面板" : "展开详情面板";
  const current = modules.find((m) => m.id === module);
  return (
    <ToastProvider>
      <header className="topbar" data-ui="topbar">
        <span className="title" data-ui="topbar.title">框架全景</span>
        <span className="spacer"></span>
        <input className="search" type="search" placeholder="搜索标题、用途、Skill、工具和术语" aria-label="搜索" data-ui="topbar.search"
          value={query} onChange={(e) => { setQuery(e.target.value); if (e.target.value.trim()) setModule("search"); }}
          onKeyDown={(e) => { if (e.key === "Enter") setModule("search"); }} />
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

      <div className={"workspace" + (panelOpen ? "" : " panel-closed")}>
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
            {current.render({ selected, onSelect: setSelected, theme, query })}
          </section>
        </main>
        <DetailPanel file={selected} onSelect={setSelected} />
      </div>

      <footer className="statusbar" data-ui="statusbar">
        <span data-ui="statusbar.generated">生成于 {data.generatedAt}，{data.files.length} 份文档</span>
        <span className="pick-state" data-ui="statusbar.pick-state">
          {picking ? "元素选取：开，点击元素即复制，按 Esc 关闭" : "元素选取：关（Alt+X）"}
        </span>
      </footer>

      {menuOpen && (
        <SettingsMenu anchor={settings} onClose={closeMenu} picking={picking} onTogglePicking={() => setPicking(!picking)}
          theme={theme} onTheme={(t) => { applyTheme(t); setTheme(t); }} />
      )}
      <Tooltip disabled={picking || menuOpen} />
      <Picker on={picking} />
    </ToastProvider>
  );
}
