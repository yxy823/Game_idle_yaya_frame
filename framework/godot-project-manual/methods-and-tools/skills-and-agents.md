# Skill、Agent 与提示词

[Godot 项目手册](../README.md)

本页说明生成项目中的三样东西怎样配合：

- **Skill**：可复用的方法，例如“怎样规划 Feature”“怎样诊断 Bug”。
- **Agent**：执行方法的实例，包括主 Agent 和专用角色。
- **提示词**：描述这一次具体要做什么。

三者粒度不同：每条正式提示词只对应一个具体场景；Skill 和脚本则按职责划分，一个 Skill 可以服务多个场景，不为每个场景复制一套实现。

选择 Skill 时按当前要做的事，而不是按逻辑或表现分层：规则和体验目标由设计类 Skill 处理，一次具体的游戏表现由 `design-game-presentation` 细化，获准的开发由原 Feature 承接。跨层的功能可以在同一个任务里完成，不需要分别委派“逻辑 Agent”和“表现 Agent”。

## 规则、方法和方案各放在哪里

以 Shader 为例，三类内容各有位置：

| 内容 | 位置与用途 |
| --- | --- |
| 工程约束 | [Shader 规则](../../../project-source/agent-rules/30-shaders/README.md)：语言、坐标、材质参数、真实验证等要求，按 MUST、PREFER、REVIEW 区分强度 |
| 可复用的方法 | [实现方法参考](../../../project-source/skills/implementation-guidance-godot/references/shader-implementation-methods.md)帮助推导数据流和选择算法；[诊断参考](../../../project-source/skills/bug-diagnosis-godot/references/shader-diagnostics.md)帮助选择能区分原因的检查 |
| 当前游戏的方案与证据 | 表现目标和采用的方案写在对应的游戏表现文档；需要详细工程设计时写在 Feature 设计稿；原型、诊断与验证证据留在原任务的记录中，见[知识、设计与记录](../specialist-work-and-records/knowledge-and-records.md) |

Shader 规则的入口会链接这些方法参考。正式实现、原型和排错都可以直接读它们：参考文件放在某个 Skill 的 `references/` 目录下，不代表要启动那个 Skill 的完整流程、建 Feature 或委派顾问。读参考也不改变当前任务的授权和完成条件，参考里的具体数值不会因此成为通用规则。

## Skill 职责速查

以下名称对应生成项目 `.agents/skills/<名称>/SKILL.md`。当前源文件是 [skills 目录](../../../project-source/skills)，具体触发和排除项以各自 description 与正文为准。

