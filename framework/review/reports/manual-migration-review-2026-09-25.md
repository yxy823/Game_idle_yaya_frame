# 操作手册与维护导航迁移独立审核

## 结论与版本

审核者：独立子智能体 `/root/review_manual_migration`。日期：2026-09-25。

以提交 `6c6ec2e1011d05a2a4e38c1365fe3256baab8c52` 中 `framework/docs/framework-maintenance/migration-source/` 的 19 篇原文和 README 为迁移前基线，逐篇阅读全文，对照当前工作区的 11 篇操作手册专题、手册 README、文档总入口和维护导航。审核期间发现 2 处 P2，由协调者修改后，本审核者重新读取最终正文关闭。当前未发现未关闭的 P1/P2 问题。

结论限于本报告的内容迁移与两项增量静态审核。原文压缩、专题合并、具体场景外移，以及删除与已确认单人范围不符的 worktree/改动归属流程，不构成信息遗漏；判断依据是有效概念、对象职责、工具契约及重要限制是否仍有明确承接。

## 范围与方法

审核依据为[根维护约定](../../../AGENTS.md)、[职责设计准则](../baselines/skill-script-prompt-design.md)及已确认的两册分工。被审材料只读；审核者仅编写本报告，未修改被审正文、测试或模板，也未提交。

实际阅读范围：

- 基线中的全部 19 篇迁移源和 README。当前已删除的原文通过 `git show <基线提交>:<原路径>` 读取，不以文件名或目录清单代替正文核对。
- 当前 `framework/docs/operation-manual/` 的 11 个专题和 README、`framework/docs/README.md`、`framework/docs/framework-maintenance/` 的 README、`updating-the-blank-project.md`、`validating-framework.md`，以及根 README、根 AGENTS、`framework/README.md`。
- 按具体判断追查配置、Feature/测试登记规范、文档语言规范、产物生命周期、游戏组织指南、未采纳设想默认文件等源材料。此前的 [Skill 与工具独立审核](skill-tool-implementation-review-2026-09-25.md)作为未发生新变化部分的审核依据，不将它们重复声称为本轮全量实现审核。
- 两项后续增量：`project-rules.md.tmpl` 的环境信息归属澄清，以及 `asset_analysis_source_contract_test.gd` 与原 group 套件之间的测试职责调整。

123 组提示词与场景的逐篇语义复核由另一独立审核者负责，见[提示词与场景审核](prompt-scenario-implementation-review-2026-09-25.md)。本报告完整阅读旧场景内容、检查承接归属和特殊用途遗漏，但不重复声称已完整审核 123 篇新场景的每一步。

## 已关闭的问题

| 优先级 | 发现与影响 | 修正及复核结果 |
| --- | --- | --- |
| P2 | `requirements-and-planning.md` 曾把无单元套件的组件字段写成 `unit_paths: []`；真实 Registry 字段为 `unit_test_paths`。照抄错误字段会使文档与登记契约不一致。 | 已改为 `unit_test_paths: []`。重新读取该文第 28 行，并与 `methodology/02-feature-list-schema.md` 第 257、294 行核对，关闭。 |
| P2 | 新手册缺少 `docs/unadopted-ideas.md` 与 `docs/game-organization.md` 两个原有对象的说明和入口。前者区分未采纳设想与开发承诺，后者是随项目分发的组织命名指南；仅概述代码目录不足以恢复这两个对象的可发现性。 | `project-layout.md` 第 18–19 行恢复两个对象，并链接实际游戏组织指南；`knowledge-and-records.md` 第 19 行补充未采纳设想的归属与采纳后的正式来源。重新读取三处正文，确认指南目标文件存在，与默认源文件含义一致，关闭。 |

以上问题由协调者修正，本审核者仅报告和复核。

## 旧材料的完整覆盖

下表的原路径均相对基线中的 `migration-source/`；新专题均位于当前 `operation-manual/`。具体场景的完整提示词对应关系由独立场景审核负责。

