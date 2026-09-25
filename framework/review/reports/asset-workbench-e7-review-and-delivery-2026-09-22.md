# Asset Workbench E7 独立审核、修复与交付

日期：2026-09-22。基线 `a07cdb6dbf6c984b03b8d4e834b93adcae51ef56`，开始时工作区干净。 用户授权执行 E7、调用项目审核 Agent 全面审核并修改成立问题；沿用既有外部验证项目的定向同步与真实验证授权。

## 本轮结果与范围

E7 的整合、独立审核、五项修复与自动验证已完成，新增效果的人工体验仍待确认。 保持四个独立 F6 工作台、图像/音频/Shader/粒子独立可空、Tween/AnimationPlayer、对象/场景/分析 A/B、共享 Cue 逐文件保存、源分析，以及 E5 局部 Manager / E6 有限编排。 本轮收敛消费依赖和错误恢复，整理代表性入口及导出说明；没有实施 E2 内容扩展、扩大 Manager/Timeline、建立资源数据库或新的流程状态系统。

没有发现需要为整合而新增通用层或重写 Inspector 的证据：候选仍是明确的小集合，现有响应式布局和参数分组继续可用；统一的是源分析入口对已有 `Source.describe()` 的复用。 E4 的设备/样例性能边界继续有效，本轮不重跑 128 对象压测，不将生命周期修复或三个受管对象预算称为性能保证。

## 独立性与实际审核覆盖

新实例未继承作者会话，显式读取 [项目审核角色](../../../project-source/agents/independent-reviewer.toml)、[独立审核规范](../../../project-source/methodology/12-independent-review.md) 及 code、UX、assets、audio、art 五种 review Skills。 当前委派工具没有按 TOML 名称选择角色的参数，因此这里是 fresh 实例手动加载角色约定，不能声称客户端自动选中了配置或 TOML 建立了只读沙箱。 实际共享工作区有写权限；审核实例及其一个 fresh 支持实例遵守只读约束，没有修复、运行 Godot、提交或记录验收。作者负责复现、修改和执行验证。

覆盖 `components/feedback/`、工作台及相关分析调用链、四类消费场景/资源引用、A/B/共享保存与错误恢复、Manager/Timeline 生命周期、实际测试断言、原始日志/截图、复制清单和相关说明。 不是全框架无关模块审核，也没有重新推导每个 Analyzer 数值算法。旧 E5/E6 证据只作为基线，未冒称本轮通过。 旧 `run-kp9_etvb/result.json` 对审核实例的直接读取受限；作者沿审批路径只读取得并转交字段，审核者另直接读取行为日志与其他证据。本轮最终日志与结果已由审核者直接核对。

审核先针对固定基线提出 R1–R5，修改后再检查当前差异、调用方、原始结果及必要截图。 最终独立结论为：**五项均已解决，定向复核未发现新增 must_fix；需求符合性与代码质量均支持本轮交付，但不代替人工体验。**

## 发现、复核与修复

五项均为独立审核的 P2 / must_fix；下表以实际触发和证据解释取舍，不依赖等级替代判断。

