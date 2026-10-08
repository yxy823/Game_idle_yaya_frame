# 代码刚改完，只检查解析和 lint

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

改完几个 GDScript，提交前只想知道它们能否编译、lint 有没有 Critical 或 Warning，暂时不跑自动测试。

需要的材料：

- 要检查的脚本（可空）：`res://` 路径；不提供时由 Agent 从未提交的改动找出改过的脚本。
- 所属 Feature（可空）：Feature ID，决定报告目录；不提供时按维护任务保存到 `reports/maintenance/<task>/`。

## 前置条件与适用范围

只需要 Godot 解析与 linter 的当前结果。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 自动检查与测试 → 代码刚改完，只检查解析和 lint”。填入上述材料。本页由当前 Agent 使用项目自己的 [$project-verification-godot](<../../../../../project-source/skills/project-verification-godot/SKILL.md>)，链接指向框架中的源文件，仅供核对。

**S1｜核对直接命令**

当前 Agent 读取 `yaya/methodology/contracts/gdscript-lint.md` 的[直接运行](<../../../../../project-source/methodology/contracts/gdscript-lint.md#直接运行>)和 `docs/methodology-config.json`，确定要解析的脚本（改动脚本及依赖它们的脚本）和报告目录，不另建包装。

**S2｜执行限定检查**

在项目根目录以配置 Godot 执行：

- 解析检查：对选定脚本逐个执行 `--headless --path . --check-only --script res://<脚本>`，用 `Out-Host` 等待后立即读取退出码。
- lint：随后对完整 `res://` 运行 `addons/gdscript-linter/analyzer/analyze-cli.gd`，按 `gdlint.json` 检查全项目；标准输出用 `Out-Null` 丢弃，读取退出码后从 `lint.json` 的 `summary` 读取 Critical、Warning 和 Info 数量。

替换尖括号参数，报告目录不能覆盖仍需保留的原件；无 Feature 时使用 `reports/maintenance/<任务>/`。

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectGodot = $projectConfig.engine_executable
& $projectGodot --headless --path . --check-only --script 'res://<实际脚本>.gd' | Out-Host
$LASTEXITCODE
$reportDirectory = 'reports/features/<实际FeatureID>/<本次目录>'
New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
& $projectGodot --headless --path . --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --json --output "$reportDirectory/lint.json" res:// | Out-Null
$LASTEXITCODE
```

lint 退出码：3 表示输入或配置错误，2 表示 Critical，1 表示 Warning，0 才是无 Critical/Warning。

**S3｜报告覆盖**

分别报告解析和 lint 的退出码、实际检查的脚本、`summary` 中的数量和未执行部分。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 要解析的脚本清单和报告目录已确定 |
| S2 | 每条解析命令的退出码已读取，`lint.json` 已生成 |
| S3 | 报告列出解析退出码、lint 退出码和 Critical/Warning/Info 数量 |

## 资源与文件影响

原代码只读，写入 `lint.json` 和必要的解析输出；不自动导入、修复或写完成状态。

## 阻塞、异常与范围变化

首次扫描确实缺失时转环境场景，不在每次 lint 前机械增加导入。

## 完成状态与验证标准

指定范围的解析和 lint 已执行并如实报告，失败未被阈值调整掩盖。

## 流程关联与衔接关系

依据：[lint 的退出码](<../../../../../project-source/methodology/contracts/gdscript-lint.md#lint-的退出码>)、[解读结果](<../../../../../project-source/methodology/contracts/gdscript-lint.md#解读结果>)。本入口只承担解析与 lint 检查，不由检查结果授予修复权限。