| Skill | 唯一主要职责 |
| --- | --- |
| `project-next-step-advisor` | 根据当前事实给状态、下一步或回复建议；不执行建议 |
| `project-grill-me` | 澄清会实质影响当前任务的未决问题；游戏设计归 design-gdd，交付取舍归 product-spec-elicitor |
| `wayfinder-godot` | 处理相互影响的多个未知，按依赖选择所需讨论、调研或实验 |
| `feedback-triage-godot` | 对照当前事实整理反馈类别、证据缺口与处理归属 |
| `bug-diagnosis-godot` | 围绕具体异常定位原因，区分已证实结论与假设 |
| `project-environment-godot` | 配置、更新或恢复项目工具环境，完成确有需要的首次资源扫描 |
| `project-verification-godot` | 执行本次要求的解析、lint、已有测试或限定场景检查，报告真实结果 |
| `manual-acceptance-godot` | 为实际 Feature 准备待验收清单，或登记用户真实给出的验收结果 |
| `verification-evidence-godot` | 检查、导入或恢复已有验证证据，将必要重跑与人工跟进交给对应入口 |
| `prototype-godot` | 在当前 Feature 或获准实验中制作并检查真实 Godot UI/逻辑原型 |
| `worktree-create-godot` | 为获准任务准备或复用目标工作目录，核对所需本地运行条件 |
| `worktree-integrate-godot` | 将已选成果带入目标，处理已有整合冲突并验证组合后的结果 |
| `task-handoff-godot` | 保存用户要求的停点，按需生成可复制的当前任务续接文本 |
| `plan-review-godot` | 按约定范围审核 GDD 草稿或完整文档、Product 或 Feature 方案，返回有依据的缺口与结论 |
| `retro-godot` | 根据实际开发经历提出流程、规则与工具的改进建议 |
| `loop-me-godot` | 为用户指出的重复或预计重复工作设计处理方法，明确入口、判断、产出与正文归属 |
| `technical-documentation-writing-godot` | 编写、更新或整理项目文档的表达与导航，不做游戏设计决定或职责审核 |
| `project-terminology` | 在 `docs/terminology.md` 统一保存已确认且含义不变的项目定义，维护术语引用 |
| `design-gdd` | 从想法形成、整合或修订 GDD，维护整体规则、体验目标与跨主题一致性 |
| `design-balance` | 推导或调整数值模型，直接维护获准的 GDD 数值主题、公式参数与计算说明 |
| `product-author` | 根据 GDD 维护交付预拆分和当前 Product，协调已规划工作的影响 |
| `product-spec-elicitor` | 澄清交付边界、依赖与顺序；游戏规则问题回到设计入口，明确契约的实现缺陷交工程流程 |
| `feature-plan` | 为当前 Product 建立可追溯 Feature 覆盖与依赖 |
| `feature-sync` | 将已确认来源变化映射到已有计划及测试历史 |
| `feature-execute` | 交付获准 Feature，承担适用实现、验证、记录与收尾 |
| `implementation-guidance-godot` | 为已有 Feature 准备约束、设计、必要实现顺序和验证思路，沿用该 Feature 设计稿 |
| `engineering-change-plan` | 为 Bug、重构、维护等独立工程工作确定任务范围与验证 |
| `engineering-refactor-select` | 从已有真实候选中选择值得实施的行为保持重构 |
| `design-art-direction` | 共享视觉方向与适用约束 |
| `design-audio-direction` | 共享声音方向与反馈层次 |
| `design-ui-spec` | 界面布局、状态、界面专用资源章节及关联游戏表现导航 |
| `design-game-presentation` | 从体验目标规划一次游戏表现，标准化组件需求、比较候选并记录采用及实际实现关系 |
| `design-visual-asset-spec` | 具体视觉资源的准备和交付要求 |
| `design-audio-asset-spec` | 具体音效/音乐的准备和交付要求 |
| `design-localization-spec` | 语言覆盖、回退、文本与字体等本地化要求 |
| `content-asset-integration` | 对照既定要求接入真实资源及消费者 |
| `content-localization` | 按已确认规格接入翻译、字体与语言运行支持 |
| `diagnostics-instrumentation` | 为明确问题提供有单位、用途和开销的观测信号 |
| `diagnostics-performance` | 可比较的性能测量与瓶颈诊断 |
| `diagnostics-soak-test` | 在约定负载、时长和停止条件内取得长测证据 |
| `review-code` | 独立检查变更或模块现状的需求符合性、代码质量和实际覆盖 |
| `review-ux` | 操作理解、可操作性及相关无障碍要求 |
| `review-art` | 实际视觉表现与美术/界面规格 |
| `review-audio` | 实际音频和场景播放的听觉与规格符合性 |
| `review-assets` | 资源技术规格、引用、导入及可核实来源 |
| `review-localization` | 语言覆盖、含义、术语与实际显示 |
| `review-balance` | 数值组合与已确认策略、成长及节奏目标 |

名称前缀（design、content、diagnostics、review）只帮助识别职责，不是必须依次执行的流程。只读调查、编写规格和实现修改需要的授权不同。

### 相近 Skill 怎样选

| 情况 | 使用 |
| --- | --- |
| 当前任务有影响结果的未决问题，需要澄清 | `project-grill-me` |
| 形成或修改游戏设计 | [design-gdd](../../../project-source/skills/design-gdd/SKILL.md) |
| 术语含义已明确，只需要登记 | `project-terminology`，不需要再做需求访谈 |
| 交付范围上的取舍问题 | `product-spec-elicitor` |
| 把当前 Product 拆成 Feature | `feature-plan` |
| 检验已有的 GDD 草稿、完整 GDD 或方案 | [plan-review-godot](../../../project-source/skills/plan-review-godot/SKILL.md)；按 GDD 的阶段和范围读取对应参考，没有 Product 或 Feature 也可以审核 |
| 从真实开发经历中总结经验 | [retro-godot](../../../project-source/skills/retro-godot/SKILL.md) |
| 收到反馈，还不确定要不要改 | [feedback-triage-godot](../../../project-source/skills/feedback-triage-godot/SKILL.md)：核对反馈属于哪一类、该由谁处理 |
| 已有具体异常，要查原因 | [bug-diagnosis-godot](../../../project-source/skills/bug-diagnosis-godot/SKILL.md) |

