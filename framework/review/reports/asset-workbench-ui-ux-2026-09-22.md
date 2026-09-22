# Asset Workbench UI/UX 整理与验证记录

日期：2026-09-22。实施依据为本会话确认的 P0–P3 规格及后续明确允许向既有验证项目定向同步的回复。

## 结果与版本范围

已完成资源候选、真实组合预览、对象 Inspector 和源资源分析窗口的布局与状态整理。1600×900 使用可拖动三栏；窄窗口切换候选、预览、属性区域，当前对象及方案、停止、保存和保存目标始终可访问。没有提高项目最小窗口尺寸。

框架起点为干净的 `e0a80a6`（Shader 独立组合已存在）。本报告针对本次 UI 差异及下列重新执行的验证，不把起点提交的旧通过记录计入本轮。框架中的 `project-source/` 仅作复制源维护，没有在其内启动 Godot 或生成 Feature 流程。

真实引擎在用户批准的 `D:/A_Games/Game_idle_yaya_frame_workbench_test` 执行。定向同步前核对目标原内容，最终 20 份本轮源文件与目标逐字节一致，13 份改动 GDScript 单独解析成功；验证夹具留在目标测试/报告目录。目标原有 `project.godot`、机器配置及 10 份示例 Cue/材质预设在前后核对中全部不变，没有新增目标根目录。目标项目原来即为未跟踪文件状态，本轮不在那里建立提交或覆盖其他工作。

## 已改变的使用方式

| 区域 | 本次行为与信息层级 |
| --- | --- |
| 资源候选 | 图像等比例缩略图、音频类型标识；列表获得剩余高度；摘要区显示资源名、格式、导入后图像尺寸或音频时长、分析状态。未选择时禁用相关操作，试听只对音频显示，固定试听条件与 Cue 增益分开。浏览仍不绑定；应用按钮写明当前对象 A/B。 |
| 组合预览 | 全场景 A/B 和触发全部在上，分析场景源资源、统一增益和逐文件保存放入“全场景更多…”。当前对象操作在下，只有一个可见“停止全部”。保留原场景位置和尺寸，小窗通过场景滚动访问。选中对象有稳定边框及名称。 |
| 对象 Inspector | 固定对象名称、互斥 A/B 和文字保存状态；资源绑定、图像/动画、音频、Shader 各自分组；固定保存入口、文件名及共享 Cue 影响说明。完整保存路径和当前资源路径可打开、选择复制。低频动作归入“对象更多…”。 |
| 状态表达 | 全场景 A/B 从各对象实际方案推导；对象方案混用时显示“混合方案”，场景 A/B 均不伪装为统一选中。完整操作反馈可从底部“操作详情…”查看，部分保存失败详情不会因一行状态栏而丢失。 |
| 源资源分析 | 窗口明确命名“源资源分析 / 分析对比 A/B”；待分析候选与已有 A/B 结果分别显示资源身份。核心指标和问题摘要在前，详细指标、图表及原始说明在后；选项折叠。没有结果显示“未分析”。清空异类槽或载入快照时解除旧任务关联，迟到结果不能覆写当前快照。 |
| 批量分析 | 命名明确指向源图像/音频；集合状态、资源类型和问题摘要先展示，低频成员/快照操作入菜单。仍沿用现有集合：加入对象或场景资源不清空原成员，界面明确提示这一点。 |

图像、音频与 Shader 仍可独立替换或留空；无图像 Shader 使用既有承载面。Shader 只编辑原契约参数，并显示预设、类型及现有引用；不适用的颜色等参数禁用且说明原因。Theme 只装饰控件，不改变素材调制值。

对象 A/B、场景 A/B、分析 A/B 仍为不同作用域。保存当前方案仍只写当前 Cue；全场景保存仍逐文件检查冲突并报告部分成功，不是事务。重载确认明确丢弃当前对象两份草稿。源图片、音频、共享 Shader 与材质预设不被这些操作改写。分析仍针对原始文件，不表示 Cue 增益后的声音、最终混音或 Shader 渲染质量。

只新增两个展示职责脚本：`workbench_layout.gd` 管理容器与动作位置，`workbench_widgets.gd` 复用分组、字段及只读文本对话框；业务仍由既有工作台、session、Presenter 和分析服务处理。没有新增后台分析器、通用 uniform 编辑器、布局持久化、扫描数据库或编辑器插件。

## 修改文件清单

以下路径相对框架根目录；`.gd.uid` 为目标 Godot 生成并核验的配套 UID。