| 已全文阅读的原文 | 当前主要承接位置 | 内容核对结论 |
| --- | --- | --- |
| `getting-started/create-project.md` | `framework-and-project.md`、`project-layout.md`、`errors-and-results.md`；创建场景 | 复制、重命名、独立 Git 仓库及初始提交、失败时保留部分结果、创建不包含环境准备和运行验证的边界保留。 |
| `getting-started/first-use.md` | `configuration.md`、`framework-and-project.md`、`commands-and-evidence.md`、`errors-and-results.md`；首次准备场景 | 配置与实际可用状态分开；Python 检查范围、Godot 首次扫描、初始化报告追加及 Progress 的职责保留。 |
| `getting-started/migrate-existing-project.md` | `framework-and-project.md`；接管/迁移场景 | 旧项目只读参考、新项目独立拥有文件，UID、导入配置、许可、历史及已有事实须真实保留；不自动升级、不补造过去验收。 |
| `guides/product-and-planning.md` | `requirements-and-planning.md`、`specialist-work.md`、`feature-lifecycle.md` | GDD 作为输入、模块稳定编号、当前模块覆盖、真实依赖、R000 与后续锚点、来源变化及 retired 测试仍可能执行均保留。登记字段笔误已修正。 |
| `guides/feature-delivery.md` | `feature-lifecycle.md`、`commands-and-evidence.md`、`knowledge-and-records.md` | 阶段及职责、真实 TDD、人工验收、可选独立审核、最终完成与提交不同、既有授权延续和原件有效性均有承接。 |
| `guides/engineering-changes.md` | `feature-lifecycle.md`、`requirements-and-planning.md`、`specialist-work.md`；修复与改进场景 | Bug、重构、维护、实验的目标差异及范围、验收、证据边界保留；任务特有提交限制由对应入口维护，没有提升成全部场景的通用门槛。 |
| `guides/specialist-workflows.md` | `specialist-work.md`、`skills-and-agents.md` | Product 与专业来源分工、实际测量/试听/检查、独立审核只读职责、规格不等于素材制作保留；入口数量按本轮拆分后的实际 Skill 更新。 |
| `guides/asset-workbench.md` | `asset-workbench.md`、`specialist-work.md` | 候选、草稿、保存结果区分，A/B、重载丢弃草稿、逐文件部分保存、后台取消、粒子/Shader 范围与效果预算、源文件分析不证明运行效果等限制保留。 |
| `guides/project-knowledge.md` | `knowledge-and-records.md`、`project-layout.md` | 术语、局部设计、当前架构、ADR、规则、研究、实践知识和 Progress 各有归属；历史不改写、报告不因旧或未跟踪即可删除。 |
| `guides/scenario-procedures.md` | 场景速查册的编写与索引；文档总入口 | 场景说明外移，概念和工具留在操作册；旧的工作区归属/隔离门槛按已确认单人边界移除，同目录暂停和续接仍保留。 |
| `guides/scenarios-requirements-design.md` | 需求与设计场景；`requirements-and-planning.md`、`knowledge-and-records.md` | 新需求、来源变化、插入 Product、设计边界、共享要求影响等原有用途纳入场景承接核对；未把独立场景重新塞回概念专题。 |
| `guides/scenarios-interface-audio-assets.md` | UI、音频、素材准备/接收/检查场景；`specialist-work.md`、`asset-workbench.md` | 原型与真实资源、缺素材只阻塞其依赖工作、声音方向和规格、已有素材接入等差异保留；未把制作素材写成已有能力。 |
| `guides/scenarios-verification-recovery.md` | 验证、交付前后 Bug、环境与证据恢复场景；`commands-and-evidence.md`、`errors-and-results.md`、`feature-lifecycle.md` | 原有环境故障、证据失效、测试失败、人工失败与完成判断的不同性质有承接，不把所有失败归成一个恢复步骤。 |
| `guides/scenarios-context-handoff.md` | 暂停、切换、新对话续接、无 Feature 情形与冲突定位场景；`knowledge-and-records.md` | 当前状态、授权、未决项与真实证据随同目录交接；不创建第二套任务状态，不要求为换对话清空现场。 |
| `reference/project-layout.md` | `project-layout.md`、`knowledge-and-records.md`、`specialist-work.md` | 配置、计划、证据、产物、代码、工具及复制映射已承接；遗漏的游戏组织指南和未采纳设想对象已恢复。 |
| `reference/skills.md` | `skills-and-agents.md`；具体入口归场景册 | Skill 方法与提示词场景分开；宿主是否加载角色与配置文件存在分开，不能把配置存在当作真实委派成功。 |
| `reference/configuration.md` | `configuration.md` | 文档语言与 Python/Godot 路径三字段、相对路径解析、Godot 不按 PATH 猜测、默认配置/插件/文本格式及实际环境状态归属保留。 |
| `reference/commands-and-validation.md` | `commands-and-evidence.md` | 命令输入输出、查询与完成判定区别、退出码、导入/绑定证据副作用、集合替换、失效条件、失败原件、指纹与 lint 结果解释均有承接。 |
| `reference/troubleshooting.md` | `errors-and-results.md`；具体故障恢复场景 | 导入/环境错误与真实断言失败区分；旧通过不覆盖新失败，缺状态不等于通过，诊断比较不证明引擎根因，不手改运行原件。 |
| `README.md` | `framework/docs/README.md`、操作手册 README、维护 README | 暂存迁移导航由稳定入口取代；不保留第二套旧手册或把迁移状态写进执行场景。 |

