import { Button } from "@/components/ui/button";
import { useCallback, useEffect, useRef, useState } from "react";
import { PanelRightIcon, SettingsIcon } from "lucide-react";
import data from "virtual:panorama-data";
import godotIcon from "./assets/godot-icon.webp";
import DetailPanel, { titleOf } from "./DetailPanel.jsx";
import { openChapter } from "./LearnModule.jsx";
import SettingsDialog from "./SettingsDialog.jsx";
import { modules } from "./modules.jsx";
import { SearchSlot } from "./PageSearch.jsx";
import { Picker, ToastProvider, Tooltip, useToast } from "./overlays.jsx";
import { floatDelay as delayRange, floatModes, floatWidth as widthRange, fonts, savedNumber, store } from "./store.js";
import FloatLayer from "./Float.jsx";
import { Separator } from "@/components/ui/separator";
import { ResizablePanelGroup, ResizablePanel, ResizableHandle, dimension } from "@/components/ui/resizable";
import { PickingContext } from "./overlays.jsx";

// 页面名称按最长的模块名留宽度，切换模块时右边的搜索按钮不移位
const titleChars = Math.max(...modules.map((m) => m.label.length));

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
  // 记下的是拖出来的宽度；实际宽度再按窗口限制，最宽给主区域留 480px，窗口变窄时面板跟着变窄，窗口变宽后恢复
  const panelMin = dimension("--panel-min"), panelDefault = dimension("--panel-default"), mainMin = dimension("--main-min"), activityWidth = dimension("--activity-w");
  const detail = useRef(null);
  const [panelWidth, setPanelWidth] = useState(() => { const w = Number(store.get("panel-w")); return Number.isFinite(w) && w >= panelMin ? w : panelDefault; });
  const [winWidth, setWinWidth] = useState(innerWidth);
  useEffect(() => { const r = () => setWinWidth(innerWidth); addEventListener("resize", r); return () => removeEventListener("resize", r); }, []);
  const limit = Math.max(panelMin, winWidth - activityWidth - mainMin);
  const shownWidth = Math.min(panelWidth, limit);
  const [panelOpen, setPanelOpen] = useState(() => store.get("panel") !== "closed");
  const [theme, setTheme] = useState(() => { const t = store.get("theme") || "system"; applyTheme(t); return t; });
  const [font, setFont] = useState(() => { const f = fonts.some(([id]) => id === store.get("font")) ? store.get("font") : "m"; applyFont(f); return f; });
  const [picking, setPicking] = useState(() => store.get("picking") === "on");
  const pickSaved = (list, key, fallback) => (list.some(([id]) => id === store.get(key)) ? store.get(key) : fallback);
  const [floatMode, setFloatMode] = useState(() => pickSaved(floatModes, "float.mode", "hover"));
  const [floatDelay, setFloatDelay] = useState(() => savedNumber("float.delay", delayRange));
  const [floatWidth, setFloatWidth] = useState(() => savedNumber("float.width", widthRange));
  const [settingsOpen, setSettingsOpen] = useState(false);
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
  const [searchSlot, setSearchSlot] = useState(null);

  useEffect(() => store.set("module", module), [module]);
  useEffect(() => store.set("panel", panelOpen ? "open" : "closed"), [panelOpen]);
  useEffect(() => store.set("panel-w", String(panelWidth)), [panelWidth]);
  // 窗口窄到主区域不足 480px 时先收起面板（按默认 420px 宽算），开关状态和实际一致；之后要看面板可以再展开
  useEffect(() => {
    const narrow = matchMedia("(max-width: 944px)");
    const fold = () => { if (narrow.matches) setPanelOpen(false); };
    fold();
    narrow.addEventListener("change", fold);
    return () => narrow.removeEventListener("change", fold);
  }, []);
  // 拖面板左边缘改宽度：最窄 240px，最宽留给主区域 480px（同「窄窗口」一条）
  const applyWidth = (width) => {
    const next = Math.round(Math.max(panelMin, Math.min(width, limit)));
    setPanelWidth(next);
    detail.current.resize(next);
  };
  useEffect(() => { detail.current.resize(panelOpen ? shownWidth : 0); }, [panelOpen, shownWidth]);
  // 分隔条也能用键盘改宽度：←→ 每次 16px
  const resizeKey = (e) => {
    if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;
    e.preventDefault(); e.stopPropagation();
    applyWidth(detail.current.getSize().inPixels + (e.key === "ArrowLeft" ? 1 : -1) * dimension("--resize-step"));
  };
  useEffect(() => store.set("picking", picking ? "on" : "off"), [picking]);
  useEffect(() => { store.set("float.mode", floatMode); store.set("float.delay", String(floatDelay)); store.set("float.width", String(floatWidth)); }, [floatMode, floatDelay, floatWidth]);
  // 学习模块的章节切换写进浏览器历史；在别的模块按浏览器后退回到上一章时，切回学习模块
  useEffect(() => {
    const pop = (e) => { if (e.state && "chapter" in e.state) { openChapter(e.state.chapter, e.state.anchor); setModule("learn"); } };
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
    <ToastProvider theme={theme}>
    <PickingContext.Provider value={picking}>
      <header className="topbar flex items-center gap-2 px-2 bg-(--chrome) border-b border-border" data-ui="topbar">
        <img className="brand size-5 ml-1" src={godotIcon} alt="框架全景" data-tip="框架全景" data-ui="topbar.brand" />
        {/* 中文字形落在基线附近，按盒子居中时比 Godot 图标和放大镜低约 1px，上移补齐 */}
        <span className="title relative -top-px flex-none px-1 font-semibold whitespace-nowrap w-[calc(var(--title-chars)*1em+8px)]" style={{ "--title-chars": titleChars }} data-ui="topbar.title">{current.label}</span>
        <span className="search-slot flex items-center" ref={setSearchSlot}></span>
        <span className="flex-1"></span>
        <Button variant="ghost" size="icon" className="icon-btn" aria-label={panelLabel} data-tip={panelLabel + "（Alt+B）"} data-ui="topbar.panel-toggle"
          onClick={() => setPanelOpen(!panelOpen)}>
          <PanelRightIcon aria-hidden="true" />
        </Button>
        <Separator orientation="vertical" className="h-(--space-5) self-center" />
        <SettingsDialog open={settingsOpen} onOpenChange={setSettingsOpen} picking={picking} onTogglePicking={() => setPicking(!picking)}
          theme={theme} onTheme={(t) => { applyTheme(t); setTheme(t); }} font={font} onFont={(f) => { applyFont(f); setFont(f); }}
          floatMode={floatMode} onFloatMode={setFloatMode} floatDelay={floatDelay} onFloatDelay={setFloatDelay} floatWidth={floatWidth} onFloatWidth={setFloatWidth}>
        <Button variant="ghost" size="icon" className="icon-btn" aria-label="设置" data-tip="设置" data-ui="topbar.settings">
          <SettingsIcon aria-hidden="true" />
        </Button>
        </SettingsDialog>
      </header>

      <div className={"workspace relative grid grid-cols-[var(--activity-w)_minmax(0,1fr)] min-h-0" + (panelOpen ? "" : " panel-closed")} style={{ "--panel-w": shownWidth + "px" }}>
        <nav className="activity flex flex-col items-center gap-1 pt-1.5 bg-(--chrome) border-r border-border" aria-label="模块" data-ui="activity">
          {modules.map((m) => (
            <Button key={m.id} variant="ghost" size="activity" className="icon-btn" aria-label={m.label} data-tip={m.tip} data-ui={"activity." + m.id}
              aria-current={m.id === module ? "page" : undefined} onClick={() => setModule(m.id)}>
              <m.Icon aria-hidden="true" />
            </Button>
          ))}
        </nav>
        <ResizablePanelGroup orientation="horizontal" disabled={picking} className="min-h-0" resizeTargetMinimumSize={{ fine: dimension("--resize-hit"), coarse: dimension("--resize-hit") }}
          onLayoutChanged={(_, meta) => {
            if (!panelOpen) return;
            if (meta.isUserInteraction) setPanelWidth(Math.round(detail.current.getSize().inPixels));
            else detail.current?.resize(shownWidth);
          }}>
        <ResizablePanel id="main" minSize={Math.min(mainMin, winWidth - activityWidth - (panelOpen ? panelMin : 0))}>
        <main data-ui="main" className="main h-full min-w-0 overflow-auto [scrollbar-gutter:stable] px-(--page-pad-x) py-(--page-pad-y)">
          <section className="module h-full" data-ui={"module." + module}>
            <SearchSlot.Provider value={searchSlot}>
              {current.render({ selected, onSelect: setSelected, theme, font, onModule: setModule })}
            </SearchSlot.Provider>
          </section>
        </main>
        </ResizablePanel>
        <ResizableHandle disableDoubleClick className={panelOpen ? "" : "hidden"} onDoubleClick={() => applyWidth(panelDefault)} onKeyDownCapture={resizeKey}
          aria-label="拖动改详情面板宽度" data-tip="拖动或按 ←→ 改宽度，双击恢复 420px" data-ui="panel.resizer" />
        <ResizablePanel id="detail" panelRef={detail} defaultSize={shownWidth} minSize={panelOpen ? panelMin : 0} maxSize={panelOpen ? limit : 0}
          groupResizeBehavior="preserve-pixel-size" inert={!panelOpen} className="h-full [&>.panel]:h-full">
        <DetailPanel file={selected} onSelect={setSelected} font={font}
          onBack={trail.at > 0 ? () => step(-1) : null} onForward={trail.at < trail.list.length - 1 ? () => step(1) : null} />
        </ResizablePanel>
        </ResizablePanelGroup>
      </div>

      <footer className="statusbar flex items-center gap-4 px-2.5 bg-(--chrome) border-t border-border text-xs text-muted-foreground tabular-nums" data-ui="statusbar">
        <span data-ui="statusbar.generated">生成于 {data.generatedAt}，{data.files.length} 份文档</span>
        <span className="min-w-55" data-ui="statusbar.pick-state">
          {picking ? "元素选取：开，点击元素即复制，按 Esc 关闭" : "元素选取：关（Alt+X）"}
        </span>
      </footer>

      <PanelNotice notice={notice} panelOpen={panelOpen} />
      {/* 钉住的浮窗切换模块时留着，所以浮窗层放在模块外面 */}
      <FloatLayer mode={floatMode} delay={floatDelay} width={floatWidth} disabled={picking} onSelect={setSelected} font={font} />
      <Tooltip disabled={picking} />
      <Picker on={picking} />
    </PickingContext.Provider>
    </ToastProvider>
  );
}