| 所属目录 | 修改文件 |
| --- | --- |
| `project-source/tools/asset_workbench/` | `workbench.gd`、`composition_workbench.gd`、`composition_panel.gd`、`asset_browser.gd`、`cue_controls.gd`、`shader_controls.gd`、`workbench_theme.gd`、`analysis_panel.gd`、`analysis_batch_panel.gd`、`analysis_chart.gd`；新增 `workbench_layout.gd` / `.gd.uid`、`workbench_widgets.gd` / `.gd.uid` |
| `project-source/components/feedback/` | `feedback_object.gd`（名称和选择边框） |
| `project-source/examples/asset_workbench/` | `README.md`；`single/example-workbench.tscn`、`composition/example-workbench.tscn`、`shader_composition/example-workbench.tscn`（入口标题） |
| `project-source/tools/asset_analyzer/` | `README.md` |
| `framework/tests/project/` | `asset_workbench_test.gd`、`asset_composition_test.gd`、`asset_shader_composition_test.gd`、`asset_analysis_group_test.gd`；`asset_workbench_capture.gd`、`asset_shader_render_capture.gd`、`asset_analyzer_capture.gd`、`asset_analysis_group_capture.gd` |
| `framework/docs/blank-project/` | `guides/asset-workbench.md`、`maintenance/validating-framework.md`、`reference/project-layout.md`、派生 `blank-project-handbook.html` |
| `framework/` | `progress.md`、本报告 |

## 本轮验证结果

环境为 Windows、Godot 4.7.1、NVIDIA RTX 4060 Laptop GPU；行为套件使用项目默认 Forward+ / Vulkan，截图与像素检查显式使用 Compatibility / OpenGL 3.3。Python 使用指定 `codex-python` 解释器。下面的证据目录为 [本轮外部运行产物](D:/A_Games/Game_idle_yaya_frame_workbench_test/reports/asset-workbench-ui-20260922/)。

| 层次 | 实际结果 | 证据与覆盖边界 |
| --- | --- | --- |
| 静态 / 解析 | 13 份改动 GDScript 解析通过；源与目标一致，文档与调用点核对通过 | `parse-final.log`、最后调整的 `parse-batch-final.log`；不是只用文本搜索推断能运行 |
| 项目 lint | 43 文件（包含测试），0 Critical、0 Warning、259 Info | `lint-delivery2.json`；保留原 lint 配置 |
| 渲染夹具 lint | 4 文件，0 Critical、0 Warning、34 Info | `lint-render-fixtures.json`；报告目录被忽略，因此显式指定夹具文件 |
| Godot 行为 | 65/65 通过，0 错误、失败、跳过及孤儿节点 | 单对象 14、组合 10、Shader 9、单项分析 18、分组分析 14；原始日志及各 wrapper 结果见下表 |
| 框架工具 | `unittest discover -s framework/tests -p test_*.py`：38/38 通过 | 本轮命令输出；包含复制及相关维护契约回归，没有执行 pytest |
| 真实布局 / 输入 | 三个入口的 1600×900、1152×648、900×540、720×480 检查通过 | `layout-final.log` / `layout-results.json`；窄窗各区域、图像/音频列表、属性滚动、唯一可见停止/保存及焦点；实际鼠标浏览/应用、Enter 打开外观菜单 |
| 真实渲染 / 分析 | Shader 像素及停止恢复通过；分析/批量窗口真实任务、浅深色与窄窗截图已查看 | `render3-asset_shader_render_capture.log`、`render3-asset_analyzer_capture.log`、`render4-asset_analysis_group_capture.log`；未用静态示意图充当运行截图 |
| 文档 | Markdown 说明同步；现有 HTML/Mermaid 构建通过 | 22 篇文档、33 张图、484 个源链接。未执行浏览器人工阅读验收 |
| 人工体验 | 尚待用户 | 自动输入与截图检查不等于人类对听感、视觉协调、键盘操作舒适度的接受 |

| 套件 | 最终日志（上述产物目录内） | wrapper 结果（外部项目 `reports/gdunit-wrapper/` 下） |
| --- | --- | --- |
| 单对象 14 | `verified2-asset_workbench.log` | `run-khgqq9tk/result.json` |
| 组合 10 | `verified-asset_composition.log` | `run-m7qzpvws/result.json` |
| Shader 9 | `verified-asset_shader_composition.log` | `run-g7cvfi9u/result.json` |
| 分析 18 | `verified-asset_analyzer.log` | `run-w6hqftqs/result.json` |
| 分组 14 | `verified3-asset_analysis_group.log` | `run-lz1q_9c5/result.json` |

行为回归包含浏览不绑定、应用只写当前草稿、对象切换保留各自草稿、实际混合状态、循环与延迟全部停止、独立空资源组合、Shader 参数适用性与材质隔离、当前保存与消费、全场景冲突/部分失败、重载仅丢弃当前对象 A/B，以及分析身份和迟到结果隔离。最终只读资源路径入口补充后，重新执行单对象 14 项和全部入口布局截图；提交前扫描提示修正后，重新执行分组 14 项、全项目 lint 和批量窗口渲染。其他未受影响套件保留本轮有效结果。

Shader 渲染检查的可见像素计数实际为：描边 4764→8401，半强度溶解 3731→2471，无图像噪声 0→16384。三者停止后像素与初始逐字节一致；这证明这些既有示例的运行与停止恢复，不表示任意 Shader 都已验证。原始数据见 `shader/render-results.json`。

在外部项目工作目录运行的主要入口如下，Godot 命令通过 PowerShell 管道等待退出；四份渲染夹具必须使用真实显示驱动。

