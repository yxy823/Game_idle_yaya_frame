# Product 范围已确定，想自动推进到首次人工验收

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

例如 Product 预拆分已经确认，你希望 Agent 作为 Codex Goal 连续完成规划、实现和提交，直到第一个需要你亲自体验的 Feature 准备好再停下。

需要的材料（都可选）：

- 推进范围：本次纳入的 Product 及排除项。不提供时取预拆分中约定的交付范围。
- 已有的具体限制：例如不提交、指定独立评审。没有就省略。

GDD、预拆分顺序、Progress 和 Feature 状态由 Agent 直接读取。

## 前置条件与适用范围

项目已有真实 GDD，明确请求启动 Goal，按已确认的交付预拆分范围连续推进到首个真实人工交接点。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 日常开发 → Product 范围已确定，想自动推进到首次人工验收”。填入上述材料。本页使用 [$product-author](<../../../../../project-source/skills/product-author/SKILL.md>)、[$feature-plan](<../../../../../project-source/skills/feature-plan/SKILL.md>)、[$feature-sync](<../../../../../project-source/skills/feature-sync/SKILL.md>)、[$feature-execute](<../../../../../project-source/skills/feature-execute/SKILL.md>)。

**S1｜固定 Goal 范围**

当前 Agent 核对 GDD、交付预拆分、真实进度与范围；若 Goal 已存在则沿用，未指定预算不自行设定。

**S2｜逐个推进 Product**

先依据最新 GDD 细化已轮到的 Product，再把其完整必要范围拆成所需数量的 Feature；展示拆分后按目标自主授权继续。必要游戏设计问题由 design-gdd 处理，交付取舍使用 product-spec-elicitor，沿用本次范围和有效决定。当前 Product 全部必要 Feature 真实完成后，再复核并细化下一个；实现、必要验证与本地提交沿现有流程。

**S3｜交接首个人工验收**

manual Feature 先完成全部适用自主工作，提供可运行入口与绑定当前版本的 pending 清单，再结束本段 Goal。界面按[界面的开发顺序](../../../../../project-source/methodology/13-debug-console-and-validation.md#界面的开发顺序)拆成骨架、视觉决策、完整逻辑三个 Feature；视觉决策 Feature 的交接点更早：候选和固定局面在调试台就绪后，Agent 给出 `dev/debug/README.md` 中的启动命令，停下等你在调试台比较并采纳到游戏。本段 Goal 在此结束；不依赖视觉参数的工作在下一段 Goal 中继续。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 本次纳入的 Product 与排除项已列出；Goal 已创建或沿用 |
| S2 | 每个 Product 的拆分预览；已完成 Feature 的完成记录和提交哈希 |
| S3 | 可运行的体验入口和绑定当前版本的 pending 清单路径，视觉决策 Feature 为调试台启动命令和要比较的插槽；该 Feature 仍为未完成 |

## 资源与文件影响

当前范围的来源、计划、实现、证据和 Progress 按各 Skill 修改；不建 Goal 记录文件。

## 阻塞、异常与范围变化

GDD 缺失时说明缺口并停止，不初始化设计。预算耗尽或阻塞不是达成。

## 完成状态与验证标准

首个完整人工验收材料已就绪，或范围内全部任务已真实完成；停止处和状态准确。

## 流程关联与衔接关系

依据：methodology 02 的[逐个 Product 规划](<../../../../../project-source/methodology/02-feature-list-schema.md#逐个-product-规划>)，人工验收文件的[定义与准备](<../../../../../project-source/methodology/contracts/manual-acceptance-files.md#定义与准备>)。本段 Goal 以首个完整人工验收交接或授权范围全部完成为出口，不跨过本次明确的人工交接边界继续开发。你给出验收结果后，用[人工验收已有结果，继续原 Goal](<人工验收已有结果，继续原 Goal.md>)接着推进。
