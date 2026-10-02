---
name: review-agent-instructions-yaya
description: 正式只读审核 Yaya 框架的 Codex 指令，包括 AGENTS.md、Skill、集中任务提示词和条件引用规则，交付有依据的问题与结论。编写、修改及作者自查使用 writing-for-agents-yaya；不承担一般代码审核或文档润色。
---

# Yaya 框架 Codex 指令审核

审核现有指令能否在正确任务中触发、读到必要规则，并保持授权与完成边界。对象包括框架自用材料和 `project-source/` 中待分发的指令源；本 Skill 仅供框架维护，不随 Godot 项目分发。

## 确认审核对象与独立性

沿用用户指定的问题、文件或变更范围，识别实际版本及纳入审核的未提交差异。只读取影响判断的正文、引用和调用方；局部审核不扩成全仓盘点。全量请求按[审核覆盖与结论](../../../framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#审核覆盖与结论)逐项检查，不把抽样或文件枚举写成全量通过。

按[能力划分与正式审核](../../../framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#能力划分与正式审核)使用未参与被审成果创作的独立实例。协调者提供范围、权威要求、实际快照、原始证据和允许的检查，不预设结论。当前实例参与过创作时，将正式审核交给合适实例；无法获得独立实例则报告缺口，不把作者自查改称正式独立审核。

## 按对象读取共用依据

| 审核对象 | 读取内容与用途 |
| --- | --- |
| 指令触发、条件引用、信息层级、正文归属、授权和完成边界 | [指令设计参考](../writing-for-agents-yaya/references/agent-instruction-design.md)；它是共用正文，读取不调用编写入口 |
| Skill 的职责、拆分与编排 | [Skill 评价维度和实现原则](../../../framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#skill-的评价维度)，以及实际必要的 references 和调用方 |
| Skill frontmatter、元数据、目录和调用策略 | [Codex Skill 编写参考](../writing-for-agents-yaya/references/codex-skill-authoring.md)，核对实际发现入口与包的部署范围 |
| 集中任务提示词及关联场景 | [提示词与场景准则](../../../framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#提示词与场景)；按维护入口的[联动归属](../prompt-and-graph-maintenance-yaya/SKILL.md#按实际变化同步)识别受影响对象，只读核对而不执行同步 |

沿真实使用路径检查需要的分支，例如普通直接调用、跳过创建步骤进入验证、继续已有任务、只讨论、只读和尚缺人工决定的情况。对照现行规则及实际授权，不以理想化使用顺序掩盖漏读，不为没有证据的假想风险增加流程。Skill、提示词、引用规则和执行工具各自的职责要分清。

## 保持只读并返回结论

不修改被审指令、实现、状态、原证据或派生文件，不导出、构建、格式化、暂存或提交。可做范围内、已确认无写入副作用的读取和静态检查；缺少实际试用、客户端调用或运行证据时说明缺口，不自行扩大为写入或运行试验。

每项可执行问题说明具体位置、触发情境、后果、依据、建议改法和负责入口。区分已证明问题、证据不足、可选改进与未涉及范围；允许在实际覆盖内没有发现问题。按共用准则分别报告格式/链接检查、静态判断与其他已有证据，不把读取 Skill 或文件存在当成客户端已正确触发。

默认在对话交付结论，注明对象版本、范围、执行者和未验证部分。协调者负责按现有位置归档；明确委派审核实例写报告时，该实例可以仅写获准的指定报告，被审材料、实现、状态及原证据仍保持只读，不增加审核台账。审核期间对象有变化时，核对受影响差异或限定结论适用版本。

正式审核在发现与结论交付后结束，不顺手修复。已具体授权的修复由协调者交回 [writing-for-agents-yaya](../writing-for-agents-yaya/SKILL.md) 或原实现负责人继续；不重新索取同一授权，也不让只读审核实例承接修改。审核通过不等于实现完成、实际人工验收或新增实施授权。
