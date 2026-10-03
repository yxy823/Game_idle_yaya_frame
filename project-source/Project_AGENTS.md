# 项目说明

本项目使用 Windows 11、PowerShell 7、Godot 4.7、GDScript 和 gdUnit4。工具的实际路径写在 `docs/methodology-config.json`。工具能否使用以实际检查结果为准，不根据模板推断已安装了哪些工具。

## 沟通与交付

默认采用 ADHD 友好的表达，让用户容易理解并立即行动。以下要求只约定表达方式，不改变任务授权、验收或完成标准。

- **直接表达与阅读顺序：** 开头先回答用户最关心的问题。分析、评估和建议类回答先给主要结论、优先建议及影响判断的必要边界，再展开理由；主要要求查找问题时先呈现关键发现，单纯解释概念时不强造建议或下一步。用日常用语讲清具体问题、改法和结果，必要术语就地解释；删除客套、绕句、空泛鼓励和无用比喻。
- **同题就近讲完整：** 同一主题的建议、必要理由和适用边界放在一起，不拆散到“优点、缺点、建议、另外”等位置让读者自行拼接。确需跨节提及时，用短提醒或明确引用，不重复完整论述。
- **主要判断与支撑细节：** 不影响当前判断的实现细节、背景和补充案例后置；会改变建议的重要风险、前提和不确定性就近说明或前置，不为简洁隐藏。保留必要证据和来源，用户要求详细解释时充分展开。
- **按内容组织：** 简单问题直接回答，不为凑结构增加章节；长回复用能直接说明主题的标题，每个段落或条目围绕一个主要问题。操作流程用编号步骤，每步写清执行者和一个可判断完成的动作；需要按相同维度对照对象或方案时，可使用表格；多项内容按主题或用途分组。向用户提问时，遵循个人沟通规则及当前 Skill 的具体提问要求。评估、解释类回答不必逐段套用“执行者、动作、完成标准”，不以固定字数、段落数或条目数代替可读性判断。
- **用场景说明关系：** 解释多文档、多职责或跨阶段关系时，优先用贴近当前任务的具体场景串起需求、设计、实现与验收，再补充抽象分工。只在有助于理解当前关系时使用，不强制每次套用。
- **有用重复与无效复述：** 保留帮助记住优先项、恢复上下文或避免遗漏的简短重复，以及已有的默认高频提示机制；只删没有新增作用的复述，不因出现频繁就删除。
- **状态与交付：** 多轮工作有进展时说明已完成、仍受阻和下一步，不编造总步骤数。完成后先给可用成果、文件入口和实际验证结果。只有需要用户行动时，结尾给一个能立即开始的具体动作；工作已结束不另造下一步。
- **错误与估算：** 客观说明错误位置、已知原因和修复或排查办法，分清事实、推测与未知。同样的失败不盲目重试，先核对关键假设，有新证据再试。耗时估算有依据时用分钟、小时等单位或范围，写明影响估算的条件。
- **提问与授权：** 沿用具体授权，Agent 能完成的工作继续完成；缺少关键信息、决定或实际人工验收时请用户介入，优先提出最关键的问题。可能造成重要数据损失且现有授权未覆盖的操作，执行前确认；已明确批准的同一动作不重复询问。

## 使用说明的可读性

编写、更新或整理项目文档时，使用本地 [technical-documentation-writing-godot](.agents/skills/technical-documentation-writing-godot/SKILL.md)，按本次文档类型读取其中的参考。适用于 README、使用说明及需求、设计、知识和报告中的自然语言文字。

所属规范继续决定字段、固定路径、文档语言、流程、授权、验收与完成条件；写作 Skill 不替代这些契约，也不改变机器可读结构。持久项目文档使用 `docs/methodology-config.json` 中的 `document_language`。

## 工作流程与授权

项目由一位使用者与 Agent 配合开发。工作流程不涉及多人协作，也不追踪每处改动由谁完成。

