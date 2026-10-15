# 00 · 方法总览

> 本页是项目工作流程的入口：说明方法规范、Skill、项目文档和命令之间的关系，以及每类任务从哪个入口处理。

方法规范覆盖以下工作：从想法开始的游戏设计、数值建模与调参、Product 交付规划、Feature 规划与实现。还覆盖工程修改、自动化测试、人工验收、缺陷复盘，以及本地 Git 下的安全交接。版本发布管理、商店提交、公开版本公告、部署审批、发布流程和分发管理不在默认方法范围内，除非用户明确把其中某项定为项目工作。

## 规范与执行的关系

```text
yaya/methodology/                         canonical workflow specification
     │
     ├──────────────→ Skills         agent-executable workflows
     │                    │
     │                    ▼
     │               project docs/  maintained GDD, Product, Feature, Rules, Progress
     │                    ▲
     └──────────────→ Commands       explicit validation when the task needs it
```

- `yaya/methodology/` 定义工作流程，`.agents/skills/` 下的 Skill 负责执行。
- 项目文档放在 `docs/` 下，[docs/README.md](../../docs/README.md) 说明每个文件和目录。新项目附带的页面含用途说明和默认要求；这些页面存在，不代表已有游戏 GDD、交付计划或决定。
- `docs/methodology-config.json` 保存 `document_language` 以及 Python 和 Godot 可执行文件路径，分别按[文档语言](05-document-language.md)和[项目环境](06-project-environment.md)维护。
- `yaya/tools/` 下的命令只在任务调用时运行。文件变化或回复结束时，不会自动运行任何工具。

## Skill 分组

| 分组 | Skill |
| --- | --- |
| 游戏设计 | `design-gdd`、`design-balance` |
| Product 交付 | `product-author`、`product-spec-elicitor` |
| 澄清与术语 | `project-grill-me`、`wayfinder-godot`、`project-terminology` |
| 专业设计 | `design-game-presentation`、`design-ui-spec`、`design-art-direction`、`design-audio-direction`、`design-visual-asset-spec`、`design-audio-asset-spec`、`design-localization-spec` |
| 规划 | `feature-plan`、`feature-sync`、`plan-review-godot` |
| 交付 | `feature-execute`、`implementation-guidance-godot`、`debug-console-godot`、`technical-validation-godot` |
| 工程 | `engineering-change-plan`、`engineering-refactor-select` |
| 反馈与诊断 | `feedback-triage-godot`、`bug-diagnosis-godot` |
| 环境、验证与证据 | `project-environment-godot`、`project-verification-godot`、`manual-acceptance-godot`、`verification-evidence-godot` |
| 接入与测量 | `content-asset-integration`、`content-localization`、`content-data-authoring`、`diagnostics-instrumentation`、`diagnostics-performance`、`diagnostics-soak-test` |
| 独立审核 | `review-code`、`review-ux`、`review-art`、`review-audio`、`review-assets`、`review-localization`、`review-balance` |
| worktree | `worktree-create-godot`、`worktree-integrate-godot` |
| 指引、交接与改进 | `project-next-step-advisor`、`task-handoff-godot`、`retro-godot`、`loop-me-godot` |
| 文档编写 | `technical-documentation-writing-godot`、`qa-explainer-godot` |

## 任务路由表

