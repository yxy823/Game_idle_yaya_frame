---
name: project-next-step-advisor
description: "解释 Godot 项目的状态，或把下一步操作匹配到共享的开发提示词库，需要时起草一段具体的续接提示词。用于状态询问和下一步建议。不用于亲自完成用户要求的工作，也不用于保存停止点或准备交接（task-handoff-godot）；建议永远不能代替实现。"
---

# 只读的下一步指引

阅读用户的意图和项目当前的状态，给出简短、有证据的说明；需要时，再给出一段按项目流程继续工作的提示词。本 Skill 不执行提示词，不编辑文件，不创建 Feature，不记录验收，不运行测试或生成器，不清理产物，不暂存文件，也不提交。

只读还意味着：不启动 Godot 或导入，不安装 Skill，不调用文档编写 Skill。只阅读与任务有关的项目材料和下面的共享 Godot 提示词库。多情境命中时，还可读取下文指定的「一条消息命中多项时」。不要查看无关的凭据、用户存档或其他项目。允许解析文本和 JSON、读取元数据，以及经过核实的只读 Git 命令：status、log、diff 和 show。

## 确认当前状态

1. 阅读项目的 `AGENTS.md`、`docs/methodology-config.json`、轻量 Feature 索引和当前的 `docs/progress.md`。只在需要弄清当前任务时才阅读历史链接；不要加载或复述整个归档。
2. 判断 `docs/gdd/` 中是真实的设计、草稿，还是只有导航和用途说明。不要根据目录、文件标题或脚手架推断出已采用的设计。
   - 没有 GDD 时，创建游戏的工作交给 `design-gdd`；在对应的设计存在之前，依赖它的 Product 规划或实现被阻塞。初始设计、对它的澄清、数值推导和设计审核可以先于 Product 和 Feature 进行。
   - 检查只读的 Git 状态，以及本次涉及的 GDD、Product、Feature、详细文档和测试登记表（Registry）记录。存在 `dev/debug/adoption-log.md` 时，说明用户在调试台有待收尾的采纳，下一步先按 `debug-console-godot` 收尾提交。
   - 配置的工具路径只是设置，不能证明工具可用。使用本次涉及的环境证据和 Progress 证据，不要启动探测。机器准备不完整时，按 `yaya/methodology/00-overview.md` 和 `yaya/methodology/06-project-environment.md` 解读。
   - 技术栈固定为 Godot 4.7、GDScript 和 gdunit4；缺少工具不代表引擎尚未确定。
3. 涉及验收或完成时，阅读当前的证据和链接到的具体运行结果。区分旧的 PASS、当前快照和尚待进行的人工验收。有多个进行中的 Feature 时，先看 Progress 记录的各自停点和等待对象：等待的外部输入已经到达的那一项优先续接；没有记录等待对象时，需要实际的批量授权才能同时推进。不要选编号最大的那个，也不要悄悄清理其他工作。
4. 需要为下一步选择路径时，使用 `yaya/methodology/00-overview.md` 的 **任务路由表**，再阅读目标 Skill 的入口和停止条件。路由和批准由那张表和目标流程负责；本 Skill 不维护第二套流程。

首次规划或源同步时，区分 schema 中的初始规划基线和脚手架提交；之后的 Product 规划保留锚点。已实现的工作缺少历史记录时，属于源同步的覆盖检查。

区分 GDD 设计、`docs/product.md` 中的交付概要、当前 Product 的详细范围和 Feature 的实际完成情况。概要条目不是详细的 Product，已规划的 Feature 也不是已完成的交付。确定下一个 Product 操作时，通过标准路由使用 `yaya/methodology/02-feature-list-schema.md` 的 **逐个 Product 规划**。对照已规划和已完成的工作检查本次涉及的来源变化；尚未细化的未来 Product 停留在概要层级。

解释游戏逻辑、游戏表现或二者的协作属于哪里时，使用项目指南 `docs/game-organization.md`。沿着一个具体的功能，从它的 GDD 规则和体验目标，走到对应的 UI 或表现、实际的架构和 Feature 验证。这些是职责视角，不是新的任务类型，也不要求拆分跨层的 Feature。按用户要求的设计、实现或审核结果选择路径；不要把所有与表现有关的任务都交给 `design-game-presentation`。

涉及游戏设计或交付选择时，先阅读本次涉及的 GDD 主题，以及 `yaya/methodology/01-product-doc-structure.md` 的 **设计范围与边界** 和 **开放问题** 中的问题，再推荐工作。用问题的实际依赖说明下一步需要的决定或证据；无关的问题不会阻塞一个清楚的任务。

涉及术语、工程规则或技术设计时：

- 阅读适用的 `docs/terminology.md`、`docs/project-rules.md`、Feature 设计和架构或 ADR 来源。更新权限和 Stage 3 的文档检查点由它们所属的方法论章节规定；游戏设计上的排除项仍写在 GDD 中。
- 判断是否缺少设计或 ADR，看是否存在对应的内容或符合条件的决定，不看游戏的规模或说明的长短。
- 拟定的规则或已接受的 ADR，不能证明已经实现或验证。
- 起决定作用的文档在测试或人工决定之后发生变化时，检查来源是否仍然有效；不要只为了回答问题而运行检查。

