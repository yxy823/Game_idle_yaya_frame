# 代码刚改完，只检查解析和 lint

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

代码刚改完，只检查解析和 lint。

需要的材料：

- 检查对象：改动脚本、当前版本。
- 检查授权：允许的静态检查范围。

## 前置条件与适用范围

只需要 Godot 解析与 linter 的当前结果。

## 执行步骤

使用[集中提示词库](<../../../../prompts.json>)中的“Godot 项目开发 → 验证与收尾 → 代码刚改完，只检查解析和 lint”。填入上述材料；已有对话直接补齐输入，不必重发入口。本页由当前 Agent 使用项目自己的 `project-verification-godot` Skill；[源码入口](<../../../../../project-source/skills/project-verification-godot/SKILL.md>)仅供核对。

**S1｜核对直接命令**

当前 Agent 读取 methodology/gdscript-lint.md 和配置，确认实际插件与参数，不另建包装。

**S2｜执行限定检查**

在项目根目录以配置 Godot 执行：

- 解析检查：对变更脚本及必要依赖执行 --headless --path . --check-only --script res://<脚本>。
- lint：随后对完整 res:// 运行 addons/gdscript-linter/analyzer/analyze-cli.gd。

每条命令经 Out-Host 等待后立即读取退出码。

**S3｜报告覆盖**

说明解析、lint 各自结果与未执行部分；不把静态结果等同功能测试。

- 参数与报告：替换尖括号参数，报告目录不能覆盖仍需保留的原件；无 Feature 时使用 reports/maintenance/<任务>/。
- 检查范围：解析检查选定脚本，lint 按 gdlint.json 检查全项目。
- lint 退出码：3 表示输入或配置错误，2 表示 Critical，1 表示 Warning，0 才是无 Critical/Warning。

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectGodot = $projectConfig.engine_executable
& $projectGodot --headless --path . --check-only --script 'res://<实际脚本>.gd' | Out-Host
$LASTEXITCODE
$reportDirectory = 'reports/features/<实际FeatureID>/<本次目录>'
New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
& $projectGodot --headless --path . --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --json --output "$reportDirectory/lint.json" res:// | Out-Host
$LASTEXITCODE
```

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 命令对应当前工具契约 |
| S2 | 静态错误有原始输出 |
| S3 | 结论与实际检查匹配 |

## 资源与文件影响

原代码只读，运行仅产生必要诊断；不自动导入、修复或写完成状态。

## 阻塞、异常与范围变化

首次扫描确实缺失时转环境场景，不在每次 lint 前机械增加导入。

## 完成状态与验证标准

指定范围的解析和 lint 已执行并如实报告，失败未被阈值调整掩盖。

## 流程关联与衔接关系

依据：[项目路由依据](<../../../../../project-source/methodology/00-overview.md>)、[测试与证据规范](<../../../../../project-source/methodology/08-testing-strategy.md>)、[原生解析与 lint 命令](<../../../../../project-source/methodology/gdscript-lint.md>)。本入口只承担解析与 lint 检查，不由检查结果授予修复权限。用户本次明确只验证时，在结果交付后结束该范围；若检查属于已授权完整任务的步骤，按仍有效的具体授权进入后续所属流程，不因检查结束重复确认。当前明确限制不能由旧授权撤销，检查结果也不代替 Feature 正式完成。
