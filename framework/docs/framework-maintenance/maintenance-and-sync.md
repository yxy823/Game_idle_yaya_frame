# 框架维护与说明同步

[维护文档入口](README.md) · [框架规则](../../../AGENTS.md) · [维护命令](../../commands/README.md)

本页保存框架维护的材料归属、说明同步和验证约定。具体任务入口由文档总入口统一导航，不在这里复写场景流程或正式提示词。

## 先判断修改属于哪里

| 内容 | 维护位置 |
| --- | --- |
| 项目分发材料 | project-source/；路径变化同时核对复制清单 |
| 创建器与复制规则 | framework/commands/project/create_project.py 与 framework/commands/project/project-files.json |
| 概念、配置与工具说明 | framework/docs/operation-manual/ |
| 具体项目或维护场景 | framework/prompt-scenarios/scenarios/ 的对应 Project |
| 项目内简短导航 | project-source/Project_README.md |
| 框架维护、供用户自行复用的 Skill | 仓库根目录的 .agents/skills/；所需参考、配套脚本及私有依赖随各 Skill 保存，不整包分发给项目 |
| 规则、Skill 与任务提示词文件维护 | 根 AGENTS.md 与本目录的 responsibility-design-guidelines.md，由当前任务直接处理 |
| 提示词、关联场景与关系图维护 | .agents/skills/prompt-and-graph-maintenance-yaya/，框架自用；按变化同步提示词导航、项目场景图或文档系统图，沿用各自规范 |
| 框架文档写作 | .agents/skills/technical-documentation-writing-yaya/，框架自用，不分发 |
| 分发给项目的 Godot Skill | project-source/skills/<名称>/，随 Skill 目录整包分发；各 Skill 的职责以其 SKILL.md 与 project-source/Project_AGENTS.md 的路由为准，本表不逐个登记 |
| Skill、规则和流程正文 | 所属源规范；只有任务涉及行为时调整，整理目录不隐含行为修改 |
| 职责设计和审核事实 | 长期准则在 [responsibility-design-guidelines.md](responsibility-design-guidelines.md)，当次报告的保存与清理见其[同名小节](responsibility-design-guidelines.md#当次报告的保存与清理) |
| 框架共用术语 | framework/docs/terminology.md；项目自己的业务词汇不回灌此处 |
| 正式操作提示词 | framework/prompt-scenarios/prompts/godot-development-prompts.json 与 framework/prompt-scenarios/prompts/yaya-maintenance-prompts.json，按用途各自维护完整正文 |
| 维护约束与未完成工作 | 根 AGENTS.md / framework/progress.md |
| 已有游戏的独有修改 | 明确指定的外部项目，不自动回灌或同步 |

框架规则、Skill 和任务提示词文件的维护与自查直接依据[职责设计准则](responsibility-design-guidelines.md#规则与提示词文件维护)。用户要求正式审核时，按同一准则核对范围、独立性与证据。整理已确认说明的表达与组织使用[框架文档编写 Skill](../../../.agents/skills/technical-documentation-writing-yaya/SKILL.md)。普通维护不追加独立审核阶段。

Project_AGENTS.md 是待复制源规则。根规则明确引用的沟通、可读性与共用工程约定适用于维护；项目开发 Stage 不在维护仓库启用。查看 Skill 源材料不等于当前任务进入该 Skill 流程。

维护分发的 Godot 文件按领域读取 project-source/agent-rules/，授权、Git、验证地点和交付仍以本维护仓库规则为准。指定 worktree 时以其实际文件和状态为准，不据此启用生成项目的 Stage。

## 找到受影响的说明

只核对实际变化相关专题及直接调用者，不每次全仓通读。

| 变化 | 操作专题 | 真实依据 |
| --- | --- | --- |
| 复制、目录、重命名、初始化边界 | [框架与项目](../operation-manual/foundations/framework-and-project.md)、[项目目录](../operation-manual/foundations/project-layout.md) | 创建器、清单、默认文件 |
| 环境字段、插件或 lint 默认值 | [配置](../operation-manual/foundations/configuration.md)、[错误含义](../operation-manual/methods-and-tools/errors-and-results.md) | 配置源、检查器、插件及补丁 |
| Product、AC、依赖、规划与历史 | [需求与规划](../operation-manual/requirements-and-tasks/requirements-and-planning.md) | methodology、模板、规划/同步 Skill、检查器 |
| Stage、验收、任务类型、完成或持续授权 | [阶段语义](../operation-manual/requirements-and-tasks/feature-lifecycle.md) | 执行规范、Feature Skill、工程规范 |
| 探索、worktree 准备或成果整合入口 | [Skill 与角色](../operation-manual/methods-and-tools/skills-and-agents.md#逐步探索与-worktree)、[知识与记录](../operation-manual/specialist-work-and-records/knowledge-and-records.md#探索结果与工作目录) | 对应 Skill、总路由、Git 规范及原有产物归属 |
| 专业所有者、资源、语言或独立审核 | [专业来源](../operation-manual/specialist-work-and-records/specialist-work.md)、[Skill 与角色](../operation-manual/methods-and-tools/skills-and-agents.md) | 专业/审核规范、相应 Skill、角色及复制映射 |
| 参数、测试选择、结果、指纹或错误 | [命令与证据](../operation-manual/methods-and-tools/commands-and-evidence.md)、[错误含义](../operation-manual/methods-and-tools/errors-and-results.md) | 实际 CLI、tools/lib/verification_snapshot.py、完成校验与测试策略 |
| 工作台、Analyzer、表现组件 | [资源工作台](../operation-manual/specialist-work-and-records/asset-workbench.md) | 对应工具、示例 README、消费接口及夹具 |
| 术语、设计、架构、规则、研究、知识或 Progress | [知识与记录](../operation-manual/specialist-work-and-records/knowledge-and-records.md) | 来源规范、生命周期、角色与领域规则 |
| 场景输入、步骤、提示词或出口 | 对应 Project/分类/同名场景 | 所属 Godot 开发或 Yaya 维护提示词库、Skill/methodology/CLI、[场景编写要求](../../prompt-scenarios/scenarios/README.md) |

框架的反馈核实、异常调查、方案检验和任务交接由当前 Agent 按本次要求及对应场景直接处理，复用已有事实、验证和记录。只读、只诊断或明确暂停的请求保留原边界，已有具体修复授权由原任务继续。Godot 项目使用自己的方法与记录；advisor 只读共享 Godot 提示词，不据此调用框架维护 Skill。

修改分发 Skill 的职责、写入边界或入口时，以该 Skill 的 SKILL.md 及其引用的源规范为唯一正文，同步核对总路由、项目 README 与 advisor；不在 Project_AGENTS、手册或本页复制一套操作正文。

路径、字段与 advisor 的联动按 AGENTS.md 的[修改时的联动检查](../../../AGENTS.md#修改时的联动检查)执行。说明与源码冲突时分别判断实际行为及待修问题，不能只改一段文字掩盖未解决契约。

## 文档同步应包含什么

按变化类型选择需要同步的内容：

- **用户可见行为或默认值变化**：同步对应参数、路径、初始状态、输出、副作用与必要错误解释。
- **结构变化**：更新入口、链接、锚点和相关图。
- **仅内部实现变化**：使用契约不变时，核对后不必制造无意义修改。

文档面向最终行为，不保留两套旧/新教程或空重定向页。历史原因由 Git 保存；当次仍需使用的报告按[保留边界](responsibility-design-guidelines.md#当次报告的保存与清理)处理，不建立说明版本状态、同步收据、来源哈希清单或发布资格。

### 说明的组织与措辞

框架说明的详细写法维护在 [Yaya 框架文档编写 Skill](../../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) 中，本节只保存检查约定。生成项目通过[本地写作入口](../../../project-source/Project_AGENTS.md#使用说明的可读性)使用创建时复制的 Godot 版 Skill；该包独立维护，使用时无需访问框架或框架版写作资料。

页面分工见[文档总入口](../README.md#两本手册的分工)；场景与提示词的对应关系、栏目和编号要求见[场景编写要求](../../prompt-scenarios/scenarios/README.md)。11 类信息的写法来自框架版写作 Skill 的流程参考，不作为 Godot 项目文档的默认结构。

- **路径核对**：使用 [路径检查器](../../commands/README.md#提示词与场景路径检查) 核对路径集合。
- **正文自查**：作者按本次变化核对标题、输入、单一目标、步骤与出口；调整列表时保留原有条件和先后依赖。

路径匹配不证明内容或实际执行通过。

两本手册之间不互相引用，必要解释就地提供，权威规范、工具和公共术语仍可共同引用。修改时核对受影响的 Markdown 链接、锚点与导航。

### 可复用写作 Skill 的维护

[technical-documentation-writing-yaya](../../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) 位于根目录的 `.agents/skills/`，服务整个框架的手册、场景、工具说明、维护设计和审核记录。[technical-documentation-writing-godot](../../../project-source/skills/technical-documentation-writing-godot/SKILL.md) 位于项目 Skill 分发源中，服务实际游戏项目的 README、GDD、Product、Feature、架构、知识和操作说明。框架手册里介绍游戏开发的页面仍由框架版处理；项目中的实际文档由 Godot 版处理。

- **独立正文**：两份 Skill 各自保存 `SKILL.md`、`agents/openai.yaml` 和完整参考。可以独立调整例子、默认组织和写作方法，不跨包引用或自动同步正文；相似原则可分别维护。各自产物的实际契约仍由所属规范拥有，不在写作包中另造流程。
- **发现与调用**：两份元数据均设置 `allow_implicit_invocation: true`，职责由各自 `description` 限定，`short_description` 用于界面展示。框架只启用根目录的框架版；Godot 版源文件在维护仓库只作为分发材料，复制后成为项目本地 Skill。
- **项目分发**：现有 `project-source/skills/` 目录映射整包复制 Godot 版到生成项目的 `.agents/skills/technical-documentation-writing-godot/`，保留内部相对引用。不复制框架版，也不另外生成普通写作指南副本。
- **内容与语言**：框架版保留框架文档的说明语言；Godot 版入口与参考使用项目流程源规范的英文版本，编写产物时读取项目 `document_language`。GDD、Product、Feature 及其验收场景沿用自己的结构，不能套用框架的 11 类栏目或 S1 编号。
- **更新边界**：修改框架版不改变 Godot 版；修改 Godot 版源材料只影响以后创建的项目。已创建项目拥有独立副本，后续更新由用户决定，不回查框架或自动同步。
- **包内资源与外部依据**：每包的写作方法通过内部相对路径读取。框架版查当前框架规范，Godot 版查当前游戏项目的规则、模板、词表和工具，不跨项目读取。当前两包均不需要执行脚本、私有运行时或同步工具。
- **修改验证**：根据真实误用、表达问题或维护成本调整相应条款与示例；分发变化核对复制后的文件、入口和相对引用。首次创建或明显改变适用范围时，用独立试写检查实际结果与可携带性；格式校验不替代内容判断，不要求每次局部改字都重新跑完整试写。

## 保持初始化边界

手册、维护说明、提示词库、框架自用 Skill 包和框架审核材料不加入项目复制清单，也不移动到 project-source/。Godot 版写作 Skill 是项目自身的分发材料，按普通项目 Skill 整包复制。项目 README 保持自身短导航；项目文件不接受自动同步。

advisor 直接读取本机的 Godot 提示词库，修改正文后无需导出；固定路径及其同步要求见 AGENTS.md 的[提示词维护](../../../AGENTS.md#提示词维护)，使用方法见[共享场景入口](../operation-manual/methods-and-tools/skills-and-agents.md#advisor-的共享场景入口)。

项目动态续接提示词的通用格式维护在 [Continuation prompts](../../../project-source/methodology/09-artifact-lifecycle.md#continuation-prompts)，由 advisor 和 task-handoff-godot 引用；框架集中提示词仍保留各场景的具体输入、授权和停点目的。普通暂停、换对话和已有停点恢复不合并为一条通用提示词，也不因新增 Skill 要求每个入口另建场景。

## 按修改选择验证范围

分发源、外部项目和维护夹具的具体边界见 [复制与运行验证](validating-framework.md)，命令见 [按需检查](../../commands/README.md#按需检查)。

| 修改 | 相称检查 |
| --- | --- |
| Markdown、目录与导航 | 对照源材料核对修改涉及的事实与示例、链接、锚点和导航；保留两册独立阅读边界 |
| 提示词或场景 | JSON/名称/路径检查与对应正文自查；不将其写成已逐条执行 |
| 创建器或清单 | 映射、边界及按需创建器回归 |
| Python 项目工具 | 相关实现与调用静态核对，指定外部项目中的工具回归 |
| Godot 代码、插件、场景或资源 | 按实际影响在指定外部项目运行真实引擎验证 |
| 仅静态或只读请求 | 不生成项目、不启动 Godot、不运行测试 |

文档指纹与人工验收回归可用中立临时 Git 夹具；不创建业务项目或替代真实人工体验。项目工具回归入口不替用户创建/更新项目，不启动引擎。已有结果只在对应最终内容与覆盖仍有效时复用，未执行部分明确保留。

检查手册未被复制无需创建真实游戏，可静态展开清单核对。静态图源核对不是渲染或视觉验收。外部测试项目的机器路径、主场景、台账与历史不回灌默认值。

## 提交与交付

提交与未完成事项遵循[根维护约定](../../../AGENTS.md#本地提交)，不在本页维护第二套规则。交付提供受影响文档入口与真实验证结果；文档任务不宣称游戏运行通过，框架提交不更新已有游戏。

## 整体重检与详细报告

按目标选择已有场景，不在维护规范中复写执行步骤：

- **检查当前工作区**：[本地静态审核](<../../prompt-scenarios/scenarios/Yaya 框架维护/维护与复盘/想检查本地框架是否自洽，先做静态审核.md>)。
- **先了解框架结构**：[框架结构总览](<../../prompt-scenarios/scenarios/Yaya 框架维护/只读专项审核/想先总览框架，再选择审核专题.md>)，直接从当前框架最新内容了解职责和入口，选择值得深入的专题；总览不承诺全面审核。
- **深入核对专项问题**：从[只读专项审核](../../prompt-scenarios/scenarios/scenario-index.md#只读专项审核)选择一个专题，与「专项审核通用模板」拼接后使用，无需填写参数。
- **核实收到的意见**：[外部意见复核](<../../prompt-scenarios/scenarios/Yaya 框架维护/维护与复盘/收到外部审核意见，先核实哪些值得修改.md>)。
- **验证真实流程**：[小任务验证](<../../prompt-scenarios/scenarios/Yaya 框架维护/维护与复盘/想用一个小任务实际验证框架流程.md>)，实际运行范围与静态结论分别记录。

总体判断依据为[根规则的核心原则](../../../AGENTS.md#核心决策原则)，文本与职责评价依据为[职责设计准则](responsibility-design-guidelines.md)。报告只记录已核实的版本、范围和证据，不授予实施权限。

## 后续用口语继续

同一会话的具体授权、职责、说明同步和如实验证要求继续有效。最新明确要求调整相应目标与范围，已被替代的临时只读、输出或停止条件不永久约束后续工作。

例如先只读分析，再明确说“按该方案修改这两处”，即可在所选范围实施；“这样改合适吗”仍是讨论。已批准且未变的决定不重复确认，新决定和实际人工验收分别处理。交接区分有效原则、当前限制与已替代要求，接收方依自己的实际文件与授权继续。
