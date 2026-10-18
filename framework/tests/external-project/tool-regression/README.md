# 工具回归夹具

[测试与夹具](../../README.md#按需检查) · [验证范围](../../../maintenance/validation/validation-scope.md)

本目录保存两类夹具：

- **Python 工具回归**（`test_*.py`）：由 [run_project_tool_tests.py](../run_project_tool_tests.py) 统一运行，用法见[按需检查](../../README.md#按需检查)。
- **GDScript 夹具**：验证 lint 和 gdUnit 运行器本身，用法见下文。

它们都不随新项目分发，也不需要每次维护都运行。

## 运行前准备

1. 选择本次获准使用的外部项目，核对它的 Godot、插件和被测工具版本与本次修改对应。
2. 新项目第一次运行前，按[首次 Godot 扫描](../../../../project-source/tools/README.md#首次-godot-扫描)完成首次导入。
3. 在外部项目根目录准备 Godot 路径变量（后续命令都使用它）：

```powershell
$validationGodot = (Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json).engine_executable
New-Item -ItemType Directory -Path 'reports/maintenance' -Force
```

每次运行使用新的报告文件名，不覆盖旧的证据。

## 夹具一览

| 夹具 | 检查什么 | 副作用 |
| --- | --- | --- |
| `gdscript_lint_contracts.gd` | lint 的解析、度量、忽略指令和具体诊断规则 | 只在内存中构造被分析的代码 |
| `gdscript_lint_entry_contracts.gd` | lint CLI 的参数、配置拒绝、退出码和 JSON 一致性，报告与配置写入失败时保留原文件，以及读不了的目录（用悬空的目录联接模拟） | 临时替换根目录的 `gdlint.json`，并创建 `gdlint-entry-contracts*` 文件，正常结束时恢复。已有同名残留文件时拒绝运行；只能在可丢弃的外部项目中使用 |
| `gdscript_lint_editor_contracts.gd` | 编辑器面板的真实加载、配置缺失时用默认值新建、配置损坏或打不开时阻止扫描、控件保存和重建 | 临时修改项目配置和本机的 `code_quality/*` 编辑器设置，正常结束时恢复；不能与其他编辑器实例同时运行 |
| `measure_3d_contracts.gd` | 3D 占位测量的轮廓计算：包围框、阈值与图片格式、伸出距离、相邻遮挡和轮廓移动 | 只在内存中生成图片 |
| `gdunit_runner_contracts.gd` | 运行器对真实发现、参数化、预期错误和未处理引擎错误的处理 | 使用现有运行器和它的 `result.json` |

## lint 规则与 CLI 夹具

前两个夹具和 `measure_3d_contracts.gd` 是 SceneTree 脚本：

1. 复制到外部项目的 `tests/contracts/`。
2. 在项目根目录运行。`--` 后面唯一的参数是 JSON 报告路径，报告的父目录要已经存在：

```powershell
& $validationGodot --headless --path . --script res://tests/contracts/gdscript_lint_contracts.gd -- reports/maintenance/lint-contracts.json | Out-Host
$LASTEXITCODE
```

3. 核对进程退出码和 JSON 中的 `failures`。CLI 夹具会故意触发一些拒绝，它们由夹具自己的断言核实；日志里出现“错误”字样不代表整项失败。

运行中途异常中断时，先检查备份和临时文件，不能覆盖残留文件后直接重跑。

## lint 编辑器夹具

编辑器夹具不能用 `--script` 启动，要作为临时插件运行：

1. 把它放到外部项目的 `addons/maintenance_lint_contracts/`，在同一目录创建临时的 `plugin.cfg`：

```ini
[plugin]
name="Maintenance lint contracts"
description="Temporary lint editor checks"
author="Framework maintenance"
version="1.0"
script="gdscript_lint_editor_contracts.gd"
```

2. 备份项目配置和相关的编辑器设置，把这个插件加入项目的启用列表。
3. 运行：

```powershell
& $validationGodot --headless --editor --path . -- --lint-editor-contracts reports/maintenance/lint-editor-contracts.json | Out-Host
$LASTEXITCODE
```

4. 检查退出码和报告。
5. 结束后恢复临时插件的配置；运行异常中断时，还要恢复被测的编辑器设置。

不要在日常开发的项目中做这项检查。

## 运行器夹具

1. 把 `gdunit_runner_contracts.gd` 放到外部项目的 `tests/features/gdunit_runner/`。
2. 用项目配置中的 Python 运行 `yaya/tools/testing/run-gdunit-tests.py --target tests/features/gdunit_runner`，确认正常运行通过。
3. 只为这一次运行的进程设置环境变量 `YAYA_RUNNER_REGRESSION_FAILURE=native` 再运行一次。这次应该失败：即使四个断言都通过，未处理的引擎错误仍会让运行器报告失败。这个失败是预期结果，不算业务测试失败，也不能改报为通过。
4. 结束后恢复原来的环境变量，两次运行的结果分别保留。

这项检查不需要创建 Feature，也不需要填写验收记录。