这些 Skill 的结论交回原来的负责人，不增加必经步骤，也不代替人工验收。正式的独立审核必须由没有参与创作的实例执行。

几项补充说明：

- **数值设计**：[design-balance](../../../project-source/skills/design-balance/SKILL.md) 从已知目标和规则推导数值方案，也可以调整已有模型的参数，并在写入授权内直接维护 GDD 中所属的数值正文。采纳的参数、写入的文件和验证状态分别记录；需要新增玩法或改变体验目标时，回到 `design-gdd`。检查现有模型、策略组合和已采用数值是否成立，用 `review-balance` 独立审核；设计者自己验算不算独立审核。普通的尺寸或数量记录不需要专门建模。
- **反馈与诊断**：用户描述实际症状即可，Agent 根据证据追查逻辑、表现以及两者的连接，不需要用户先判断属于哪一层，也不会因为跨层就拆成多个 Bug。只要求调查时，交付证据和结论；已有具体的修复授权时，查清原因后回到原任务继续。
- **环境、检查、验收与证据**：`project-environment-godot`、`project-verification-godot`、`manual-acceptance-godot` 和 `verification-evidence-godot` 可以在任何环节按需调用，也可以单独处理用户直接提出的限定任务。例如只要求跑现有测试时，按那次检查的范围执行，与有没有 Feature 无关；但登记人工验收结果，必须对应实际的 Feature 和用户的真实结果。调用其中一个，不会扩展成整套交付。具体怎样选择由[任务路由](../../../project-source/methodology/00-overview.md#canonical-task-routing)统一规定。
- **原型**：[prototype-godot](../../../project-source/skills/prototype-godot/SKILL.md) 用可运行的 Godot 场景或逻辑实验回答本次的具体问题。原型观察到的结果不等于正式验收。
- **暂停与续接**：[task-handoff-godot](../../../project-source/skills/task-handoff-godot/SKILL.md) 使用已有的 Progress、Feature 或任务记录。只要求暂停时，保存停点；需要换对话时，再生成可复制的续接文本。它不会自动创建对话、发送消息或另建交接台账。恢复已有停点时直接回到原任务，不需要再调用一次交接。
- **显式调用更可靠**：description 帮助客户端按任务自动选择 Skill，但 Skill 文件存在、格式正确，不代表客户端一定会自动选中它。规范要求的调查和验证仍由原流程负责，不依赖自动发现。

## 逐步探索与 worktree

| Skill | 什么时候用 | 说明 |
| --- | --- | --- |
| [wayfinder-godot](../../../project-source/skills/wayfinder-godot/SKILL.md) | 几个问题互相牵连，要先解决一个才能判断下一个。例如背包容量会影响搜索需求和列表性能 | 按当前缺口选择讨论、事实调查或限定原型，不需要把所有方法都走一遍。普通澄清、检验已有方案或目标清楚的实施任务不必先经过它。只讨论时交付结论；已有实施授权时，问题解决后回到原任务。结论与证据的存放见[探索结果与工作目录](../specialist-work-and-records/knowledge-and-records.md#探索结果与工作目录) |
| [worktree-create-godot](../../../project-source/skills/worktree-create-godot/SKILL.md) | 确实需要另一个工作目录 | 准备或复用指定版本的 checkout。目录分开不代表运行数据也分开，具体准备方法只在它的[运行参考](../../../project-source/skills/worktree-create-godot/references/godot-worktree-runtime.md)中维护；环境与验证入口遇到写入位置不明或变化时，也直接引用这份参考 |
| [worktree-integrate-godot](../../../project-source/skills/worktree-integrate-godot/SKILL.md) | 已选定要采用的成果，或要接手已有的整合冲突 | 带回必要的依赖并检查合并后的结果。原任务的验证、人工验收和提交条件仍然有效；整合后不会自动删除源目录或分支。Git 细则见[项目 Git 规范](../../../project-source/agent-rules/00-core/git-worktree-and-commits.md) |

这三个 Skill 可以分别调用，不构成固定的阶段。

## 为重复工作设计方法

已经反复做、或预计以后会经常做的工作，可以用 [loop-me-godot](../../../project-source/skills/loop-me-godot/SKILL.md) 设计处理方法，不必等到出了问题。例如经常要重新说明“准备资源需要哪些输入”，就可以比较三种做法：补充现有入口、明确引用已有资料、新增一项能力，然后设计下次怎样开始、判断和交付。

- **与 retro 的区别**：`retro-godot` 从真实经历中分析原因和经验，`loop-me-godot` 面向以后的同类工作设计方法。两者都可以在讨论、开发或维护中按需调用，没有固定的先后顺序。
- **来源**：两者分别借鉴 Matt Pocock 的 loop-me 和 retro，保留来源名称，按项目的实际职责改编；它们随项目分发，只使用项目自己的规范和能力。
- **交付什么**：默认交付一份可以讨论的方案，详细规则仍写在已有正文中，不会自动创建脚本、报告或定期任务。用户已经明确授权的实施由原任务继续，方法设计结束后不需要再次批准。

## 主 Agent 与专用角色

- **主 Agent**：找到实际目录、范围和已有决定，按任务调用方法，持续推进尚未完成的授权工作。
- **用户**：决定尚未确定的意图，亲自完成人工体验。
- **工具**：执行可重复的检查；工具成功不能代替用户的判断。

### 调研与独立审核角色

项目附带 [researcher](../../../project-source/agents/researcher.toml)（按需独立调研）和 [independent-reviewer](../../../project-source/agents/independent-reviewer.toml)（独立审核）。使用它们需要全新的上下文、宿主程序的实际支持和合适的权限；配置文件存在不代表宿主已加载这个角色。作者自己按审核 Skill 读一遍，仍然只是自查。

调研可以使用用户级的 anysearch，框架不复制它的实现、密钥或个人路径。工具不可用时，按角色规则选用其他实际可用的渠道并说明限制；找不到来源时如实说明，不写成已查证。调研方法和报告格式由角色配置维护，长期保存位置见[调研与项目知识](../specialist-work-and-records/knowledge-and-records.md#调研与项目知识)。

### 实施顾问

已有 Feature 需要实施指导时，使用 [implementation-guidance-godot](../../../project-source/skills/implementation-guidance-godot/SKILL.md)。

- **谁来准备**：默认由主 Agent 自己准备。只有用户在任务提示词或仍有效的授权中明确要求，才委派给 [implementation-advisor](../../../project-source/agents/implementation-advisor.toml)。任务复杂、加载了这个 Skill、或要求写详细设计，都不会自动触发委派。顾问使用的模型和推理强度只在角色配置中维护。
- **顾问做什么**：读取相关规则和实际代码，给出有来源依据的设计和验证思路。需要用户决定时，顾问把编号问题、A/B 选项和建议交给主 Agent，主 Agent 在当前对话中展示，再把用户的回答传回同一个顾问。方案获批前只在对话中讨论；获批后，顾问才能把这份方案保存为 Feature 设计稿（位置见[局部设计与当前架构](../specialist-work-and-records/knowledge-and-records.md#局部设计与当前架构)）。
- **顾问不做什么**：不运行 Godot、测试或实验；不修改业务实现、Feature JSON、测试登记表、状态或验收记录；不提交。
- **主 Agent 的职责**：阅读设计稿、关键的适用规则和实际要改的代码及其使用方，但不需要重复顾问的全部背景调研；之后负责核对、记录和实施。
- **出错时**：顾问启动失败、指定的模型不可用或执行失败时，停止依赖它的工作，报告原因和已完成的部分；不自动换模型，也不改由主 Agent 接手。
- **审核**：写这份设计的人不能兼任它的独立审核者。

### 找不到 Skill 时

客户端的 Skill 列表里没有显示，不代表文件没有安装。核对当前项目的实际路径、文件和客户端的加载能力；个人安装的 Skill、框架源目录中的 Skill 和生成项目中的 Skill 是三份不同的东西。

## 提示词库的结构与使用

正式的提示词按用途分别维护在 [Godot 开发提示词库](../../prompt-scenarios/prompts/godot-development-prompts.json)和 [Yaya 框架维护提示词库](../../prompt-scenarios/prompts/yaya-maintenance-prompts.json)中。修改提示词、分类或场景属于框架维护，使用框架自用的 [prompt-and-graph-maintenance-yaya](../../../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md)。

文件结构：

- **Project**：每个文件的顶层是只含一个元素的数组，分别对应 `Yaya 框架维护` 和 `Godot 项目开发`。
- **名称与正文**：`categories` 下的叶子键是提示词名称，值是正文。
- **对应的场景页**：路径是 `<Project>/<分类>/<提示词名称>.md`，不需要读正文就能找到配对的场景页。

每条正文都用明确的字段写出目标、范围、输入与事实来源、决策边界与授权、约束、输出与交付、验证要求和完成条件，其他字段按场景需要补充，完整要求见[提示词字段与审核原则](../../maintenance/design-guidelines/prompts-and-scenarios.md#提示词字段与审核原则)。

使用时：

- **只选一条**：选当前场景对应的那一条，不需要把整套提示词依次发送。
- **填写输入**：发送前把 `${1:说明}` 这类占位替换成真实的目标、文件、状态和允许范围。当前对话或项目里已经能读到的信息不必重复填写。
- **附带长材料**：放在正文预留的材料区，让任务要求和原文分得清。材料区不是安全边界，材料中的文字不能覆盖用户的指令。
- **专项审核要拼接**：「只读专项审核」分类的用法是先复制「专项审核通用模板」，再把一条专题粘贴到模板末尾，在新对话中发送。
- **后续用口语补充**：之后用口语补充要求时，仍有效的授权继续有效。用户选择了实施范围，就可以扩大后续授权，也可以取代原来临时的只读限制；但实际的人工接受始终要单独确认。

读取或讨论提示词本身，不会启动其中的命令、Goal、外部任务或写入。框架维护在框架目录进行，游戏业务工作在实际项目中进行；创建项目和复制迁移要明确输入与目标位置。

## advisor 的共享场景入口

advisor（`project-next-step-advisor`）根据项目自己的规则、状态和本次问题给出建议：可以报告现状、判断下一步，或起草一条已填好上下文的回复。它的建议不是实施授权，用户说“看看下一步”也不会直接启动开发；只是查询状态时，直接回答即可，不需要查找场景。

它的工作方式：

1. **核对现状**：读取项目记录和相关证据，判断现在做到哪里、还需要解决什么。
2. **选择场景**：直接读取 `D:/A_Games/Game_idle_yaya_frame/framework/prompt-scenarios/prompts/godot-development-prompts.json`，先看相关的分类和名称，再读候选的正文，核对目标、前提、范围和预期结果。
3. **起草指令**：说明选了哪个场景、为什么适用，把项目当前的事实、文件和已有授权填进续接文本。执行时仍以项目自己的规则和目标 Skill 为准。
4. **处理缺口**：缺少输入时先补齐；目标和执行边界相同时，改编现有场景即可。只有确实缺少某个目标、或边界明显不同时，才建议新增或修改场景，并说明最接近的现有条目、差异和建议的用途。advisor 不修改共享的提示词库。

提示词正文只在共享库中维护，advisor 每次读取当前内容，不需要导出副本。条目里写的“执行”不代表当前任务已获准；条目里出现某个 Skill 名称，也不代表本项目一定具备它。

advisor 和 `task-handoff-godot` 起草的续接提示词，都遵循项目的 [Continuation prompts](../../../project-source/methodology/09-artifact-lifecycle.md#continuation-prompts) 格式，不因任务简短而省略固定字段。等待人工验收、缺少决定、验证受阻，都要和“已完成”分开写。

职责设计的长期评价规则见[职责设计准则](../../maintenance/design-guidelines/README.md)，项目实际的任务路由见[方法总览](../../../project-source/methodology/00-overview.md)。
