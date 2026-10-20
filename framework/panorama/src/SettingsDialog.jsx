import { floatDelay, floatModes, floatWidth, fonts } from "./store.js";
import { Dialog, DialogTrigger, DialogContent, DialogTitle } from "@/components/ui/dialog";
import { Slider } from "@/components/ui/slider";
import { Switch } from "@/components/ui/switch";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";

const themes = [["system", "跟随系统"], ["light", "浅色"], ["dark", "深色"]];

// 一行设置：左边名称，右边控件
function Row({ label, id, children }) {
  return <div className="flex min-h-(--control-h) items-center gap-3">
    <label className="w-16 flex-none text-muted-foreground" id={id}>{label}</label>
    <div className="flex min-w-0 flex-1 items-center gap-2">{children}</div>
  </div>;
}
function Group({ title, children }) {
  return <section className="flex flex-col gap-2 border-t border-border px-4 py-3">
    <h3 className="text-xs font-semibold text-muted-foreground">{title}</h3>
    {children}
  </section>;
}
// 分段按钮：必须选中一项，再点已选中的那项不取消
function Segments({ label, ui, value, onChange, items }) {
  return <ToggleGroup type="single" spacing={0} variant="outline" aria-labelledby={label} data-ui={ui} value={value} onValueChange={(v) => v && onChange(v)}>
    {items.map(([id, name]) => <ToggleGroupItem key={id} value={id}>{name}</ToggleGroupItem>)}
  </ToggleGroup>;
}
function Range({ label, ui, value, onChange, range }) {
  return <>
    <Slider aria-labelledby={label} data-ui={ui} min={range.min} max={range.max} step={range.step} value={[value]} onValueChange={([v]) => onChange(v)} />
    <span className="w-14 text-right tabular-nums" data-ui={ui + "-value"}>{value}{range.unit}</span>
  </>;
}

// 设置窗口（Radix Dialog）：点设置按钮在页面中间打开，改动立即生效；点窗口外、点右上角的叉或按 Esc 关闭，焦点回到设置按钮。
export default function SettingsDialog({ children, open, onOpenChange, picking, onTogglePicking, theme, onTheme, font, onFont, floatMode, onFloatMode, floatDelay: delay, onFloatDelay, floatWidth: width, onFloatWidth }) {
  return <Dialog open={open} onOpenChange={onOpenChange}>
    <DialogTrigger asChild>{children}</DialogTrigger>
    {/* Esc 只关窗口，不再传给页面去取消选中 */}
    <DialogContent data-ui="settings" onEscapeKeyDown={(e) => e.stopPropagation()}>
      <DialogTitle className="flex h-(--bar-h) items-center px-4">设置</DialogTitle>
      <Group title="外观">
        <Row label="主题" id="set-theme"><Segments label="set-theme" ui="settings.theme" value={theme} onChange={onTheme} items={themes} /></Row>
        <Row label="字号" id="set-font"><Segments label="set-font" ui="settings.font" value={font} onChange={onFont} items={fonts} /></Row>
      </Group>
      <Group title="浮窗">
        <Row label="弹出方式" id="set-float-mode"><Segments label="set-float-mode" ui="settings.float-mode" value={floatMode} onChange={onFloatMode} items={floatModes} /></Row>
        <Row label="延迟" id="set-float-delay"><Range label="set-float-delay" ui="settings.float-delay" value={delay} onChange={onFloatDelay} range={floatDelay} /></Row>
        <Row label="宽度" id="set-float-width"><Range label="set-float-width" ui="settings.float-width" value={width} onChange={onFloatWidth} range={floatWidth} /></Row>
        <p className="text-xs text-muted-foreground">按住 Alt 时不弹出。宽度只影响之后弹出的浮窗。</p>
      </Group>
      <Group title="工具">
        <Row label="元素选取" id="set-picking">
          <Switch aria-labelledby="set-picking" data-ui="settings.picking" checked={picking} onCheckedChange={onTogglePicking} />
          <span className="text-xs text-muted-foreground">点击元素即复制（Alt+X）</span>
        </Row>
      </Group>
    </DialogContent>
  </Dialog>;
}