```powershell
& 'C:/Users/89523/anaconda3/envs/codex-python/python.exe' -B tools/testing/run-gdunit-tests.py --godot-binary 'E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe' --target tests/features/asset_workbench/asset_workbench_test.gd --continue
& 'E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe' --headless --path . --check-only --script res://tools/asset_workbench/workbench_layout.gd | Out-Host
& 'E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe' --path . --rendering-method gl_compatibility --script res://reports/asset-workbench-ui-20260922/fixtures/asset_workbench_capture.gd | Out-Host
```

其余 suite 使用上表对应 `tests/features/<suite>/<suite>_test.gd`；并未重新运行未修改的 Python 分析后端全套测试，后端工作进程由本轮 Godot 分析/分组用例及真实分析截图链路覆盖。

## 早期失败及处理

本轮并非第一次执行即全绿。首次导入发现 lambda 中内联 `match` 解析错误，改为具名动作处理函数；首次行为检查发现 ItemList 图标间距误当普通属性，改为实际 Theme 常量。菜单显式设置普通键盘焦点，避免仅能鼠标访问。后续修正局部命名遮蔽、测试浮点类型期望及 Theme 函数复杂度告警，没有放宽 lint 配置。

720×480 首次渲染发现候选摘要挤出底部动作，改为窄窗隐藏次要摘要、压缩元数据并保留列表空间；图像与音频状态均重新检查通过。截图驱动也同步选择实际 ItemList 项，避免截图中的高亮与摘要不一致。

提交前差异复查发现新增成功提示被放进扫描发现回调，会被原来的非空错误判断误认为失败并终止后续批次。已将提示放到对象/场景加入集合的入口，保留扫描的原错误处理；新增 40 文件跨批次扫描用例，验证扫描完成且此前成员保留。该用例首轮动态调用误传无类型数组，按实际 `Array[Resource]` 接口修正夹具后，14 项分组回归全通过。失败保留于 `verified2-asset_analysis_group.log`，最终通过为 `verified3-asset_analysis_group.log`。

一次 runner 调用误带不支持的 `--project`，只产生参数错误；改为指定工作目录后实际通过的结果是 `verified2-asset_workbench.log`，失败保留于 `final-asset_workbench.log`。手册初次构建被沙箱 npm 缓存权限阻止，同一构建命令经审批在沙箱外成功；不把环境失败归咎于源码。早期 import、test、layout 日志保留在证据目录，最终解析/渲染日志没有 SCRIPT ERROR、ERROR 或 WARNING。

## 改前 / 改后截图与人工待确认

改前图来自用户提供的截图，无法确认它精确对应哪个提交；只用于对照布局问题，不作为本轮旧版运行证据。改后图来自本次真实引擎。两张主图处于不同播放时刻，不能据此比较特效强弱。

| 截图 | 内容 |
| --- | --- |
| [改前](C:/Users/89523/.codex/visualizations/2026/09/21/01a0c467-22c6-7d93-af48-4fb1f1ef20e5/asset-workbench-ui/before.png) | 用户提供，1600×900 |
| [改后浅色](C:/Users/89523/.codex/visualizations/2026/09/21/01a0c467-22c6-7d93-af48-4fb1f1ef20e5/asset-workbench-ui/after-light.png) / [深色](C:/Users/89523/.codex/visualizations/2026/09/21/01a0c467-22c6-7d93-af48-4fb1f1ef20e5/asset-workbench-ui/after-dark.png) | 三栏、固定动作、对象上下文 |
| [小窗预览](C:/Users/89523/.codex/visualizations/2026/09/21/01a0c467-22c6-7d93-af48-4fb1f1ef20e5/asset-workbench-ui/small-preview.png) / [小窗属性](C:/Users/89523/.codex/visualizations/2026/09/21/01a0c467-22c6-7d93-af48-4fb1f1ef20e5/asset-workbench-ui/small-inspector.png) / [小窗音频候选](C:/Users/89523/.codex/visualizations/2026/09/21/01a0c467-22c6-7d93-af48-4fb1f1ef20e5/asset-workbench-ui/small-audio.png) | 720×480，各区域与公共操作 |
| [源资源分析](C:/Users/89523/.codex/visualizations/2026/09/21/01a0c467-22c6-7d93-af48-4fb1f1ef20e5/asset-workbench-ui/source-analysis.png) / [批量分析](C:/Users/89523/.codex/visualizations/2026/09/21/01a0c467-22c6-7d93-af48-4fb1f1ef20e5/asset-workbench-ui/batch-analysis.png) | 真实结果身份、核心摘要及后续详情 |

用户仍需在三个 F6 入口实际体验独立试听与 Cue 触发的听感、重复触发的视觉/声音协调、分栏拖动和键盘操作是否顺手，并确认保存后消费场景的实际使用体验。程序回归和截图检查已完成，不据此代替这些主观决定。

阅读版入口为 [空白项目使用手册](../../docs/blank-project/blank-project-handbook.html)，本轮关注“美术、音频与 Shader 资源工作台”“框架的复制与运行验证”及三入口导航；排版和浏览器交互按根规则由用户在外部检查。没有新增长期审核台账或自动同步机制。
