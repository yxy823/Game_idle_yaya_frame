# 框架维护约定

本机环境与审批遵循当前生效的个人规则；文本格式以 [.editorconfig](.editorconfig)、[.gitattributes](.gitattributes) 为准。

## 核心决策原则

| 原则 | 必须执行的要求 |
| --- | --- |
| 目标驱动 | 先从用户要完成的事情识别关键决策和交付物，再检查现有能力覆盖，最后决定复用、补充或新增。 |
| 背景与场景核对 | 讨论新增能力或文档之前，先说明与本次决策有关的现有背景、已有职责、新增位置和上下游关系，再讨论内部细节。收束时还应拿具体使用场景走一遍，检查用户能否从需求找到设计、从设计找到实现与验收。 |
| 唯一正文与集中维护 | 同一作用域内的同一事实、规则或决定，只在职责所属位置维护一份权威正文；其他位置引用，并按需保留简短提醒。新增或调整文档职责时，按[文档职责与固定归属](framework/maintenance/design-guidelines/document-responsibilities.md#文档职责与固定归属)确定内容对应的固定路径或命名模式，区分按需创建与存放位置。新增或拆分前先核对已有归属，优先复用；确需迁移时同步引用并移除旧正文，不留下并行维护副本。 |
| 按职责组织，权衡拆合成本 | 围绕共同目标、变化原因和使用场景组织内容与能力。需要共同理解、修改或完成的部分优先集中；职责或使用条件可以独立，且拆分能减少无关阅读、依赖或维护牵连时，再分开。综合考虑查找、跳转、交接和维护成本，不以文件长短、数量或步骤多少单独决定拆合。具体判断沿用[职责设计准则](framework/maintenance/design-guidelines/README.md)。 |
| 奥卡姆剃刀 | 先比较复用、合并、删除与局部修正；普通文件、现有命令或 Agent 判断已经足够时，不增加脚本、依赖或流程层。 |
| 第一性原理 | 从当前需求、真实问题和已知约束推导方案，重新判断既有机制是否必要；不把现有实现或历史投入当作必须保留的理由。 |
| 最小完整修改 | 在本次授权范围内选择能完整解决问题的最小方案，保留必要能力与约束；不以最少行数或最少文件数为目标，也不借修复扩大任务。 |

不以脚本监督 Agent 的每个动作；不得为此增加 Agent 动作 Hook、重复状态、来源哈希清单、收据、评分或发布资格。保留针对实际成果的必要验证。

只面向已确定的 Godot 技术栈，不为其他引擎、平台或旧项目预留兼容机制，也不做向后兼容。

框架面向单人项目，由一位项目使用者与 Agent 配合开发。不将多人协作、改动归属处理纳入框架设计与手册场景范围，不为这些需求扩展流程、工具或配置。同一项目目录内的任务暂停、切换和新对话续接仍属于支持范围；worktree 的使用由当前任务范围与授权决定，不因普通暂停或换对话默认创建。按需调研和独立审核 Agent 沿用现有约定。

## 沟通与交付

遵循 [通用沟通与交付要求](project-source/Project_AGENTS.md#沟通与交付)。本仓库与生成项目共用该节正文，只在源模板中维护。

## 使用说明的可读性

编写或整理框架技术文档时，使用本仓库的 [Yaya 框架文档编写 Skill](.agents/skills/technical-documentation-writing-yaya/SKILL.md)，按当前文档类型读取其中的参考。框架手册的专有分工见 [说明的组织与措辞](framework/maintenance/maintenance-and-sync.md#说明的组织与措辞)。

框架版与分发给项目的 [Godot 项目文档编写 Skill](project-source/skills/technical-documentation-writing-godot/SKILL.md) 各自独立维护、不跨包引用，分工见[两份写作 Skill 的分工](framework/maintenance/maintenance-and-sync.md#两份写作-skill-的分工)。

框架及生成项目共用的术语写法维护在 [框架术语](framework/terminology.md)；游戏自身的业务词汇由生成项目的 `docs/terminology.md` 维护，不把两者混为同一份词表。

## 维护边界与查阅

| 当前工作 | 执行依据 |
| --- | --- |
| 框架维护 | `framework/` 保存维护材料，框架自用 Skill 在 `.agents/skills/`，未完成事项见 [框架待办](framework/progress.md)；`project-source/` 保存常规分发材料，其中的项目开发流程仅作为源材料阅读，不在维护仓库启用。 |
| 创建项目 | [创建器](framework/project-creation/tools/create_project.py) 按 [复制清单](framework/project-creation/project-files.json) 复制和重命名，然后建立独立 Git 仓库与本地初始提交；不附带环境探测、Bootstrap、测试、远程推送、来源记录或升级。 |
| 生成项目 | 项目独立拥有其文件，不接受自动同步；维护手册与提示词库不进入生成项目，项目 README 保持简短的自身使用导航。 |
| 修改空白项目 | 先读 [框架入口](framework/README.md)，再按 [维护与同步说明](framework/maintenance/maintenance-and-sync.md) 查阅受影响专题、核对源材料并同步说明。 |
| 使用手册 | Godot 项目手册解释生成项目的概念、文档对象、配置与工具，具体场景归同名提示词对应的速查页；两册只维护 Markdown，不互相引用，由框架入口导航。 |
| 审核及后续讨论 | 外部报告先核对当前文件和版本，分别判断问题与改法；用户明确选择实施范围后才修改。 |
| 选择验证 | 只要求静态审查时，不生成项目、启动 Godot 或运行测试；实际项目验证在明确指定的外部项目执行。具体范围见 [验证说明](framework/maintenance/validation/validation-scope.md#按修改选择验证范围)，确切命令见 [按需检查](framework/tests/README.md#按需检查)。 |

维护 `project-source/` 中的 Godot 代码、场景、资源或测试时，按 [领域规则路由](project-source/Project_AGENTS.md#engineering-rule-routing) 核对适用工程语义；任务授权、Git、验证范围与地点及交付仍以本维护仓库规则为准。

修改代码或工具前，按共用的[变更准备与范围约定](project-source/agent-rules/00-core/change-scope-and-ownership.md)确认实际实现、影响范围与简短方案；验证和交付沿用本仓库约定，不因此启用生成项目的 Stage。

框架维护任务开始或续接时，按当前主题核对 [framework/progress.md](framework/progress.md)。只保留仍需推进的工作、真实验证缺口、阻塞与必要待决定项，写明下一步和必要依据；条目不授予实施权限。完成并通过必要验证的事项立即删除；尚有必要人工验收时仅保留具体待验收项。历史由 Git 保存，不保留完成记录、成果汇总或长期搁置的设想；无待办时清空文件。相关状态发生实质变化时，在本次允许写入的范围内及时更新，提交或交接前核对一致；只读任务在回复中指出需更新项，无实质变化不制造更新。

## 文件命名与修改

自主命名的文件必须能直接看出用途，并包含必要的所属领域与具体职责，例如 `test-registry.json` 明确表达测试登记表。工具要求的约定文件名和第三方原始名称按各自契约保留。

临时文档统一保存在仓库根目录的 `tmp/`，可按任务、主题建立子目录；草稿、当次方案、审核报告和交接材料不得混入正式文档目录。长期有效的结论整理到职责所属正文后，删除不再需要的临时文档。框架报告的使用与清理见[当次报告的保存与清理](framework/maintenance/design-guidelines/reviews-and-reports.md#当次报告的保存与清理)。

### 修改时的联动检查

- **职责评价**：新增、实质调整职责或审核 Skill、脚本、提示词与场景时，按[职责设计准则](framework/maintenance/design-guidelines/README.md)评价对应对象；普通局部修改不触发无关全量审核。
- **行为不变**：整理文档或文件名不得顺带改变 Skill 行为。
- **路径与字段**：调整文件路径或配置字段时，追到全部读写方及其调用链、复制映射与回归夹具，核对生成后的路径和语义一致，不留下仅部分工具支持的选项。
- **文档系统图**：文档职责、路径、产物归属或实际引用关系变化时，使用 [提示词与关系图维护 Skill](.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md) 同步对应节点与关系；普通正文措辞变化不触发全图维护。全仓文档覆盖扫描只在用户明确要求时运行。
- **advisor**：修改框架任务路由、Stage、职责边界、产物归属或授权与完成机制时，同步检查 `project-source/skills/project-next-step-advisor/SKILL.md` 与相关 Godot 提示词及同名场景；仍适用的内容不制造修改，不在 advisor 中复制另一套流程。
- **外部项目回归**：运行前核对被测文件是否对应本次修复；需要同步时只更新授权范围内的具体文件，保留目标项目的机器配置与无关内容。
- **如实记录**：分别记录静态核对、工具回归、真实引擎运行与人工验收的实际结果；失败、未执行和旧版本通过记录不能写成当前修改已通过。

### 目录与入口组织

维护侧（根目录、`.agents/`、`framework/`）的目录由 [框架入口](framework/README.md#目录与职责) 统一说明。新增、移动、拆分或合并文件前，先按下列约束确定位置，并同步该表：

- **按对象划分顶层**：`framework/` 的顶层目录按材料讲述的对象划分（生成的 Godot 项目、提示词与场景、关系图、框架维护、项目创建、测试），不设 `docs/` 这类只按文件类型归堆的目录。
- **按功能建子目录**：同一目录内的文件功能不同时，按功能建立子目录分类，即使目前只有一两个文件；功能相同的文件放在一起。子目录名直接表达功能，例如 `design-guidelines/`、`validation/`、`dependencies/`、`tools/`。
- **脚本放在 `tools/`**：脚本放在所属对象目录下的 `tools/`，不与数据或文档平铺，参数、退出码和运行方式写在同目录 README；没有单一对象的全仓检查放在 `framework/maintenance/tools/`。`framework/README.md` 的「维护命令」只做索引，其他文档说明何时运行并链接到对应 README。回归测试放在 `framework/tests/repository/`，外部项目夹具的放置与运行写在 `framework/tests/external-project/` 各子目录 README。
- **一处目录说明**：根 README 只画顶层与 `project-source/`，`framework/README.md` 维护 `framework/` 的唯一目录表；其他 README 只说明自身内容，不重画上层目录树或别处的目录。
- **按职责落位**：新内容先并入职责、读者和变化原因相同的现有页面；确能独立时才新建。不保留只做跳转或只剩一两段的薄页面。
- **不登记分发清单**：维护文档按目录或命名模式指向 `project-source/`，不逐个列出分发的 Skill、模板或工具；它们的职责以分发材料自身为准。
- **命名一致**：维护侧自主命名的目录和文档文件使用小写英文加连字符，Python、GDScript 等代码文件按语言约定使用下划线；场景目录与文件按提示词库的准确名称保留中文。
- **正式文档只写现状**：带日期的验证过程、审核记录与迁移说明放在 `tmp/`、外部项目报告或提交说明；正式文档只保留当前结论、未解决问题和核对方法。

## AGENTS.md、Skill 与任务提示词编写

维护本框架的 AGENTS.md、Skill、任务提示词和条件引用规则时，按[规则与提示词文件维护约定](framework/maintenance/design-guidelines/instruction-files.md)核对实际变化并自查；内容归属、触发、按需阅读、流程粒度、授权与完成、阻塞说明等编写要求都在该节。用户要求独立审核时，按[正式审核的独立性](framework/maintenance/design-guidelines/reviews-and-reports.md#正式审核的独立性)执行。

## 提示词维护

新增、修改、重命名、调整分类或删除集中提示词时，使用框架自用的 [prompt-and-graph-maintenance-yaya](.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md)，按本次变化核对同名场景、导航、开发场景图与 advisor 引用。两份提示词库的结构、一对一场景和命名规则见[提示词与场景准则](framework/maintenance/design-guidelines/prompts-and-scenarios.md)；提示词正文不混入 README、规则或工具说明。

advisor 通过固定绝对路径 `D:/A_Games/Game_idle_yaya_frame/framework/prompt-scenarios/prompts/godot-development-prompts.json` 只读使用 Godot 提示词库。移动或改名该文件时，同步 `project-source/skills/project-next-step-advisor/SKILL.md`；已创建的项目由用户决定是否更新。

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
