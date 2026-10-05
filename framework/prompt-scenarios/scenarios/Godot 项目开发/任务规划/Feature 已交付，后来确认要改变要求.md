# Feature 已交付，后来确认要改变要求

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

例如 F002 已经 `done`，试玩后决定改掉它的一条规则，GDD 或 Product 已按新决定改好并提交；现在要让计划承接这次变化，而不是重新打开 F002。

需要的材料（都可选）：

- 变化说明：你对这次改动意图的原话。不提供时，Agent 只按已提交的来源差异分析，意图有实质歧义时才追问。
- 已知受影响的 Feature ID：不提供时由 Agent 从差异和消费者追查。

来源差异、现有计划和测试登记由 Agent 直接读取。

## 前置条件与适用范围

受影响 Feature 已交付，相关 GDD、专业规格或 Product 交付范围已按确认决定改好并提交；本次只同步计划，不实现新行为。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 任务规划 → Feature 已交付，后来确认要改变要求”。填入上述材料。本页使用 [$feature-sync](<../../../../../project-source/skills/feature-sync/SKILL.md>)。

**S1｜分析来源差异**

当前 Agent 用 feature-sync 从最后一条修订记录的锚点取已提交差异，追查直接和传递的消费者及受影响测试，报告实质变化、受影响 ID 和建议动作。

**S2｜确认计划动作**

按[阶段 3：用户审阅与决定](<../../../../../project-source/skills/feature-sync/SKILL.md#阶段-3用户审阅与决定>)，只就尚未批准的实质选择询问，例如新任务的范围、退役或依赖。已批准的需求变化不等于批准这些计划动作。

**S3｜追加独立任务**

按[修订](<../../../../../project-source/skills/feature-sync/references/apply-plan-changes.md#修订>)中 `done` 一行追加依赖原 ID 的新 Feature，在 AC 中写明新行为；按[下游回归](<../../../../../project-source/skills/feature-sync/references/apply-plan-changes.md#下游回归>)把消费者回归分配给它。原 Feature 的索引、详情和完成记录不改。

**S4｜记录、检查并提交**

追加本次修订记录，然后在游戏项目根目录运行：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectPython = $projectConfig.python_executable
& $projectPython -B yaya/tools/checks/check-feature-list.py
$LASTEXITCODE
```

打印 `FEATURE LIST CHECK: PASS` 且退出码为 0，只证明 Feature 记录的结构、引用和依赖一致，不证明需求覆盖或实现完成。检查通过后按 feature-sync 的提交约定提交计划。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 影响报告：锚点、实质变化、受影响 ID 与状态、测试影响 |
| S2 | 未批准动作已有用户决定 |
| S3 | 新 Feature ID、依赖、AC 和回归安排已写入；原 Feature 记录无差异 |
| S4 | `FEATURE LIST CHECK: PASS` 和计划提交哈希 |

## 资源与文件影响

- 修改：追加新 Feature 的索引条目与详情、必要的测试登记，以及本次修订记录。
- 读取与保留：GDD、Product 交付范围与专业来源只读；原 Feature 的索引、详情和完成记录不改。

## 阻塞、异常与范围变化

来源尚未改好或基线无法核实时先交对应来源或基线恢复场景；不伪造差异。尚未细化的后续 Product 只处理预拆分影响，不提前创建 Feature。

## 完成状态与验证标准

新变更有独立可执行任务，旧完成历史保持真实。

## 流程关联与衔接关系

依据：feature-sync 的[阶段 3：用户审阅与决定](<../../../../../project-source/skills/feature-sync/SKILL.md#阶段-3用户审阅与决定>)和[修订](<../../../../../project-source/skills/feature-sync/references/apply-plan-changes.md#修订>)，methodology 02 的[同步记录](<../../../../../project-source/methodology/02-feature-list-schema.md#同步记录>)。
