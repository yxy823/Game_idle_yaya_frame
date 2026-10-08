# 要求已经改好，同步受影响的 Feature

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

GDD、专业规格或 Product 交付范围已按新决定改好并提交，或者已有计划需要和当前来源重新对齐，现在要让 Feature 计划跟上。例如：

- GDD 某条规则改了，受影响的 F003 还是 `pending`，开工前先让它的 AC、依赖和验证安排跟上新规则。
- F004 已经 `in_progress`，实现了一半时确认它依赖的 UI 规格要改，要先理清剩余工作和失效的验证义务，再回去继续实现。
- F002 已经 `done`，试玩后决定改掉它的一条规则；或你在调试台把 F002 链接的调参资源调了值并采纳到游戏、Agent 收尾提交后，要让计划承接这次变化，而不是重新打开 F002。

- 修订记录的最后一条没有可用的 `synced_at_commit`，或者新纳入了一份 `docs/ui/` 规格，却查不出旧锚点当时是否覆盖过它；这时不能直接按锚点差异同步。

一次变化常同时影响多个状态的 Feature，你不需要先判断它们的状态，也不需要先判断来源基线能否核实。

需要的材料（都可选）：

- 变化说明：你对这次改动意图的原话。不提供时，Agent 只按已提交的来源差异分析，意图有实质歧义时才追问。
- 已知受影响的 Feature ID：不提供时由 Agent 从差异和消费者追查。
- 对齐范围：基线无法核实时要重新对齐的 Product 或 Feature ID。不提供时，Agent 先提出当前文档对齐的范围，等你确认。
- 已知的历史缺口：例如“早期规划提交被合并过”。不提供时由 Agent 从 Git 和修订记录核对。

来源差异、现有计划、测试登记、已有实现和证据由 Agent 直接读取。

## 前置条件与适用范围

