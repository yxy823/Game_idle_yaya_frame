import { useEffect, useLayoutEffect, useRef } from "react";
import { IconCheck } from "@tabler/icons-react";
import { fonts } from "./store.js";

const themes = [["system", "跟随系统"], ["light", "浅色"], ["dark", "深色"]];

// 设置菜单：贴在设置按钮下方、右边对齐；点菜单外或按 Esc 关闭，焦点回到设置按钮。
export default function SettingsMenu({ anchor, onClose, picking, onTogglePicking, theme, onTheme, font, onFont }) {
  const ref = useRef(null);
  useLayoutEffect(() => {
    const r = anchor.current.getBoundingClientRect(), menu = ref.current;
    menu.style.top = (r.bottom + 4) + "px";
    menu.style.left = (r.right - menu.offsetWidth) + "px";
    menu.querySelector("button").focus();
  }, [anchor]);
  useEffect(() => {
    const close = () => { onClose(); anchor.current.focus(); };
    const click = (e) => { if (!ref.current.contains(e.target) && !anchor.current.contains(e.target)) close(); };
    const key = (e) => { if (e.key === "Escape") { e.stopPropagation(); close(); } };
    document.addEventListener("click", click);
    document.addEventListener("keydown", key, true);
    return () => { document.removeEventListener("click", click); document.removeEventListener("keydown", key, true); };
  }, [anchor, onClose]);
  return (
    <div className="menu" role="menu" ref={ref} data-pick-ignore>
      <div className="group">工具</div>
      <button role="menuitemcheckbox" aria-checked={picking} onClick={onTogglePicking}>
        <span className="mark"></span>元素选取：点击即复制<span className="key">Alt+X</span><span className="switch"></span>
      </button>
      <div className="group">主题</div>
      {themes.map(([id, name]) => (
        <button key={id} role="menuitemradio" aria-checked={theme === id} onClick={() => { onTheme(id); onClose(); anchor.current.focus(); }}>
          <span className="mark">{theme === id && <IconCheck aria-hidden="true" />}</span>{name}
        </button>
      ))}
      <div className="group">字号</div>
      {fonts.map(([id, name]) => (
        <button key={id} role="menuitemradio" aria-checked={font === id} onClick={() => { onFont(id); onClose(); anchor.current.focus(); }}>
          <span className="mark">{font === id && <IconCheck aria-hidden="true" />}</span>{name}
        </button>
      ))}
    </div>
  );
}
