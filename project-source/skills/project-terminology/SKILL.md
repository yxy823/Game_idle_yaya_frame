---
name: project-terminology
description: "在 `docs/terminology.md` 中记录已确认的项目术语定义、别名和链接，不改变行为。用于已获授权的术语文档工作，包括 Feature 的文档检查点。不用于含义尚未决定的术语（project-grill-me），也不用于行为变更（design-gdd）。"
---

# 项目术语

按 `yaya/methodology/14-project-terminology.md` 的说明，在固定文件 `docs/terminology.md` 中维护不改变含义的定义，并维护使用这些术语的文档指向它的链接。实质的游戏设计含义由 `design-gdd` 负责，限定范围的数值设计由 `design-balance` 负责。保存的措辞按 `yaya/methodology/05-document-language.md`，写入和提交按项目的 Git 规则。

## 核对输入

创建 GDD 时，可以用本 Skill 记录含义已经确定的术语；不需要 Product，也不需要 GDD 已经完成。

阅读请求的定义、当前的 `docs/terminology.md`，以及与之有关的想法、GDD、Product 交付和代码来源，其余不读。复用已确认的决定和当前的文档授权，不重复访谈。代码只说明当前行为，不能批准新的领域含义。

本 Skill 不能做的决定，按下面转交：

- 实质含义仍未决定的，交给 `project-grill-me`。
- 某个定义会改变游戏规则、数值或流程的，先退回 GDD 的设计负责方，再修改依赖它的定义。
- Product 交付变更使用 `product-author`；Feature AC 发生变化的，按规划流程处理。

## 编写定义

- 已确认的项目定义只写在 `docs/terminology.md` 中，只在单个主题里使用的术语也一样。
- 把授权范围内的定义移进该文件，原处的正文改为链接，并保留来源锚点。原始来源的保留、别名、退役和排除规则见 `yaya/methodology/14-project-terminology.md`；玩法细节留在 GDD 中。
- 目标语言的措辞通过 `design-localization-spec` 写在 `docs/localization/localization-spec.md` 的 **术语译名** 中（methodology 11 的 **本地化术语译名**）。不要把目标语言词表作为别名保存在这里。
- 文件不存在、又有已确认的定义需要保存时，创建该文件。没有已确认的术语时，不编造条目。
- 术语写成 `| 术语 | 含义与边界 | 不用的说法 |` 表格，每个术语一行，不用小标题或列表逐条写。同一概念不再使用的写法登记在“不用的说法”列，登记或统一用词后运行 `python -B yaya/tools/checks/check-terminology.py`（methodology 14 的 **术语文件的格式**）。

不改变含义的编辑不重命名代码、不迁移数据、不做专业澄清、不创建 Product 交付文档或 Feature，也不同步计划。

## 验证与提交

对照已确认的含义检查最终措辞，并核对受影响的链接。单独提出的请求，验证后按项目 `AGENTS.md` 的「Git 与提交」提交文档，除非用户另设了提交条件。提交主题使用 `docs(terminology): <术语摘要>`，摘要语言按项目规则；不为此编造 Feature。

在已获授权的 Product 或 Feature 任务中，把修改后的定义和剩余缺口交回该任务的协调 Agent，放进同一个逻辑提交。

返回调用方；Skill 返回不会结束它所在的已授权任务（methodology 03 的 **授权与续接**）。