相关来源已按确认决定改好并提交；来自调试台时，来源差异是被已完成 Feature 的文档或 AC 链接的调参资源的 Git 差异，见[完成后再调值](../../../../../project-source/methodology/13-debug-console-and-validation.md#完成后再调值)。本次只同步计划，不实现新行为。Agent 按每个受影响 Feature 的状态在同一次同步中分别处理，不分批推进锚点：

| 状态 | 处理 |
| --- | --- |
| 未开工（`pending`） | 更新 AC、依赖和验证映射，明确退役被取代的已规划测试 |
| 进行中（`in_progress`） | 更新 AC、依赖和验证映射，标出失效证据，保留仍有效的成果 |
| 已交付（`done`） | 追加依赖原 ID 的新 Feature，原 Feature 的 AC、描述和完成证据不改 |

锚点不可用、或新来源没有可追溯的历史时，Agent 先尝试从历史恢复锚点；恢复不了时，只在获准范围内对齐当前有效来源，并写明历史未知。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 要求变了 → 要求已经改好，同步受影响的 Feature”。填入上述材料。本页使用 [$feature-sync](<../../../../../project-source/skills/feature-sync/SKILL.md>)。

**S1｜分析来源差异**

当前 Agent 先核对最后一条修订记录的锚点能否证明计划覆盖了哪些来源：

- 锚点可用：用 feature-sync 从锚点取已提交差异，追查直接和传递的消费者、受影响测试，以及进行中 Feature 的已有实现，报告实质变化、受影响 ID 与各自状态和建议动作。
- 基线无法核实：先按[从历史中恢复锚点](<../../../../../project-source/skills/feature-sync/references/anchor-and-fallback.md#从历史中恢复锚点>)核对规划提交和计划内容，恢复后按上一条处理；恢复不了时，说明缺失的历史证据，区分不存在与未读到，再按[提出当前文档对齐](<../../../../../project-source/skills/feature-sync/references/anchor-and-fallback.md#提出当前文档对齐>)在对齐范围内阅读完整的当前来源并与计划比较，报告对齐缺口和未知历史，注明检查的 HEAD。

**S2｜确认计划动作**

按[阶段 3：用户审阅与决定](<../../../../../project-source/skills/feature-sync/SKILL.md#阶段-3用户审阅与决定>)，只就尚未批准的实质选择询问，例如范围、退役、依赖、拆分或合并。已批准的需求变化不等于批准这些计划动作。

**S3｜按状态修订计划**

当前 Agent 按[修订](<../../../../../project-source/skills/feature-sync/references/apply-plan-changes.md#修订>)中对应状态的一行修改：

- 未开工：更新 AC、依赖和验证映射，明确退役被取代的已规划测试。需要清理测试代码时写明负责的 Feature，不在同步中修改测试代码。
- 进行中：更新 AC、依赖和验证映射，标出失效的证据，保留仍有效的成果，并提示当前实现可能需要调整。已批准的执行计划受影响时，回到执行时按[1D. 提交批准材料](<../../../../../project-source/methodology/03-execute-loop.md#1d-提交批准材料>)重新批准变化部分。
- 已交付：追加依赖原 ID 的新 Feature，在 AC 中写明新行为；按[下游回归](<../../../../../project-source/skills/feature-sync/references/apply-plan-changes.md#下游回归>)把消费者回归分配给它。确认删除原要求时，按[删除](<../../../../../project-source/skills/feature-sync/references/apply-plan-changes.md#删除>)把原 Feature 设为 `obsolete_done` 并追加删除原因。

**S4｜记录、检查并提交**

追加本次修订记录；基线无法核实时按[记录修订](<../../../../../project-source/skills/feature-sync/references/anchor-and-fallback.md#记录修订>)写明历史未知。然后在游戏项目根目录运行：

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
| S1 | 影响报告：锚点、实质变化、受影响 ID 与状态、已有实现和测试影响；基线无法核实时是对齐报告：检查的 HEAD、对齐缺口、未知历史 |
| S2 | 未批准动作已有用户决定 |
| S3 | 修订后的 AC、依赖和验证映射；退役测试及清理责任、失效证据和需重新批准的部分已写明；新 Feature 的 ID、依赖、AC 和回归安排已写入，原 Feature 的 AC、描述和完成证据无差异 |
| S4 | `FEATURE LIST CHECK: PASS` 和计划提交哈希 |

## 资源与文件影响

- 修改：受影响 Feature 的详情（标题变化时含索引标题）、追加的新 Feature 索引条目与详情、测试登记，以及本次修订记录。
- 读取与保留：GDD、Product 交付范围与专业来源只读，不制造来源收据、旧提交或虚构 R000；测试代码不改；进行中 Feature 已完成且仍有效的成果和已有证据保留；已交付 Feature 的 AC、描述和完成证据不改，删除、拆分或合并时只改状态并追加笔记。

## 阻塞、异常与范围变化

来源尚未改好时先交对应来源的场景；关键来源本身未确认时保留待定，不把基线恢复当作批准所有当前文字；不伪造差异。尚未细化的后续 Product 只处理预拆分影响，不提前创建 Feature。

## 完成状态与验证标准

未开工任务与已提交新要求一致且尚未实施，进行中任务的新范围和剩余义务明确，已交付 Feature 的新变更有独立可执行任务且旧完成历史保持真实；基线无法核实时，获准范围已按当前有效来源对齐，无法恢复的历史明确记录；计划检查通过。

## 流程关联与衔接关系

依据：feature-sync 的[阶段 3：用户审阅与决定](<../../../../../project-source/skills/feature-sync/SKILL.md#阶段-3用户审阅与决定>)和[修订](<../../../../../project-source/skills/feature-sync/references/apply-plan-changes.md#修订>)、[提出当前文档对齐](<../../../../../project-source/skills/feature-sync/references/anchor-and-fallback.md#提出当前文档对齐>)，methodology 02 的[同步记录](<../../../../../project-source/methodology/02-feature-list-schema.md#同步记录>)。
