# 框架的复制与运行验证

[维护文档入口](README.md) · 相关：[维护与同步](updating-the-blank-project.md#按修改选择验证范围)、[创建器契约](../operation-manual/框架基础/framework-and-project.md#创建器用法)

`project-source/` 是未初始化的分发材料，包含最小入口 `main/main.tscn`；不在这里启动 Godot， 不预置实际游戏玩法、本机就绪配置、业务需求或已完成任务。可用性通过源材料检查和独立项目中的真实运行共同验证。

## 分层验证

| 层次 | 要检查的结果 | 证据与限制 |
| --- | --- | --- |
| 源材料与分发 | 清单可展开；相对引用、JSON/TOML、Skill 元数据、Prompt 路由及文档链接一致；默认配置不包含就绪结论；GDD 目录和 Product 只保留用途说明，Feature/Registry 无业务条目 | 静态核对及创建器回归；不代表引擎或 Agent 已执行 |
| 项目工具 | 在指定外部项目调用既有工具回归，验证输入拒绝、任务规划/演进、测试选择、证据、人工记录及文档指纹 | unittest 是工具契约验证；合成夹具不是实际游戏或人工体验 |
| 新项目初始化 | 从正式复制清单创建全新外部目录；核实工具版本、环境检查通过、正常导入与随带最小入口；按授权实际启动 | 保留实际命令、退出码、配置与初始化报告；就绪检查、入口存在、启动成功和测试通过分别判断 |
| 真实 Godot 行为 | 导入真实资源；解析、lint、gdUnit、独立入口及消费场景实际运行；按本次变化检查保存、重载、取消、音频和生命周期 | 原始引擎/JUnit/诊断、可选截图与运行观察；画面和声音的人工接受单独记录 |
| 工作流与迁移 | 对一个明确的小任务，实际经过需求、规划、开发/维护、验证、记录和续接；再在新路径从无缓存副本核对启动与资源引用 | 标明实际执行的 Skill/脚本和未经过分支；不能据一次样例宣称全部 Skill、所有提示词及所有平台已验证 |

每次按改动选择适用层，不要求纯文档修改也建立游戏项目。

- **命令入口**：见 [维护工具](../../README.md#按需检查)。
- **流程入口**：提示词库中的“想用一个小任务实际验证框架流程”。Skill 是 Agent 阅读的方法，Prompt 是输入。
- **证据区分**：格式检查、脚本测试和一次真实委派是三种不同证据。
- **未验证项**：reviewer/researcher 的客户端加载与独立实例执行没有实测时，必须明确保留该缺口。

## 测试载体与文件归属

按验证目标选择载体：

- **复制、首次初始化或干净重建**：按授权从当前源材料创建全新外部项目，避免缓存或旧文件遮住遗漏。
- **工具回归或局部集成**：使用明确指定的既有外部项目，核对被测文件对应本次修复；不为普通回归重新创建项目。

测试项目独立拥有文件，只在本次授权内修正具体文件，不增加自动同步或升级机制。

| 文件类别 | 保留位置 | 是否回到分发材料 |
| --- | --- | --- |
| 最小入口与共同骨架、框架通用代码、必要第三方依赖和明确提供的 `example_*` 素材 | `project-source/` | 属于正式分发源，通过清单复制 |
| Godot 为这些源文件生成的可移植 `.gd.uid`、素材 `.import` | 经目标版本核验后随对应源文件保留 | 可以，范围限定在本次正式分发文件；不复制 `.godot` 缓存 |
| 回归套件、截图驱动、合成任务与测试资源 | `framework/tests/` 的维护夹具，以及外部项目 `tests/` | 不进入 `project-source/` 或复制清单 |
| 测试项目名称/主场景、本机工具配置、GDD、Product、Feature、测试登记表、Git 历史 | 外部测试项目 | 不回灌；分发默认文件不夹带该项目的业务条目或就绪结论 |
| 导入缓存、引擎日志、JUnit、截图、测试运行证据 | 外部项目 `.godot/`、`reports/` | 不回灌；维护报告只链接和总结事实 |

已经初始化且非空的项目可以作为有明确范围的集成验证载体，但不能直接用创建器覆盖。现有创建器只接受不存在或空的目标；已有 `project.godot`、机器配置与业务文件须按接入/迁移范围逐项合并。新项目复制后可以导入已有 GDD，也可以在获准范围内使用 `design-gdd` 形成设计；环境准备与具体运行依实际任务安排，依赖设计的实施须等待当前范围明确。维护层中立工具夹具不冒充游戏项目。“小任务验证”入口仍限定使用已有 GDD，不因新增设计能力而自动扩大为从零创作或修改验证项目的游戏目标。

## 一次有意义的流程抽样

执行入口见[小任务验证场景](<../quick-reference/Yaya 框架维护/维护与复盘/想用一个小任务实际验证框架流程.md>)。本节只限定证据含义：

- 已有实现的保存、消费和试调回归，只证明本轮实际运行的行为，不证明重新经历了需求、规划和开发。
- 补录文档不能充当当时进行需求讨论或 TDD 的证据；一个样例不能证明所有 Skill 和提示词已执行。
- 涉及观感、音色与手感的 AC 仍需实际人工验收；实施授权与自动化通过不能替代它。

迁移检查使用另一条干净路径、无 `.godot` 缓存和无已初始化数据的副本重新导入、加载资源与启动入口。 可以在指定测试项目已被 `.gdignore` 排除的报告区放置独立子项目，避免外层 Godot 扫描到重复全局类。 这证明本次版本在所测 Windows/Godot 版本和路径下可重建；跨机器仍需重新完成工具路径配置与验证。

## lint 与运行器专项入口

这些夹具验证工具本身，不随新项目分发，也不要求每次维护都运行。源文件在 `framework/tests/project/`。先选择本次获准的外部项目，核对其 Godot、插件和被测工具；首次运行按[项目工具说明](../../../project-source/tools/README.md#首次-godot-扫描)完成导入。

| 夹具 | 入口与用途 | 输出及副作用 |
| --- | --- | --- |
| `gdscript_lint_contracts.gd` | SceneTree 脚本；检查解析、度量、忽略指令及具体诊断规则 | `--` 后唯一参数是 JSON 报告路径；只在内存中构造被分析代码 |
| `gdscript_lint_entry_contracts.gd` | SceneTree 脚本；检查 CLI 参数、配置拒绝、退出码与 JSON 一致性 | 同上；临时替换根目录 `gdlint.json`，创建 `gdlint-entry-contracts*` 文件，正常结束恢复。已有同名残留时拒绝运行，只用于可丢弃的外部项目 |
| `gdscript_lint_editor_contracts.gd` | 临时 EditorPlugin；检查真实面板加载、控件保存及重建 | 参数为 `--lint-editor-contracts <报告路径>`；临时修改项目配置和本机 `code_quality/*` 编辑器设置，正常结束恢复，不能与其他编辑器实例并行 |
| `gdunit_runner_contracts.gd` | gdUnit 套件；检查真实发现、参数化、预期错误和未处理的引擎错误 | 使用现有运行器及其 `result.json`；设置 `YAYA_RUNNER_REGRESSION_FAILURE=native` 的负向运行应失败，不能算业务测试失败或改报为通过 |

两个 SceneTree 夹具放到外部项目 `tests/contracts/`，报告父目录须先存在。在该项目根目录，用已配置的 Godot 执行所选文件，例如：

```powershell
$validationGodot = (Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json).engine_executable
New-Item -ItemType Directory -Path 'reports/maintenance' -Force
& $validationGodot --headless --path . --script res://tests/contracts/gdscript_lint_contracts.gd -- reports/maintenance/lint-contracts.json | Out-Host
$LASTEXITCODE
```

每轮使用不覆盖旧证据的报告名。核对进程退出码与 JSON 的 `failures`；CLI 夹具内故意触发的拒绝由夹具断言核实，不凭日志出现错误字样就判整项失败。异常中断时先检查备份和临时文件，不能覆盖残留后重跑。

编辑器夹具不能用 `--script` 启动。将它放到外部项目 `addons/maintenance_lint_contracts/`，在同目录建立临时 `plugin.cfg`：

```ini
[plugin]
name="Maintenance lint contracts"
description="Temporary lint editor checks"
author="Framework maintenance"
version="1.0"
script="gdscript_lint_editor_contracts.gd"
```

备份项目配置及相关编辑器设置，把这个插件加入项目的启用列表，再执行 `& $validationGodot --headless --editor --path . -- --lint-editor-contracts reports/maintenance/lint-editor-contracts.json | Out-Host`。检查退出码与报告；结束后恢复临时插件配置，异常中断还需恢复被测设置。不要在日常开发项目中做这一项检查。

运行器夹具放到 `tests/features/gdunit_runner/`。用配置中的 Python 调用 `tools/testing/run-gdunit-tests.py --target tests/features/gdunit_runner`，先确认正常运行通过；再仅为该进程设置上述负向环境变量，确认即使四个断言通过，未处理引擎错误仍使运行器失败。结束后恢复原环境变量，保留两次独立结果；不需要创建 Feature 或填写验收记录。

## 工作台专项验证入口

先按本次修改选择下列小节，不要求每轮运行全部夹具。源文件均在 `framework/tests/project/`，仅将需要的文件复制到明确指定的外部验证项目；运行前确认被测文件对应本次改动，保留该项目机器配置与无关内容。

### 功能、保存与错误恢复

**适用变化：** Cue 参数、A/B、保存、播放生命周期、管理编排或故障恢复。将套件放入外部项目 `tests/features/<职责名>/`，职责名为文件名去掉 `_test.gd`，再使用现有 `run-gdunit-tests.py --target` 或已登记 Feature 运行。

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

保存测试在各自测试目录或上表指定的报告目录写临时 Cue/资源，不修改示例 Cue。冷释放与已入树后的装卸是不同分支，不能互相替代。

相关套件的依赖与分工如下：

- **后台与协议验证**：`asset_analyzer_test.gd` 同时需要同目录的 `analyzer_process_fixture.py` 和 `analyzer_protocol_cases.json`，三者放入 `tests/features/asset_analyzer/`。单独复制套件不能证明已具备运行条件。
- **批量源格式契约**：由上表的独立套件维护。
- **集合、规则和历史**：`asset_analysis_group_test.gd` 继续核对其余职责，不重复承担源格式用例。其取消隔离测试也依赖 `tests/features/asset_analyzer/analyzer_process_fixture.py`；即使不运行单项分析套件，也必须将该 worker 复制到这个规定路径。

编排边界测试关闭该播放器的自动 process 后显式推进时间；声音取消另用真实场景时钟等待，不证明逐采样同步。管理器对象预算与生命周期回归也不替代规模测量。

### Python 分析后端与内存边界

这两项从框架根目录直接调用维护夹具，通过 `YAYA_TEST_PROJECT` 选择已授权外部项目，不复制为业务测试。先按 [Analyzer 安装说明](../../../project-source/tools/asset_analyzer/README.md)准备该项目的固定版本依赖；后端测试还需要调用解释器可导入 `jsonschema`，并保留夹具旁的 `analyzer_protocol_cases.json`。建立外部项目的 `reports/asset-analyzer/` 后运行，示例项目路径须替换为本次实际路径：

```powershell
$env:YAYA_TEST_PROJECT = 'D:/A_Games/YayaValidation'
$validationPython = 'C:/Users/89523/anaconda3/envs/codex-python/python.exe'
```

| 夹具与命令（按需选择） | 检查及副作用 |
| --- | --- |
| `& $validationPython -B framework/tests/project/asset_analyzer_backend_test.py` | 实际音频/图像后端、错误输入、缓存与协议；写入专属临时媒体及缓存，正常清理；以 unittest 结果与退出码判断 |
| `& $validationPython -B framework/tests/project/asset_analyzer_memory_check.py` | Windows 子进程内存限制、边界素材及双 worker 测量；生成并清理临时媒体和本次缓存，固定写入外部项目 `reports/asset-analyzer/memory-check.json` |

内存测量会覆盖同名报告，先保留仍需使用的旧结果。检查真实进程退出码、内存记录和分配拒绝断言，不把一次测量推广为所有素材或设备的性能保证。结束后恢复原 `YAYA_TEST_PROJECT` 环境变量。

### 渲染、交互与源分析

**适用变化：** 布局、输入路由、材质/粒子效果、分析窗口或编排画面。使用真实显示驱动，不支持 headless 截图。窗口夹具按各自范围检查浅深色、1600×900、1152×648、900×540、720×480；分析窗口另检查紧凑尺寸与滚动。

| 要观察的内容 | 捕获文件 | 实际检查 |
| --- | --- | --- |
| 原三个工作台与单对象消费 | `asset_workbench_capture.gd` | 图像/音频候选、固定停止/保存、真实鼠标/键盘、窗口布局 |
| Shader | `asset_shader_render_capture.gd` | 真实像素与停止恢复 |
| 单项/批量源分析 | `asset_analyzer_capture.gd`、`asset_analysis_group_capture.gd` | 实际分析结果来源、图表/集合访问及跳过原因 |
| 粒子与动画 | `asset_effect_render_capture.gd` | GPU 粒子重触发/停止/结束、动画变换恢复、第四入口与消费 |
| 组合复用 | `asset_composition_reuse_capture.gd` | 局部/场景粒子位移及变换后的双组合消费 |
| 编排 | `asset_feedback_timeline_capture.gd` | 第四入口编排操作、消费分阶段画面和重复装卸回收 |

**运行前选择输出位置：** 以下是源夹具当前默认目录，均相对外部项目，并非“本轮已通过”的记录。重用夹具时只改获准外部副本的输出位置，保留失败与仍被引用的旧截图，不覆盖历史证据。

| 夹具 | 默认输出 |
| --- | --- |
| 工作台、Shader、单项分析、批量分析 | `reports/asset-workbench-ui-20260922/`；后三者分别在 `shader/`、`analysis/`、`group/` 子目录 |
| 粒子与动画 | `reports/asset-workbench-effects-20260922/`，按渲染器分目录 |
| 组合复用 | `reports/asset-workbench-e3-e4-20260922/`，按渲染器分目录 |
| 编排 | `reports/asset-workbench-e5-e6-20260922/`，按渲染器分目录 |

结果只证明实际执行的渲染器和样例；协调性、听感与操作舒适度仍需人工体验。粒子画面和源资源 Analyzer 的测量不能互相替代。

### 规模测量

**适用变化：** 对象数量、加载或重复播放成本、长时回收。使用 `asset_effect_scale_probe.gd`，先核实负载和预算，不并行运行多个 GPU 测量。

探针使用真实 Presenter，按以下维度测量：

- **显示范围**：1600×900 内的 8/32/128 对象。
- **重触发间隔**：比较 0.6 s 与 0.1 s。
- **持续运行与装卸**：另测 128 对象 120 s，以及每轮 32 对象的 10 轮装卸。

默认输出为外部项目 `reports/asset-workbench-e3-e4-20260922/`，新一轮应选择不覆盖旧证据的位置。

测量记录设备/渲染器、应用帧间隔、引擎进程时间、Godot 内存计数和节点，不是独占 GPU 时间、进程工作集或其他设备保证。草稿清空声音、粒子延迟置零以避免快速重触发抑制发射；原 Cue 不改，声音行为由功能套件单独回归。

不要把热身缓存或探针采样数组增长直接判为泄漏，也不为压测提前引入池化。功能回归通过不证明 128 对象性能改善。

### 独立消费与导出

**适用变化：** 消费资源引用、运行脚本依赖或导出排除规则。使用 `asset_consumer_export_presets.cfg` 与 `asset_consumer_export_probe.gd`；它们只用于维护验证，不进入分发清单，也不是生产导出配置。

**预设前置：** 仅在指定项目没有 `export_presets.cfg` 时临时安装测试预设；已有预设不得覆盖，先按本次授权选择隔离办法。

1. 使用测试预设选择四消费场景及依赖，包含表现脚本、局部音频池和许可；排除工作台、Analyzer、测试及维护材料。
2. 通过 Godot `--export-pack` 输出到本轮报告区，保留原始失败包和日志。
3. 从报告目录用 `--main-pack` 启动探针，在 `--` 后传唯一的绝对 JSON 输出路径。从项目根启动会让源文件掩盖缺漏，不构成同样的验证。
4. 核对四入口的 Cue、真实声部、组合/编排、停止/回收和工具目录缺席；结束后将临时预设恢复到原先不存在的状态。

独立资源包运行不等于签名安装包、发行模板或其他平台已验证。

### 查阅已有验证结果

以往验证结果通过 Git 历史查阅。旧结果只适用于当时的版本和执行范围，不能代替本次运行或人工验收。
