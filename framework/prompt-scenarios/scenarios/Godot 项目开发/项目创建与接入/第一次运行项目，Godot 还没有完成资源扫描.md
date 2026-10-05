# 第一次运行项目，Godot 还没有完成资源扫描

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

第一次运行测试或项目脚本时报找不到 `GdUnitTestCIRunner`、`GdUnitTestSuite` 之类的全局类，或打算在第一次运行前先让 Godot 导入资源。需要的材料：

- **错误信息**（可选）：首次运行的错误原文；运行前的预防性扫描没有错误可填。

## 前置条件与适用范围

环境路径可用，项目尚未生成 Godot 首次扫描所需缓存。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 项目创建与接入 → 第一次运行项目，Godot 还没有完成资源扫描”。填入上述材料。本页由当前 Agent 使用项目自己的 `project-environment-godot` Skill；[源码入口](<../../../../../project-source/skills/project-environment-godot/SKILL.md>)仅供核对。

**S1｜核对扫描缺口**

当前 Agent 对照 `yaya/tools/README.md` 的首次扫描说明和日志，确认是首次项目识别或导入问题。

**S2｜调用实际编辑器扫描**

在项目根目录执行：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectGodot = (Resolve-Path -LiteralPath $projectConfig.engine_executable -ErrorAction Stop).Path
& $projectGodot --headless --editor --path . --quit | Out-Host
$LASTEXITCODE
```

`| Out-Host` 让 PowerShell 等 Godot 结束后再读退出码。读取退出码和扫描、导入诊断原文；失败时保留原文，停止依赖这次扫描的运行。

**S3｜返回原运行**

核对原缺失缓存或资源识别问题，回到此前获准命令；记录扫描与业务运行各自结果。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 错误属于未扫描（例如找不到 `GdUnitTestCIRunner`），不是具体的脚本解析错误 |
| S2 | 扫描命令的退出码和导入诊断原文 |
| S3 | 原命令的实际结果另行记录；扫描生成的 `.import` 已按规则提交 |

## 资源与文件影响

Godot 生成 `.godot/` 导入缓存，不提交；扫描为插件资源生成的 `.import` 随项目提交，生成文件的处理见[首次 Godot 扫描](<../../../../../project-source/tools/README.md#首次-godot-扫描>)。不新增包装脚本或每 Feature 扫描阶段。

## 阻塞、异常与范围变化

实际资源或脚本错误不能靠反复清缓存掩盖；保留日志进入对应修复。

## 完成状态与验证标准

首次扫描完成，原识别缺口解除；后续业务是否通过仍由真实运行判断。

## 流程关联与衔接关系

依据：[项目环境准备](<../../../../../project-source/methodology/06-project-environment.md#项目环境准备>)、[首次 Godot 扫描](<../../../../../project-source/tools/README.md#首次-godot-扫描>)。
