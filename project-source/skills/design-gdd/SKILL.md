---
name: design-gdd
description: "发展游戏想法，共同创作、起草、修改或整合 GDD 设计。用于从一个想法、一次对话或已有材料出发的整体游戏设计。不用于 Product 交付规划（product-author）、数值建模（design-balance）、批量内容数据（content-data-authoring）或独立审核。"
---

# 游戏设计与 GDD 编写

把一个想法、一段进行中的设计对话或已有材料，变成有用的游戏设计。概念探索、共同创作、起草、修改和整合都属于同一项能力。深度按要求的结果和项目阶段决定；一份有用的概念草稿不需要定下所有实现细节。

## 范围与权限

GDD 的权限及其与交付的关系，按 `yaya/methodology/01-product-doc-structure.md` 执行。本 Skill 可以在没有 GDD、Product 或 Feature 的情况下从一个想法开始。它负责 `docs/gdd/` 中的定位、期望体验、核心循环、规则与系统关系、内容进程、整体设计范围，以及这些内容对应的设计要求。GDD 默认描述完整的游戏；只有用户自己定义了发布版本时才写版本边界，不主动提出“第一版包含什么”这类问题，开发顺序交给 Product 规划。

修改之前，先阅读本次涉及的已有设计和用户的具体决定。先按 `yaya/methodology/01-product-doc-structure.md` 的 **设计范围与边界** 阅读，再阅读受影响的主题和必要的依赖。项目规则中的工程约束影响拟定的设计时，一并核对。边界规则需要平台接口或特殊检测才能实现时（例如识别电脑休眠），写明这项代价；用户授权按最简做法定规则时，选不需要这类实现的规则。复用已经清楚的要求；只就重要的未决选择提问。直接要求起草时不需要先访谈；只要求讨论时，不授权写文件。

GDD 文件按 methodology 01 的 **GDD 文件名** 命名；该章节也说明了导入的或组织方式不同的 GDD 怎样处理。入口 `docs/gdd/README.md` 链接实际存在的主题，包括 `design-scope-and-boundaries.md` 和 `open-questions.md`。即使只有部分主题有内容，文件名也保持固定。标题和正文使用配置的 `document_language` 编写（`yaya/methodology/05-document-language.md`），文件名不翻译。

建议、已采用的决定和验证证据要能区分开。每条建议保存在 methodology 01 的 **备选方案与未采纳想法** 选定的位置；本 Skill 在写入授权范围内维护这些位置。保存草稿不等于采用其中的建议，也不能悄悄替换已采用的规则。采用不代表游戏已经平衡、易懂或好玩。有用的工作假设要标明，并链接到它的开放问题，不要编造缺少的事实。

## 只阅读需要的设计方法

| 当前需要 | 参考 |
| --- | --- |
| 寻找或比较玩法方向；找出值得验证的问题；根据试玩记录调整设计 | [概念探索与验证问题](references/concept-ideation.md) |
| 通过提问、回答和逐版草稿共同创作 | [GDD 共同创作](references/gdd-dialogue.md) |
| 起草完整的 GDD，或判断它在当前阶段的覆盖情况 | [GDD 设计覆盖](references/gdd-fields.md) |
| 组织或修改入口、主题页和规则的归属 | [设计文档结构与规则归属](references/design-docs.md) |
| 整合笔记或解决互相冲突的设计来源 | [整合游戏设计材料](references/consolidation.md) |

