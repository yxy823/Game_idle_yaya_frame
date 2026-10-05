# 人工验收已有结果，继续原 Goal

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

例如上一段 Goal 停在 F006 的人工验收，你已经试玩，在清单里填了结论，或在对话里说了哪几项通过、哪几项不行，现在要接着推进。

需要的材料：

- 验收结论：对话原话，或你已修改的清单路径。

原 Goal 范围、当前 Feature 和清单由 Agent 从 Progress 与 Feature 记录读取；范围或限制有变化时再说明。

## 前置条件与适用范围

上一段停在人工交接，用户现已给出结果并明确继续。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 日常开发 → 人工验收已有结果，继续原 Goal”。填入上述材料。本页使用 [$feature-execute](<../../../../../project-source/skills/feature-execute/SKILL.md>)、[$manual-acceptance-godot](<../../../../../project-source/skills/manual-acceptance-godot/SKILL.md>)；继续推进时沿用原 Goal 的 [$product-author](<../../../../../project-source/skills/product-author/SKILL.md>)、[$feature-plan](<../../../../../project-source/skills/feature-plan/SKILL.md>)、[$feature-sync](<../../../../../project-source/skills/feature-sync/SKILL.md>)。

**S1｜核对实际人工结果**

当前 Agent 读取原清单或对话原话及当前版本，用 manual-acceptance-godot 按[记录用户的结论](<../../../../../project-source/methodology/contracts/manual-acceptance-files.md#记录用户的结论>)记录，不能把继续指令代替接受。

**S2｜处理当前任务**

通过 feature-execute 先修复获准失败并复验，或完成已接受任务的适用收尾。

**S3｜继续下一段目标**

旧 Goal 已结束时按当前继续请求启动下一段，否则沿用；按原范围逐个推进到下个人工交接点。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 清单中各检查项的状态与原话已记录 |
| S2 | 已接受时为完成记录和提交哈希；修复后仍需再次验收时，体验入口和当前版本的 pending 清单已备好，在此交接，不进入 S3 |
| S3 | 下一个人工交接的体验入口与 pending 清单，或原范围全部完成的记录 |

## 资源与文件影响

当前任务、验收记录和 Progress 修改；后续仅在原 Goal 明确范围内推进。

## 阻塞、异常与范围变化

结果无效或版本不符时停在真实缺口，不绕过人工检查；新玩法不自动纳入 Goal。

## 完成状态与验证标准

当前结果已正确承接，并推进到下一真实人工交接点或原范围全部完成。

## 流程关联与衔接关系

依据：人工验收文件的[记录用户的结论](<../../../../../project-source/methodology/contracts/manual-acceptance-files.md#记录用户的结论>)，methodology 03 的[Stage 5 · 明确的人工验收（仅 manual 模式）](<../../../../../project-source/methodology/03-execute-loop.md#stage-5--明确的人工验收仅-manual-模式>)。
