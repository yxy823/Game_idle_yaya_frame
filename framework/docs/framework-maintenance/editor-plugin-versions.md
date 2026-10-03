# 编辑器插件版本与兼容性记录

本页供框架维护者查找五个编辑器效率插件的上游、当前安装版本和升级检查依据。源码保存在 `project-source/addons/`，由[复制清单](../../commands/project-files.json)分发；本页只保留在 `framework/`，不复制到生成项目，也不建立自动升级或项目同步机制。

## 当前安装来源

来源核对日期：2026-09-27。下表的“资产库 Godot 标签”是上游资产库声明，不能直接当作本框架 Godot 4.7 的实测结论。固定源码链接确定本次复制的内容；版本号与包内声明不一致时保留原值。

| 插件与原始仓库 | 资产库版本 | 包内 `plugin.cfg` 版本 | 资产库 Godot 标签 | 本次固定源码 |
| --- | --- | --- | --- | --- |
| [Script-IDE](https://github.com/Maran23/script-ide) | [2.2.5](https://godotengine.org/asset-library/asset/2206) | `2.2.5` | `4.5` | [11784e8d](https://github.com/Maran23/script-ide/tree/11784e8dfef200116a1c8fb500f0188868e6bed6) |
| [Inspector Tabs](https://github.com/PiCode9560/Godot-Inspector-Tabs) | [v0.10-stable](https://godotengine.org/asset-library/asset/3951) | `0.10-stable` | `4.4` | [d052af92](https://github.com/PiCode9560/Godot-Inspector-Tabs/tree/d052af929060ec3099dfca2ac849e64ece23ee0d) |
| [Kanban Tasks - Todo Manager 2](https://github.com/HolonProduction/godot_kanban_tasks) | [2.1](https://godotengine.org/asset-library/asset/1474) | `2.1` | `4.0` | [3ca60d25](https://github.com/HolonProduction/godot_kanban_tasks/tree/3ca60d25e37da0eefa4c470b79bc1f44bc255ad5) |
| [Edit Resources as Table 2](https://github.com/don-tnowe/godot-resources-as-sheets-plugin) | [2.17.4](https://godotengine.org/asset-library/asset/1479) | `2.7` | `4.0` | [3363e0d2](https://github.com/don-tnowe/godot-resources-as-sheets-plugin/tree/3363e0d2136c432c989ac1f249aa8aaa634e84e9) |
| [Signal Lens](https://github.com/yannlemos/signal-lens) | [1.4.1](https://godotengine.org/asset-library/asset/3620) | `1.4.1` | `4.3` | [5919c07c](https://github.com/yannlemos/signal-lens/tree/5919c07cb370d151b8937f9696474f3af2f059b1) |

Edit Resources as Table 2 的资产库版本与包内版本确有差异，不能只读 Godot 插件列表就判断是否已升级；应同时核对本表的固定源码。Kanban 使用资产库条目 `1474` 的 Godot 4 版本，不使用旧 Godot 3 条目 `1245`。

五个插件均采用 MIT 许可证。保留包内许可证，包括 Kanban 的 `uuid/LICENSE`。Inspector Tabs 与 Signal Lens 的资产库源码包遗漏根许可证，本次从各自同一固定提交的原始 `LICENSE` 补入插件目录；不改许可证正文。

## 分发与启用

| 分发目录（相对生成项目） | 默认状态 | 使用与维护要点 |
| --- | --- | --- |
| `addons/script-ide/` | 启用 | 改造 Script 编辑区；使用编辑器内部控件结构，升级 Godot 后需检查标签、大纲、搜索与停用恢复 |
| `addons/inspector_tabs/` | 启用 | 改造检查器属性分类；布局偏好属于编辑器设置，会影响同一编辑器配置下的其他项目 |
| `addons/kanban_tasks/` | 启用 | 顶部 `Tasks` 工作区，默认数据为 `res://kanban_tasks_data.kanban`；用户自行维护，和框架任务系统完全独立，无读取、字段映射或同步脚本 |
| `addons/resources_spreadsheet_view/` | 安装但停用 | 启用后进入顶部 `ResourceTables`；当前组合存在退出泄漏诊断，按需使用。直接编辑实际资源，升级前备份资源与插件目录内的 `saved_state.json` 偏好 |
| `addons/signal_lens/` | 安装但停用 | 调试时通过“项目 → 项目设置 → 插件”启用；注册 `SignalLens` Autoload，停用时移除 |

Signal Lens 1.4.1 没有自动在发行导出时剥离 Autoload 的逻辑，调试结束或发行导出前应停用，并确认 `project.godot` 不再含 `autoload/SignalLens`。框架默认不注册该 Autoload。当前版本主要检查远程场景树中的节点，不支持 Resource、RefCounted 或普通 Object 信号检查。

Kanban 数据是用户内容，停用或升级时保留；本框架不预置看板任务，也不把看板内容纳入开发流程。插件源码使用上游目录名，不引入统一插件管理器。

## 本地修正

本地修改限定在下列 Kanban 与 Script-IDE 源码，包内版本分别保留 `2.1` 与 `2.2.5`。升级时逐项确认上游是否已修复；未修复且仍可复现时保留对应处理。

| 文件 | 原问题与本地处理 |
| --- | --- |
| [kanban_tasks/plugin.gd](../../../project-source/addons/kanban_tasks/plugin.gd) | 退出时 Help 菜单误写成再次释放 File 菜单，改为释放 `help_menu`；同时销毁该插件创建的 `PluginSingletons` 容器，使停用后不残留编辑上下文与快捷键节点 |
| [kanban_tasks/view/edit_context.gd](../../../project-source/addons/kanban_tasks/view/edit_context.gd) | `UndoRedo` 是需显式释放的 Object；在编辑上下文销毁时释放，消除单独运行 Kanban 时的退出泄漏 |
| [script-ide/plugin.gd](../../../project-source/addons/script-ide/plugin.gd) | 关闭分屏时只移除容器会遗留离树节点；移除后同时 `queue_free()`，释放容器及其 CodeEdit |
| [script-ide/split/split_code_edit.gd](../../../project-source/addons/script-ide/split/split_code_edit.gd) | 分屏和原编辑器共用高亮器会覆盖它所属的 TextEdit，分屏释放后可导致原编辑器访问失效对象；只读分屏保存独立的逐行高亮快照，保持打开时的显示结果，并使两边各自拥有高亮器 |

Inspector Tabs、Edit Resources as Table 2 和 Signal Lens 源码保持固定提交的原文，仅补齐前述两个许可证文件。Kanban 的五个图标/文档 SVG 与 Signal Lens 的两个 PNG 所附 `.import` 文件采用外部 Godot 4.7.1 重导入后的设置，增加引擎默认的压缩与通道映射字段；不带入 `.godot` 缓存或用户偏好。没有给资源表格插件应用未经证实的退出修正。

## 当前兼容性状态

最近一次实测环境为 Windows、Godot `4.7.1.stable.official.a13da4feb`，在由创建器生成的独立外部项目中执行，图形运行使用 OpenGL Compatibility。原始日志、JSON 报告与退出码保存在对应外部项目的 `reports/`；本页只保留当前结论，验证过程与证据位置随本页的 Git 历史查阅。新的 Godot 或插件版本不能沿用这些结论。

| 检查范围 | 当前结论 |
| --- | --- |
| Script-IDE 分屏 | 应用本地修正后，headless 与图形回归均通过：多轮开关、容器与 CodeEdit 实际释放、高亮器各自归属、逐行高亮一致、折叠后搜索，以及关闭后原编辑器高亮更新；日志无脚本错误、泄漏或退出崩溃。恢复原“只移除”行为的负向对照会失败，说明释放断言有效 |
| Signal Lens 目标生命周期 | 使用上游源码，`queue_free()` 与 `free()` 两种销毁方式下的目标切换、信号接收、解绑与清理均通过；失效目标与 `null` 的比较行为与 [Godot 4.7.1 的实现](https://github.com/godotengine/godot/blob/4.7.1-stable/core/variant/variant_op.h#L496-L501)一致 |
| 五插件功能与启停 | 同时启用、Script-IDE 标签与 Inspector Tabs 注册、看板保存重载、表格资源加载、逐个停用再启用、Kanban 菜单与容器释放、表格界面释放、Signal Lens Autoload 添加与移除均通过 |
| 默认组合启动与退出 | headless 启动/退出无脚本错误或泄漏诊断（gdUnit4 在 headless 下跳过插件主体，不覆盖其界面）；只含 Script-IDE、Inspector Tabs 与 Kanban 的图形启动/退出无错误 |

### 未解决问题

- **gdUnit4 图形组合**：包含 gdUnit4 的完整默认图形组合仍有状态栏信号重复连接、退出时访问已释放实例及残留资源诊断。单独启用 gdUnit4 也会出现字体初始化与退出访问问题；重复连接尚未定位，本框架未修改 gdUnit4。
- **资源表格退出泄漏**：单独启动无退出错误，与 gdUnit4 或其他新增插件组合时出现 ObjectDB、资源、纹理等泄漏；同步释放界面与空偏好对照均未消除，根因未确定，因此默认停用。
- **维护探针 lint**：外部验证项目的 lint 仍报告插件生命周期探针的长函数与结果打印问题，不能写成 lint 全通过。
- **人工验收缺口**：尚未验收 Script-IDE 分屏与搜索观感、检查器标签切换、Kanban 卡片拖放、表格编辑撤销，以及 Signal Lens 远程面板收包与信号图；自动化探针的通过结论不覆盖这些范围。

进程退出码为 `0` 不代表无错误，复核时同时读取报告和引擎日志。Inspector Tabs 首次缺少可选偏好文件时会普通打印 `ERROR LOADING SETTINGS FILE` 并使用默认设置，这与引擎的 `ERROR:`、`SCRIPT ERROR:` 诊断不同。

## 验证夹具

[editor_plugin_lifecycle_probe.gd](../../tests/external-project/plugins/editor_plugin_lifecycle_probe.gd) 只供已指定的外部验证项目临时使用，不进入项目复制清单。将它复制为外部项目的 `addons/editor_plugin_probe/plugin.gd`，同目录创建以下 `plugin.cfg`，导入后临时启用该插件并启动编辑器：

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

[signal_lens_target_lifecycle_probe.gd](../../tests/external-project/plugins/signal_lens_target_lifecycle_probe.gd) 复制到外部项目的 `tests/contracts/`，在 Signal Lens 插件停用、没有现成 `SignalLens` Autoload 时运行：

```powershell
& $validationGodot --headless --debug --path . --script res://tests/contracts/signal_lens_target_lifecycle_probe.gd | Out-Host
$LASTEXITCODE
```

`$validationGodot` 取自该项目已确认的 Godot 配置。`--debug` 提供 Autoload 发送消息所需的本地调试器；在命令末尾加 `-- --free-immediately` 验证立即释放，否则验证延迟释放。探针在内存中创建目标，使用观察子类记录真实回调并调用上游实现，清理节点及调试捕获注册后退出；报告固定为 `reports/signal-lens-target-lifecycle.json`。两次运行分别保存 JSON、日志和退出码，不把本地调试器结果当作远程 UI 验收。

## 升级时核对

1. 从原始仓库的发布说明、对应 Godot 分支和资产库核对候选版本，选择确定提交；同时检查本页记录的包内版本差异与本地修正。
2. 保留许可证和用户数据，只替换所属插件目录。目录名或插件入口变化时同步复制清单、默认 `project.godot` 与使用说明，不覆盖已有游戏项目。
3. 在指定外部项目用目标 Godot 版本重新导入并启动全新编辑器，检查五插件共存、启用 → 停用 → 再启用，以及受变化影响的功能。Signal Lens 还需核对 Autoload 添加/移除；不能只凭退出码忽略脚本错误或泄漏日志。
4. 更新本页的版本、固定源码、当前兼容性结论与未解决问题，验证过程只留在外部项目报告与提交说明中，并同步受影响的手册说明。新的 Godot 或插件版本不能沿用旧版通过结论。
