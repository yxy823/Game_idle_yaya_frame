# 框架维护与说明同步

[框架维护](README.md) · [框架规则](../../AGENTS.md) · [维护命令](../README.md#维护命令)

本页回答维护框架时的三个问题：这次修改属于哪里、改完要同步哪些说明、怎样交付。验证范围见[框架验证范围](validation/validation-scope.md)。具体的任务步骤在场景速查手册，由[框架入口](../README.md)导航，本页不重复。

## 先判断修改属于哪里

| 要改的内容 | 位置 |
| --- | --- |
| 项目分发材料 | `project-source/`；路径变化时同时核对复制清单 |
| 分发给项目的规则、方法与流程正文 | `project-source/` 中的所属规范。只有任务涉及行为时才改；整理目录不代表修改行为 |
| 分发给项目的 Godot Skill | `project-source/skills/<名称>/`，整个目录随项目分发。各 Skill 的职责以其 `SKILL.md` 和 `project-source/Project_AGENTS.md` 的路由为准，本表不逐个登记 |
| 项目内的简短导航 | `project-source/Project_README.md` |
| 创建器与复制规则 | `framework/project-creation/tools/create_project.py` 与 `framework/project-creation/project-files.json` |
| 生成项目的概念、配置与工具说明 | `framework/godot-project-manual/` |
| 具体的项目开发或框架维护场景 | `framework/prompt-scenarios/scenarios/` 下对应的 Project |
| 正式的提示词 | `framework/prompt-scenarios/prompts/` 下的两份提示词库，各自维护完整正文 |
| 框架共用术语 | `framework/terminology.md`；项目自己的业务词汇不写回这里 |
| 职责设计准则与审核报告 | 长期准则在 [design-guidelines/](design-guidelines/README.md)；当次报告的保存与清理见[审核与报告](design-guidelines/reviews-and-reports.md#当次报告的保存与清理) |
| 规则、Skill 与任务提示词文件的编写 | 根 `AGENTS.md` 与[规则与提示词文件](design-guidelines/instruction-files.md) |
| 框架自用 Skill | 仓库根目录的 `.agents/skills/`。参考资料、配套脚本和私有依赖都放在各 Skill 目录内，不分发给项目 |
| 提示词、场景与关系图的维护方法 | `.agents/skills/prompt-and-graph-maintenance-yaya/` |
| 框架文档的写作方法 | `.agents/skills/technical-documentation-writing-yaya/` |
| 维护约束与未完成的工作 | 根 `AGENTS.md` 与 `framework/progress.md` |
| 某个已有游戏独有的修改 | 在明确指定的外部项目中进行，不写回框架，也不自动同步 |

几条通用原则：

- **编写与审核**：维护规则、Skill 和任务提示词文件时，按[规则与提示词文件](design-guidelines/instruction-files.md)自查；整理已确认说明的表达和组织，使用[框架文档编写 Skill](../../.agents/skills/technical-documentation-writing-yaya/SKILL.md)。普通维护由作者自查，不额外安排独立审核；用户要求正式审核时，按[审核与报告](design-guidelines/reviews-and-reports.md)进行。
- **`project-source/` 只是源材料**：其中的规则和 Skill 在维护仓库里只供阅读，不启用项目开发的 Stage，适用边界见 `AGENTS.md` 的[维护边界与查阅](../../AGENTS.md#维护边界与查阅)。

## 找到受影响的说明

只核对与实际变化相关的专题和直接调用方，不需要每次通读整个仓库。

| 变化 | Godot 项目手册中的专题 | 以什么为准 |
| --- | --- | --- |
| 复制、目录、重命名、初始化边界 | [框架与项目](../godot-project-manual/foundations/framework-and-project.md)、[项目目录](../godot-project-manual/foundations/project-layout.md) | 创建器、复制清单、默认文件 |
| 环境字段、插件或 lint 默认值 | [配置](../godot-project-manual/foundations/configuration.md)、[错误含义](../godot-project-manual/methods-and-tools/errors-and-results.md) | 配置源文件、检查器、插件及补丁 |
| Product、AC、依赖、规划与历史 | [需求与规划](../godot-project-manual/requirements-and-tasks/requirements-and-planning.md) | methodology、模板、规划与同步 Skill、检查器 |
| Stage、验收、任务类型、完成或持续授权 | [任务与阶段](../godot-project-manual/requirements-and-tasks/feature-lifecycle.md) | 执行规范、Feature Skill、工程规范 |
| 探索、worktree 准备或成果整合 | [Skill 与角色](../godot-project-manual/methods-and-tools/skills-and-agents.md#逐步探索与-worktree)、[知识与记录](../godot-project-manual/specialist-work-and-records/knowledge-and-records.md#探索结果与工作目录) | 对应 Skill、任务路由、Git 规范和原有产物归属 |
| 专业文档维护者、资源、语言或独立审核 | [专业来源](../godot-project-manual/specialist-work-and-records/specialist-work.md)、[Skill 与角色](../godot-project-manual/methods-and-tools/skills-and-agents.md) | 专业与审核规范、相应 Skill、角色配置和复制映射 |
| 参数、测试选择、结果、指纹或错误 | [命令与证据](../godot-project-manual/methods-and-tools/commands-and-evidence.md)、[错误含义](../godot-project-manual/methods-and-tools/errors-and-results.md) | 实际 CLI、`tools/lib/verification_snapshot.py`、完成校验与测试策略 |
| 工作台、Analyzer、表现组件 | [资源工作台](../godot-project-manual/specialist-work-and-records/asset-workbench.md) | 对应工具、示例 README、调用接口和夹具 |
| 术语、设计、架构、规则、调研、知识或 Progress | [知识与记录](../godot-project-manual/specialist-work-and-records/knowledge-and-records.md) | 来源规范、产物生命周期、角色和领域规则 |
| 场景的输入、步骤、提示词或出口 | 对应 Project / 分类下的同名场景页 | 所属提示词库、Skill / methodology / CLI、[场景编写要求](../prompt-scenarios/scenarios/README.md) |

其他需要同步的情况：

- **修改分发 Skill 的职责、写入边界或入口**：以该 Skill 的 `SKILL.md` 和它引用的源规范为唯一正文，同步核对任务路由、项目 README 和 advisor；不要在 Project_AGENTS、手册或本页复制一份操作说明。
- **调整路径、字段或 advisor 相关的内容**：按 `AGENTS.md` 的[修改时的联动检查](../../AGENTS.md#修改时的联动检查)执行。
- **说明与源码冲突**：分别判断实际行为是什么、哪里需要修；不能只改一段文字掩盖没解决的契约问题。

框架自身的反馈核实、异常调查、方案检验、维护复盘、重复工作的方法设计和任务交接，都由当前 Agent 按本次要求和对应场景直接处理，复用已有的事实、验证和记录，不启用项目的 Stage：

- 复盘和方法设计默认只交付分析和方案。不会因为缺少 Hook 或 CI 就判定有问题，也不会自动修改规则、写脚本或新增报告。
- 只读、只诊断或明确暂停的请求保持原有边界；已有具体修复授权时，由原任务继续。
- Godot 项目使用自己的方法和记录。advisor 只读取共享的 Godot 提示词库，不会因此调用框架维护 Skill。

## 文档同步应包含什么

按变化类型决定要同步的内容：

- **用户能看到的行为或默认值变了**：同步对应的参数、路径、初始状态、输出、副作用和必要的错误解释。
- **结构变了**：更新入口、链接、锚点和相关的关系图。
- **只是内部实现变了**：使用契约不变时，核对后不需要为改而改。

文档只描述现在的行为，不同时保留新旧两套教程，也不留空的跳转页。历史原因由 Git 保存；当次仍需要的报告按[保留边界](design-guidelines/reviews-and-reports.md#当次报告的保存与清理)处理。不为说明文档建立版本状态、同步收据、来源哈希清单或发布资格。

### 说明的组织与措辞

框架说明的详细写法在 [Yaya 框架文档编写 Skill](../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) 中维护，本节只列检查要点：

- **页面分工**：见[框架入口的两本手册分工](../README.md#两本手册的分工)；场景与提示词的对应关系、栏目和编号要求见[场景编写要求](../prompt-scenarios/scenarios/README.md)。
- **11 类信息**：来自框架版写作 Skill 的流程参考，只用于框架的场景页，不作为 Godot 项目文档的默认结构。
- **场景正文**：作者按本次变化核对标题、输入、单一目标、步骤与出口；调整列表时保留原有的条件和先后顺序。路径检查只证明目录对应，见[路径校验的职责](design-guidelines/prompts-and-scenarios.md#路径校验的职责)。
- **两本手册不互相引用**：必要的解释就地写出；权威规范、工具和公共术语两册都可以引用。
- **链接**：修改时核对受影响的 Markdown 链接、锚点和导航。

生成项目通过[项目内的写作入口](../../project-source/Project_AGENTS.md#使用说明的可读性)使用创建时复制的 Godot 版写作 Skill。它独立维护，使用时不需要访问框架。

### 两份写作 Skill 的分工

| | 框架版 | Godot 版 |
| --- | --- | --- |
| Skill | [technical-documentation-writing-yaya](../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) | [technical-documentation-writing-godot](../../project-source/skills/technical-documentation-writing-godot/SKILL.md) |
| 位置 | 仓库根目录的 `.agents/skills/` | `project-source/skills/`，随项目分发 |
| 服务对象 | 框架的手册、场景、工具说明、维护文档和审核记录（包括 Godot 项目手册） | 实际游戏项目的 README、GDD、Product、Feature、架构、知识和操作说明 |
| 使用语言 | 框架文档的说明语言 | 入口与参考使用英文；编写产物时读取项目的 `document_language` |
| 依据来源 | 当前框架的规范 | 当前游戏项目的规则、模板、词表和工具 |

维护时注意：

- **各自独立**：两份 Skill 各有自己的 `SKILL.md`、`agents/openai.yaml` 和完整参考，可以独立调整例子、默认组织和写作方法，不跨包引用或自动同步；相似的原则可以各写一份。各自产物的实际契约由所属规范决定，写作 Skill 不另造流程。
- **调用方式**：两份的元数据都设置 `allow_implicit_invocation: true`，职责由各自的 `description` 限定，`short_description` 用于界面展示。维护仓库只启用框架版；Godot 版在这里只是待分发的源文件。
- **分发**：`project-source/skills/` 整个目录被复制到生成项目的 `.agents/skills/`，Godot 版的内部相对引用保持有效。框架版不分发，也不另外生成一份普通写作指南。
- **结构**：GDD、Product、Feature 及其验收场景使用各自的结构，不套用框架场景页的 11 类栏目或 S1 编号。
- **更新范围**：修改框架版不影响 Godot 版；修改 Godot 版的源文件只影响以后创建的项目，已创建的项目是否更新由用户决定。
- **依赖**：两份都只通过内部相对路径读取参考，不需要执行脚本、私有运行时或同步工具。
- **修改验证**：根据真实的误用、表达问题或维护成本调整条款和示例；涉及分发时，核对复制后的文件、入口和相对引用。第一次创建或明显改变适用范围时，用一次独立的试写检查实际效果和可移植性；普通的局部改字不需要每次都完整试写。

## 保持初始化边界

- **不进入项目的材料**：手册、维护说明、提示词库、框架自用 Skill 和框架审核材料，都不加入复制清单，也不移到 `project-source/`。
- **随项目分发的材料**：Godot 版写作 Skill 属于项目自己的分发材料，按普通项目 Skill 整包复制。项目 README 保持自己的简短导航；项目文件不接受自动同步。
- **advisor**：直接读取本机的 Godot 提示词库，修改提示词正文后不需要导出。固定路径及其同步要求见 `AGENTS.md` 的[提示词维护](../../AGENTS.md#提示词维护)，用法见[advisor 的共享场景入口](../godot-project-manual/methods-and-tools/skills-and-agents.md#advisor-的共享场景入口)。
- **续接提示词**：项目中动态生成的续接提示词，格式统一维护在 [Continuation prompts](../../project-source/methodology/09-artifact-lifecycle.md#continuation-prompts)，由 advisor 和 `task-handoff-godot` 引用；框架的集中提示词仍各自保留具体场景的输入、授权和停点目的。普通暂停、换对话和恢复已有停点不合并成一条通用提示词，新增 Skill 也不要求每个入口都建场景。

## 验证、提交与交付

- **验证**：按[按修改选择验证范围](validation/validation-scope.md#按修改选择验证范围)确定。
- **提交与未完成事项**：遵循[根维护约定的本地提交](../../AGENTS.md#本地提交)，本页不另写规则。
- **交付**：给出受影响的文档入口和真实的验证结果。文档任务不能宣称游戏运行通过；框架的提交也不会更新已有的游戏项目。

## 整体审核与专项审核的入口

按目的选择已有场景，本页不重复执行步骤：

| 目的 | 场景 |
| --- | --- |
| 检查当前工作区是否自洽 | [本地静态审核](<../prompt-scenarios/scenarios/Yaya 框架维护/维护与复盘/想检查本地框架是否自洽，先做静态审核.md>) |
| 先了解框架结构，再选专题 | [框架结构总览](<../prompt-scenarios/scenarios/Yaya 框架维护/只读专项审核/想先总览框架，再选择审核专题.md>)；总览不承诺全面审核 |
| 深入核对某个专项问题 | 从[只读专项审核](../prompt-scenarios/scenarios/scenario-index.md#只读专项审核)选一个专题，与「专项审核通用模板」拼接后使用，不需要填参数 |
| 核实收到的审核意见 | [外部意见复核](<../prompt-scenarios/scenarios/Yaya 框架维护/维护与复盘/收到外部审核意见，先核实哪些值得修改.md>) |
| 用一个小任务验证真实流程 | [小任务验证](<../prompt-scenarios/scenarios/Yaya 框架维护/维护与复盘/想用一个小任务实际验证框架流程.md>)；实际运行范围与静态结论分别记录 |

总体判断依据[根规则的核心原则](../../AGENTS.md#核心决策原则)，文本与职责的评价依据[职责设计准则](design-guidelines/README.md)。报告只记录已核实的版本、范围和证据，不授予实施权限。

## 授权在后续对话中的延续

- 同一会话中已给出的具体授权继续有效，说明同步与如实记录验证的要求也始终适用。
- 用户最新的明确要求会调整目标与范围；已被替代的临时只读、输出或停止条件，不再约束后续工作。
- 例如先只读分析，用户再明确说“按这个方案改这两处”，就可以在选定范围内实施；而“这样改合适吗”仍然是讨论，不是授权。
- 已批准且没有变化的决定不重复确认；新的决定和实际的人工验收要单独处理。
- 交接时区分仍有效的原则、当前的限制和已被替代的要求，接收方按自己读到的实际文件和授权继续。
