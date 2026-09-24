# 维护工具

这里保留文件复制、手册生成和可显式调用的回归入口。修改不需要任务登记、源码清单续接、
发布身份、升级计划或专门的哈希状态。

面向空白项目使用者的完整说明见 [空白项目使用手册](docs/blank-project/README.md)。
桌面浏览器可直接打开 [离线 HTML 阅读版](docs/blank-project/blank-project-handbook.html)，
生成命令和依赖见 [生成离线阅读版](docs/blank-project/maintenance/updating-the-blank-project.md#生成离线阅读版)。
修改源材料前先查阅入口与受影响专题，修改后按
[维护与同步说明](docs/blank-project/maintenance/updating-the-blank-project.md) 更新对应章节。
手册属于框架，不复制到生成项目。

| 路径 | 职责 |
| --- | --- |
| [progress.md](progress.md) | 框架当前成果、验证缺口、未决事项与下一步；随相关维护更新，不复制到项目 |
| [框架的复制与运行验证](docs/blank-project/maintenance/validating-framework.md) | 源材料、真实外部测试项目、工作流抽样与迁移检查的职责和证据边界 |
| [commands/create_project.py](commands/create_project.py) | 按清单复制，建立独立 Git 仓库与本地初始提交 |
| [project-files.json](project-files.json) | 唯一复制清单；每项只有 source 与 target |
| [prompts.json](prompts.json) | 集中管理框架维护与实际项目开发的全部操作提示词；不复制到项目 |
| [commands/export_advisor_prompt_examples.py](commands/export_advisor_prompt_examples.py) | 从 JSON 精选导出 advisor 的表达参考；只在维护时显式执行 |
| [docs/blank-project/README.md](docs/blank-project/README.md) | 空白项目详细使用手册与维护指引；不复制到项目 |
| [commands/build_blank_project_handbook.py](commands/build_blank_project_handbook.py) | 将手册 Markdown、[页面模板](commands/blank-project-handbook-page.html)、[交互源文件](commands/blank-project-handbook-interactions.js) 与 SVG 图表内嵌为单文件 HTML，默认复用未变图表，详见[构建与缓存说明](docs/blank-project/maintenance/updating-the-blank-project.md#生成离线阅读版) |
| [commands/run_project_tool_tests.py](commands/run_project_tool_tests.py) | 用户需要时，对指定外部项目执行已有项目工具回归 |
| [tests/test_project_copy.py](tests/test_project_copy.py) | 复制选择、重命名、目标路径与覆盖边界回归 |
| [tests/test_documentation_fingerprint.py](tests/test_documentation_fingerprint.py) | 用中立临时 Git 夹具核对使用 README、知识/调研 Markdown 与验证契约的指纹边界 |
| [tests/test_manual_acceptance_files.py](tests/test_manual_acceptance_files.py) | 中立 Git 夹具验证人工清单、逐项文件结果、快照匹配与口头入口，不执行游戏或人工体验 |
| tests/project/ | 当前项目工具的回归源码；不进入空白项目 |
| tests/project/gdscript_lint_contracts.gd | 按需在外部项目运行的真实引擎 lint 契约；unittest 不执行它 |
| tests/project/gdscript_lint_entry_contracts.gd、gdscript_lint_editor_contracts.gd | CLI 配置/检查 ID 拒绝与真实编辑器面板的配置归属、控件保存回归；仅在指定外部项目的隔离夹具内执行，保留结果与环境限制 |
| tests/project/gdunit_runner_contracts.gd | 真实运行器回归：普通/参数化断言、预期错误与受控生命周期失败；不进入空白项目 |
| tests/project/asset_workbench_test.gd、asset_workbench_capture.gd | 工作台的真实 Godot 行为与渲染夹具；仅按任务复制到指定外部测试项目，不进入分发清单 |
| tests/project/asset_analyzer_backend_test.py、asset_analyzer_test.gd、asset_analyzer_capture.gd、analyzer_process_fixture.py | 第二阶段可选依赖的真实分析、后台异常与图表回归；仅在已安装依赖的指定项目按 [实施报告](review/reports/asset-analyzer-phase2-2026-09-21.md) 显式执行，不加入默认项目工具 unittest 发现 |
| tests/project/asset_analysis_group_test.gd、asset_composition_test.gd、asset_analysis_group_capture.gd | 第三阶段真实批量分析、规则/历史、组合对象试调/保存及渲染夹具；按 [验证记录](review/reports/asset-workbench-phase3-2026-09-21.md) 在指定项目运行，不随框架分发 |
| tests/project/asset_shader_composition_test.gd、asset_shader_render_capture.gd | 图片/声音/Shader 独立组合、材质隔离、保存消费及真实像素回归；按 [验证记录](review/reports/asset-workbench-shader-composition-2026-09-22.md) 在既有外部项目执行 |
| tests/project/asset_effect_composition_test.gd、asset_effect_render_capture.gd | 粒子/Tween/AnimationPlayer 的独立绑定、生命周期、实例/草稿隔离、保存消费及真实渲染；仅在明确指定的外部项目按范围执行 |
| tests/project/asset_composition_reuse_test.gd、asset_composition_reuse_capture.gd、asset_effect_scale_probe.gd | 同 Cue 多实例草稿/保存、原生组合消费、粒子坐标像素及并发/持续装卸测量；外部项目执行，记录设备与测量边界，不随框架分发 |
| tests/project/asset_playback_manager_test.gd、asset_feedback_timeline_test.gd、asset_timeline_integration_test.gd、asset_feedback_timeline_capture.gd | 场景局部句柄、优先级/分组取消、有限编排及停止/重入/离树回归；真实渲染检查第四入口、消费编排和装卸，按需在指定外部项目执行 |
| [review/baselines/design-quality.md](review/baselines/design-quality.md) | 设计判断依据、当前静态基线与待观察成本 |
| [review/baselines/scenario-coverage.md](review/baselines/scenario-coverage.md) | 按层级编号的场景职责、覆盖依据及提示词使用清单 |
| [review/README.md](review/README.md) 与 `review/reports/` | 基线和按次报告的分类导航；报告保留具体版本、检查范围与历史结果 |

## 导出 advisor 精选表达参考

`prompts.json` 是唯一手写正文。导出器按其中“Godot 项目开发”的分类与提示词名称精确选择 12 条，
生成 `project-source/skills/project-next-step-advisor/references/prompt-examples.md` 索引及
`prompt-examples/` 下五个分类文件。选择清单在导出器的 `SELECTION` 中，不另建配置或流程映射。

```powershell
& 'C:\Users\89523\anaconda3\envs\codex-python\python.exe' -B framework/commands/export_advisor_prompt_examples.py
& 'C:\Users\89523\anaconda3\envs\codex-python\python.exe' -B framework/commands/export_advisor_prompt_examples.py --check
```

修改入选提示词、Skill 名称或选择范围后显式导出；`--check` 只比较内容，缺失或过期返回非零且不写入。
全部入选来源有效后才开始输出，正文与占位符原样保留，使用 UTF-8 和 LF；无时间戳、后台同步或新依赖。
生成后随本次逻辑变更提交。相关回归在 `tests/test_advisor_prompt_examples.py`。

创建器只复制 Skill 已有的静态参考，不调用导出器；完整 JSON 与本导出脚本不进入新项目。
advisor 只在需要措辞参考时读取相应条目，项目规范、目标 Skill 与真实授权决定行动。
资料的分发与使用边界见 [精选参考说明](docs/blank-project/reference/skills.md#advisor-的精选表达参考)。

## 提示词

`prompts.json` 顶层是数组，包含两个独立 Project；每项仍使用 `project` 与
`categories`，不增加另一套提示词配置格式：

- `Yaya 框架维护`：10 条，包含新增能力、外部框架借鉴、修复/删减、复盘、GitHub 审核、动态全流程审核、外部结果复核、实际开发反馈复盘、按需验证与新线程交接。
- `Godot 项目开发`：40 条，覆盖创建与迁移、环境、澄清与术语、外部调研、需求与规划、开发、Goal、架构调查、专业设计、本地化、资源接入、观测/性能/长测、独立审核、验证与经验沉淀。

各 Project 的 `categories` 按用途组织；叶子键为提示词名称，字符串值为完整文本，
换行保存为 JSON 的 `\n`。50 条提示词均有完整正文；有 `${1:说明}` 等
输入占位符时，发送前填写实际信息，已有授权在会话中继续有效。按需选用某一条，
不要求每个任务按清单逐条发送。
需要粘贴长篇原文时，材料区位置与填写方法见 [提示词使用说明](docs/blank-project/reference/skills.md#从哪里取得操作提示词)。
环境准备与普通修改任务使用相同的项目 Git 规则；初始化报告与后续更新见[首次使用说明](docs/blank-project/getting-started/first-use.md)。
需要准备新项目时，使用“Godot 项目开发 → 项目创建与接入 → 准备 Godot 开发环境”。
已有旧框架成果需要保留时，使用“Godot 项目开发 → 项目创建与接入 → 复制并迁移旧框架项目”；
输入、授权及原件保留方式见[复制迁移说明](docs/blank-project/getting-started/migrate-existing-project.md)。
`prompts.json` 只保存提示词，不执行命令，也不要求项目读取维护目录。
需要按任务准备素材时，使用“Godot 项目开发 → 资源、性能与数据 → 分析并整理任务资源清单”；清单保存在具体游戏项目，用法见 [资源准备与原型交接](docs/blank-project/guides/product-and-planning.md#按清单准备资源再继续原型)。
外部文本或文档需要先整理、不写入或执行时，选择“Godot 项目开发 → 需求设计 → 只读适配外部需求内容”；用法见 [只整理外部需求内容](docs/blank-project/guides/product-and-planning.md#只整理外部需求内容)。
功能已经实现、需求或任务记录缺失时，选择“Godot 项目开发 → 需求设计 → 从已有实现补齐需求与任务”；输入和文档/交付边界见 [已有实现补齐说明](docs/blank-project/guides/product-and-planning.md#从已有实现补齐需求与任务)。
需要独立检查模块现状或指定变更时，选择“Godot 项目开发 → 验证与收尾 → 独立审查代码或指定变更”；现状审查无需创建 Feature 或虚构差异，用法见 [独立评审说明](docs/blank-project/guides/feature-delivery.md#按需独立评审与再次验证)。
手动编辑代码、资源或需求/任务文档后，选择“Godot 项目开发 → 验证与收尾 → 检查手动修改与需求的一致性”；提供范围、意图与比较基线，用法见 [手动修改检查说明](docs/blank-project/guides/engineering-changes.md#手动修改后检查需求一致性)。
需要结合项目流程回复 Codex 时，选择“Godot 项目开发 → 日常开发 → 判断当前状态与下一步”；用法见 [根据 Codex 输出起草回复](docs/blank-project/reference/skills.md#根据-codex-输出起草回复)。
从实际游戏项目转发 Codex 输出、判断框架是否需要改进时，选择“Yaya 框架维护 → 维护与复盘 → 依据实际开发反馈复盘框架”；
审核后可按需参考提示词库，输出标明接收任务、已填入上下文的下一步输入，供手动复制发送；用法与建议边界见 [开发反馈复盘说明](docs/blank-project/maintenance/updating-the-blank-project.md#从实际开发反馈复盘框架)。
新增提示词前先核对 [使用场景清单](review/baselines/scenario-coverage.md#提示词使用场景清单)，
合并目的和授权边界相同的场景；正文确定后写入 JSON，并同步场景用途。
外部框架借鉴先比较实际价值，阶段总结先核对已有覆盖；不自动把每个优点或经验
变成规则、脚本或新机制。项目提示词不要求项目连接或跟随维护源变化。
提示词正文及清单做静态核对；不把工具回归当成已逐条运行全部提示词。

框架提示词遵循根规则并按任务读取资料，复用仍有效的上下文；修改空白项目源材料前
查阅手册入口、维护说明与受影响专题。局部复盘、验证与交接不要求通读相同入口，具体边界见
[通过提示词开始维护](docs/blank-project/maintenance/updating-the-blank-project.md#通过提示词开始维护)。

后续可以直接用口语补充：相关框架工作继续沿用既有原则，最新明确要求只调整对应的目标或限制。
从评估转入实施、检查范围与输出格式如何沿用，见
[后续用口语继续](docs/blank-project/maintenance/updating-the-blank-project.md#后续用口语继续)。

需要重新检查整个框架及空白项目时，选择
`Yaya 框架维护 → 维护与复盘 → 静态审核框架与空白项目源材料`。
它默认做整体静态审查，输出包含覆盖范围、文件依据、问题详情、处理顺序和未验证项的详细报告；
也可限定模块、提供历史对照，或指定报告文件路径。输入与报告边界见
[整体重检与详细报告](docs/blank-project/maintenance/updating-the-blank-project.md#整体重检与详细报告)。

通过 GitHub 请其他模型独立审核时，选择
`Yaya 框架维护 → 维护与复盘 → 静态审核 GitHub 框架快照`，发送完整正文。
它默认读取 `yxy823/Game_idle_yaya_frame` 的默认分支，先固定提交 SHA，再按该快照审核；可指定其他分支或提交。
审核方需要仓库读取权限，无需上传源码压缩包；十个审核主题、九节报告及问题证据要求保持不变。
交付文件名为 `Game_idle_yaya_frame-audit-report.md`，不支持文件输出时直接给出完整正文。
准备与边界见 [GitHub 审核说明](docs/blank-project/maintenance/updating-the-blank-project.md#通过-github-交给其他模型审核)。

要通过实际操作检验流程，选择
`Yaya 框架维护 → 维护与复盘 → 通过实际任务动态审核框架流程`。
在指定的新建外部项目中完成一个小 Product、一个 Feature 和适用 Stage，实际执行引擎验证与收尾。
输入、提交授权、条件阶段及阻塞处理见
[动态流程审核说明](docs/blank-project/maintenance/updating-the-blank-project.md#用一个实际任务动态审核流程)。

收到外部审核报告后，选择
`Yaya 框架维护 → 维护与复盘 → 复核外部审核结果并讨论取舍`。
它对照当前材料分别判断问题是否成立、建议是否值得采用；简单意见直接说明，复杂意见用对应表与必要论证，同一依据只展开一次。
先交付分析并讨论，收到明确的实施选择后再修改；用法见
[外部结果复核说明](docs/blank-project/maintenance/updating-the-blank-project.md#复核外部审核结果与讨论取舍)。

任务对话过长或需要换线程时，在原线程选择对应入口：

- 框架维护：`Yaya 框架维护 → 维护与复盘 → 生成新线程交接提示词`，只读当前会话与仓库。
- 项目开发：`Godot 项目开发 → 验证与收尾 → 整理进度与任务交接`，写入前置满足时整理必要记录，否则只读交接并说明记录缺口。

两者都输出一个已填入实际目标、目录、进展、授权、检查结果与下一步的完整代码块。
由使用者复制到同一工作区的新线程，接收方先核对实际文件再继续；原线程输出后停止实施。
具体用法见 [换到新线程继续](docs/blank-project/guides/project-knowledge.md#换到新线程继续)。

## 复制入口

```powershell
python -B framework/commands/create_project.py --output D:\Games\MyGodotGame
```

清单路径相对本维护源，target 相对新项目。文件可重命名；目录包含其子目录内容。
脚本不做内容替换，所以初始默认文件必须已经可直接复制。
`Project_AGENTS.md → AGENTS.md` 由清单表达，不另设模板引擎。

脚本只做必要的路径检查和文件复制。缺文件、无权限、非空目标等错误直接返回，
保留现场；不增加事务目录、复制身份、文件归属表或恢复状态机。
写入前展开清单检查实际目标：允许目录合并，拒绝重复文件和文件/目录冲突。
修改清单时仍需核对选中内容是否应交付。

## 按需检查

维护层回归（复制器、文档指纹与人工验收文件契约）：

```powershell
python -B -m unittest discover -s framework/tests -p test_*.py
```

这些回归使用系统临时目录。文档指纹和人工文件检查只建立中立 Git 夹具，不创建游戏或运行引擎测试；合成验收结果不证明真实人工体验。

项目工具回归：

```powershell
python -B framework/commands/run_project_tool_tests.py --project D:\Games\MyGodotGame
```

后者只运行已有 unittest，不替用户生成或配置项目，不写示例业务台账，
不顺带执行 Godot、人工验收或发布流程。项目工具测试可能使用临时文件及子进程。
真实引擎、静态检查和场景启动按具体任务单独决定。

本轮用户只要求静态审查时，上述命令均不执行。

## 这些维护入口各自负责什么

从第一性原理看，创建项目需要“按确定清单搬运文件”，一个脚本即可完成；
不需要版本管理、发布判定或跨项目同步来支撑复制。

手册生成器负责重复的格式转换、链接重写和图表内嵌，正文仍由 Markdown 维护；
生成文件可直接离线阅读，不需要网站服务，也不承担项目创建或验证职责。

项目工具仍有独立回归源码，维护者需要明确指定被测项目。验证入口只承担传递路径、
执行回归和返回退出码的重复操作，不决定当前任务是否必须运行它。
Skill 直接调用的项目命令保留；自动事件及其专用测试已删除。
保留实际成果检查，删除逐动作监督和多余包装；Skill 引用某个命令，
不代表必须保留该命令内部所有旧机制。删除机制时同步删除其专用测试，
不因存在测试就默认继续保留其设计。