## 横向边界核对

| 关注点 | 结论与依据 |
| --- | --- |
| 两册分工 | 操作册围绕框架、对象、概念、配置和工具用法组织。工作台点击与命令参数属于工具说明，不因出现操作步骤而自动成为独立业务场景。具体任务入口与状态分流归速查册。两册由总入口并列导航；本轮阅读未发现互相引用。 |
| 权威来源 | 新手册引用 `project-source/` 的方法、Skill、规则、默认材料及实际工具；复制清单和提示词库仍有各自唯一正文。概念解释没有另建一套完成条件或自动同步契约。 |
| 授权与结果 | 测试通过、代码提交、配置存在、生成成功与正式交付分别说明。Goal/阶段名不自动授予实施权限，已有具体授权也不会因阶段切换重新失效；人工验收没有被自动测试替代。 |
| 命令与副作用 | 创建器建立 Git 与初始提交；验证工具的写入、导入、替换、清除旧绑定、失败保留和状态判断有说明。查询记录不再代替完成判定。工具失败、业务未完成与证据无效未混为一个结果。 |
| 单人范围 | 根约定与新手册一致排除多人归属、worktree 隔离及其续接，保留同一目录暂停、任务切换、新对话恢复及按需独立调研/审核。 |
| HTML 暂缓 | 根入口、框架 README 和维护说明一致只交付 Markdown，保留构建工具并明确重新引入前需要适配。未把旧构建成功或工具保留写成当前 HTML 已交付。 |
| 导航与维护 | 三份维护文档按修改、同步和验证职责组织；当前入口不依赖已删除的迁移源目录。模板、例子和空文件没有被描述为所有项目必须填满的材料。 |

## 两项后续增量

| 对象 | 实际核对内容 | 结论 |
| --- | --- | --- |
| `project-source/methodology/templates/project-rules.md.tmpl` 第 143 行 | 与 `methodology/05-document-language.md` 和真实三字段配置对照：配置拥有语言与可执行路径；实际准备发现和观察到的引擎版本归初始化报告及当前 Progress；不添加 readiness 标志或命令字符串。 | 归属清晰，与现有契约一致；没有新增环境判断状态或同步义务。 |
| `framework/tests/project/asset_analysis_source_contract_test.gd` | 全文读取 4 个测试、前后置清理及辅助方法，检查统一格式表、损坏配置的失败/恢复、额外来源类型拒绝/恢复、历史结果不依赖当前文件或支持扩展名；对照 `analysis_source.gd` 与剩余 group 套件，检索测试名只出现一次。 | source 能力契约形成独立套件，group 保留分组、统计和批处理/界面职责。配置文件字节与缓存状态恢复、扫描取消和临时文件清理责任明确，未发现通过拆分削弱断言或重复执行同一 case。 |

本审核未新增或执行引擎测试。协调者报告的 13 套件、139 个测试及 lint 结果属于其他执行者的运行证据，见[实施验证记录](framework-implementation-validation-2026-09-25.md)，不作为本审核者亲自运行的结果。

## 验证限制

- 本报告完成内容、对象归属和关键源契约的静态审核；不以根任务已执行的链接/锚点批量检查代替内容判断，也不把该机械检查写成本审核独立执行。
- 没有生成或浏览 HTML，没有使用 Playwright，没有替代用户的 Markdown 试读或真实游戏人工验收。
- 提示词与 123 篇场景的最终逐项一致性，以及非本报告两项增量的工具运行结论，以相应独立报告和真实运行记录为准。