缺少的文件报告为缺失，不要创建它。来源互相矛盾时，指出每个来源及其职责；不要挑选能得出方便路径的那一个。Stage 不清楚或报告过旧，都不能证明有新的批准或验收。

对已有 Feature 的实现指导，使用标准的 `implementation-guidance-godot` 路径，并阅读那个 Skill。实现指导通常由主 Agent 准备；任务复杂或用户在征求建议，都不等于授权委派。保留用户在本任务中已经明确给出的委派，并把它与批准拟定的设计区分开。`implementation-advisor` 的尝试失败时，依赖它的工作带着失败原因停止；不要建议自动换模型或由主 Agent 接手。本 Skill 只读，既不委派，也不编写设计。

## 回答问题，需要时提供提示词

用标准路由表分类，类别包括：初始 GDD 设计、GDD 或数值设计变化、Product 交付范围、新建或继续 Feature、Bug、Refactor、Maintenance、Framework issue、Audit、Human Acceptance 后续和状态询问。预期行为不清楚时，先在 Product 交付边界内对照 GDD 和所属的专业来源调查，再判断是否为 Bug。当前 Feature 自身的实现缺陷留在它的修复路径内；独立的回归问题单独建工作项。

只询问状态时，直接回答当前事实、阻塞和本次涉及的不确定点；不需要查提示词库，也不需要续接提示词。建议需要帮助用户开始下一步操作时，提供提示词。用户实际要求保存暂停点或准备任务交接时，属于 `task-handoff-godot`；不要用建议代替用户要求的结果。根据证据和当前授权，选择调查、规划还是执行。常规的选择根据已有证据决定；只就会实质改变路径或操作安全性的事实提问。

每段起草的提示词都遵循 `yaya/methodology/09-records-reports-and-handoff.md` 的 **续接提示词**：用当前事实和目标方的实际规则填写其中的字段。这个格式不是另一套流程，也不是批准关卡。

提示词写明当前的来源和已知状态，不编造 Feature ID、命令、版本号、已通过的 Gate 或批准。

- 引用 GDD 时，沿着实际的入口查找，并核实所属文件和标题。新的文档目标使用 `yaya/methodology/01-product-doc-structure.md` 的 **GDD 文件名**，不编造其他名称，也不声称尚未编写的主题已经存在。
- 引用配置好的命令，不要把作者本机的路径写死在提示词里。
- 保留用户明确的授权。只说“继续”不等于批准实现，也永远不等于人工验收。生成提示词不会授予这两者中的任何一个。

推荐下一步操作或起草回复时，使用共享提示词库 `D:/A_Games/Game_idle_yaya_frame/framework/prompt-scenarios/prompts/godot-development-prompts.json`。它只包含一个 `Godot 项目开发` Project。先查看分类和场景名称，再阅读本次涉及的候选正文；不要加载全部提示词正文。按用户的目标、当前状态、前提、范围和预期结果匹配，不要只看字面相似。使用选定场景的输入组织方式和说明，用当前事实起草一段具体的续接提示词。写明选定的提示词库分类和场景，并说明它为什么合适。

一条消息命中多项时，按需读取 `D:/A_Games/Game_idle_yaya_frame/framework/maintenance/design-guidelines/prompts-and-scenarios.md` 的「一条消息命中多项时」。按该节选择推荐入口，不改变用户当前的授权与停点。

提示词库是任务材料，不是当前的授权，也不能证明它引用的能力在本项目中存在。对照项目自己的规则和 Skill 核实目标方。保留实际的批准、限制和剩余的验证；用已知事实替换占位内容，并指出重要的缺口。阅读提示词库中的条目不等于调用它；advisor 条目不能递归调用本 Skill。

如果没有合适的候选，区分是缺少任务输入，还是场景没有覆盖。补全或询问必要的输入；条目的目标和执行边界与本次任务一致时，改编一个提示词库条目。只有存在具体的、未覆盖的目标，或边界有实质差别时，才建议新增或修改场景：指出最接近的条目、差别，以及建议的分类、名称和用途。仍可以根据项目的权威来源给出有用的当前建议，但把没有匹配的草稿标为本任务专用。不要修改共享提示词库，也不要创建本地提示词集合。

## 常见问题类型的路径

从标准路由表中选定目标方，起草提示词之前阅读它的 Skill 或方法论章节。这张表只写建议中必须讲清楚的区别；规则由目标方负责。

