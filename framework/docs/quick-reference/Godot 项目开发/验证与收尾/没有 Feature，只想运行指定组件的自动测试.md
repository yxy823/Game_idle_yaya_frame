# 没有 Feature，只想运行指定组件的自动测试

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

没有 Feature，只想运行指定组件的自动测试。

准备材料：

- 测试对象：已有测试目标路径、所属组件。
- 影响与授权：改动范围和测试授权。

## 前置条件与适用范围

目标是现有组件的实际自动测试，没有 Feature ID；不创建虚构任务或完成记录。

## 执行步骤

使用[集中提示词库](../../../../prompts.json)中的“Godot 项目开发 → 验证与收尾 → 没有 Feature，只想运行指定组件的自动测试”。已有对话补齐实际材料即可，续接不重新索取已经存在的授权。 本页由当前 Agent 使用项目自己的 `project-verification-godot` Skill；[源码入口](<../../../../../project-source/skills/project-verification-godot/SKILL.md>)仅供核对。

**S1｜确认实际目标**

当前 Agent 核对现有测试文件或目录、项目配置和需要覆盖的组件。`--target` 接收真实测试路径，不接收组件名代号。

**S2｜运行目标测试**

在项目根目录以配置 Python 调用 `tools/testing/run-gdunit-tests.py --target <实际测试文件或目录>`；此时不传互斥的 `--feature`。读取退出码、实际用例与报告。

**S3｜交付组件结果**

交付运行器输出的真实 result.json 和原始报告，区分失败、跳过与零测试。没有 Feature 时不调用 record-tests 建立完成依据。

- 位置与参数：示例在游戏项目根目录执行，将测试目标换成现有文件或目录；`--target` 与 `--feature` 互斥。
- 结果：退出码为零仍需读取实际用例和原始报告。
- 状态边界：此模式按实际目标执行，不添加 Feature 完成记录。

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectPython = $projectConfig.python_executable
& $projectPython -B tools/testing/run-gdunit-tests.py --target 'tests/<实际组件目录>'
$LASTEXITCODE
```

## 步骤产出与状态变化

| 步骤 | 继续条件 |
| --- | --- |
| S1 | 测试对象是存在的路径 |
| S2 | 本次运行已真实结束 |
| S3 | 结果未伪装成 Feature 交付 |

## 资源与文件影响

运行创建 reports/gdunit-wrapper/ 下的实际报告及必要缓存；测试代码和任务状态不修改。

## 阻塞、异常与范围变化

目标不存在、运行中断或零测试不能记为通过；组件修复交所属已有授权，不靠创建假 ID 绕过。

## 完成状态与验证标准

指定组件测试已实际执行，原件、覆盖与结果明确；没有生成 Feature 或人工接受。

## 流程关联与衔接关系

依据：[testing/run-gdunit-tests.py](<../../../../../project-source/tools/testing/run-gdunit-tests.py>)。

本页的分析、记录或验证结论只证明上述目标；后续写入与实施按仍有效的具体授权进入其所属场景，不由建议本身扩大范围。
