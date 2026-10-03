# 编辑器插件验证夹具

[插件版本记录](../../../maintenance/dependencies/editor-plugin-versions.md) · [验证范围](../../../maintenance/validation/validation-scope.md)

本目录的两个探针用来验证随项目分发的编辑器效率插件。它们只在明确指定的外部验证项目中临时使用，不进入项目复制清单。不要在有用户工作内容的项目中直接运行。

运行前，在外部项目根目录取得已确认的 Godot 路径：

```powershell
$validationGodot = (Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json).engine_executable
```

## 插件生命周期探针

[editor_plugin_lifecycle_probe.gd](editor_plugin_lifecycle_probe.gd) 检查五个插件的启用、停用和共存。

**放置与启动**：

1. 把它复制为外部项目的 `addons/editor_plugin_probe/plugin.gd`。
2. 在同一目录创建 `plugin.cfg`：

```ini
[plugin]
name="Editor Plugin Lifecycle Probe"
description="Temporary editor plugin verification"
author="Framework maintenance"
version="1.0"
script="plugin.gd"
```

3. 导入后临时启用这个插件，然后启动编辑器。

**它会做什么**：依次切换五个插件、打开脚本和检查器，在 `tests/editor_plugin_probe_data/` 下写入临时的看板和 Gradient 资源，生成报告 `reports/editor-plugin-lifecycle.json` 后退出。结束时它会停用资源表格插件和 Signal Lens。

**结束后**：在外部项目中停用这个探针，并把插件列表恢复为分发模板的默认值。复核时同时读取报告、进程退出码和引擎日志。

**只回归 Script-IDE 分屏时**：临时只启用 Script-IDE 和这个探针，启动编辑器时在 `--` 后面加 `--script-ide-split-only`。这个模式不切换其他插件，报告中的 `scope` 为 `script-ide-split`。报告仍写到 `reports/editor-plugin-lifecycle.json`，重复运行前先保留需要的旧报告。

## Signal Lens 目标生命周期探针

[signal_lens_target_lifecycle_probe.gd](signal_lens_target_lifecycle_probe.gd) 检查 Signal Lens 在目标节点被释放时的处理。

1. 复制到外部项目的 `tests/contracts/`。
2. 确认 Signal Lens 插件处于停用状态，项目中没有现成的 `SignalLens` Autoload。
3. 运行：

```powershell
& $validationGodot --headless --debug --path . --script res://tests/contracts/signal_lens_target_lifecycle_probe.gd | Out-Host
$LASTEXITCODE
```

4. 在命令末尾加 `-- --free-immediately` 再运行一次。不加时验证延迟释放（`queue_free()`），加上后验证立即释放（`free()`）。

说明：

- `--debug` 提供 Autoload 发送消息所需的本地调试器。
- 探针在内存中创建目标节点，用一个观察子类记录真实的回调并调用上游实现，结束时清理节点和调试捕获的注册。
- 报告固定写到 `reports/signal-lens-target-lifecycle.json`。两次运行要分别保存 JSON、日志和退出码。
- 本地调试器下的结果不等于远程 UI 面板的人工验收。
