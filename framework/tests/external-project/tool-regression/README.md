# 工具回归夹具

[测试与夹具](../../README.md#按需检查) · [验证范围](../../../maintenance/validation/validation-scope.md)

## lint 与运行器专项检查

本目录的 GDScript 夹具验证 lint 与 gdUnit 运行器本身，不随新项目分发，也不要求每次维护都运行。同目录的 Python 工具回归由 [run_project_tool_tests.py](../run_project_tool_tests.py) 统一运行，用法见[维护命令的按需检查](../../README.md#按需检查)。先选择本次获准的外部项目，核对其 Godot、插件和被测工具；首次运行按[项目工具说明](../../../../project-source/tools/README.md#首次-godot-扫描)完成导入。

| 夹具 | 入口与用途 | 输出及副作用 |
| --- | --- | --- |
| `gdscript_lint_contracts.gd` | SceneTree 脚本；检查解析、度量、忽略指令及具体诊断规则 | `--` 后唯一参数是 JSON 报告路径；只在内存中构造被分析代码 |
| `gdscript_lint_entry_contracts.gd` | SceneTree 脚本；检查 CLI 参数、配置拒绝、退出码与 JSON 一致性 | 同上；临时替换根目录 `gdlint.json`，创建 `gdlint-entry-contracts*` 文件，正常结束恢复。已有同名残留时拒绝运行，只用于可丢弃的外部项目 |
| `gdscript_lint_editor_contracts.gd` | 临时 EditorPlugin；检查真实面板加载、控件保存及重建 | 参数为 `--lint-editor-contracts <报告路径>`；临时修改项目配置和本机 `code_quality/*` 编辑器设置，正常结束恢复，不能与其他编辑器实例并行 |
| `gdunit_runner_contracts.gd` | gdUnit 套件；检查真实发现、参数化、预期错误和未处理的引擎错误 | 使用现有运行器及其 `result.json`；设置 `YAYA_RUNNER_REGRESSION_FAILURE=native` 的负向运行应失败，不能算业务测试失败或改报为通过 |

两个 SceneTree 夹具放到外部项目 `tests/contracts/`，报告父目录须先存在。在该项目根目录，用已配置的 Godot 执行所选文件，例如：

```powershell
$validationGodot = (Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json).engine_executable
New-Item -ItemType Directory -Path 'reports/maintenance' -Force
& $validationGodot --headless --path . --script res://tests/contracts/gdscript_lint_contracts.gd -- reports/maintenance/lint-contracts.json | Out-Host
$LASTEXITCODE
```

每轮使用不覆盖旧证据的报告名。核对进程退出码与 JSON 的 `failures`；CLI 夹具内故意触发的拒绝由夹具断言核实，不凭日志出现错误字样就判整项失败。异常中断时先检查备份和临时文件，不能覆盖残留后重跑。

编辑器夹具不能用 `--script` 启动。将它放到外部项目 `addons/maintenance_lint_contracts/`，在同目录建立临时 `plugin.cfg`：

```ini
[plugin]
name="Maintenance lint contracts"
description="Temporary lint editor checks"
author="Framework maintenance"
version="1.0"
script="gdscript_lint_editor_contracts.gd"
```

备份项目配置及相关编辑器设置，把这个插件加入项目的启用列表，再执行 `& $validationGodot --headless --editor --path . -- --lint-editor-contracts reports/maintenance/lint-editor-contracts.json | Out-Host`。检查退出码与报告；结束后恢复临时插件配置，异常中断还需恢复被测设置。不要在日常开发项目中做这一项检查。

运行器夹具放到 `tests/features/gdunit_runner/`。用配置中的 Python 调用 `tools/testing/run-gdunit-tests.py --target tests/features/gdunit_runner`，先确认正常运行通过；再仅为该进程设置上述负向环境变量，确认即使四个断言通过，未处理引擎错误仍使运行器失败。结束后恢复原环境变量，保留两次独立结果；不需要创建 Feature 或填写验收记录。
