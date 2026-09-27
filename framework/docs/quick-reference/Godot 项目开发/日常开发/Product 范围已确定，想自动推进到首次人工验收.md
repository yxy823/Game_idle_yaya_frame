# Product 范围已确定，想自动推进到首次人工验收

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

Product 范围已确定，想自动推进到首次人工验收。

需要的材料：

- 推进范围：当前 Product 范围、排除项。
- 执行授权：已有授权。

## 前置条件与适用范围

明确请求启动 Goal，按既定范围连续推进到首个真实人工交接点。

## 执行步骤

使用[集中提示词库](<../../../../prompts.json>)中的“Godot 项目开发 → 日常开发 → Product 范围已确定，想自动推进到首次人工验收”。填入上述材料；已有对话直接补齐输入，不必重发入口。本页使用 [$feature-plan](<../../../../../project-source/skills/feature-plan/SKILL.md>)、[$feature-sync](<../../../../../project-source/skills/feature-sync/SKILL.md>)、[$feature-execute](<../../../../../project-source/skills/feature-execute/SKILL.md>)，具体执行者和切换位置见下文。

**S1｜固定 Goal 范围**

当前 Agent 核对总览、真实进度与范围；若 Goal 已存在则沿用，未指定预算不自行设定。

**S2｜逐个推进 Product**

只规划当前 Product，写前展示拆分后按目标自主授权继续，实现、必要验证与本地提交沿现有流程。

**S3｜交接首个人工验收**

manual Feature 先完成全部适用自主工作，提供可运行入口与绑定当前版本的 pending 清单，再结束本段 Goal。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 目标与可自主工作的范围明确 |
| S2 | 当前 Product 的实际工作持续推进 |
| S3 | 待验收 Feature 保持未完成 |

## 资源与文件影响

当前范围的来源、计划、实现、证据和 Progress 按各 Skill 修改；不建 Goal 台账。

## 阻塞、异常与范围变化

局部原型确认只阻塞依赖实现，不算整段目标完成；预算耗尽或阻塞不是达成。

## 完成状态与验证标准

首个完整人工验收材料已就绪，或范围内全部任务已真实完成；停止处和状态准确。

## 流程关联与衔接关系

依据：[项目路由依据](<../../../../../project-source/methodology/00-overview.md>)、[人工验收文件契约](<../../../../../project-source/methodology/manual-acceptance-files.md>)。本段 Goal 以首个完整人工验收交接或授权范围全部完成为出口，不跨过本次明确的人工交接边界继续开发。用户后续要求继续时核对实际验收结果与仍有效的授权；交接材料就绪不代表该 Feature 已验收或正式完成。
