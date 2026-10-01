# 《设计范围与边界》职责与调用路径独立审核

本次限定范围的静态审核未发现必须修复项，结论为保留当前变更。GDD 整体范围、局部设计限制和 Project Rules 工程约束的归属一致；直接调用、讨论续接、获准保存与下游读取能够到达同一权威契约。此结论不代表客户端触发、实际游戏设计写作或人工体验已经验证。

## 1. 对象、版本与审核边界

- **审核日期：** 2026-10-02。
- **执行者：** 未参与被审成果创作的独立审核实例 `/root/review_design_boundaries`，使用 [review-agent-instructions-yaya](../../../.agents/skills/review-agent-instructions-yaya/SKILL.md)。报告表达按 [technical-documentation-writing-yaya](../../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) 整理。
- **基线与实际 HEAD：** `2947b1c9326e9f89e0a4e772ff6fee51b4ab7c27`，主题为 `docs(agents): 明确按职责组织与拆合成本原则`。该提交中的拆合原则作为现行依据，不是本次重新评价的对象。
- **被审快照：** 上述基线后的 35 个非 HTML 文件改动，为 80 行增加、63 行删除；最终核对包含 `project-grill-me` 明确使用 `docs/terminology.md` 的读取入口和 5 条提示词恢复一致的 8 空格缩进，关系图末尾格式与基线保持一致。两本派生 HTML 不作为独立正文审查。
- **权限：** 被审材料只读。审核实例只获准新增本报告，没有修改实现、状态、原始证据或派生产物，也未暂存或提交。

核对范围是本次改动、必要前后文及直接调用关系，不是全仓指令审核。协调者提供的已确认要求作为本次需求依据：整体游戏范围、排除项和版本边界归 GDD 固定子文档；局部机制和表现限制留在所属主题；Project Rules 负责开发约束、协作与工程原则；按任务读取相关内容；已有 GDD 写入授权随确认决定持续有效，纯讨论只说明尚未保存的有用结论。

## 2. 覆盖对象与正文归属

