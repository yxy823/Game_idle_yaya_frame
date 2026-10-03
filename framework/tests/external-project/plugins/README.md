# 编辑器插件验证夹具

[插件版本记录](../../../maintenance/dependencies/editor-plugin-versions.md) · [验证范围](../../../maintenance/validation/validation-scope.md)

[editor_plugin_lifecycle_probe.gd](editor_plugin_lifecycle_probe.gd) 只供已指定的外部验证项目临时使用，不进入项目复制清单。将它复制为外部项目的 `addons/editor_plugin_probe/plugin.gd`，同目录创建以下 `plugin.cfg`，导入后临时启用该插件并启动编辑器：

```ini
[plugin]
name="Editor Plugin Lifecycle Probe"
description="Temporary editor plugin verification"
author="Framework maintenance"
version="1.0"
script="plugin.gd"
```

夹具会切换五个插件、打开脚本和检查器、写入 `tests/editor_plugin_probe_data/` 下的临时看板与 Gradient 资源，并生成 `reports/editor-plugin-lifecycle.json` 报告后退出。结束时停用资源表格与 Signal Lens；还应在外部项目停用夹具，并恢复分发模板的默认插件列表。不要在有用户工作内容的项目直接运行。复核时同时读取报告、进程退出码和引擎日志。

只回归 Script-IDE 分屏时，临时启用 Script-IDE 与该探针，启动编辑器时在 `--` 后传 `--script-ide-split-only`。该模式不切换其他插件，报告的 `scope` 为 `script-ide-split`；报告仍写入 `reports/editor-plugin-lifecycle.json`，重复运行前保留需要的旧原件。

[signal_lens_target_lifecycle_probe.gd](signal_lens_target_lifecycle_probe.gd) 复制到外部项目的 `tests/contracts/`，在 Signal Lens 插件停用、没有现成 `SignalLens` Autoload 时运行：

```powershell
& $validationGodot --headless --debug --path . --script res://tests/contracts/signal_lens_target_lifecycle_probe.gd | Out-Host
$LASTEXITCODE
```

`$validationGodot` 取自该项目已确认的 Godot 配置。`--debug` 提供 Autoload 发送消息所需的本地调试器；在命令末尾加 `-- --free-immediately` 验证立即释放，否则验证延迟释放。探针在内存中创建目标，使用观察子类记录真实回调并调用上游实现，清理节点及调试捕获注册后退出；报告固定为 `reports/signal-lens-target-lifecycle.json`。两次运行分别保存 JSON、日志和退出码，不把本地调试器结果当作远程 UI 验收。
