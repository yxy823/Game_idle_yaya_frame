---
name: writing-for-agents-yaya
description: 编写、修改并自查 Yaya 框架中的 Codex 指令，包括 AGENTS.md、Skill、任务提示词及条件引用规则。正式只读审核使用 review-agent-instructions-yaya；普通技术说明润色或仅执行既有指令不触发。
---

# Yaya 框架 Codex 指令编写

编写或修改指令，让 Codex 在正确的任务中找到约束、理解授权并完成有依据的交付。适用于框架维护规则与 `project-source/` 中待分发的指令源材料；本 Skill 仅在框架仓库使用，不随游戏项目分发。

沿用当前任务的对象、目标和授权，先读当前正文及必要调用方，再完成获准修改、引用同步和必要自查。正式审核请求交给独立的 [review-agent-instructions-yaya](../review-agent-instructions-yaya/SKILL.md)，不在本入口切换为审核模式；作者自查仍属于实现，不是正式独立审核。普通说明文字的表达使用 [框架文档编写 Skill](../technical-documentation-writing-yaya/SKILL.md)。

## 按任务选择依据

| 当前任务 | 查阅内容 |
| --- | --- |
| 编写或修改指令的触发、引用、正文归属、授权和完成边界 | [指令设计参考](references/agent-instruction-design.md) |
| 编写或修改 Skill 的 description、目录、元数据、调用策略 | [Codex Skill 编写参考](references/codex-skill-authoring.md) |
| 新增或调整 Skill 的职责、判断拆分与合并 | [职责设计准则：Skill](../../../framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#skill-的评价维度) |
| 编写或修改集中任务提示词 | 以[提示词与场景准则](../../../framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#提示词与场景)判断正文；入口定位与联动维护由 [prompt-and-graph-maintenance-yaya](../prompt-and-graph-maintenance-yaya/SKILL.md) 承接，复用已读依据 |

普通局部修改只读取相关正文与必要调用方；复用仍有效的上下文，不把所有参考设为固定前置。

## 实现、自查与交付

依照所选参考完成当前修改，保持未获准改变的行为、来源归属与完成条件。按实际变化自查入口、引用、分发路径和语义，Skill 元数据变化按其参考验证。复杂的新职责或明显触发调整，可用实际场景做独立试用：只给必要输入，不把预期答案交给试用者；如实说明实际加载、权限和未验证部分。

自查发现本次范围内的问题时修正并验证；范围外问题说明依据与影响，不擅自扩大修改。区分格式与链接检查、静态推演、有限试用和客户端实际调用。普通修正不额外建立脚本、评分、审批或报告层。

交付变更、实际验证和未完成项，按当前任务的 Git 条件处理提交。需要正式审核时，由相应独立实例使用审核入口；不把作者自查改称审核，也不把每次编写强制接到一个新关卡。尚有已授权工作时返回原任务继续，不因本方法完成而结束整个任务。

本 Skill 根据 Matt Pocock 的 writing-for-agents 本地材料改编，共用设计方法及来源说明维护在所引参考中。