| 编号 | 原问题与实际证据 | 本轮修复及最小方案取舍 | 结果 |
| --- | --- | --- | --- |
| R1 | `feedback_object.gd`、单对象消费以字符串加载 Cue，场景没有声明依赖；按原说明仅选四消费场景导出的包只有 23 文件，没有 Cue、媒体及 Presenter 等脚本。包独立启动出现缺文件和解析错误 | 消费场景改为显式 `cue_resource: FeedbackCue`；对象保存路径从引用派生，启动仍绕过 Cue 缓存重读。补充导出时显式包含运行脚本和许可的说明，不建立自有依赖管理器或生产导出配置 | 新包包含 Cue/媒体/预设与 17 份运行脚本，不含工作台/Analyzer/测试；四入口独立运行通过。缓存场景读取最近保存值且不改共享引用的断言通过 |
| R2 | `single/example_reward_game.gd` 预加载工作台 Theme，排除开发工具后消费场景无法加载 | 仅为白底 Label 设置本地黑字，按钮沿用原生样式/状态/焦点；移除工具依赖，不复制完整 Theme 或新增主题层 | 独立包、颜色/焦点断言与新消费截图通过 |
| R3 | 节点先构造、到 `_ready()` 才挂接，冷实例直接释放泄漏。真实引擎测得单对象/普通组合/Shader/效果消费分别增加 12/33/33/66 个孤儿，四工作台各增加 470 个 | 消费内部节点在构造时建立归属；工作台 UI 延后至实际组装时创建。没有另增析构补偿集合或生命周期管理层 | 四消费、四工作台及 ObjectView/Game 直接构造释放均回到原始孤儿基线；正常播放/装卸继续通过 |
| R4 | `analysis_batch_panel.open_assets()` 按输入数量报告成功，Batch 实际跳过不支持路径。Atlas 输入产生“收集 1”但集合为 0 | 复用 `Source.describe()`，区分实际新增、已有、跳过和未加入，显示原因，保留 busy/512 上限及部分加入结果；不自动展开间接资源或扩 Analyzer | Atlas/SVG、重复、空/null、忙碌、容量、候选/对象/场景入口及 Cue 不变断言通过；紧凑窗口原因可读 |
| R5 | 首次 Cue 加载失败留下空 drafts，对象源分析直接访问索引 0，真实日志出现越界与 Nil.texture | 对依赖 Cue 的分析/触发/循环增加有效会话检查和可读拒绝，保留候选独立工具及修正后重载；不增加全局编辑状态机 | 重复拒绝不改集合、不启动循环；候选试听/分析可用，重载恢复正常操作 |

消费接口不保留可写字符串兼容层；场景、全部已发现调用方及测试夹具一并迁移。 工作台自身 `cue_path` 仍是编辑目标，消费对象的同名 getter 只从绑定资源派生；草稿和持久引用职责分开。 既有游戏未自动迁移。保存仍只写 Cue，重载仍丢弃选中对象两份草稿；新引用不改变共享文件冲突或逐文件部分失败语义。

## 最终验证与证据

真实引擎只在 `D:/A_Games/Game_idle_yaya_frame_workbench_test` 运行，Godot 4.7.1 / Windows / RTX 4060 Laptop；Python 使用指定 `codex-python`。 同步前逐一确认九份受影响分发文件等于基线，随后只同步本轮具体文件与夹具；最终九份材料与外部副本规范换行后相等。 示例 Cue、素材、预设、机器配置及其他内容保持不变；测试只在自身目录创建临时 Cue/资源。导出专用预设只在确认外部项目原无 `export_presets.cfg` 后临时安装，结束恢复不存在状态。

以下相对路径以 [本轮原始证据目录](D:/A_Games/Game_idle_yaya_frame_workbench_test/reports/asset-workbench-e7-20260922) 为根。

| 层次 | 实际结果 | 原始证据 |
| --- | --- | --- |
| 静态核对 | 独立基线审查与修后复核、调用方/资源引用/复制排除、源与被测文件一致、完整差异与 whitespace | 本轮差异；正式独立审核结论见上文 |
| 解析 | 14 份改动脚本和夹具均退出 0 | `parse-results.json`、各 `parse-*.log` |
| Godot 行为 | **134/134**，12 套件，23.447 s；零错误、失败、跳过、孤儿。原 117 项保留，新增消费边界 8 项与恢复 9 项 | `behavior-final.log`；项目根下 `reports/gdunit-wrapper/run-2566keg6/result.json` 和 `report_1/results.xml` |
| lint | **64 文件，0 Critical / 0 Warning，455 Info**；阈值未改 | `lint-final.json` / `.log` |
| 维护测试 | **38/38**，13.835 s；未执行 pytest | 本轮维护 unittest 终端原始输出，没有另存日志 |
| 独立消费包 | 从报告目录 `--main-pack` 运行，避免项目源兜底；四入口 Cue 有效、声部分别 1/3/2/2、受管编排、停止与零孤儿通过。最终无退出诊断 | `consumers-after.zip`、`consumer-export-after.log`、`consumer-pack-final.json` / `.log`、`fixtures/asset_consumer_export_*` |
| 第四入口及消费真实渲染 | Forward+ / Compatibility 均通过四尺寸 × 浅深色、真实播放/停止输入、编排 A/B/并行阶段像素、10 轮回收；节点回到 1，孤儿 0 | `timeline-<renderer>.log`、`<renderer>/timeline-render-results.json` 及 PNG |
| 原三入口及单对象消费 | 四尺寸、浅深色、输入、停止/保存可达，单对象新主题真实显示 | `existing-entries.log`、`existing-entries/layout-results.json` 与 `example-game.png` |
| 批量源分析画面 | 四个原始源文件实际分析 success、无错误；浅深色、620×440 滚动可达，新增不支持 Atlas 的原因直接显示 | `batch-capture.log`、`group/batch-results.json`、`group/group-unsupported-source*.png` |
| 文档 | Markdown/调用关系/链接静态核对，离线手册构建 **22 篇 / 33 图 / 490 链接** | 阅读版（当时的 HTML 已撤下）；未进行浏览器排版或交互验收 |

