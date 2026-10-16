# 框架维护与说明同步

[框架维护](README.md) · [框架维护约定](../../AGENTS.md) · [维护命令](../README.md#维护命令)

本页回答维护框架时的三个问题：这次修改属于哪里、改完要同步哪些说明、怎样交付。验证范围见[框架验证范围](validation/validation-scope.md)。具体的任务步骤在场景速查手册，由[框架入口](../README.md)导航，本页不重复。

## 先判断修改属于哪里

| 要改的内容 | 位置 |
| --- | --- |
| 分发源 | `project-source/`；路径变化时同时核对复制清单 |
| 分发给项目的规则、方法与流程正文 | `project-source/` 中的所属规范。只有任务涉及行为时才改；整理目录不代表修改行为 |
| 分发给项目的 Godot Skill | `project-source/skills/<名称>/`，整个目录随项目分发。各 Skill 的职责以其 `SKILL.md` 和 `project-source/Project_AGENTS.md` 的路由为准，本表不逐个登记 |
| 项目内的简短导航 | `project-source/Project_README.md` |
| 创建器与复制规则 | `framework/project-creation/tools/create_project.py` 与 `framework/project-creation/project-files.json` |
| 生成项目的概念、配置与工具说明 | `framework/godot-project-manual/` |
| 具体的项目开发或框架维护场景 | `framework/prompt-scenarios/scenarios/` 下对应的 Project |
| 正式的提示词 | `framework/prompt-scenarios/prompts/` 下的两份提示词库，各自维护完整正文 |
| 框架共用术语 | `framework/terminology.md`；项目自己的业务词汇不写回这里 |
| 职责设计准则与审核报告 | 长期准则在 [design-guidelines/](design-guidelines/README.md)；当次报告见[当次报告的保存与清理](design-guidelines/05-reviews-and-reports.md#当次报告的保存与清理) |
| 规则、Skill 与任务提示词文件的编写 | 根 `AGENTS.md` 与[规则与提示词文件](design-guidelines/02-instruction-files.md) |
| 框架自用 Skill | 仓库根目录的 `.agents/skills/`。参考资料、配套脚本和私有依赖都放在各 Skill 目录内，不分发给项目。`.claude/skills/` 是相同的副本，因为 Claude Code 只从这里发现 Skill；修改后用 `robocopy .agents\skills .claude\skills /MIR` 同步，提交钩子检查两份一致 |
| 提示词、场景与关系图的维护方法 | `.agents/skills/prompt-and-graph-maintenance-yaya/` |
| 框架文档的写作方法 | `.agents/skills/technical-documentation-writing-yaya/` |
| 框架修改与试验的复盘方法 | `.agents/skills/framework-retro-yaya/` |
| 外部设计经验引入分发 Skill 参考文件的方法 | `.agents/skills/design-knowledge-intake-yaya/`；条目出处见 `framework/maintenance/dependencies/design-reference-sources.md` |
| 按需开启的回复「决策依据」一节 | `.agents/skills/decision-trace-yaya/`；写法沿用分发的 `project-source/skills/decision-trace/` |
| 维护约束与未完成的工作 | 根 `AGENTS.md`、`framework/AGENTS.md` 与 `framework/todo.md` |
| 某个已有游戏独有的修改 | 在明确指定的外部项目中进行，不写回框架，也不自动同步 |

几条通用原则：

- **编写与审核**：维护规则、Skill 和任务提示词文件时，按[规则与提示词文件](design-guidelines/02-instruction-files.md)自查；整理已确认说明的表达和组织，使用 [technical-documentation-writing-yaya](../../.agents/skills/technical-documentation-writing-yaya/SKILL.md)。普通维护由作者自查，不额外安排独立审核；用户要求正式审核时，按[审核与报告](design-guidelines/05-reviews-and-reports.md)进行。
- **`project-source/` 只是源材料**：其中的规则和 Skill 在框架仓库里只供阅读，不启用项目开发的 Stage；修改时的补充规则见下文[修改分发源](#修改分发源)。

## 找到受影响的说明

只核对与实际变化相关的专题和直接调用方，不需要每次通读整个仓库。

| 变化 | Godot 项目手册中的专题 | 以什么为准 |
| --- | --- | --- |
| 复制、目录、重命名、初始化边界 | [框架、创建器与项目边界](../godot-project-manual/foundations/01-framework-and-project.md)、[项目对象与目录](../godot-project-manual/foundations/03-project-layout.md) | 创建器、复制清单、默认文件 |
| 环境字段、插件或 lint 默认值 | [配置参考](../godot-project-manual/foundations/04-configuration.md)、[错误与结果的含义](../godot-project-manual/methods-and-tools/errors-and-results.md) | 配置源文件、检查器、插件及补丁 |
| Product、AC、依赖、规划与历史 | [需求、Feature 与规划基线](../godot-project-manual/requirements-and-tasks/requirements-and-planning.md) | methodology、模板、规划与同步 Skill、检查器 |
| Stage、验收、任务类型、完成或持续授权 | [任务类型、开发阶段与完成语义](../godot-project-manual/requirements-and-tasks/feature-lifecycle.md) | Stage 0–8 `feature-execute` 执行循环、Feature Skill、工程规则 |
| 探索、worktree 准备或成果整合 | [逐步探索与 worktree](../godot-project-manual/methods-and-tools/skills-and-agents.md#逐步探索与-worktree)、[探索结果与工作目录](../godot-project-manual/specialist-work-and-records/knowledge-and-records.md#探索结果与工作目录) | 对应 Skill、任务路由、Git 规范和原有产物归属 |
| 专业文档维护者、资源、语言或独立审核 | [专业来源与资源](../godot-project-manual/specialist-work-and-records/specialist-work.md)、[Skill、Agent 与提示词](../godot-project-manual/methods-and-tools/skills-and-agents.md) | 专业与审核规范、相应 Skill、角色配置和复制映射 |
| 参数、测试选择、结果、指纹或错误 | [命令与验证证据](../godot-project-manual/methods-and-tools/commands-and-evidence.md)、[错误与结果的含义](../godot-project-manual/methods-and-tools/errors-and-results.md) | 实际 CLI、`tools/lib/verification_snapshot.py`、完成校验与测试策略 |
| 调试台调用的外部分析工具 GAA | [配置参考](../godot-project-manual/foundations/04-configuration.md) | 调试台的[分析](../../project-source/defaults/dev/debug/_shared/README.md#分析)、`analyzer_service.gd` 与调试台分析测试 |
| 术语、设计、架构、规则、调研、知识或 Progress | [知识、设计与记录](../godot-project-manual/specialist-work-and-records/knowledge-and-records.md) | 来源规范、产物生命周期、角色和领域规则 |
| 场景的输入、步骤、提示词或出口 | 对应 Project / 分类下的同名场景页 | 所属提示词库、Skill / methodology / CLI、[场景速查手册的编写与维护](../prompt-scenarios/scenarios/README.md) |

其他需要同步的情况：

- **修改分发 Skill 的职责、写入边界或入口**：以该 Skill 的 `SKILL.md` 和它引用的源规范为唯一正文，同步核对任务路由、项目 README 和 advisor；不要在 Project_AGENTS、手册或本页复制一份操作说明。
- **调整路径、字段或 advisor 相关的内容**：按下文[修改时的联动检查](#修改时的联动检查)执行。
- **说明与源码冲突**：分别判断实际行为是什么、哪里需要修；不能只改一段文字掩盖没解决的契约问题。

框架自身的反馈核实、异常调查、方案检验、维护复盘、重复工作的方法设计和任务交接，都由当前 Agent 按本次要求和对应场景直接处理，复用已有的事实、验证和记录，不启用项目的 Stage：

- 复盘和方法设计默认只交付分析和方案。不会因为缺少 Hook 或 CI 就判定有问题，也不会自动修改规则、写脚本或新增报告。
- 只读、只诊断或明确暂停的请求保持原有边界；已有具体修复授权时，由原任务继续。
- Godot 项目使用自己的方法和记录。advisor 只读取共享的 Godot 提示词库，不会因此调用框架维护 Skill。

## 修改时的联动检查

开始修改前读一遍，修改后、提交前按本次实际变化逐条核对；修改 `project-source/` 时，另按下文[修改分发源](#修改分发源)核对复述的命令与 advisor。

- **职责评价**：新增、实质调整职责，或审核 Skill、脚本、提示词与场景时，按[职责设计准则](design-guidelines/README.md)评价对应对象；普通局部修改不触发无关的全量审核。
- **行为不变**：整理文档或文件名，不能顺带改变 Skill 的行为。
- **被证明错误的内容**：规则、提示词、文档或示例中的做法被证明错误时，删除错误的建议，不保留原文，也不加“已取代”“已废弃”之类的标记；同时检查引用它的依据、索引和摘要里有没有同样的说法。只有它容易让人再犯时，才在原处改写成一两句陷阱提示：不要做什么、为什么会出错、怎么做。
- **路径与字段**：调整文件路径或配置字段时，追到全部读写方及其调用链、复制映射和回归夹具，核对生成后的路径和含义一致，不留下只有部分工具支持的选项；搬迁时要追的位置见[目录组织](design-guidelines/01-document-responsibilities.md#目录组织)。移动、改名文档或修改标题时，还要在两份提示词库中搜索旧路径和「旧标题」：提示词正文里的引用是纯文本，链接检查只能发现不存在的路径和标题，查不出重复或指错对象的引用。
- **术语用词**：写完或改过文档后，对本次改过的文档运行术语检查 `python -B project-source/tools/checks/check-terminology.py --terms framework/terminology.md <文件> <文件>…`（改过的提示词 JSON 同样列出），把报出的不用说法改为正式名称；不顺手改本次没碰过的文档。命令说明见[检查术语用词](tools/README.md#检查术语用词)；提交时[提交钩子](tools/README.md#提交钩子)还会检查一次。
- **文档系统图**：文档职责、路径、产物归属或实际引用关系变化时，使用 [prompt-and-graph-maintenance-yaya](../../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md) 同步对应的节点与关系；普通措辞变化不需要维护全图。全仓文档覆盖扫描只在用户明确要求时运行。
- **重复的症状先找根因**：同一类问题第二次出现时，先查[框架 Lessons](../lessons.md)，再停下来查它为什么反复出现，再决定修具体文件还是修源头，不连续修补单个实例。例如新项目扫描后总冒出新的 `.uid`、`.import` 或格式差异，要追到分发源的写法或工具，而不是每次补交一批文件。

## 修改分发源

在框架仓库修改 `project-source/` 时，除上面的联动检查外再核对下面几条。生成项目的规则源文件是 [Project_AGENTS.md](../../project-source/Project_AGENTS.md)，在本仓库只作为源材料阅读，不启用其中的 Stage。

- **Godot 代码、场景、资源或测试**：按[工程规则目录](../../project-source/agent-rules/README.md)核对适用的工程规则；任务授权、Git、验证范围与地点和交付，仍以根 `AGENTS.md` 为准。
- **代码或工具**（也适用于 `framework/` 下的框架工具）：修改前按 Project_AGENTS.md 的[任务范围](../../project-source/Project_AGENTS.md#任务范围)确认实际实现、影响范围和简短方案；验证和交付沿用根 `AGENTS.md`。
- **复述的命令与事实**：修改分发规范中的命令、路径、参数、默认值或版本号时，在 Godot 项目手册、场景页、提示词和 Skill 中搜索同样的写法，一并更新，或改为链接到规范。修改 Stage、流程走向或产物关系时，还要搜索手册、README 和 `project-source/` 中的 Mermaid 图（`mermaid` 代码块），按新流程一并更新。
- **advisor**：修改任务路由、Stage、职责边界、产物归属或授权与完成机制时，同步检查 `project-source/skills/next-step-advisor/SKILL.md` 与相关的 Godot 提示词及同名场景；仍适用的内容不为改而改，也不在 advisor 中复制另一套流程。

## 文档同步的内容

按变化类型决定要同步的内容：

- **用户能看到的行为或默认值变了**：同步对应的参数、路径、初始状态、输出、副作用和必要的错误解释。
- **结构变了**：更新入口、链接、锚点和相关的关系图。
- **只是内部实现变了**：使用契约不变时，核对后不需要为改而改。

文档只描述现在的行为，不同时保留新旧两套教程，也不留空的跳转页。历史原因由 Git 保存；当次仍需要的报告按[当次报告的保存与清理](design-guidelines/05-reviews-and-reports.md#当次报告的保存与清理)处理。不为说明文档建立版本状态、同步收据、来源哈希清单或发布资格。

### 说明的组织与措辞

框架说明的详细写法在 [technical-documentation-writing-yaya](../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) 中维护，本节只列检查要点：

- **页面分工**：见[两本手册的分工](../README.md#两本手册的分工)；场景与提示词的对应关系、栏目和编号要求见[场景速查手册的编写与维护](../prompt-scenarios/scenarios/README.md)。
- **Godot 项目手册的页面要素与风格**：每类页面必须有的要素、称呼和“行为配原因”等写法，见 [Godot 项目手册的组织与语言风格](../../.agents/skills/technical-documentation-writing-yaya/references/manual-style.md)；改完手册页面后按其中的核对一节逐条检查。
- **11 类信息**：来自框架版写作 Skill 的流程参考，只用于框架的场景页，不作为 Godot 项目文档的默认结构。
- **场景正文**：作者按本次变化核对标题、输入、单一目标、步骤与出口；调整列表时保留原有的条件和先后顺序。路径检查只证明目录对应，见[路径校验的职责](design-guidelines/04-prompts-and-scenarios.md#路径校验的职责)。
- **两本手册不互相引用**：必要的解释就地写出；权威规范、工具和公共术语两册都可以引用。
- **链接**：修改时核对受影响的 Markdown 链接、锚点和导航。

生成项目按项目 AGENTS.md 的[使用说明的可读性](../../project-source/Project_AGENTS.md#使用说明的可读性)使用创建时复制的 Godot 版写作 Skill。它独立维护，使用时不需要访问框架。

### 两份写作 Skill 的分工

| | 框架版 | Godot 版 |
| --- | --- | --- |
| Skill | [technical-documentation-writing-yaya](../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) | [technical-documentation-writing-godot](../../project-source/skills/technical-documentation-writing-godot/SKILL.md) |
| 位置 | 仓库根目录的 `.agents/skills/` | `project-source/skills/`，随项目分发 |
| 服务对象 | 框架的手册、场景、工具说明、维护文档和审核记录（包括 Godot 项目手册） | 实际游戏项目的 README、GDD、Product、Feature、架构、知识和操作说明 |
| 使用语言 | 中文 | 说明为中文；编写产物时读取项目的 `document_language` |
| 依据来源 | 当前框架的规范 | 当前游戏项目的规则、模板、词表和工具 |

维护时注意：

- **各自独立**：两份 Skill 各有自己的 `SKILL.md`、`agents/openai.yaml` 和完整参考，可以独立调整例子、默认组织和写作方法，不跨包引用或自动同步；唯一的例外是[措辞检查](../../project-source/skills/technical-documentation-writing-godot/references/writing-guide.md#措辞检查)的说明，它只维护在 Godot 版，框架版链接它，因为措辞检查在框架仓库和生成项目中读的是同一份配置；相似的原则可以各写一份。各自产物的实际契约由所属规范决定，写作 Skill 不另造流程。
- **调用方式**：两份的元数据都设置 `allow_implicit_invocation: true`，职责由各自的 `description` 限定，`short_description` 用于界面展示。框架仓库只启用框架版；Godot 版在这里只是待分发的源文件。
- **分发**：`project-source/skills/` 整个目录被复制到生成项目的 `.agents/skills/` 和 `.claude/skills/`（两份副本的原因见[复制与重命名](../godot-project-manual/foundations/03-project-layout.md#复制与重命名)），Godot 版的内部相对引用保持有效。框架版不分发，也不另外生成一份普通写作指南。
- **结构**：GDD、Product、Feature 及其验收场景使用各自的结构，不套用框架场景页的 11 类栏目或 S1 编号。
- **更新范围**：修改框架版不影响 Godot 版；修改 Godot 版的源文件只影响以后创建的项目，已创建的项目是否更新由用户决定，对齐步骤见[让项目里的框架副本与框架对齐](../godot-project-manual/foundations/01-framework-and-project.md#让项目里的框架副本与框架对齐)。
- **依赖**：两份都只通过内部相对路径读取参考，不需要执行脚本、私有运行时或同步工具。
- **修改验证**：根据真实的误用、表达问题或维护成本调整条款和示例；涉及分发时，核对复制后的文件、入口和相对引用。第一次创建或明显改变适用范围时，用一次独立的试写检查实际效果和可移植性；普通的局部改字不需要每次都完整试写。

## 保持初始化边界

- **不进入项目的材料**：手册、维护说明、提示词库、框架自用 Skill 和框架审核材料，都不加入复制清单，也不移到 `project-source/`。
- **随项目分发的材料**：Godot 版写作 Skill 是分发给项目的 Skill，按普通项目 Skill 整包复制。项目 README 保持自己的简短导航；项目文件不接受自动同步。
- **advisor**：直接读取本机的 Godot 提示词库，修改提示词正文后不需要导出。固定路径及其同步要求见 `framework/AGENTS.md` 的[提示词维护](../AGENTS.md#提示词维护)，用法见[advisor 的共享场景入口](../godot-project-manual/methods-and-tools/skills-and-agents.md#advisor-的共享场景入口)。
- **续接提示词**：项目中动态生成的续接提示词，格式统一维护在 [续接提示词](../../project-source/methodology/09-records-reports-and-handoff.md#续接提示词)，由 advisor 和 `task-handoff` 引用；框架的预设提示词仍各自保留具体场景的输入、授权和停点目的。普通暂停、换对话和恢复已有停点不合并成一条通用提示词，新增 Skill 也不要求每个入口都建场景。

## 验证、提交与交付

- **验证**：按[按修改选择验证范围](validation/validation-scope.md#按修改选择验证范围)确定。
- **提交**：何时提交和禁止的操作见根 `AGENTS.md` 的[本地提交](../../AGENTS.md#本地提交)，具体做法见下文[本地提交的做法](#本地提交的做法)。
- **交付**：给出受影响的文档入口和真实的验证结果。文档任务不能宣称游戏运行通过；框架的提交也不会更新已有的游戏项目。

### 本地提交的做法

**提交前**

- 开始修改时运行一次 `git status`，记录已有改动及其暂存状态。同一任务之前留下的改动可以继续完成并提交。
- [提交钩子](tools/README.md#提交钩子)拒绝提交时，按输出改正本次改过的文档，重新暂存后再提交；报出的位置不在本次改动内时，保留修改并报告。
- 发现未完成的合并、变基等状态，或 HEAD、分支出现当前操作无法解释的变化时，保留现场并报告，核对清楚后再继续依赖该状态的写入和提交。
- **暂存本任务改动**：无论开始时工作区是否干净，只暂存本任务明确的路径或已核对的差异块。提交前核对 `git status`，排除无关改动、运行产物和缓存。
- **开始时已有改动**：保留它们及其暂存状态，只暂存本项明确的路径或差异块，不用 `git add -A`、`git add .` 或 `git commit -a`；无法分开时说明冲突并保留现场。

**提交内容**

- 按完整的逻辑成果组织提交，带上必要的实现、测试、引用和说明；不按文件数或“代码、测试、文档”机械分批。
- 验证按任务的实际改动与必要范围执行，复用仍有效的结果。提交不另设审核关卡，不要求每次重读完整的暂存差异或重跑已通过的检查；出现新的改动、失败或证据失效时才补充核对。
- 主题采用 `<type>(<scope>): <中文摘要>`，说明实际的行为变化；非简单修改在正文说明原因、关键取舍和真实的验证结果。

**提交后**

- 交付时说明本次的提交、实际做过的验证，以及本任务还没提交的修改。
- 本地提交不等于任务完成或实际人工验收。

## 整体审核与专项审核的入口

按目的选择已有场景，本页不重复执行步骤：

| 目的 | 场景 |
| --- | --- |
| 检查当前工作区是否自洽 | [想检查本地框架是否自洽，先做静态审核](<../prompt-scenarios/scenarios/Yaya 框架维护/整体体检与整理/想检查本地框架是否自洽，先做静态审核.md>) |
| 觉得框架有问题，但不确定从哪里查起 | [框架好像有问题，先判断从哪里查起](<../prompt-scenarios/scenarios/Yaya 框架维护/只读专项审核/框架好像有问题，先判断从哪里查起.md>)；按症状、卡住的任务和已有记录推荐 1–3 个现有入口，没有线索时先做结构总览；不承诺全面审核 |
| 深入核对某个专项问题 | 从[只读专项审核](../prompt-scenarios/scenarios/scenario-index.md#只读专项审核)选一个专题，与「专项审核通用模板」拼接后使用，不需要填参数 |
| 核实收到的审核意见 | [收到外部审核意见，先核实哪些值得修改](<../prompt-scenarios/scenarios/Yaya 框架维护/改完检查/收到外部审核意见，先核实哪些值得修改.md>) |
| 用一个小任务验证真实流程 | [想用一个小任务实际验证框架流程](<../prompt-scenarios/scenarios/Yaya 框架维护/整体体检与整理/想用一个小任务实际验证框架流程.md>)；实际运行范围与静态结论分别记录 |

总体判断依据根 `AGENTS.md` 的[核心决策原则](../../AGENTS.md#核心决策原则)，文本与职责的评价依据[职责设计准则](design-guidelines/README.md)；质疑已确认的取舍、带具体任务推演和列出需要的试用，按[审核的判断方法](design-guidelines/05-reviews-and-reports.md#审核的判断方法)。报告只记录已核实的版本、范围和证据，不授予实施权限。

## 授权在后续对话中的延续

- 同一会话中已给出的具体授权继续有效，说明同步与如实记录验证的要求也始终适用。
- 用户最新的明确要求会调整目标与范围；已被替代的临时只读、输出或停止条件，不再约束后续工作。
- 例如先只读分析，用户再明确说“按这个方案改这两处”，就可以在选定范围内实施；而“这样改合适吗”仍然是讨论，不是授权。
- 已批准且没有变化的决定不重复确认；新的决定和实际的人工验收要单独处理。
- 交接时区分仍有效的原则、当前的限制和已被替代的要求，接收方按自己读到的实际文件和授权继续。
