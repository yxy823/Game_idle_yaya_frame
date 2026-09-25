# 测试已经通过，但结果没有导入成功

[返回场景索引](../../scenario-index.md#测试与交付) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

运行器已完成本次 Feature 测试，但记录结果时使用了错误的报告路径，完成记录未取得应有的测试引用。

## 前置条件与适用范围

已有满足当前义务的真实成功运行，原始报告完整，内容与当前项目一致，没有尚未解决的较新失败；本次只需修正引用并重新导入。

运行未结束、测试实际失败、原件丢失、覆盖不足或项目内容已改变时，不属于本页的引用恢复。不能靠修改报告或哈希把这些情况变为通过。

## 参与角色与职责边界

Agent 找到并核实原件，调用导入工具；工具检查原件并保存引用。用户不需要为修正路径重复确认已经授权的验证工作。

## 执行步骤

当前 Agent 在 [$feature-execute](../../../../../project-source/skills/feature-execute/SKILL.md)的验证阶段处理本次恢复，直接使用完成依据工具；没有独立的“导入恢复 Skill”或 Agent。

需要重新发起续接时，使用 [集中提示词库](../../../../prompts.json)中的“Godot 项目开发 → 日常开发 → 继续中断的当前任务”，填入实际 Feature ID、原运行目录、错误信息及“仅修正引用并导入”的范围。已有对话中直接补充这些材料即可。

**S1｜找到正确结果**

Agent 从运行器实际输出定位 `reports/gdunit-wrapper/<Feature-ID>/run-<id>/result.json`，检查运行已结束且成功、属于当前 Feature 的最终验证，并读取其引用的原始报告。核实当前内容和覆盖仍满足本次义务，不能只看摘要中的“通过”。

**S2｜准备完整引用组**

Agent 核对本次需要保留的全部兼容运行路径，确认没有尚未解决的较新失败。在游戏项目根目录读取 `docs/methodology-config.json`，取得已确认的 `python_executable`；将下面示例中的 `F0XX` 和运行编号替换为 S1 核实的真实值。

**S3｜重新导入**

Agent 调用 `record-tests`，在同一次调用中列出全部需要保留的 `--run` 参数。该调用以本次整组引用替换旧测试引用；校验失败会清除旧测试引用，但保留原始报告。不要分多次调用来假定引用会累加。

单份结果示例；多份结果在最后一条工具命令中重复添加 `--run <真实路径>`：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectPython = $projectConfig.python_executable
& $projectPython -B tools/features/record-feature-completion.py record-tests --feature F0XX --run "reports/gdunit-wrapper/F0XX/run-<实际编号>/result.json"
$LASTEXITCODE
```

**S4｜查看记录**

Agent 确认 S3 的实际退出码为 0，再用相同项目 Python 查看保存的记录，核对测试引用确实对应 S2 的整组原件：

```powershell
& $projectPython -B tools/features/record-feature-completion.py show --feature F0XX
$LASTEXITCODE
```

核对后回到 `feature-execute` 的剩余验证与完成检查。`show` 只展示已存记录，不证明整个 Feature 已满足完成条件；本页不因修正路径重跑仍有效的测试。

## 步骤产出与状态变化

| 步骤 | 产出与继续条件 |
| --- | --- |
| S1 | 真实成功原件可定位且可用 |
| S2 | 同一次导入需要的全部运行路径已确定 |
| S3 | 导入成功，工具记录对应当前内容的测试引用 |
| S4 | 已保存引用与实际原件一致，可继续其他完成检查 |

## 资源与文件影响

| 项目内对象 | 影响 |
| --- | --- |
| reports/gdunit-wrapper 下的运行结果和原始报告 | 读取与保留，本页不重跑测试或修改原件 |
| 当前 Feature、测试登记及相关内容 | 读取当前验证义务与内容绑定 |
| docs/feature-completion-evidence.json | 导入时创建必要记录或替换测试引用；失败可能清除旧测试引用 |
| 游戏实现与测试代码 | 本页不修改 |

## 阻塞、异常与范围变化

S1 发现原件、内容或覆盖不满足条件时，保留导入错误和已有材料，退出引用恢复，补足实际验证缺口。不能凭摘要或旧成功补写通过。

正确引用仍无法导入时，保留实际错误，查明工具报告的具体缺口后处理；不转人工接受来抵消自动证据缺失。本页不会为了修正报告路径重复运行已有有效测试。

## 完成状态与验证标准

导入命令成功，保存的整组引用对应真实原件，内容和覆盖满足当前测试义务。这里只证明测试引用已恢复；静态检查、专项检查、人工验收和 Feature 收尾仍按原任务继续。

## 流程关联与衔接关系

上游可以是[当前 Feature 修复](../../issues/current-feature/bug-after-tests.md)或[独立 Bug 修复](../../issues/completed-feature/bug-after-delivery.md)的验证。下游为原任务的剩余完成检查。

依据：[实际完成依据工具](../../../../../project-source/tools/features/record-feature-completion.py)、[测试证据规范](../../../../../project-source/methodology/08-testing-strategy.md#artifact-backed-completion-and-semantic-freshness)。
