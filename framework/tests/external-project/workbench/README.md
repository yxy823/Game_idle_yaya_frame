# 资源工作台验证夹具

[测试与夹具](../../README.md#按需检查) · [验证范围](../../../maintenance/validation/validation-scope.md)

本目录保存资源工作台、Analyzer 与表现组件的维护夹具。按本次修改选择需要的小节，不需要每次运行全部夹具：

| 本次修改了什么 | 看哪一节 |
| --- | --- |
| Cue 参数、A/B、保存、播放生命周期、管理与编排、故障恢复 | [功能、保存与错误恢复](#功能保存与错误恢复) |
| Analyzer 的 Python 后端、协议或内存限制 | [Python 分析后端与内存边界](#python-分析后端与内存边界) |
| 布局、输入、材质与粒子效果、分析窗口或编排画面 | [渲染、交互与源分析](#渲染交互与源分析) |
| 对象数量、加载或重复播放成本、长时间回收 | [规模测量](#规模测量) |
| 资源引用、运行脚本依赖或导出排除规则 | [独立消费与导出](#独立消费与导出) |

通用要求：

- 只把需要的文件复制到明确指定的外部验证项目。
- 运行前确认被测文件对应本次修改。
- 保留该项目的机器配置和无关内容。

## 功能、保存与错误恢复

**适用变化**：Cue 参数、A/B、保存、播放生命周期、管理编排或故障恢复。

**放置与运行**：把套件放到外部项目的 `tests/features/<职责名>/`，职责名是文件名去掉 `_test.gd`；然后用现有的 `run-gdunit-tests.py --target` 运行，或作为已登记的 Feature 运行。

| 变化范围 | 套件文件 | 主要核对 |
| --- | --- | --- |
| 基础试调与保存 | `asset_workbench_test.gd` | 草稿隔离、磁盘冲突、无效/边界参数、保存消费、延迟取消、重叠上限、浏览与绑定、A/B/连续触发、主题不改数据 |
| 多对象工作台 | `asset_composition_test.gd` | 对象选择、独立草稿、批量增益、部分保存与消费；运行前建立 `reports/asset-analyzer/`，临时 Cue 在该目录创建并清理 |
| Shader 组合 | `asset_shader_composition_test.gd` | Shader 重启、结束/停止恢复、独立资源保存与消费；套件必须放在 `tests/features/asset_shader_composition/`，其 `test-shader-cue.tres` 会被写入并删除，运行前确认不存在 |
| 粒子、Tween 与动画 | `asset_effect_composition_test.gd` | 延迟/结束/停止、变换归属、重触发与退出取消、字段保存及源分析边界 |
| 组合复用与共享 Cue | `asset_composition_reuse_test.gd` | 多实例草稿、共享保存分歧/外部冲突、消费与移除清理 |
| 管理与编排 | `asset_playback_manager_test.gd`、`asset_feedback_timeline_test.gd`、`asset_timeline_integration_test.gd` | 句柄/预算、分组/抢占、待播音频、接管、冷释放/离树/重入；编排重读、窗口/循环/迟帧、草稿与原生消费 |
| 消费依赖与启动恢复 | `asset_consumer_boundary_test.gd`、`asset_workbench_recovery_test.gd` | 四类入口未入树释放、显式 Cue 依赖、最近保存值、缺 Cue 恢复、不支持项/重复/容量反馈 |
| 批量源格式契约 | `asset_analysis_source_contract_test.gd` | 独立检查当前源格式配置、配置变化与错误恢复；历史结果读取不依赖当前源格式配置 |

`asset_workbench_test.gd` 的 `test_analysis_identity_survives_browsing_and_late_completion` 会实际启动 Analyzer：运行前按 [Analyzer 安装说明](../../../../project-source/asset_workbench/analyzer/README.md)在外部项目安装依赖。没装时 Analyzer 按设计返回 `dependency_missing`，这个用例因此失败，不代表工作台有问题。

保存测试在各自测试目录或上表指定的报告目录写临时 Cue/资源，不修改示例 Cue。冷释放与已入树后的装卸是不同分支，不能互相替代。

相关套件的依赖与分工如下：

- **后台与协议验证**：`asset_analyzer_test.gd` 同时需要同目录的 `analyzer_process_fixture.py` 和 `analyzer_protocol_cases.json`，三者放入 `tests/features/asset_analyzer/`。单独复制套件不能证明已具备运行条件。
- **集合、规则和历史**：`asset_analysis_group_test.gd` 继续核对其余职责，不重复承担源格式用例。其取消隔离测试也依赖 `tests/features/asset_analyzer/analyzer_process_fixture.py`；即使不运行单项分析套件，也必须将该 worker 复制到这个规定路径。

编排边界测试关闭该播放器的自动 process 后显式推进时间；声音取消另用真实场景时钟等待，不证明逐采样同步。管理器对象预算与生命周期回归也不替代规模测量。

## Python 分析后端与内存边界

这两项从框架根目录直接调用维护夹具，通过 `YAYA_TEST_PROJECT` 选择已授权外部项目，不复制为业务测试。先按 [Analyzer 安装说明](../../../../project-source/asset_workbench/analyzer/README.md)准备该项目的固定版本依赖；后端测试还需要调用解释器可导入 `jsonschema`，并保留夹具旁的 `analyzer_protocol_cases.json`。建立外部项目的 `reports/asset-analyzer/` 后运行，两个占位值替换为本次实际路径（解释器使用外部项目 `docs/methodology-config.json` 中已确认的 `python_executable`）：

```powershell
$env:YAYA_TEST_PROJECT = '<外部验证项目绝对路径>'
$validationPython = '<已确认的 Python 3.12+ 解释器路径>'
```

| 夹具与命令（按需选择） | 检查及副作用 |
| --- | --- |
| `& $validationPython -B framework/tests/external-project/workbench/asset_analyzer_backend_test.py` | 实际音频/图像后端、错误输入、缓存与协议；写入专属临时媒体及缓存，正常清理；以 unittest 结果与退出码判断 |
| `& $validationPython -B framework/tests/external-project/workbench/asset_analyzer_memory_check.py` | Windows 子进程内存限制、边界素材及双 worker 测量；生成并清理临时媒体和本次缓存，固定写入外部项目 `reports/asset-analyzer/memory-check.json` |

内存测量会覆盖同名报告，先保留仍需使用的旧结果。检查真实进程退出码、内存记录和分配拒绝断言，不把一次测量推广为所有素材或设备的性能保证。结束后恢复原 `YAYA_TEST_PROJECT` 环境变量。

## 渲染、交互与源分析

**适用变化**：布局、输入路由、材质/粒子效果、分析窗口或编排画面。使用真实显示驱动，不支持 headless 截图。窗口夹具按各自范围检查浅深色、1600×900、1152×648、900×540、720×480；分析窗口另检查紧凑尺寸与滚动。

| 要观察的内容 | 捕获文件 | 实际检查 |
| --- | --- | --- |
| 原三个工作台与单对象消费 | `asset_workbench_capture.gd` | 图像/音频候选、固定停止/保存、真实鼠标/键盘、窗口布局 |
| Shader | `asset_shader_render_capture.gd` | 真实像素与停止恢复 |
| 单项/批量源分析 | `asset_analyzer_capture.gd`、`asset_analysis_group_capture.gd` | 实际分析结果来源、图表/集合访问及跳过原因 |
| 粒子与动画 | `asset_effect_render_capture.gd` | GPU 粒子重触发/停止/结束、动画变换恢复、第四入口与消费 |
| 组合复用 | `asset_composition_reuse_capture.gd` | 局部/场景粒子位移及变换后的双组合消费 |
| 编排 | `asset_feedback_timeline_capture.gd` | 第四入口编排操作、消费分阶段画面和重复装卸回收 |

**运行前选择输出位置**：下表是各夹具当前的默认输出目录（相对外部项目），目录名中的日期只是默认值，不代表已经运行过。重复使用夹具时，只修改获准使用的外部副本中的输出位置；失败的截图和仍被引用的旧截图都要保留，不覆盖历史证据。

| 夹具 | 默认输出 |
| --- | --- |
| 工作台、Shader、单项分析、批量分析 | `reports/asset-workbench-ui-20260922/`；后三者分别在 `shader/`、`analysis/`、`group/` 子目录 |
| 粒子与动画 | `reports/asset-workbench-effects-20260922/`，按渲染器分目录 |
| 组合复用 | `reports/asset-workbench-e3-e4-20260922/`，按渲染器分目录 |
| 编排 | `reports/asset-workbench-e5-e6-20260922/`，按渲染器分目录 |

结果只证明实际执行的渲染器和样例；协调性、听感与操作舒适度仍需人工体验。粒子画面和源资源 Analyzer 的测量不能互相替代。

## 规模测量

**适用变化**：对象数量、加载或重复播放成本、长时回收。使用 `asset_effect_scale_probe.gd`，先核实负载和预算，不并行运行多个 GPU 测量。

探针使用真实 Presenter，按以下维度测量：

- **显示范围**：1600×900 内的 8/32/128 对象。
- **重触发间隔**：比较 0.6 s 与 0.1 s。
- **持续运行与装卸**：另测 128 对象 120 s，以及每轮 32 对象的 10 轮装卸。

默认输出为外部项目 `reports/asset-workbench-e3-e4-20260922/`，新一轮应选择不覆盖旧证据的位置。

测量记录设备/渲染器、应用帧间隔、引擎进程时间、Godot 内存计数和节点，不是独占 GPU 时间、进程工作集或其他设备保证。草稿清空声音、粒子延迟置零以避免快速重触发抑制发射；原 Cue 不改，声音行为由功能套件单独回归。

不要把热身缓存或探针采样数组增长直接判为泄漏，也不为压测提前引入池化。功能回归通过不证明 128 对象性能改善。

## 独立消费与导出

**适用变化**：消费资源引用、运行脚本依赖或导出排除规则。使用 `asset_consumer_export_presets.cfg` 与 `asset_consumer_export_probe.gd`；它们只用于维护验证，不进入分发清单，也不是生产导出配置。

**预设前置**：只有在指定项目还没有 `export_presets.cfg` 时，才临时安装测试预设。已有预设不能覆盖，要先按本次授权选择隔离办法。

1. 使用测试预设选择四消费场景及依赖，包含表现脚本、局部音频池和许可；排除工作台、Analyzer、测试及维护材料。
2. 通过 Godot `--export-pack` 输出到本轮报告区，保留原始失败包和日志。
3. 从报告目录用 `--main-pack` 启动探针，在 `--` 后传唯一的绝对 JSON 输出路径。从项目根启动会让源文件掩盖缺漏，不构成同样的验证。
4. 核对四入口的 Cue、真实声部、组合/编排、停止/回收和工具目录缺席；结束后将临时预设恢复到原先不存在的状态。

独立资源包运行不等于签名安装包、发行模板或其他平台已验证。
