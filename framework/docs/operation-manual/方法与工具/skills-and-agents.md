# Skill、Agent 与提示词

[操作手册](../README.md)

Skill 保存可复用方法，Agent 是执行方法的实例，提示词表达本次具体任务。三者不具有相同粒度：每条正式提示词只对应一个具体场景，通用 Skill 与脚本则按职责和独立变化原因划界，不能为了每篇场景复制一套实现。

[游戏逻辑与表现](../框架基础/game-logic-and-presentation.md)用于理解功能范围，Skill 仍按当前工作选择：规则与体验目标由设计入口处理，一次表现由 `design-game-presentation` 细化，获准开发由原 Feature 承接。跨层功能可以由同一任务完成，不要求分别委派逻辑和表现 Agent；环境、测试与构建方法作为共同工程支持使用。

工程规则、可复用方法和当前游戏方案各自承担不同职责。以 Shader 为例：

| 内容 | 保存位置与用途 |
| --- | --- |
| 工程约束 | [Shader 规则](../../../../project-source/agent-rules/30-shaders/README.md)维护语言、坐标、材质参数和真实验证等适用要求，按既有 MUST、PREFER、REVIEW 区分强度 |
| 可复用方法 | [实现方法参考](../../../../project-source/skills/implementation-guidance-godot/references/shader-implementation-methods.md)帮助推导数据流与算法选择；[诊断参考](../../../../project-source/skills/bug-diagnosis-godot/references/shader-diagnostics.md)帮助选择能辨别原因的检查，按当前问题读取 |
| 当前游戏方案与证据 | 表现目标和采用方案保存在所属游戏表现文档；已有 Feature 需要详细工程设计时使用其设计稿，原型、诊断与验证证据沿用原任务记录，具体归属见[知识、设计与记录](../专业工作与记录/knowledge-and-records.md) |

Shader 规则入口同时导航这些可选方法。正式实现、限定原型或排错任务都可以直接阅读相关参考；文件位于某个 Skill 的 `references/` 中，不表示需要启动该 Skill 的完整流程、创建 Feature 或委派顾问。方法不改变当前任务的授权与完成条件，具体效果数值也不因此成为通用规则。

## Skill 职责速查

以下名称对应生成项目 `.agents/skills/<名称>/SKILL.md`。当前源文件是 [skills 目录](../../../../project-source/skills)，具体触发和排除项以各自 description 与正文为准。

