# 工作台第三阶段与交互组合场景实施记录

日期：2026-09-21。范围：用户已授权资源分组、批量分析、一致性检查，并明确选择“同时做一个可交互的组合场景示例，复用现有属性与分析能力”。 实现留在框架源材料；真实验证使用已指定的 `D:/A_Games/Game_idle_yaya_frame_workbench_test`。 本轮没有改变项目 Stage、Skill、Prompt、初始化规则或音频播放插件，没有新增外部依赖。

## 分辨率的实际原因与修正

源 `project-source/defaults/project.godot` 与测试项目均未设置 display/window 尺寸，旧工作台也未主动设置尺寸，因此继承 Godot 的 1152×648。 这是 [Godot 4.7 的默认 viewport 尺寸](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html#class-projectsettings-property-display-window-size-viewport-width)，不是框架要求使用的设计分辨率；旧的小窗验证夹具也使用过该尺寸。

独立运行工作台现在优先 1600×900，并限制在当前屏幕可用区域的 90% 内；保留 `--resolution` 指定值。 嵌入编辑器的 `--wid` 运行服从宿主尺寸，按钮提示先分离游戏视图；不改正式游戏全局配置。 参数语义依据 [4.7 命令行说明](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)。 实际渲染记录 `reports/asset-analysis-group/window-state.json`：窗口 1600×900、项目设置仍为 1152×648。 嵌入编辑器本身没有进行人工操作验收；这里不能据此宣称所有宿主尺寸均已验证。

## 实际交付与位置

下表路径以 `project-source/` 为根，复制后成为项目自己的文件。

| 位置 | 实际责任 |
| --- | --- |
| `tools/asset_workbench/analysis_group.gd` | 分组 v1、历史快照 v1 的结构校验和项目内 JSON 读写 |
| `analysis_group_scan.gd`（同目录） | 逐帧目录发现、隐藏/链接/生成目录排除、取消与数量上限 |
| `analysis_batch.gd`（同目录） | 批量任务状态及结果；复用现有 AnalysisService，取消只影响自身任务 |
| `analysis_group_statistics.gd`、`analysis_group_rules.gd`（同目录） | 同类统计、明确阈值与中位数偏差；规则编辑与测量分离 |
| `analysis_batch_panel.gd`（同目录） | 批量窗口、成员与规则、文件保存/加载、历史标记；将两项结果交回原 A/B 图表 |
| `composition_panel.gd`（同目录） | 每个 Cue 独立试调会话、选中对象、整体音量、逐文件保存和源资源分析 |
| `components/feedback/feedback_object.gd`、`feedback_composition.gd` | 可点击真实场景对象及明确的表现接口；复用 FeedbackPresenter，无 Analyzer 或业务奖励依赖 |
| `examples/asset_workbench/example-composition.tscn`、三个 `example-composition-*.tres` | 三对象场景与各自保存目标，独立运行读取同一数据 |
| `examples/asset_workbench/example-analysis-group.json` | 四个原有资源的分组及示例阈值 |

已有 `workbench.gd` 增加上述接入与窗口适配，`asset_browser.gd` 增加当前筛选资源的分组入口， `analysis_panel.gd` 接收已完成/历史结果，并过滤其他任务的状态信号。没有第二套资源浏览器、图表、进程执行器或缓存。 九个新增分发脚本的 `.uid` 来自测试项目的正常 Godot 导入。

## 使用闭环与数据边界

从 `examples/asset_workbench/example-workbench.tscn` 按 F6：

1. 原浏览器点击 `Add filtered candidates to group`，也可加载示例分组或扫描项目内目录。
2. `Analyze group` 使用第二阶段后台执行与内容缓存。取消或关闭只取消本组任务，保留已完成结果；失败不阻止预览、单项分析或其他成员完成。
3. 查看成员状态、可比样本数/最小值/中位数/最大值；添加 Minimum/Maximum/Max distance from median 规则。Ctrl 选择两项同类结果，直接送入原 A/B 指标/图表。
4. 保存分组和规则；需要保留本次结果时显式保存快照。历史加载显示 HISTORICAL 和原时间，重分析才检查当前文件。
5. 顶部 `Open composition scene` 打开三个可点击对象；选中后主工作台继续编辑该对象的属性与 A/B，切换对象保留各自试调。
6. 可同时触发、对三个对象的当前试调批量设音量、加入选中/全场景源分析、保存 Cue，然后独立运行组合场景读取已保存数据。

分组为 `group_version: 1`，包含 name/assets/parameters/rules；快照为 `snapshot_version: 1`，包含 group/results/created_at。 单项结果仍用原 Analyzer Schema v1。源路径保存为 `res://`，不把测试机器路径作为可迁移资源身份。 规则示例和完整字段见 [示例 JSON](../../../project-source/examples/asset_workbench/example_analysis_group.json) 与 [操作说明](../../../project-source/tools/asset_analyzer/README.md#分组批量分析与一致性检查)。

只统计 available 的数值，缺失、不适用、不支持、失败均不补零。资源类型、单位、Schema、Analyzer/后端版本、参数不同则分组统计。 相对中位数偏差至少需要 3 个可比测量，显示实际值、距离和样本数；不足时为 unmeasured。阈值来自明确规则，不生成审美分数。 上限为每组 512 个资源、64 条规则，扫描 50,000 条目录项，每帧最多 32 条/约 3 ms；快照读入限制 32 MiB。 增量目录遍历减少阻塞，但同步文件系统调用仍可能受慢盘影响；本轮没有验证网络目录吞吐。

组合场景的批量保存复用原 PreviewSession 的冲突检查和保存，不是多文件事务：分别报告成功与冲突，失败对象保留试调。 批量音量只修改每个对象当前 A/B，不改另一方案、原图或音频文件；源分析不等于最终混音或渲染画面测量。 示例重复使用已有 CC0 素材，未复制新媒体或改变原文件字节；新增示例文件均为 `example-` 前缀。

## 验证环境与命令

Windows 11、Godot **4.7.1.stable.official.a13da4feb**、CPython **3.12.13**。 分析继续使用第二阶段锁定的 PyAV 18.1.0、Pillow 12.3.0、NumPy 2.5.3、pyloudnorm 0.2.0、SciPy 1.18.1， 版本和许可沿用 [依赖记录](../../../project-source/tools/asset_analyzer/DEPENDENCIES.md)。本轮没有重新选型、升级或新增后端。 SoundManager 及 AudioPlayback 封装保持不变。

维护回归在框架根运行：

```powershell
& 'C:/Users/89523/anaconda3/envs/codex-python/python.exe' -B -m unittest discover -s framework/tests -p test_*.py
```

三个新增维护夹具位于 `framework/tests/project/`，只按本次范围复制进指定测试项目： 两个 suite 分别放入 `tests/features/asset_analysis_group/`、`tests/features/asset_composition/`，capture 放入 `tests/`。 依赖第二阶段已有 `tests/features/asset_analyzer/analyzer_process_fixture.py` 与实际安装环境。以下在该外部项目根运行，外部写入/引擎执行已按本机审批路径执行：

```powershell
$python = 'C:/Users/89523/anaconda3/envs/codex-python/python.exe'
$godot = 'E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe'
& $python -B tools/testing/run-gdunit-tests.py --godot-binary $godot --target tests/features/asset_analysis_group/asset_analysis_group_test.gd --continue
& $python -B tools/testing/run-gdunit-tests.py --godot-binary $godot --target tests/features/asset_composition/asset_composition_test.gd --continue
& $python -B tools/testing/run-gdunit-tests.py --godot-binary $godot --target tests/features/asset_analyzer/asset_analyzer_test.gd --continue
& $python -B tools/testing/run-gdunit-tests.py --godot-binary $godot --target tests/features/asset_workbench/asset_workbench_test.gd --continue
& $godot --path . --script res://tests/asset_analysis_group_capture.gd | Out-Host
& $godot --headless --path . --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --json --output reports/asset-analysis-group/lint-final.json res:// | Out-Host
```

## 实际结果

以下证据路径相对外部测试项目，均为本轮运行；不是沿用第二阶段通过记录。

| 检查 | 结果与证据 |
| --- | --- |
| 分组批量 | **12/12**，`reports/gdunit-wrapper/run-39rm0fpt/result.json`；结构/上限、单位版本参数分组、缺失状态、真实四资源分析/缓存、独立任务取消、中文空格路径扫描/取消、JSON、历史与内容变化重算、复用 A/B、失败后实际声音仍播放 |
| 组合场景 | **6/6**，`run-9cvi7w_b/result.json`（同上级目录）；选择切换、每对象 A/B、批量音量隔离、分析资源去重、部分保存/冲突、真实消费、同时播放与延迟停止、独立场景运行 |
| 第二阶段回归 | **12/12**，`run-3l3chrim/result.json`；实际后台分析与异常、队列、缓存、图表和显示语义 |
| 第一阶段回归 | **12/12**，`run-64y2yhvq/result.json`；预览/试听、绑定/试调、主题、停止与保存/消费 |
| GDScript lint | **34 文件，0 Critical / 0 Warning**，`reports/asset-analysis-group/lint-final.json`；未禁用规则或降低阈值 |
| 维护测试 | **38/38** unittest；本轮未运行 pytest，没有把其写为通过 |
| 实际渲染 | Vulkan / RTX 4060 Laptop GPU；`reports/asset-analysis-group/capture-final.log` 退出 0。Agent 查看大窗、组合与分组浅/深色、小窗及滚动后图；组合 600×400 可滚至最后对象，分组 620×440 可滚至详情，保存了断言与截图 |
| 使用手册 | 现有生成器构建通过：**22 篇、33 张 Mermaid、475 个源链接**。命令沿用维护说明；未使用 Playwright，未将 HTML 构建当作排版人工验收 |

渲染证据包括 `workbench-large.png`、`composition-light.png`、`composition-dark.png`、`composition-compact*.png`、 `group-light.png`、`group-dark.png`、`group-compact*.png`，以及实际 `batch-results.json`。 最初迭代发现类型推断/诊断、原生子窗口设置顺序、断言参数类型、截图等待时序和滚动容器定位问题，均已修复后执行上表验证；旧失败日志不作为通过证据。 最后补充扫描回调取消检查，防止组满额后的提示被“完成”覆盖，分组 suite 已再次通过。

## 验收边界与后续

自动验证覆盖本次授权的组合示例及第三阶段基础批量闭环，用户仍需实际体验窗口、交互、听感和操作效率。 没有运行时自然语言场景生成器、通用拖拽/任意节点属性编辑；Agent 可根据描述编写原生 `.tscn`，通过明确接口接入真实对象。 本例批量属性只提供音量，其他共同属性应按具体游戏对象扩展；当前不做聚类、语义风格判断、跨历史趋势或高级音乐指标。

未改第一阶段 Cue/播放器/保存实现，只增加选择会话与新入口；新场景复用已有表现组件。 新源文件由现有 tools/components/examples 递归映射复制，框架默认环境仍为 incomplete；本机配置、runtime/cache/history/测试结果留在外部项目。 本轮没有再做第二路径无缓存创建，也没有重新执行完整需求到 Feature 结束的流程抽样；相关缺口继续保留在 [框架进度](../../progress.md)。