- 支持在同一目录内暂停、切换和续接任务，包括换到新对话后续接。
- 只有当前任务的范围和授权需要时才使用 worktree，并遵循 [Git 与提交](methodology/15-task-scope-git-and-reporting.md#git-与提交)。任务默认不在 worktree 中开始。
- 限定范围的调研和独立审核通过下表的入口使用各自的角色。

| 需要做的事 | 阅读 |
| --- | --- |
| 选择工作流程或下一个允许的动作 | [任务路由表](methodology/00-overview.md#任务路由表)。Skill 在 `.agents/skills/`，显式命令在 `tools/` |
| 创建或维护 GDD、数值模型或 Product 交付计划 | `methodology/01-product-doc-structure.md` |
| 维护项目术语 | `methodology/14-project-terminology.md` |
| 制作视觉或逻辑原型 | `methodology/13-prototypes.md` |
| 规划 Feature、排定 Product 顺序或修改 Feature 台账 | `methodology/02-feature-list-schema.md` |
| 执行 Feature，包括批准、可选的独立审核和完成 | `methodology/03-execute-loop.md` |
| 解释、应用或修改项目规则 | `methodology/04-project-rules.md` 和 `agent-rules/00-core/rule-precedence-and-routing.md` |
| 准备 Feature 的设计与实施指导 | `implementation-guidance-godot` Skill |
| 设置文档语言 | `methodology/05-document-language.md` |
| 配置工具或准备项目环境 | `methodology/06-project-environment.md` |
| 修复 Bug、重构或做工程维护 | `methodology/07-engineering-change.md` |
| 确定修改范围、保留已有改动、本地提交或写完成汇报 | `methodology/15-task-scope-git-and-reporting.md` |
| 选择测试、记录本次运行的证据或使用完成辅助工具 | `methodology/08-test-traceability-and-evidence.md`。直接的解析和 lint 命令在 `methodology/contracts/gdscript-lint.md` |
| 整理报告、临时工作区、Progress、历史或清理 | `methodology/09-records-reports-and-handoff.md` |
| 维护可选的架构图或 ADR | `methodology/10-architecture-overview.md` |
| 处理专业设计、资源、本地化、诊断或多个需求来源 | `methodology/11-specialist-workflows.md` |
| 执行用户要求的正式审核 | `methodology/12-independent-review.md` |
| 调研外部事实或方案 | `methodology/09-records-reports-and-handoff.md` 的 **外部调研** |

这些行是任务入口，不是阅读顺序。按选中的流程及其需要的参考执行，不加载全部工作流程。Skill 返回后，按 [授权与续接](methodology/03-execute-loop.md#授权与续接) 继续任务。

### 设计前提与需阅读的来源

游戏设计可以从一个想法开始，使用 `design-gdd`。交付规划、实现、工程工作和可运行的实验，都需要能说清当前范围的实质 GDD 内容；只有占位内容的页面不算。完整规则见 [GDD 前提与职责](methodology/01-product-doc-structure.md#gdd-前提与职责)。Product 文档负责组织交付，链接到 GDD，不复制其中的设计。

在设计讨论、规划、实现或审核之前，按任务阅读下列内容：

- [设计范围与边界](methodology/01-product-doc-structure.md#设计范围与边界)、与本任务有关的[开放问题](methodology/01-product-doc-structure.md#开放问题)，以及覆盖该主题的 GDD 页面。
- `docs/terminology.md` 中与本任务有关的定义。
- 与本任务有关的 Product 和专业来源，以及已接受的架构决定。
- `docs/project-rules.md` 中约束本任务的工程规则。Product、Feature 或 ADR 不能悄悄豁免这些规则。

只说明目录用途或待定状态的起始页面，不算已确认的需求或定义。设计讨论不必等待所有后续细节，也不必等待详细的 Product 文档。

## 环境与 Git

第一个编码 Feature 开始前，完成 [项目环境准备](methodology/06-project-environment.md#项目环境准备)（项目环境准备）。编码需要一个经实际检查结果确认的环境。下列情况运行 `python -B tools/checks/check-project-environment.py --require-ready`：

- 初次准备环境时；
- 工具或配置变化后；
- 诊断某次工具调用失败时。

普通 Feature 直接复用已确认的命令，不重新探测版本。

启动任何 Godot 编辑器检查（包括 `--headless --editor`）之前，阅读并遵循 [Windows 编辑器检查](agent-rules/00-core/validation-policy.md#windows-编辑器检查)。

每个会修改文件的任务都遵循 [Git 与提交](methodology/15-task-scope-git-and-reporting.md#git-与提交)：

- 在任务指定的工作目录中工作；
- 保留已有的改动；
- 只暂存本任务的路径；
- 按完整的逻辑改动提交。

本地提交不代表任务完成，也不代表人工验收。

## 项目知识与规则反馈

在规划、调查、实现、调试或审核中选择做法之前，先查阅[相关的项目知识](docs/knowledge/README.md#先查找相关知识)。主题为空不阻塞工作。知识不能推翻已接受的决定或规则。

在已获授权的任务文档工作中，按[知识维护](docs/knowledge/README.md#在已获授权的工作中维护)记录有用的做法和失败教训：

- 只读任务保持其写入边界。
- 没有有用的新经验时，不需要写条目。
- 在 Stage 7 提交之前定稿 Feature 笔记和知识条目；Stage 8 链接它们。

工作中发现 `agent-rules/` 或 `docs/project-rules.md` 尚未覆盖、可复用的规定性指导时，按 [规则的增量维护](methodology/04-project-rules.md#规则的增量维护) 规定的时机和自查方式提出。没有获得该批准，不修改规则。

## 领域规则路由

`methodology/` 规定工作流程和可追溯性，包括[任务范围、Git 与完成汇报](methodology/15-task-scope-git-and-reporting.md)；`agent-rules/` 规定具体的引擎与语言规则。规则冲突按[规则冲突的处理流程](agent-rules/00-core/rule-precedence-and-routing.md#规则冲突的处理流程)解决。带编号的规则模块目录不规定项目自身的目录布局。

做修改或与修改有关的工程决定时，先读 `agent-rules/00-core/README.md`，再读下表中每个受影响领域的 README：

- 按 README 的路由表只读匹配的文件和小节，不读整个目录。需要的验证写在模块 README 末尾的验证节。
- 模块可以叠加。例如测试用的 `.gd` 文件同时适用 GDScript 规则和测试规则。
- 续接时，已读且未变化的规则直接复用。只有任务或新证据需要时才多读。

| 修改的对象或领域 | 规则入口 |
| --- | --- |
| GDScript | `agent-rules/10-gdscript/README.md` |
| 场景 | `agent-rules/20-scenes/README.md` |
| 资源 | `agent-rules/21-resources/README.md` |
| Shader | `agent-rules/30-shaders/README.md` |
| ProjectSettings | `agent-rules/40-project-config/README.md` |
| 导出配置或导出流水线 | `agent-rules/41-export-config/README.md` |
| 游戏数据、数据结构定义或数据流水线 | `agent-rules/50-data-files/README.md` |
| 素材或导入流水线 | `agent-rules/60-assets/README.md` |
| 测试、测试夹具或测试运行器 | `agent-rules/70-tests/README.md` |
| UID、路径、NodePath、业务 ID 或 RID 的身份 | `agent-rules/00-core/godot-resource-references.md` |

常见任务读哪些（路径相对于 `agent-rules/`）：

| 任务 | 阅读 |
| --- | --- |
| 改 `.gd` 并加单元测试 | `00-core/README.md`；`10-gdscript/README.md` 与 `typing-and-api.md`；`70-tests/README.md` 与 `test-levels.md` |
| 重命名或移动节点、场景、资源 | `00-core/godot-resource-references.md`；`20-scenes/README.md`；移动资源文件时再读 `60-assets/README.md` |
| 导入或替换图片、音频、字体 | `60-assets/README.md`；涉及 `.import` 或生成文件时读 `00-core/third-party-generated-and-temporary-files.md` |
| 新增或修改游戏数据及其定义 | `21-resources/README.md`；`50-data-files/README.md` |
| 运行 Godot 编辑器检查 | `00-core/validation-policy.md` 的 Windows 编辑器检查 |

没有专门模块时，使用 `00-core` 规则和项目已有的约定，只在主题重叠处读相邻模块。修改依赖随版本变化的引擎行为时，按 [Godot 版本与依据](agent-rules/00-core/godot-version-and-authority.md) 核对 Godot 4.7 的行为；普通的 Markdown 编辑不需要。不在实现过程中顺带扩展规则体系。

要判断游戏逻辑和游戏表现的职责归属、它们的设计来源，或模块的位置和命名，读 `docs/game-organization.md` 中匹配的小节。它解释概念并给出示例；命名和引擎约束仍以上面的规则模块为准。
