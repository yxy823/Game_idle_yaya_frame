# 本项目的调试台

调试台从调试入口启动真实游戏，在独立窗口中调参、比较候选并采纳到游戏。入口、插槽、预设、采纳与收尾等机制见[调试台共享代码](_shared/README.md)，界面任务见[调试台使用场景](_shared/usage-scenarios.md)。本页只登记本项目自己的内容。

## 启动

在项目根目录打开 PowerShell，粘贴下面三行：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectGodot = (Resolve-Path -LiteralPath $projectConfig.engine_executable -ErrorAction Stop).Path
& $projectGodot --path . res://dev/debug/debug_main.tscn
```

出现游戏窗口和调试窗口两个窗口；在任一窗口按 F1 显示或隐藏调试窗口。

## 调试存档

[debug_project.gd](debug_project.gd) 还没有按本项目的存档系统改写：调试会话使用游戏的真实存档，调试窗口的状态栏会提示。改写后在这里写明调试存档的位置。

## 调试对象与候选

### shared

跨界面共用的调试对象，主场景是[样式总览](shared/overview/style_overview.tscn)：列出全部设计 token、各控件和按钮变体的示例，以及每种样式被哪些界面使用。

- **插槽**：`game/shared/tuning/ui/` 下的 14 份设计 token。原始值 6 份（调色板、字号、间距、圆角、边框宽度、阴影），语义值 7 份（文字、面板、输入框、进度条，以及主要、次要、危险三种按钮），动效 1 份（按钮）。中文名在 `shared/slots/ui/` 下各插槽的 `slot.gd` 和 `token_names.gd`。
- **固定局面**：没有。

### 新增调试对象

新增调试对象时，在这里按对象登记：

- **插槽**：`game/<对象>/tuning/` 下的调参资源及其中文名。
- **候选**：`dev/debug/<对象>/slots/<插槽>/<候选>/` 的名称、来源与许可；已采纳的实现在 `game/` 中的位置。
- **固定局面**：`debug_target.gd` 登记的局面名称与文件。
