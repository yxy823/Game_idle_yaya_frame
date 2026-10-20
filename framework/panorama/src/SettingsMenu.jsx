import { useRef } from "react";
import { floatDelays, floatModes, floatWidths, fonts } from "./store.js";
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuCheckboxItem, DropdownMenuRadioGroup, DropdownMenuRadioItem, DropdownMenuLabel, DropdownMenuSeparator } from "@/components/ui/dropdown-menu";
import { Switch } from "@/components/ui/switch";

const themes = [["system", "跟随系统"], ["light", "浅色"], ["dark", "深色"]];

// 设置菜单（Radix DropdownMenu）：贴在设置按钮下方、右边对齐；↑↓ 在菜单项之间循环，点菜单外或按 Esc 关闭，焦点回到设置按钮。
export default function SettingsMenu({ children, open, onOpenChange, picking, onTogglePicking, theme, onTheme, font, onFont, floatMode, onFloatMode, floatDelay, onFloatDelay, floatWidth, onFloatWidth }) {
  const content = useRef(null), nextFocus = useRef(null);
  const close = () => onOpenChange(false);
  // Radix 菜单里按 Tab 不移动焦点。这里改成和普通页面一样：Tab 关菜单并把焦点交给活动栏第一项，Shift+Tab 交给面板开关
  const key = (e) => {
    if (e.key !== "Tab") return;
    e.preventDefault(); e.stopPropagation();
    nextFocus.current = document.querySelector(e.shiftKey ? "[data-ui='topbar.panel-toggle']" : ".activity button");
    close();
  };
  return <DropdownMenu modal={false} open={open} onOpenChange={onOpenChange}>
    <DropdownMenuTrigger asChild>{children}</DropdownMenuTrigger>
    {/* 打开时焦点落在第一项，关闭时落到 Tab 指定的位置，否则回到设置按钮 */}
    <DropdownMenuContent ref={content} loop onKeyDownCapture={key}
      onOpenAutoFocus={(e) => { e.preventDefault(); queueMicrotask(() => content.current?.querySelector("[role='menuitemcheckbox']").focus()); }}
      onCloseAutoFocus={(e) => { e.preventDefault(); (nextFocus.current ?? document.querySelector("[data-ui='topbar.settings']")).focus(); nextFocus.current = null; }}
      onEscapeKeyDown={(e) => { e.preventDefault(); e.stopPropagation(); close(); }}>
      <DropdownMenuLabel>工具</DropdownMenuLabel>
      <DropdownMenuCheckboxItem checked={picking} onCheckedChange={onTogglePicking} onSelect={(e) => e.preventDefault()}>
        元素选取：点击即复制<span className="ml-auto text-xs text-muted-foreground">Alt+X</span>
        <Switch checked={picking} aria-hidden="true" tabIndex={-1} className="pointer-events-none ml-2" />
      </DropdownMenuCheckboxItem>
      <DropdownMenuSeparator />
      <DropdownMenuLabel>主题</DropdownMenuLabel>
      <DropdownMenuRadioGroup value={theme} onValueChange={onTheme}>
        {themes.map(([id, name]) => <DropdownMenuRadioItem key={id} value={id}>{name}</DropdownMenuRadioItem>)}
      </DropdownMenuRadioGroup>
      <DropdownMenuSeparator />
      <DropdownMenuLabel>字号</DropdownMenuLabel>
      <DropdownMenuRadioGroup value={font} onValueChange={onFont}>
        {fonts.map(([id, name]) => <DropdownMenuRadioItem key={id} value={id}>{name}</DropdownMenuRadioItem>)}
      </DropdownMenuRadioGroup>
      <DropdownMenuSeparator />
      <DropdownMenuLabel>浮窗（按住 Alt 不弹出）</DropdownMenuLabel>
      <DropdownMenuRadioGroup value={floatMode} onValueChange={onFloatMode}>
        {floatModes.map(([id, name]) => <DropdownMenuRadioItem key={id} value={id}>{name}</DropdownMenuRadioItem>)}
      </DropdownMenuRadioGroup>
      <DropdownMenuSeparator />
      <DropdownMenuLabel>浮窗延迟</DropdownMenuLabel>
      <DropdownMenuRadioGroup value={floatDelay} onValueChange={onFloatDelay}>
        {floatDelays.map(([id, name]) => <DropdownMenuRadioItem key={id} value={id}>{name}</DropdownMenuRadioItem>)}
      </DropdownMenuRadioGroup>
      <DropdownMenuSeparator />
      <DropdownMenuLabel>浮窗宽度</DropdownMenuLabel>
      <DropdownMenuRadioGroup value={floatWidth} onValueChange={onFloatWidth}>
        {floatWidths.map(([id, name]) => <DropdownMenuRadioItem key={id} value={id}>{name}</DropdownMenuRadioItem>)}
      </DropdownMenuRadioGroup>
    </DropdownMenuContent>
  </DropdownMenu>;
}