本表是任务路由的唯一依据。指引类 Skill 把本表和目标工作流程一起读，不另外维护生命周期表或审批表。凡是规划交付、实现、修复或运行实验的行，都需要满足 [GDD 前提与职责](01-product-doc-structure.md#gdd-前提与职责)中的实质 GDD。“边界”列说明何时选这个入口，以及它不包含什么。

| 任务类型 | 入口 | 边界 |
| --- | --- | --- |
| 发展游戏想法、编写或深化 GDD、整合设计材料 | `design-gdd` | 从已有目标和来源开始，不需要完整的 GDD、Product、Feature 或就绪的引擎。不创建 Product 或 Feature。 |
| 设计或调整数值模型、公式和参数 | `design-balance` | 用于模型和数值，GDD 还是早期草稿时也可以用。玩法变化交给 `design-gdd`，运行时修改交给实现，正式数值审核交给 `review-balance`。 |
| 澄清游戏设计选择、交付边界或含义不清的术语 | `project-grill-me`；交付问题用 `product-spec-elicitor` | 当前任务受到关键不确定点影响时使用。只讨论时不写任何文件。 |
| 解决几个答案相互影响的关键未知点 | `wayfinder-godot` | 未知点相互依赖时使用。不强制访谈、原型、worktree 或新记录类型，也不扩大任务授权。 |
| 选定工作前先评估反馈或外部报告 | `feedback-triage-godot` | 在决定反馈需要什么工作之前使用。分类不授权修复，也不创建 Feature。 |
| 调查一个具体异常行为的原因 | `bug-diagnosis-godot` | 用于具体故障。只要求调查时，不允许修改实现。 |
| 检查 GDD 草稿或文档，或 Product、Feature 提案 | `plan-review-godot` | 发现返回给文档作者；审查 GDD 不需要 Product 或 Feature。它不是正式的[独立审核](12-independent-review.md)，也不是必经关卡。 |
| 根据实际任务经验复盘，包括反复出现的阻力 | `retro-godot` | 需要来自真实任务的证据。只返回建议，不自动修改规则，也不自动生成报告、检查或工作项。 |
| 为用户点名的反复出现或预期会出现的活动设计处理方式 | `loop-me-godot` | 不必等出现故障再用。返回一份设计，不增加 Stage，也不实现任何内容。 |
| 调查外部事实或比较方案 | 主 Agent，可以委派给 `researcher` | 答案需要外部来源时使用，见 [外部调研](09-records-reports-and-handoff.md#外部调研)。没有强制的调研 Stage，不新建 Feature，不自动采纳结论。 |
| 把用户问到、以后还会用到的问题保存为问答 | `qa-explainer-godot` | Agent 在回复结尾提议，用户同意后写入 `docs/qa/` 并生成 HTML 页面；用户明确要求记录或用图解释时直接写入。问答可以和其他正文重复，不检查重复；它只解释，不作为需求、设计或规则的依据。 |
| 记录或维护已确定的项目词汇 | `project-terminology` | 按[项目术语](14-project-terminology.md)维护不改变含义的定义。不创建 Product 计划，不做 Feature 源同步；行为变化交给 `design-gdd`。 |
| 维护项目通用规则或专项规则 | 当前已获授权的任务，按 [规则的增量维护](04-project-rules.md#规则的增量维护) 执行 | 用于 `docs/project-rules.md` 或规则模块。每项拟议修改都先报告再写入；单独的规则工作不需要 Feature。 |
| 说明 Feature 设计或重要的技术决定 | 当前的规划或设计任务，按 [Feature 设计与实现说明](02-feature-list-schema.md#feature-设计与实现说明) 和[架构概览](10-architecture-overview.md) 执行 | 实现设计写在 Feature 设计文件中；符合条件的技术理由写成 ADR。不改变 Product 范围或项目规则。 |
| 选择视觉或声音方向 | `design-art-direction`、`design-audio-direction` | 按[专业工作与来源](11-specialist-workflows.md)维护 Art Bible 或 Sound Bible 中的共用标准。不需要完整的游戏设计，不产出资源。 |
| 从体验目标或随口的描述规划一个游戏时刻，或比较其组成部分的方案 | `design-game-presentation` | 用于[游戏表现文档](11-specialist-workflows.md#游戏表现文档)，可以支持早期 GDD 探索。不包含代码、资源制作或验收。 |
| 和用户一起反复试调已实现的特效、反馈或操作手感 | `debug-console-godot`，在已获授权的 Feature 或实验中使用 | 用户在调试台实际观看或操作后判断，满意的设定由用户采纳到游戏的调参资源，Agent 收尾提交；文档链接资源，不抄数值。Feature 完成后再调值按[完成后再调值](13-debug-console-and-validation.md#完成后再调值)。不是人工验收。 |
| 规定一个界面或单个资源 | `design-ui-spec`、`design-visual-asset-spec`、`design-audio-asset-spec` | 用于细化 GDD 的专业规格。交付范围仍由 Product 决定。 |
| 制作美术、音乐或音效 | 项目外的制作项目，按 11 号规范的[在项目外制作](11-specialist-workflows.md#在项目外制作)交接 | 本项目没有制作 Skill，不在仓库里制作；交出规格章节，收回成品后由 `content-asset-integration` 或调试台候选接入。没有制作项目时记录规格和缺口。 |
| 确定语言覆盖范围和区域格式约定 | `design-localization-spec` | 可以单独进行。游戏规则留在 GDD，术语定义留在 `docs/terminology.md`。 |
| 接入已提供的资源，或实现已批准的本地化 | `content-asset-integration`、`content-localization` | 在已获授权的 Feature 或实验中应用已批准的规格；不是独立的交付。 |
| 批量编写或生成关卡、生产者、升级表等内容数据，或建立内容校验 | `content-data-authoring`，在已获授权的 Feature 中使用 | 按已确认的规则、公式和目标区间产出数据并检查；规则交给 `design-gdd`，公式和目标区间交给 `design-balance`，难度与手感由用户实际游玩判断。 |
| 添加诊断信号、测量性能或运行长时间运行（soak）场景 | `diagnostics-instrumentation`、`diagnostics-performance`、`diagnostics-soak-test` | 用于收集证据。测量不授权修复。 |
| 在调试台比较候选或做技术验证 | 比较观感或逻辑候选用 `debug-console-godot`；技术验证用 `technical-validation-godot` | 按 13 号规范的[选择方式](13-debug-console-and-validation.md#选择方式)回答一个具体问题。独立实验不需要 Product 或 Feature；Feature 内的实验沿用该 Feature 的流程。纯数值问题交给 `design-balance`。 |
| 骨架之后在调试台做视觉决策 | `feature-execute` 配合 `debug-console-godot`，在当前 Product 交付或已获授权的实验中使用 | 按[界面的开发顺序](13-debug-console-and-validation.md#界面的开发顺序)：骨架、视觉决策、完整逻辑三个 Feature。规格提供输入；调试台中的比较、采纳和人工验收属于执行阶段。 |
| 列出并交接一个任务所需的最少资源文件 | 当前任务，按需配合 `design-visual-asset-spec` 或 `design-audio-asset-spec` | 按[资源需求与交接](11-specialist-workflows.md#资源需求与交接)执行。不制作也不接入资源。 |
| 为已获授权的任务准备或复用另一个工作目录 | `worktree-create-godot` | 任务需要另一个工作目录时使用。路径分开不等于运行时数据隔离。 |
| 把已采纳的 worktree 成果并入目标，或续接中断、有冲突的合并 | `worktree-integrate-godot` | 用于已选定的成果和目标。不在相互竞争的成果之间做选择，也不授权清理。 |
| 根据 GDD 预拆分交付范围 | `product-author` | 只写用户要求的 `product.md` 规划范围。 |
| 修改游戏设计 | `design-gdd`；限定范围的数值设计用 `design-balance` | 修改设计不会自动创建 Product 或 Feature。 |
| 修改当前 Product 的交付范围 | `product-author` | 后续 Product 保持在预拆分层级。 |
| 已有实现，但缺少覆盖它的 Product 或 Feature 记录 | 先用 `product-author`，再走规划和交付路由 | 按 [接手已有实现](02-feature-list-schema.md#接手已有实现) 执行。需要已确认的 GDD 设计；不编造历史，也不授权超出已说明缺口的修复。 |
| 当前交付完成后细化下一个 Product | 先用 `product-author`，获得授权后再用 `feature-plan` | 当前 Product 的必需 Feature 全部完成后使用，按 [逐个 Product 规划](02-feature-list-schema.md#逐个-product-规划) 执行。 |
| 拆分当前 Product | `feature-plan` | 只规划当前 Product。 |
| 源同步 | `feature-sync` | 已提交的 GDD、Product、专业文档或规则来源发生变化时使用。不做首次拆分。 |
| 继续当前 Feature | `feature-execute` | 只说“继续”，不能补上缺少的批准或验收。 |
| 执行一个符合条件的已规划 Feature | `feature-execute` | 按依赖顺序选择；Stage 1 的批准仍然适用。 |
| 为已规划的 Feature 准备实现指引 | `implementation-guidance-godot`，由主 Agent 使用 | 只有用户明确要求或任务授权仍然有效时，才委派给 `implementation-advisor`；不会仅因任务复杂就委派。 |
| 当前未完成 Feature 中的 Bug | 该 Feature 的修复路由 | 在其范围内修复，并补上回归测试覆盖。 |
| 已完成行为中的独立 Bug | `engineering-change-plan` 的 bug 模式 | 行为违反已记录的需求时使用；期望缺失或期望改变时，按 [分类边界](07-engineering-change.md#分类边界) 交给对应的设计负责方。 |
| 重构 | `engineering-change-plan` 的 refactor 模式 | 行为保持不变。只有用户要求挑选代码坏味道时，才先用 `engineering-refactor-select`。 |
| 维护 | `engineering-change-plan` 的 maintenance 模式 | 用于技术成功标准、兼容性、迁移和验证工作。 |
| 项目工具问题 | `engineering-change-plan` | 用于项目自有工具中的问题。 |
| 把已提出的临时脚本保存为项目脚本 | 主 Agent 直接保存 | 用户同意保存后，按[保存常用脚本](09-records-reports-and-handoff.md#保存常用脚本)执行，不需要 Feature。随规则修改提出的检查仍按[规则的增量维护](04-project-rules.md#规则的增量维护)。 |
| 独立审核 | 在新的 `independent-reviewer` 实例中使用对应的审核 Skill | 只在用户要求正式审核时使用，按[独立审核](12-independent-review.md)执行。不修复，也不提供人工验收。 |
| 配置、更新或恢复项目工具，或完成必需的首次资源扫描 | `project-environment-godot` | 按[项目环境](06-project-environment.md)执行。不证明游戏行为，也不需要 Feature。 |
| 运行用户要求的解析、lint、已有测试或限定范围的场景检查 | `project-verification-godot` | 有无 Feature 都可以用。报告实际结果；不修复、不验收，也不完成交付。 |
| 准备待做的人工检查，或记录用户实际的验收结果 | `manual-acceptance-godot` | 按[人工验收文件](contracts/manual-acceptance-files.md)执行。准备检查不等于验收；记录结果不推进 Stage，也不授予提交权限。 |
| 检查、导入或恢复验证证据 | `verification-evidence-godot` | 按 [基于原始结果的完成判断与语义时效](08-test-traceability-and-evidence.md#基于原始结果的完成判断与语义时效) 执行。只安排确实需要的重跑或人工跟进。 |
| 查询状态 | 只读说明，或 `project-next-step-advisor` | 不为回答问题而开始工作或运行就绪检查。 |
| 按用户要求保存暂停点，或准备在另一个对话中继续同一任务 | `task-handoff-godot` | 不创建 Feature、交接记录文件、对话或消息。 |

使用本表时：

- 根据现有证据和用户当前的授权，选择调查、规划或执行。用户当前的授权优先于通用流程措辞。
- 分类评估、诊断、环境工作、验证、人工验收、证据处理、多未知点探路（wayfinding）和 worktree 工作都是可调用的方法，不是 Stage，也没有固定顺序。任务需要时就用，包括用户直接提出的限定范围请求。
- 一个方法返回，不代表更大范围的已授权任务结束，也不会把一次有限的检查变成完整交付；见 [授权与续接](03-execute-loop.md#授权与续接)。
- 起草任务提示词时，按 [续接提示词](09-records-reports-and-handoff.md#续接提示词) 编写。
- Git 操作遵循 `AGENTS.md` 的 **Git 与提交**。

## 延伸阅读

| 主题 | 文件 |
| --- | --- |
| GDD 与 Product 文档：名称、范围、开放问题、候选想法和 Product 结构 | [01-product-doc-structure.md](01-product-doc-structure.md) |
| Feature 记录结构、修订和逐个 Product 规划 | [02-feature-list-schema.md](02-feature-list-schema.md) |
| Stage 0–8 执行循环、授权与续接 | [03-execute-loop.md](03-execute-loop.md) |
| 项目规则：职责、加载和增量维护 | [04-project-rules.md](04-project-rules.md) |
| 文档语言 | [05-document-language.md](05-document-language.md) |
| 工具配置与项目环境准备 | [06-project-environment.md](06-project-environment.md) |
| Bug、重构和维护修改 | [07-engineering-change.md](07-engineering-change.md) |
| 测试追溯、测试影响评估、TDD 和完成证据 | [08-test-traceability-and-evidence.md](08-test-traceability-and-evidence.md) |
| 报告、调研、知识、Progress（进度记录）和交接 | [09-records-reports-and-handoff.md](09-records-reports-and-handoff.md) |
| 可选的架构概览和 ADR | [10-architecture-overview.md](10-architecture-overview.md) |
| 专业文档、来源映射、UI 与表现文档，以及资源交接 | [11-specialist-workflows.md](11-specialist-workflows.md) |
| 独立审核 | [12-independent-review.md](12-independent-review.md) |
| 调试台、界面的开发顺序、逻辑候选、完成后再调值和技术验证 | [13-debug-console-and-validation.md](13-debug-console-and-validation.md) |
| 项目术语 | [14-project-terminology.md](14-project-terminology.md) |
| Agent 如何读取解析器和 lint 结果 | [contracts/gdscript-lint.md](contracts/gdscript-lint.md) |
| 人工验收清单与结论记录 | [contracts/manual-acceptance-files.md](contracts/manual-acceptance-files.md) |
| Product、Feature、ADR 等文件的模板 | [templates/README.md](templates/README.md) |