渲染四尺寸为 1600×900、1152×648、900×540、720×480。作者和审核者查看了新宽/窄工作台、单对象消费及批量反馈截图。 像素变化只证明实际绘制；包验证使用引擎加载资源包，不是签名可执行发行包或其他平台验证。 源分析仍不测最终混音/渲染质量；本轮未重跑不受影响的后端工具全部测试及 E4 长时性能探针，只对已迁移的规模探针做解析/lint。

## 失败与复验记录

- `consumer-dependencies-before.log`、`consumers-before.zip`、`consumer-pack-before-run.log` 保留导出缺漏证据。旧包命令虽退出 0，日志有解析错误，不能视为通过。
- `consumer-cold-free-before.log`、`workbench-recovery-before.log` 保留真实冷释放泄漏、空草稿越界和虚报收集。后者 headless 弹窗另有位置诊断，与产品问题分开；正式 UI 验证使用真实显示驱动。
- 首轮 `behavior-initial.log` / `run-vqai1avy` 的 134 项断言通过，但三个测试变量 `before` 遮蔽 GdUnit 基类方法，wrapper 判失败；更名后最终通过，未放宽检查。
- `lint-initial.json` 的两条 Warning 来自新导出探针的冗余打印和长函数。去掉重复打印、提取释放步骤后最终零 Warning，没有改变断言。
- 独立包初轮功能通过但退出有四个 ObjectDB/两个 Resource 告警；`consumer-pack-diagnostic.log` 定位为音频线程中的 Ogg 播放对象。探针沿用既有捕获的输出延迟加 0.1 s 等待后退出，最终告警消失；生产播放逻辑未因此改变，原日志保留。

## 修改文件与使用入口

| 文件范围 | 用途 |
| --- | --- |
| `project-source/components/feedback/feedback_object.gd` | 显式 Cue 引用、冷构造节点归属 |
| `project-source/examples/asset_workbench/single/example_reward_game.gd`、`single/example-game.tscn` | 独立主题、显式绑定和安全消费 |
| 同示例目录下 `composition/example-composition.tscn`、`shader_composition/example-composition.tscn`、`effects_composition/example-effect-cluster.tscn` | 四消费链的实际资源引用 |
| `project-source/tools/asset_workbench/workbench.gd`、`analysis_batch_panel.gd` | 延后 UI 构造、Cue 失败恢复与真实收集反馈 |
| `framework/tests/project/asset_consumer_boundary_test.gd`、`asset_workbench_recovery_test.gd` | 17 项新增回归 |
| 同目录 `asset_consumer_export_presets.cfg`、`asset_consumer_export_probe.gd` | 仅维护侧的实际消费包检查 |
| 同目录六份既有消费/规模夹具、`asset_analysis_group_capture.gd` | 绑定 API 迁移；补不支持源资源的真实画面捕获 |
| 示例 README、手册工作台指南/验证说明、派生 HTML、progress 及本报告 | 同步入口、契约、证据与阶段状态 |

使用与导出步骤集中在 [示例 README](../../../project-source/examples/asset_workbench/README.md#消费接入与导出)。 继续在既有验证项目打开第四工作台或对应 `example-consumer.tscn` 按 F6，体验编排、分组/抢占、保存后消费。 仍待用户确认：主观听感、组合协调、节奏及片段截止截尾、操作顺手程度；手册阅读版排版与交互由用户外部检查。 E7 记录为实现、独立审核与自动验证完成，人工体验待确认；E2 保持未开工，不因本轮收敛自动开展下一项功能。