这些参考服务于当前的设计任务，不是必须依次执行的步骤。提问时使用[共享提问方法](../grill-me/SKILL.md#共享提问方法)，不启动 `grill-me` 自己的独立流程。

## 在来源处维护设计

用目的、触发条件、输入、状态、结果和有意义的边界，描述每个受影响的机制。有助于把玩家的目标、操作、反馈和进展连起来时，写一段有代表性的游玩过程。按 `docs/game-organization.md` 中的逻辑与表现模型，GDD 仍然同时负责整体规则和体验目标；区分有效的游戏结果和玩家怎样感知它。区分规则的验收情景和需要观察或试玩的体验假设。

每条规则只有一个所属位置。决定变化时，更新受影响的正文和引用，不要保留矛盾的规则再在后面追加更正。不同的来源可以支持不同的论断：观察到的实现是当前行为的证据，不会自动压过已采用的设计。未解决的冲突保留它的来源和影响，不受影响的工作继续进行。

在获准起草或修改范围时，随着有用的范围决定逐步确定，按 methodology 01 的 **设计范围与边界** 维护 `docs/gdd/design-scope-and-boundaries.md` 及其入口链接。局部的机制和表现限制留在各自的主题中。保存已经确认的游戏设计边界，使用当前的 GDD 写入授权即可，不需要另开一个项目规则任务。

按实际任务选择支持能力：

- 普通规格和已有数值直接记录。规则需要、但还没建模的参数，按 methodology 01 的 **数值放在哪里** 先写成标明“未建模”的占位值。公式推导、参数模型、经济或成长曲线和调优，使用 [design-balance](../design-balance/SKILL.md)。把本次涉及的目标、规则草稿和当前授权交给它；早期的数值探索不要求 GDD 已经完整。
- 交付边界、依赖和顺序属于 [product-author](../product-author/SKILL.md)。
- 具体关卡、表格等内容实例，在已授权的 Feature 中由 [content-data-authoring](../content-data-authoring/SKILL.md) 制作；GDD 只保留种类目录和规则，并链接数据文件。
- 详细的游戏表现、UI、美术、音频、资源和本地化规格，属于 `yaya/methodology/11-specialist-workflows.md` 中规定的固定所属位置。该文件也规定了首次创建 GDD 时怎样保存这些规格，以及整合时怎样把它们从 GDD 中迁出。游戏规则和整体体验目标留在 GDD；非 UI 的表现从对应的 GDD 主题链接。
- 设计变化影响已规划或已完成的工作时，按 `yaya/methodology/11-specialist-workflows.md` 的 **编写与采纳** 和 **源同步前先提交来源修改** 处理，并在当前授权范围内使用 `feature-sync`。尚未规划的未来想法，不需要 Product 文档或 Feature 计划。
- 在获准创建、修改或整合 GDD 时，按 `yaya/methodology/14-project-terminology.md` 使用 [terminology-register](../terminology-register/SKILL.md)，把当前范围内已确认的术语保存到 `docs/terminology.md`，并从 GDD 链接过去。术语维护属于同一个写入任务；GDD 不另外保留一份词表。文档措辞或组织使用 [technical-documentation-writing-godot](../technical-documentation-writing-godot/SKILL.md)；它不决定设计。
- 按 methodology 01 的 **开放问题**，阅读并维护 `docs/gdd/open-questions.md` 中本次涉及的问题。已定的决定留在对应的 GDD 主题中，问题解决后写回那里。暂停或阻塞需要续接时，按 `yaya/methodology/09-records-reports-and-handoff.md` 在 Progress 或任务记录中链接对应的问题，并保留下一步；不要复制问题正文，也不要建设计状态记录文件。

对修改过的设计做作者自查。用户要求设计审核时使用 [plan-review](../plan-review/SKILL.md)，独立的数值审核使用 [review-balance](../review-balance/SKILL.md)。正式的独立审核按 `yaya/methodology/12-independent-review.md` 需要另一个非作者实例；本 Skill 不为自己的成果背书，也不给普通的起草增加审核关卡。

游戏代码、运行时资源，以及原型或资源制作，都不在本 Skill 的设计产出范围内。验证建议不会启动制作。上层任务已经授权后续工作时，把设计、来源和剩余的不确定点交回所属流程。依赖它的规划或实现，仍然需要当前范围内规则、状态、反馈和可观察结果都已写明的设计。

## 完成要求的结果

只讨论时，返回有用的结论和剩余的重要选择，并指出哪些已确认的有用结论还没有保存。获准写入时，交付实际的 GDD 入口或修改过的主题；受影响时还包括范围、开放问题、未采纳想法和项目术语文件，并说明重要的修改、假设和本次涉及的未解决问题。检查当前范围的边界、规则一致性、建议的归属、术语的归属、数值引用和链接；整合时还要说明保留的内容和尚未解决的来源冲突。

草稿满足要求的用途时，可以带着明确列出的未知项结束。指出哪些未知项会阻塞预定的下一步用途，哪些可以等待。计算、静态推理、实际运行和人工反馈，都只按证据实际支持的程度报告。遵守当前任务的 Git 规则和完成规则。

返回调用方；Skill 返回不会结束它所在的已授权任务（methodology 03 的 **授权与续接**）。
