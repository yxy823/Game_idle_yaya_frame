# 没有 Feature，只想运行指定组件的自动测试

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

改了一个不属于任何 Feature 的通用组件（例如存档序列化工具），想运行对应的现有测试（`tests/` 下，或调试台的 `dev/debug/` 下），看它是否仍然通过。

需要的材料：

- 测试目标（可空）：`tests/` 或 `dev/debug/` 下的测试文件或目录路径，可以给多个。未指定路径、要按已有变更选测时，按下文转到对应入口。
- 运行限制（可空）：例如不得写入真实存档、限时完成；不写则按运行器默认执行。

## 前置条件与适用范围

未指定测试路径、需要按已有变更选测时，转到[已有变更需要重新运行相关自动测试](<已有变更需要重新运行相关自动测试.md>)使用 `--changed`。

目标是现有组件的实际自动测试，没有 Feature ID；不创建虚构任务或完成证据。

## 执行步骤

使用[预设提示词库](../../../prompts/godot-development-prompts.json)中的“Godot 项目开发 → 自动检查与测试 → 没有 Feature，只想运行指定组件的自动测试”。本页由当前 Agent 使用项目自己的 [$run-checks](<../../../../../project-source/skills/run-checks/SKILL.md>)，链接指向框架中的源文件，仅供核对。

**S1｜确认实际目标**

当前 Agent 核对现有测试文件或目录、项目配置和需要覆盖的组件。`--target` 接收真实测试路径，不接收组件名代号。

**S2｜运行目标测试**

在项目根目录以配置 Python 调用 `yaya/tools/testing/run-gdunit-tests.py --target <实际测试文件或目录>`；此时不传互斥的 `--feature`。读取退出码、实际用例与报告。

**S3｜交付组件结果**

交付运行器输出的真实 result.json 和原始报告，区分失败、跳过与零测试。没有 Feature 时不调用 record-tests 建立完成证据。

- 位置与参数：示例在游戏项目根目录执行，将测试目标换成现有文件或目录；`--target` 与 `--feature` 互斥。
- 结果：退出码为零仍需读取实际用例和原始报告。
- 状态边界：此模式按实际目标执行，不添加 Feature 完成证据。

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectPython = $projectConfig.python_executable
& $projectPython -B yaya/tools/testing/run-gdunit-tests.py --target 'tests/<实际组件目录>'
$LASTEXITCODE
```

## 步骤产出与状态变化

| 步骤 | 继续条件 |
| --- | --- |
| S1 | 要运行的测试路径已列出，且都存在 |
| S2 | `reports/gdunit-wrapper/focused/run-<id>/result.json` 已生成，退出码已读取 |
| S3 | 报告列出实际执行、失败、跳过的用例数和原始报告路径 |

## 资源与文件影响

运行创建 reports/gdunit-wrapper/ 下的实际报告及必要缓存；测试代码和任务状态不修改。

## 阻塞、异常与范围变化

目标不存在、运行中断或零测试不能记为通过；组件修复交所属已有授权，不靠创建假 ID 绕过。

## 完成状态与验证标准

指定组件测试已实际执行，原件、覆盖与结果明确；没有生成 Feature 或人工接受。

## 流程关联与衔接关系

依据：[run-gdunit-tests.py](<../../../../../project-source/tools/README.md#run-gdunit-testspy>)、[运行记录](<../../../../../project-source/methodology/08-test-traceability-and-evidence.md#运行记录>)（聚焦运行不授予完成）。

下一步：

- 后来需要按已有变更选测：[已有变更需要重新运行相关自动测试](<已有变更需要重新运行相关自动测试.md>)
