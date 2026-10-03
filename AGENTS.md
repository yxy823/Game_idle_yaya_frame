# 框架维护约定

本机环境与审批遵循当前生效的个人规则；文本格式以 [.editorconfig](.editorconfig)、[.gitattributes](.gitattributes) 为准。

## 核心决策原则

| 原则 | 必须执行的要求 |
| --- | --- |
| 目标驱动 | 先从用户要完成的事情识别关键决策和交付物，再检查现有能力覆盖，最后决定复用、补充或新增。 |
| 背景与场景核对 | 讨论新增能力或文档之前，先说明与本次决策有关的现有背景、已有职责、新增位置和上下游关系，再讨论内部细节。收束时还应拿具体使用场景走一遍，检查用户能否从需求找到设计、从设计找到实现与验收。 |
| 唯一正文与集中维护 | 同一作用域内的同一事实、规则或决定，只在职责所属位置维护一份权威正文；其他位置引用，并按需保留简短提醒。新增或调整文档职责时，按[文档职责与固定归属](framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#文档职责与固定归属)确定内容对应的固定路径或命名模式，区分按需创建与存放位置。新增或拆分前先核对已有归属，优先复用；确需迁移时同步引用并移除旧正文，不留下并行维护副本。 |
| 按职责组织，权衡拆合成本 | 围绕共同目标、变化原因和使用场景组织内容与能力。需要共同理解、修改或完成的部分优先集中；职责或使用条件可以独立，且拆分能减少无关阅读、依赖或维护牵连时，再分开。综合考虑查找、跳转、交接和维护成本，不以文件长短、数量或步骤多少单独决定拆合。具体判断沿用[职责设计准则](framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md)。 |
| 奥卡姆剃刀 | 先比较复用、合并、删除与局部修正；普通文件、现有命令或 Agent 判断已经足够时，不增加脚本、依赖或流程层。 |
| 第一性原理 | 从当前需求、真实问题和已知约束推导方案，重新判断既有机制是否必要；不把现有实现或历史投入当作必须保留的理由。 |
| 最小完整修改 | 在本次授权范围内选择能完整解决问题的最小方案，保留必要能力与约束；不以最少行数或最少文件数为目标，也不借修复扩大任务。 |

不以脚本监督 Agent 的每个动作；不得为此增加 Agent 动作 Hook、重复状态、来源哈希清单、收据、评分或发布资格。保留针对实际成果的必要验证。

只面向已确定的 Godot 技术栈，不为其他引擎、平台或旧项目预留兼容机制，也不做向后兼容。

框架面向单人项目，由一位项目使用者与 Agent 配合开发。不将多人协作、改动归属处理纳入框架设计与手册场景范围，不为这些需求扩展流程、工具或配置。同一项目目录内的任务暂停、切换和新对话续接仍属于支持范围；worktree 的使用由当前任务范围与授权决定，不因普通暂停或换对话默认创建。按需调研和独立审核 Agent 沿用现有约定。

## 沟通与交付

遵循 [通用沟通与交付要求](project-source/Project_AGENTS.md#沟通与交付)。本仓库与生成项目共用该节正文，只在源模板中维护。

## 使用说明的可读性

编写或整理框架技术文档时，使用本仓库的 [Yaya 框架文档编写 Skill](.agents/skills/technical-documentation-writing-yaya/SKILL.md)，按当前文档类型读取其中的参考。框架手册的专有分工见 [说明的组织与措辞](framework/docs/framework-maintenance/updating-the-blank-project.md#说明的组织与措辞)。

框架版在上述目录独立维护；[Godot 项目文档编写 Skill](project-source/skills/technical-documentation-writing-godot/SKILL.md) 在项目分发源中独立维护，创建器随项目 Skill 目录整包复制，由[项目写作入口](project-source/Project_AGENTS.md#使用说明的可读性)引用。两份 Skill 各自拥有入口、元数据和参考，可独立修改，不跨包引用写作正文。框架版不分发；生成项目拥有自己的 Godot 版副本，不查询框架或接受自动同步。已有项目的更新由用户决定。

框架及生成项目共用的术语写法维护在 [框架术语](framework/docs/terminology.md)；游戏自身的业务词汇由生成项目的 `docs/terminology.md` 维护，不把两者混为同一份词表。

## 维护边界与查阅

| 当前工作 | 执行依据 |
| --- | --- |
| 框架维护 | `framework/` 保存维护材料，框架自用 Skill 在 `.agents/skills/`，未完成事项见 [框架待办](framework/progress.md)；`project-source/` 保存常规分发材料，其中的项目开发流程仅作为源材料阅读，不在维护仓库启用。 |
| 创建项目 | [创建器](framework/commands/create_project.py) 按 [复制清单](framework/commands/project-files.json) 复制和重命名，然后建立独立 Git 仓库与本地初始提交；不附带环境探测、Bootstrap、测试、远程推送、来源记录或升级。 |
| 生成项目 | 项目独立拥有其文件，不接受自动同步；维护手册与提示词库不进入生成项目。advisor 通过固定绝对路径只读引用本机 Godot 开发提示词库，项目 README 保持简短的自身使用导航。 |
| 修改空白项目 | 先读 [使用手册](framework/docs/README.md)，再按 [维护与同步说明](framework/docs/framework-maintenance/updating-the-blank-project.md) 查阅受影响专题、核对源材料并同步说明。 |
| 使用手册 | 操作手册维护框架、概念、配置与工具，具体场景归同名提示词对应的速查页；两册只维护 Markdown，不互相引用，由文档总入口导航。 |
| 审核及后续讨论 | 外部报告先核对当前文件和版本，分别判断问题与改法；用户明确选择实施范围后才修改。 |
| 选择验证 | 只要求静态审查时，不生成项目、启动 Godot 或运行测试；实际项目验证在明确指定的外部项目执行。具体范围见 [验证说明](framework/docs/framework-maintenance/updating-the-blank-project.md#按修改选择验证范围)，确切命令见 [按需检查](framework/README.md#按需检查)。 |

维护 `project-source/` 中的 Godot 代码、场景、资源或测试时，按 [领域规则路由](project-source/Project_AGENTS.md#engineering-rule-routing) 核对适用工程语义；任务授权、Git、验证范围与地点及交付仍以本维护仓库规则为准。

修改代码或工具前，按共用的[变更准备与范围约定](project-source/agent-rules/00-core/change-scope-and-ownership.md)确认实际实现、影响范围与简短方案；验证和交付沿用本仓库约定，不因此启用生成项目的 Stage。

框架维护任务开始或续接时，按当前主题核对 [framework/progress.md](framework/progress.md)。只保留仍需推进的工作、真实验证缺口、阻塞与必要待决定项，写明下一步和必要依据；条目不授予实施权限。完成并通过必要验证的事项立即删除；尚有必要人工验收时仅保留具体待验收项。历史由 Git 保存，不保留完成记录、成果汇总或长期搁置的设想；无待办时清空文件。相关状态发生实质变化时，在本次允许写入的范围内及时更新，提交或交接前核对一致；只读任务在回复中指出需更新项，无实质变化不制造更新。

## 文件命名与修改

自主命名的文件必须能直接看出用途，并包含必要的所属领域与具体职责，例如 `test-registry.json` 明确表达测试登记表。工具要求的约定文件名和第三方原始名称按各自契约保留。

临时文档统一保存在仓库根目录的 `tmp/`，可按任务、主题建立子目录；草稿、当次方案、审核报告和交接材料不得混入正式文档目录。长期有效的结论整理到职责所属正文后，删除不再需要的临时文档。框架报告的使用与清理见[复盘材料说明](framework/docs/framework-maintenance/review-materials.md)。

新增、实质调整职责或审核 Skill、脚本、提示词与场景时，按[职责设计准则](framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md)评价对应对象；普通局部修改不触发无关全量审核。长期准则与当次审核报告分开维护。

整理文档或文件名不得顺带改变 Skill 行为。

调整文件路径或配置字段时，追到全部读写方及其调用链、复制映射与回归夹具，核对生成后的路径和语义一致，不留下仅部分工具支持的选项。

文档职责、路径、产物归属或实际引用关系变化时，使用 [提示词与关系图维护 Skill](.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md) 同步文档系统图中的对应节点与关系；普通正文措辞变化不触发全图维护。全仓文档覆盖扫描只在用户明确要求检查时运行。

修改框架任务路由、Stage、职责边界、产物归属或授权与完成机制时，同步检查 `project-source/skills/project-next-step-advisor/SKILL.md` 与相关 Godot 开发提示词及同名场景。使建议和来源引用与当前权威规范一致；仍适用的内容无需制造修改，不在 advisor 中复制另一套流程。

在已指定的外部项目运行回归前，核对被测文件是否对应本次修复；需要同步时仅更新授权范围内的具体文件，保留目标项目的机器配置与无关内容。

分别记录静态核对、工具回归、真实引擎运行与人工验收的实际结果；失败、未执行和旧版本通过记录不能写成当前修改已通过。

## AGENTS.md、Skill 与任务提示词编写

维护本框架的 AGENTS.md、Skill、任务提示词和条件引用规则时，按[规则与提示词文件维护约定](framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#规则与提示词文件维护)核对实际变化并自查。用户要求独立审核时，按[正式审核的独立性](framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#能力划分与正式审核)执行。

维护上述规则和提示词文件时，按 [OpenAI 的 Astra 指令设计建议](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra) 与本仓库已确认边界执行以下约束。

| 关注点 | 编写要求 |
| --- | --- |
| 内容归属与去重 | AGENTS.md 只保留代码和配置无法推断的约束，任务提示词补充本次目标、输入与特有约束；流程与测试规则以权威规范为唯一正文。已有 README 或工具配置负责的内容不重复展开，同义规则合并。 |
| Skill 触发 | description 简短说明职责和具体适用任务，必要时注明易混淆的排除项；不堆砌关键词或用宽泛领域强制触发无关 Skill。 |
| 按需阅读 | 引用资料时写明适用任务或条件，同一能力的条件分支按需引用；复用仍有效的上下文，不把固定文档组、通读目录或全仓地图设为每轮任务的前置。 |
| 流程粒度 | 写清必要依赖，保留 Agent 对普通实现细节的判断；不照搬旧模型的逐动作配方，不设置无依据的提问轮数、产物数量或逐阶段发言要求。 |
| 授权与完成 | 按本次授权定义完成标准，覆盖适用的实现、必要验证与交付；已有具体授权按 [会话延续约定](framework/docs/framework-maintenance/updating-the-blank-project.md#后续用口语继续) 跨 Skill、阶段和后续口语请求沿用。Skill 返回或局部步骤完成不结束已授权工作；授权范围完成、必要前置受阻、缺少决定、范围实质变化或用户要求暂停时停止，实现授权不替代实际人工验收。 |
| 阻塞可解释 | 指令确实导致暂停或改变方向时，指出具体文件、条款与当前缺口；先核对适用范围和已有授权，不因推测的风险追加确认。 |

紧密相关的几个短语可以保留在一句中；需要分别查阅的并列事项按主题使用无序列表，有真实分类时再增加一层。具体排版遵循上述通用可读性要求，不为压缩行数堆叠信息。模型或工作方式变化后，按真实误触发、冲突、等待和重复工作检查相关指令，不因个别现象叠加普遍规则。

## 提示词维护

新增、修改、重命名、调整分类或删除集中提示词时，使用框架自用的 [prompt-and-graph-maintenance-yaya](.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md)，按本次变化核对同名场景、导航、项目场景图与 advisor 引用。用户要求正式审核时，按[审核覆盖与结论](framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#审核覆盖与结论)交付。详细规范继续由条件引用的材料维护，这些框架入口不随 Godot 项目分发。

任务提示词按用途分别维护在 [Godot 开发提示词库](framework/prompt_scenarios/prompts/godot-development-prompts.json)与 [Yaya 框架维护提示词库](framework/prompt_scenarios/prompts/yaya-maintenance-prompts.json)，不把提示词正文混入 README、规则或工具说明。advisor 直接读取 `D:/A_Games/Game_idle_yaya_frame/framework/prompt_scenarios/prompts/godot-development-prompts.json`，结合项目事实选择场景、起草具体指令，并判断真实的场景覆盖缺口；提示词不授予当前任务权限，advisor 不修改共享库。

两份 JSON 各自保留仅含所属 Project 的顶层数组：`yaya-maintenance-prompts.json` 对应 `Yaya 框架维护`，`godot-development-prompts.json` 对应 `Godot 项目开发`。保留 `project`、`categories` 结构，按用途放入对应分类。

提示词与具体场景一对一，名称和目录对应遵循[提示词与场景准则](framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#提示词与场景)。新增前核对已有用途，只合并目标与执行边界相同的重复入口，不用一条通用提示词覆盖不同场景。运行验证与提交要求引用所属仓库约定，不在模板中无意覆盖默认行为；任务特有的只读、只验证或不提交例外应限定作用范围。修改后核对[场景索引](framework/prompt_scenarios/scenarios/scenario-index.md)与受影响的使用说明，只同步实际变化，不维护第二份场景清单。

## 本地提交

凡会修改文件的获准任务，按可验证的逻辑成果自动创建本地提交，无需再次询问；用户明确要求不提交或规定提交条件时，按其具体范围执行。

- 开始修改时查看 Git 状态和相关差异，保留无关内容及其暂存状态；同一任务续接的改动可以沿用、完成并提交。
- 按完整逻辑成果组织提交，带上必要实现、测试、引用和说明；不按文件数或“代码、测试、文档”机械分批。
- 发现未完成的合并、变基等状态，或 HEAD、分支出现当前操作无法解释的变化时，保留现场并报告，先核对再继续依赖该状态的写入和提交。
- 只暂存本项明确路径或差异块，不混入无关改动；无法分离已有暂存内容时，说明冲突并保留现场。
- 验证按任务的实际改动与必要范围执行，复用仍有效的结果。提交不另设审核关卡，不要求每次重读完整暂存差异或重跑已通过的检查；发现新的改动、失败或证据失效时才补充核对。
- 主题采用 `<type>(<scope>): <中文摘要>`，说明实际行为变化；非简单修改在正文说明原因、关键取舍与真实验证结果。
- 交付时说明本次提交、实际验证和仍未提交的本任务修改。提交后发现问题时新建修正提交，不改写历史；本地提交不代替任务完成或实际人工验收。
- 不使用 `--no-verify`，不自动 push、tag、amend、rebase、reset、切换分支或修改远程配置，不用 stash 或 clean 整理提交。非仓库、权限、身份、签名或钩子等阻止提交时，保留修改并报告，不为补救提交擅自 init 或改配置；用户明确要求创建项目时，创建器仍按其契约初始化新仓库。