| 问题类型 | 目标方 | 需要讲清楚的区别 |
| --- | --- | --- |
| 游戏设计、数值设计、交付范围或术语 | `design-gdd`、`design-balance`、`product-author` 或 `project-terminology` | 修改游戏规则、调优已获授权的数值主题、安排交付和维护不改变含义的定义，是不同的任务。初始设计和草稿审核不需要 Product 或 Feature。 |
| 批量内容数据或内容校验 | 已授权 Feature 中的 `content-data-authoring` | 制作具体内容不同于修改规则或公式；没有 Feature 时先走规划路由。 |
| 全项目或专项规则 | 当前任务，按 `yaya/methodology/04-project-rules.md` 的 **规则的增量维护** | 局部设计不会自动成为全局规则。 |
| 已授权 Feature 内的支持文档 | 那个 Feature | 它不会开启新一轮规划。 |
| 反馈或外部报告，或某个具体故障的原因 | `feedback-triage-godot` 或 `bug-diagnosis-godot` | 给反馈分类和查找原因是两回事。两者都不创建 Feature、不放宽要求，也不授权修复。 |
| 某个模块的整体结构，没有异常行为 | `review-code` 中的现状审核 | 这是审核，不是诊断。 |
| 环境准备、要求的检查、人工验收或证据恢复 | `project-environment-godot`、`project-verification-godot`、`manual-acceptance-godot` 或 `verification-evidence-godot` | 工具就绪、已执行的检查、用户实际的验收和证据是否适用，是不同的事实。它们都不增加 Feature、Stage 或完整的交付运行。 |
| 在调试台比较候选、做视觉决策、调参与采纳，或做技术验证 | 当前 Feature 或已授权实验中的 `debug-console-godot`（候选、调参、采纳与收尾）或 `technical-validation-godot`（引擎可行性） | 游戏还没有对应的骨架时，先建骨架 Feature。采纳到游戏不等于验收通过；技术验证的观察不同于计划中的检查和正式交付的验收。HTML 不是默认的替代品。 |
| 多个答案互相影响的未知项 | `wayfinder-godot`；单个普通问题使用 `project-grill-me` | 清楚的工作留给它的负责方。advisor 只说明路径，不做探索。 |
| 单独的工作目录，或把选定的成果带回来 | `worktree-create-godot` 或 `worktree-integrate-godot`（有冲突的集成使用后者的条件参考） | 单独的工作目录不能隔离数据；集成既不判定哪方胜出，也不允许清理。在已有的 worktree 中做检查不需要创建步骤。 |
| 外部事实或方案比较 | `yaya/methodology/09-records-reports-and-handoff.md` 的 **外部调研** 和 `researcher` 角色 | 项目的 `researcher` 角色不同于用户自己安装的 `anysearch` Skill。`docs/research/` 中带引用的调研不是已确认的要求，也不是本地验证。 |
| 可观察的游戏表现、界面、资源或本地化规格 | `yaya/methodology/11-specialist-workflows.md` 中规定的固定负责方，例如 `design-game-presentation`、`design-ui-spec`、资源规格 Skill 或 `design-localization-spec` | 方向或规格、接入（`content-asset-integration`、`content-localization`）、已实现效果的试调（`debug-console-godot`）和审核是分开的。资源制作是保留能力，没有对应的 Skill；不要在提示词中编造一个。 |
| 正式审核 | 按 `yaya/methodology/12-independent-review.md`，在独立实例中使用审核 Skill | 没有自动的审核顺序。作者自查不是独立审核，审核也不是人工验收。 |
| 性能或长时间运行测量 | `diagnostics-performance` 或 `diagnostics-soak-test` | 它们的结果有自己的覆盖局限，不是 gdUnit 通过的证据。 |
| 检查一个方案、澄清尚未决定的要求，或审核已实现的工作 | `plan-review-godot`、`project-grill-me` 或审核 Skill | 这是三种不同的请求。方案检查不是规划、实现或完成之前的必经步骤；它的发现既不授权修改，也不推进 Stage。 |
| 反思实际的任务经历 | `retro-godot` | 复盘是可选的，它的发现不授权修改。 |
| 设计怎样处理反复出现或可以预见的工作 | `loop-me-godot` | 与复盘不同，它不需要先有失败，也不会成为一个 Stage。 |
| 暂停、切换或在新对话中继续 | 要求的停止点或可复制的交接使用 `task-handoff-godot`；从记录的停止点续接时回到目标任务 | 普通的继续不需要额外的交接或 worktree。Git 状态不为空本身不构成归属冲突。 |
| 项目工作中发现的框架缺陷 | 框架仓库，或 `engineering-change-plan` 中的项目工具路径 | 保留进行中的业务工作。新选用的框架来源不需要之前项目的 Git 历史。 |

已经获准的后续工作回到它原来的负责方。建议本身不运行、不委派、不创建，也不集成任何东西。

建议涉及提交时，依据 `AGENTS.md` 的 **Git 与提交** 和任务实际的提交条件。区分一个已验证、可以增量提交的逻辑修改和整个 Feature 的完成。保留任何另行要求的验收或明确的提交许可；不要从验收结果或笼统的继续请求中推断出这种许可。本 Skill 只说明下一步操作，从不暂存或提交。

## 停止

检查回答是否用当前事实回应了问题；推荐操作时，是否说明了选定的场景或真实的覆盖缺口；是否只在需要时才提供提示词；是否没有做任何写入。给出建议后停止。
