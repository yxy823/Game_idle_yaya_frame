# 游戏设计文档目录

本目录保存持续维护的 GDD 设计正文，包括游戏定位、核心循环、系统规则、数值、体验与反馈目标、内容与版本范围。`README.md` 是固定总览入口，通用主题按需建立并使用[标准文件名与职责](../../methodology/01-product-doc-structure.md#gdd-document-names)中指定的名称；相同职责沿用同一名称，不为填满目录预建空文件。实际编写时链接《设计范围与边界》子文档 `design-scope-and-boundaries.md`，集中整体范围、排除项与版本边界；局部限制留在所属主题，具体契约见[设计范围与边界](../../methodology/01-product-doc-structure.md#design-scope-and-boundaries)。局部修改不重组无关内容或另存副本，调整路径或被引用标题时同步实际使用方。

[开放问题](open-questions.md)集中当前尚未解决的设计问题，说明相关主题、影响和所需决定或证据。后续讨论、规划、审核及相关实验按范围读取；解决后将决定写回所属主题并更新引用。具体职责见[开放问题规范](../../methodology/01-product-doc-structure.md#open-design-questions)。

系统规则固定使用 `systems/<system-key>.md`；系统数值模型使用相同键的 `balance/<system-key>.md`，跨系统数值模型使用 `balance/cross-system.md`。`gameplay.md` 保存核心循环、系统关系和入口链接。按上述标准命名契约区分内容职责，游戏规模、篇幅和复杂程度不改变位置；没有实际内容时不预建文件。

GDD 同时说明游戏逻辑与表现目标；界面细节和一次具体表现分别链接到 [UI 设计](../ui/README.md)与[游戏表现](../presentation/README.md)。例如商店主题保存购买规则和成功反馈目标，再引用界面、获得物品的表现以及实际接入说明。整体查找关系见[游戏职责与项目组织](../game-organization.md)。

共享视觉规格、声音规格和本地化要求分别由[美术规范](../art/art-bible.md)、[声音规范](../audio/sound-bible.md)和[本地化规范](../localization/localization-spec.md)保存。编写或整合 GDD 时按[专业来源规范](../../methodology/11-specialist-workflows.md)归位当前范围内的已确认规格，本目录引用其正文。

项目术语的定义与别名统一维护在[项目术语](../terminology.md)，本目录引用该文件，不另设术语表。编写或整合 GDD 时，一并整理当前范围内已确认的术语；具体职责见[项目术语规范](../../methodology/01-product-doc-structure.md#project-terminology)。

当前尚无 GDD 设计正文。本页仅说明目录用途，不能代替 GDD。可以导入已有设计，也可以使用 `design-gdd` 从游戏想法开始讨论并编写初稿；数值建模与调参使用 `design-balance`，按授权直接维护本目录中的对应主题。候选、已采纳设计和实际验证结果分别说明。

设计讨论不要求先有完整 GDD、Product、Feature 或可运行环境。交付规划与实现仍须有当前范围足够明确的真实设计；具体边界见 [GDD 前提与职责](../../methodology/01-product-doc-structure.md#gdd-prerequisite-and-authority)。

交付预拆分与推进顺序维护在 [Product 总览](../product.md)，具体交付单元按 [Product 规范](../../methodology/01-product-doc-structure.md) 逐个细化。Product 引用本目录中的设计要求，不重复保存完整设计正文。