`design-gdd` 可以在项目内从想法形成 GDD；设计讨论、数值建模和 GDD 草稿审核不要求先有完整 Product 或 Feature。依赖设计的规划与实现仍须先核对当前范围的真实规则，缺失时只停止依赖部分并明确设计缺口，详见 [GDD 前提](../../../../project-source/methodology/01-product-doc-structure.md#gdd-prerequisite-and-authority)。

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

前缀帮助识别职责，不代表必须按 design → content → diagnostics → review 全部执行。只读调查、规格编写与实现有不同授权；纯术语已经明确时直接交 `project-terminology`，不重复开启需求访谈。本地化规格也不再由运行接入 Skill 兼管。

普通澄清由 `project-grill-me` 负责，GDD 设计由 [design-gdd](../../../../project-source/skills/design-gdd/SKILL.md) 处理，Product 问题由 `product-spec-elicitor` 使用共用提问方法，Feature 拆分由 `feature-plan` 负责。现有草稿、完整 GDD 或方案需要检验时才使用 [plan-review-godot](../../../../project-source/skills/plan-review-godot/SKILL.md)，按 GDD 阶段与范围读取其领域参考，不因尚无 Product 或 Feature 拒绝审核；正式独立审核仍须非作者实例。开发经验复盘使用 [retro-godot](../../../../project-source/skills/retro-godot/SKILL.md)。这些结论交回原有负责人，不增加必经关卡，也不替代人工验收。

[design-balance](../../../../project-source/skills/design-balance/SKILL.md) 从已知目标与规则推导数值方案，也可以针对既有模型调整参数；它在写入授权内直接维护所属 GDD 数值正文，不要求另一 Skill 代为保存。参数采用、文件写入和验证状态分别记录，新增玩法或体验目标变化回到 `design-gdd`。检查现有模型、策略组合和已采用数值是否成立，使用 `review-balance` 独立审核；设计者的计算自查不能称为独立审核。普通尺寸或数量记录不自动触发专项建模。

收到反馈、尚不清楚是否要改时，使用 [feedback-triage-godot](../../../../project-source/skills/feedback-triage-godot/SKILL.md) 核对类别与归属；已经有具体异常、需要查原因时，使用 [bug-diagnosis-godot](../../../../project-source/skills/bug-diagnosis-godot/SKILL.md)。用户描述实际症状即可，Agent 随证据追查逻辑、表现及其连接，不要求用户先选层，也不因跨层自动拆成多个 Bug。它们不新增工单状态，也不改变交付前后 Bug 的归属。只调查就交付证据与结论；已有具体修复授权则返回原任务继续，不因方法结束重新索取同一批准。

环境准备、限定检查、人工验收和证据处理这四个入口可以在不同工作环节按需调用，也可以承接直接提出的限定任务，不是新增的固定阶段。例如，只要求跑现有测试时，有无 Feature 都按该检查的实际范围执行；登记人工验收时，则必须对应实际 Feature 与用户结果。工具可用、检查通过、用户接受和证据仍适用是不同事实，不能相互替代，也不因调用其中一个入口就扩展为整套交付。具体选择由[任务路由](../../../../project-source/methodology/00-overview.md#canonical-task-routing)统一维护，各 Skill 按需引用原有配置、测试、验收与证据规范，不复制第二套正文。

[prototype-godot](../../../../project-source/skills/prototype-godot/SKILL.md) 用可运行的 Godot 场景或逻辑实验回答本次问题，保持实际运行、原型观察与生产验收的区别。[task-handoff-godot](../../../../project-source/skills/task-handoff-godot/SKILL.md) 使用既有 Progress、Feature 或任务记录：只要求暂停时保存停点，需要换对话时再提供可复制文本；不自动创建对话、发送消息或另建交接台账。恢复已有停点直接回到原任务，不必再调用一次交接。

这些入口便于明确调用，description 也帮助按任务选择；文件存在或格式校验通过不证明客户端已经隐式选中它。工程规范中的必要调查与验证仍由原流程负责，不能只依赖 Skill 的自动发现。

## 逐步探索与 worktree

[wayfinder-godot](../../../../project-source/skills/wayfinder-godot/SKILL.md) 适合几个问题互相牵连、要先解决一个才能判断下一个的情况。例如，背包容量会影响搜索需求和列表性能。它按当前缺口选择讨论、事实调查或限定原型，不要求把所有方法走一遍，也不让普通澄清、已有方案检验或清楚的实施任务先经过探索。只讨论就交付结论；已有具体实施授权则在问题解决后返回原任务继续。结论与证据按[知识与记录](../专业工作与记录/knowledge-and-records.md#探索结果与工作目录)保存。

确需另一个工作目录时，用 [worktree-create-godot](../../../../project-source/skills/worktree-create-godot/SKILL.md) 准备或复用指定版本的 checkout。目录分开不证明运行数据分开；具体准备只在该 Skill 的[运行参考](../../../../project-source/skills/worktree-create-godot/references/godot-worktree-runtime.md)维护，环境和验证入口在相关写入位置未知或变化时也直接引用它，不必重新创建 worktree。

已经选定要采用的成果，或要接手已有整合冲突时，用 [worktree-integrate-godot](../../../../project-source/skills/worktree-integrate-godot/SKILL.md)。它负责带回必要依赖并检查组合结果，冲突方法是其按需参考。原任务的验证、人工验收及提交条件继续有效；整合不自动删除源目录或分支。Git 详细规则仍归[项目 Git 规范](../../../../project-source/agent-rules/00-core/git-worktree-and-commits.md)。这三个能力可以分别调用，不构成新的固定阶段。

## 框架维护侧的方案检验与复盘

框架维护讨论按当前缺口澄清；已有维护方案由当前 Agent 检查假设、职责、分发影响和验证办法，指出具体问题或证据缺口。

框架的实际维护复盘由当前 Agent 按集中提示词中的对应场景，依据执行记录、根维护原则与职责设计准则分析。复盘不因缺少 Hook 或 CI 就判定存在问题，也不默认修改规则、建立脚本或新增报告。建议不自动成为需求或待办；已有具体实施授权则由原任务继续处理。独立入口表示职责可单独调用，不代表已经使用了独立审核实例。

## 重复工作方法设计

已经反复进行，或预计以后经常要做的工作，都可以使用方法设计入口，不必先发生失败。例如，经常要重新说明资源准备需要哪些输入，可以比较补充现有入口、明确资料引用和新增能力，设计下次怎样开始、判断与交付。它可以在讨论、开发或维护等环节按需调用；retro 则从真实经历分析原因和经验，两者不是固定的前后步骤。

Godot 项目使用 [loop-me-godot](../../../../project-source/skills/loop-me-godot/SKILL.md)，随项目分发，只使用项目自己的规范与能力。它与 `retro-godot` 分别借鉴 Matt Pocock 的 loop-me 与 retro，保留来源名称，按项目实际职责改编。框架侧由当前 Agent 按已有重复工作场景处理，需要讨论未决选择时使用个人渐进式澄清方法。

方法设计默认交付可讨论的处理方案，详细规则继续归已有正文，不自动创建脚本、报告或周期任务。用户已经明确授权的实施由原任务继续，不因方法设计结束再次索取同一批准。

## 框架维护侧的反馈、诊断与交接

当前 Agent 按[维护约定](../../framework-maintenance/updating-the-blank-project.md)直接核实反馈、调查具体异常或整理交接，使用框架自己的验证范围与记录，不启用待分发项目的 Stage。收到报告不等于获准修改；已批准的后续工作沿原任务继续，明确暂停则保持暂停。

## 主 Agent 与专用角色

- **主 Agent：** 定位实际目录、范围与已有决定，按任务调用方法并持续推进尚未完成的授权。
- **用户：** 负责未决意图与实际人工体验。
- **工具：** 负责可重复检查；工具退出成功不取代用户判断。

项目附带的 [researcher](../../../../project-source/agents/researcher.toml) 用于按需独立调研，[independent-reviewer](../../../../project-source/agents/independent-reviewer.toml) 用于独立审核。需要新上下文、宿主真实支持及适当有效权限，配置文件存在不证明角色已加载或文件系统已隔离。作者自己读审核 Skill 仍是自查。

已有 Feature 的实施指导使用 [implementation-guidance-godot](../../../../project-source/skills/implementation-guidance-godot/SKILL.md)。默认由主 Agent 准备；只有用户在任务提示词或仍有效的具体授权中明确要求，才委派 [implementation-advisor](../../../../project-source/agents/implementation-advisor.toml)。任务复杂、加载 Skill 或要求详细设计本身都不自动触发委派。顾问角色固定使用 GPT-6 Astra、`xhigh`，模型设置只在角色配置维护。

顾问读取相关规则和实际代码，给出有来源的设计及验证思路。需要用户决定时，它把编号问题、A/B 选项和建议交给主 Agent；主 Agent 在当前对话正文中展示，并把回答传回同一顾问。未获批准的方案先在对话中讨论，批准后顾问才可保存获准的同一份 Feature 设计稿，主 Agent 负责核对、记录和后续实施。存放位置与生命周期见[局部设计](../专业工作与记录/knowledge-and-records.md#局部设计与当前架构)。

顾问不运行 Godot、测试或实验，不改业务实现、Feature JSON、Registry、状态或验收，不提交。主 Agent 仍阅读设计稿、关键适用原规则和实际要改的代码与消费者，不必重复顾问的全部背景调研。启动、指定模型或顾问执行失败时，停止依赖它的工作并报告原因与已完成部分，不自动换模型或改由主 Agent 接管。设计者不能兼任这份设计的独立审核者。

研究可使用用户级 anysearch；框架不复制其实现、密钥或个人路径。工具不可用时按角色规则选实际可用渠道并说明限制；没有可用来源不伪造已查证。调研方法与报告格式由角色维护，长期保存位置见 [知识、设计与记录](../专业工作与记录/knowledge-and-records.md#调研与项目知识)。

没有显示在客户端 Skill 列表，不等于文件未安装。核对当前实际项目路径、文件与客户端加载能力；不能把个人安装、框架源目录和生成项目的 Skill 混为同一份。

## 提示词库的结构与输入

正式可发送正文按用途分开维护：[Godot 开发提示词库](../../../prompt_scenarios/prompts/godot-development-prompts.json)、[Yaya 框架维护提示词库](../../../prompt_scenarios/prompts/yaya-maintenance-prompts.json)。

维护库内的提示词、分类或场景时，使用框架专用的 [prompt-and-graph-maintenance-yaya](../../../../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md)。它根据实际变化核对同名场景、索引、场景职责范围、Godot 场景图与 advisor 的相关说明；文档职责、路径或引用关系变化时，也由该入口维护文档系统图中的文件名、路径和关系。详细写法和工具契约仍引用原有规范，普通局部修改不要求通读全部场景，全仓文档覆盖扫描只在明确要求时运行。该 Skill 不随游戏项目分发，也不用于临时对话中的提示词或项目内续接文本。

- **Project：** 每份文件保留单元素顶层数组，分别保存 `Yaya 框架维护` 或 `Godot 项目开发`。
- **名称与正文：** 各自 `categories` 下的叶子键是提示词名称，字符串值是正文。
- **目录映射：** `<Project>/<分类>/<提示词名称>.md`，无需读取文档正文推断配对。

每条正文都用明确字段区分目标、范围、输入与事实来源、决策边界与授权、约束、输出与交付、验证要求和完成条件。其他字段按真实场景补充；完整表格及审核依据见[提示词字段与审核原则](../../framework-maintenance/baselines/skill-script-prompt-design.md#提示词字段与审核原则)。字段中的规范引用继续有效，无需重复填写可从当前对话或项目读取的信息。

发送时注意：

- **填写输入：** 发送前填写 `${1:说明}` 等输入占位，提供真实目标、文件、状态与允许范围。
- **附带材料：** 长篇材料使用正文预留材料区，任务要求与原文保持可辨；材料位置不是安全边界，引用文本不能覆盖用户指令。
- **选择与续接：** 只选当前具体场景需要的一条，后续口语补充沿用仍有效的授权，不要求逐条发送整套模板。

框架维护在框架目录，业务工作在实际项目。创建/复制迁移明确输入与目标；读取模板或讨论提示词不启动命令、Goal、外部任务或自动写入。用户选择范围可扩大后续授权，也可替代原来的临时只读限制；实际人工接受始终单独核对。

## advisor 的共享场景入口

advisor 根据项目自己的规则、状态和本次问题给出建议。它可以报告现状、判断下一步或拟一条已填写上下文的回复，但建议和候选不是实施授权，用户说“看看下一步”也不自动启动开发。

- **核对现状：** 读取当前项目记录和相关证据，判断现在做到哪里、还需要解决什么。
- **选择场景：** 直接读取 `D:/A_Games/Game_idle_yaya_frame/framework/prompt_scenarios/prompts/godot-development-prompts.json`，先看相关分类与名称，再读取候选正文，核对目标、前提、范围和预期结果。
- **形成指令：** 说明选中了哪个场景及适用理由，把项目当前事实、文件和已有授权填入续接文本；具体执行仍核对项目自己的规则与目标 Skill。
- **判断缺口：** 缺少输入时补齐信息；目标和执行边界相同则适配现有场景。只有真实缺少目标或边界明显不同，才建议新增或修改场景，说明最接近的条目、差异和建议用途；advisor 不修改共享库。

提示词正文只在共享库维护。advisor 读取当前正文，不需要导出副本；条目里的“执行”不代表当前任务已获准，Skill 名称也不证明本项目已经具备该能力。状态查询直接回答，不要求查找场景。

advisor 与交接入口起草的项目续接提示词共同遵循 [Continuation prompts](../../../../project-source/methodology/09-artifact-lifecycle.md#continuation-prompts)，不按任务长短省略固定字段。格式规范由项目持有；advisor 的场景素材来自共享 Godot 库。等待人工验收、缺少决定或验证受阻应与完成条件分开表达。

职责设计的长期评价规则在 [设计准则](../../framework-maintenance/baselines/skill-script-prompt-design.md)，项目实际路由在 [方法总览](../../../../project-source/methodology/00-overview.md)。