| 对象组 | 本次覆盖 | 结论与依据 |
| --- | --- | --- |
| 项目规范、模板与导航，10 文件 | `Project_AGENTS.md`、`Project_README.md`、`defaults/docs/game-organization.md`、`defaults/docs/gdd/README.md`，methodology 的 00、01、04、11，以及模板 README、Project Rules 模板 | 保留。完整范围契约集中在 [methodology 01](../../../project-source/methodology/01-product-doc-structure.md#design-scope-and-boundaries)；其他位置承担路由、说明或短提醒，没有另建一套采用和保存流程。 |
| GDD 写作入口与参考，5 文件 | [design-gdd](../../../project-source/skills/design-gdd/SKILL.md)，及 `consolidation.md`、`design-docs.md`、`gdd-dialogue.md`、`gdd-fields.md` | 保留。固定路径只用于范围子文档；其他主题保留按内容组织的自由。首次保存、既有 GDD 局部调整与整合没有被混成全量重组。 |
| 相关 Skill，9 文件 | `engineering-change-plan`、`feature-plan`、`feature-sync`、`product-author`、`product-spec-elicitor`、`project-grill-me`、`project-next-step-advisor`、`retro-godot`、`review-code` | 保留。按设计、交付或工程任务读取相关约束；建议、同步、正式审核和实现各自保留原来的写入及完成边界。 |
| 集中提示词与同名场景，6 文件 | [Godot 提示词库](../../godot-development-prompts.json)中的 5 条改动正文，以及对应 5 篇场景全文 | 保留。名称、入口、范围、授权、交付与出口能够对应；逐条结果见下一节。 |
| 操作手册，3 文件 | [需求与规划](../../docs/operation-manual/需求与任务/requirements-and-planning.md)、[项目对象与目录](../../docs/operation-manual/框架基础/project-layout.md)、[知识与记录](../../docs/operation-manual/专业工作与记录/knowledge-and-records.md)的相关段落及前后文 | 保留。能区分实际设计、目录说明、确认排除、版本暂缓和未决选择；说明明确指向权威契约。 |
| 覆盖说明与文档关系图，2 文件 | [场景覆盖](../baselines/scenario-coverage.md)和 [文档关系图](../../docs/workflow-maps/document-system.readable.json)的本次差异 | 保留。说明与正文一致；图只更新 GDD、Project Rules 两个节点的职责备注，没有改变场景关系或引入实际游戏内容。 |

归属判断依据如下：

- [范围契约](../../../project-source/methodology/01-product-doc-structure.md#design-scope-and-boundaries)明确固定 `docs/gdd/design-scope-and-boundaries.md`，正文标题和语言遵循 `document_language`，入口直接链接它。整体范围、确认排除与版本边界集中维护；每项仍保留条件、例外和有用理由。
- 同一契约明确长期或跨系统的游戏边界仍属 GDD；[Project Rules 规范](../../../project-source/methodology/04-coding-rules-4-layers.md)和[模板](../../../project-source/methodology/templates/project-rules.md.tmpl)一致收束为开发约束、协作及工程原则，没有继续用“长期”替代职责判断。
- 局部机制留在所属 GDD 主题，局部表现和 Shader 限制留在对应设计或专业规格。迁移范围正文时修复引用、旧位置改为链接，没有要求复制到 Product、Feature 或 Project Rules。
- [专业来源规范](../../../project-source/methodology/11-specialist-workflows.md#discover-and-map-sources)把适用边界读取接入专业要求的创建和审核；[design-game-presentation](../../../project-source/skills/design-game-presentation/SKILL.md)及其 [Shader 参考](../../../project-source/skills/design-game-presentation/references/shader-requirements.md)继续在表现方案中处理局部可见行为和实现限制，没有被改成全局排除项汇总。

## 3. 代表性使用路径核对

以下结果来自逐条正文阅读和静态情境推演，不是客户端实际调用试验。

| 路径 | 核对结果 |
| --- | --- |
| 直接调用 `design-gdd`，已确认游戏只做单机，讨论商店玩法 | 入口先读取范围契约和当前主题，复用尚未保存的明确决定；`project-grill-me` 的共用方法据此过滤已排除的情境。无需重新讨论多人同步，也不会把未定的交易设计当作永久排除。 |
| “只有游戏想法，先形成 GDD 草稿” | 提示词与同名场景都授权当前草稿保存，并要求按真实已知范围建立固定子文档和入口引用。草稿保存不等于候选采用，不因已写文件而结束仍需共同决定的共创；用户只要先交一版时可交付标明缺口的草稿。 |
| “设计资料分散在多处，需要整合 GDD” | 整合按既有采用状态处理来源冲突；涉及整体范围时移动到固定正文，保留无关结构及原始输入资料。局部规则仍有自己的主题，未解决关键冲突不会被改写成确认规则。已有具体同步授权继续由所属入口执行。 |
| “有一个项目问题没想清楚，先讨论” | 明确只讨论、文件只读。根据问题读取设计边界或工程约束；结尾指出有用的确认结论尚未保存，不生成 GDD、Product 或术语文件。 |
| “项目问题还没讨论清楚，继续原来的讨论” | 前提明确原工作仅为讨论。继续使用原方法和有效决定，复用已读材料及未保存结论；本次不写文件、不运行实验，也不把继续讨论当作采用或验收。 |
| “项目约束已确认要改，现在维护规则文档” | 入口只维护确认的开发、协作和工程条款，沿用 methodology 04 的写前自检及既有写入授权。游戏范围和排除项返回 `design-gdd`，无需为了保存 GDD 决定另开工程规则维护流程。 |
| Product 澄清、编写、Feature 规划和同步的直接调用 | 各入口都能到达适用范围与相关主题；Product 只组织交付，`feature-sync` 只更新既有计划。需要改设计时返回设计正文维护，不通过改计划静默改变游戏边界。 |
| 专业表现及 Shader 规格设计 | 经 methodology 11 读取适用整体设计边界，同时保留表现方案、部件行为和 Shader 局部限制的原归属。早期表现探索仍可支持 GDD；写规格不授权制作资源或运行实现。 |
| 游戏行为审核、advisor 建议与复盘归属判断 | 已通过项目入口或相应 Skill 接入范围契约。正式审核和 advisor 保持只读，复盘建议不自动落盘；长期游戏排除项不会因复用价值被升级为 Project Rules。 |
| 范围子文档尚未形成、纯工程或状态查询 | 缺失范围文件本身不会否定已有实质设计或阻塞讨论；纯工程和状态任务无需读取无关设计章节。既有开发所需实质 GDD 前提仍有效，本次没有用“文件不存在”新增强制设计访谈。 |

五条改动提示词的 8 个固定字段均有实质内容；相关按需字段与当前场景一致。五篇场景的正文一级标题与提示词名称对应。讨论型入口明确限制当前写入；获准写作入口复用具体授权，局部方法返回或文档保存不撤销后续授权。

## 4. 静态分发与验证证据

审核实例实际完成了以下读取与检查：

- 核对 HEAD、工作区差异和暂存状态；报告写入前暂存区为空，35 个被审源文件之外的新增差异为两本派生 HTML。
- 执行 `git diff --check`，退出码为 0，无诊断输出。
- 解析实际提示词 JSON，逐条阅读 5 条选定正文及 5 篇场景，核对相关规范、调用入口和说明。
- 读取 [复制清单](../../project-files.json)，核对 `project-source/skills` 到 `.agents/skills`、`methodology` 到同名项目目录、默认 docs 到项目 docs，以及 Project Rules 模板到 `docs/project-rules.md` 的映射。新引用在生成项目中的相对关系与该映射一致；advisor 保留已约定的本机共享提示词绝对路径。
- 枚举默认 GDD 分发目录，实际只有 `README.md`。范围子文档由真实 GDD 写作产生，没有新增空模板、预填游戏排除项或实际游戏设计正文。

协调者在审核期间提供的验证结果如下。它们作为本次已有维护证据记录，审核实例没有重复运行或将其记为自身执行：

| 检查 | 协调者提供的结果 | 支持的结论 |
| --- | --- | --- |
| `check_scenario_prompt_paths.py` | 退出码 0，138/138 对应 | 场景与提示词名称、路径集合对应；不证明正文语义或调用行为。 |
| 操作手册构建 | 退出码 0，14 文档、207 来源链接、2 图复用 | 构建器覆盖的收录、链接、锚点、章节及产物检查通过。 |
| 场景速查构建 | 退出码 0，141 文档、1178 来源链接 | 构建器覆盖的收录及路径检查通过，不代表浏览器试读。 |
| 构建范围外的静态映射 | 检查 25 个改动文档，新增行中 13 个 Markdown 链接目标可达，范围锚点存在 | 新引用在当前源树和复制映射下可定位，没有实际生成外部游戏项目。 |
| 变更边界检查 | Skill 元数据与 HEAD 一致；只有 5 条提示词正文变化，名称、分类、顺序不变；5 篇场景 H1 一致 | 本次未变更 Skill 发现元数据，也未新增或重命名场景入口。 |
| 关系图深度比较 | 只有 `doc-gdd`、`doc-project-rules` 的 `note` 改变，布局、连线、链接、ID 与末尾格式保持 | 文档职责说明同步，没有关系图结构变化。 |

## 5. 结论与未验证范围

**必须修复项：无。** 文本归属、Skill 职责、提示词与场景三个相关维度均可保留当前变更。现有 GDD 写作和条件引用已覆盖此次职责调整，无需另增能力或流程；脚本职责和实现未发生变化，不作脚本全量审核结论。

本次没有验证客户端自动发现或触发 Skill，没有实际创建游戏项目、运行真实 GDD 写作流程、启动 Godot、执行 pytest、运行引擎或进行人工体验验收；审核实例也没有构建手册。上述未执行项是本报告的覆盖边界，不是已经失败的检查，不能由静态通过或协调者的手册构建结果替代。

本审核没有产生新的待修复事项；已存在的关系图和文档试读待办不因本报告自动关闭。报告只评价所述工作区版本，后续若改变正文、授权边界或调用关系，应针对变化重新核对。
