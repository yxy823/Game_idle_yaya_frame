# 项目检查与测试工具

这些命令由 Agent 或使用者显式调用，不监听编辑、对话或工具事件。 使用 `docs/methodology-config.json` 中实际的 Python/Godot 路径。

```text
tools/
├── checks/      环境与台账检查
├── features/    Feature 登记合并、完成记录与人工验收
├── testing/     gdUnit 测试入口及其 Godot 辅助脚本
├── asset_workbench/  资源与事件预览、试调和分析界面
├── asset_analyzer/   可选的源文件分析后端与依赖声明
└── lib/         共享实现
```

| 入口 | 用途 |
| --- | --- |
| [check-feature-list.py](checks/check-feature-list.py) | 检查 Feature、测试登记表、引用和依赖；`--eligible` 列出可开始项 |
| [check-project-environment.py](checks/check-project-environment.py) | 检查配置；`--require-ready` 核对 Python/Godot 文件、固定测试入口文件及实际 Godot 4.7.x 版本，不写配置状态 |
| [run-gdunit-tests.py](testing/run-gdunit-tests.py) | 读取 Feature/测试登记表，选择并运行 gdUnit 测试，保留实际报告 |
| [merge-test-registry.py](features/merge-test-registry.py) | 将批准的组件合并到测试登记表 |
| [record-feature-completion.py](features/record-feature-completion.py) | 记录测试原件引用与人工决定，或检查已有完成依据 |
| [资源 Analyzer](asset_analyzer/README.md) | 后台音频/图像分析、缓存、图表、分组批量检查与历史快照；开发项目按需安装固定依赖，不参与音频播放 |

公共命令统一位于 `tools/`，Skill 引用命令并说明调用时机。`features/` 保存测试登记合并、完成记录与人工验收操作，`lib/` 保存共享实现。

台账检查、登记表合并和运行选择共用 JSON 解码规则：重复对象键及非标准数值 （`NaN`、`Infinity`）会报错，合并器在写回前拒绝这类输入并保留原件。 组件候选仍接受数组或含 `components` 数组的对象；各入口分别校验自身的数据结构。

## 首次 Godot 扫描

适用条件见 [环境配置约定](../methodology/05-document-language.md#project-environment-bootstrap)。 在已获准的首次 CLI 测试或项目脚本运行前，尚未由编辑器扫描的新项目可在项目根目录执行：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectGodot = (Resolve-Path -LiteralPath $projectConfig.engine_executable -ErrorAction Stop).Path
& $projectGodot --headless --editor --path . --quit | Out-Host
$LASTEXITCODE
```

按项目 `AGENTS.md` 的本机权限约束执行；`Out-Host` 用于等待 Windows GUI 程序结束。 读取退出码和扫描、导入诊断，失败时保留原文并停止依赖这次准备的运行。 正常完成后执行原定测试或脚本；扫描成功本身不证明用例或业务行为通过。

首次测试若报找不到 `GdUnitTestCIRunner` 或 `GdUnitTestSuite`，先核对项目是否已完成扫描。 没有发现或执行用例的解析失败不是 TDD 的业务 RED。完成扫描后仍失败时，继续核对 插件文件和具体解析错误，不反复扫描或删除缓存来掩盖原因。 生成的 `.import`、`.uid` 与 `.godot` 按现有 [资产规则](../agent-rules/60-assets/README.md) 和 [引用规则](../agent-rules/00-core/godot-resource-references.md) 处理。

## 调用

`python_executable` 和 `engine_executable` 保存完整路径， 不包含引号或参数。测试使用固定入口 `tools/testing/run-gdunit-tests.py`，默认读取配置中的 Godot 路径；全量范围用 `--scope full` 指定。

```powershell
python -B tools/checks/check-project-environment.py --require-ready
python -B tools/checks/check-feature-list.py
python -B tools/testing/run-gdunit-tests.py --feature F001 --scope auto
python -B tools/features/record-feature-completion.py record-tests --feature F001 --run reports/gdunit-wrapper/F001/run-ID/result.json
```

将上述 Python 换成配置中的实际解释器；仅需临时更换 Godot 时传入 `--godot-binary <路径>`。 测试的 `--target <path>` 用于 focused/TDD，`--phase baseline` 用于已有安全网。 `auto` 按批准范围选择 affected/full；没有独立计划文件。合法空基线或无自动测试义务的 manual 最终验证返回 0，并在 stdout 输出 `status: not_required` 的 JSON，不启动 Godot、不读取引擎配置或创建运行报告，也不调用 `record-tests`。这不表示测试通过；显式 full/必需用例、缺失路径及未解决的最终失败仍须处理。

脚本解析与 lint 由 Agent 直接调用 Godot 和插件，见 [直接检查说明](../methodology/gdscript-lint.md)。没有静态检查 Python 包装器、 静态 manifest 或静态结果登记命令。资源导入由 Godot 处理。

Feature 运行保存到 `reports/gdunit-wrapper/<Feature-ID>/run-<id>/`，focused/TDD 运行保存到 `reports/gdunit-wrapper/focused/run-<id>/`。每次测试只写一份 `result.json`，关联引擎日志、实际发现集合、JUnit 和诊断原件。 运行中、失败与通过都保存在该文件；完成检查从原件计算覆盖，不维护第二份尝试日志。 历史结果无法读取或头部无效时，启动阶段在 stderr 提示 `WARNING: invalid run history`， 保留原件并继续本次验证；警告不决定本次测试成败。当前快照读取失败仍保存本次 `failed` 结果并返回非零，不启动 Godot。 运行顺序和完成检查只读取当前 Feature 目录。目录内不可读、格式损坏或 Feature 不符的记录仍会阻止完成，须查明原因后按授权处理。正常的失败仍须由同 Feature/内容的后续充分验证解决。 目录或结果文件写入失败时如实报告 I/O 错误，不能声称结果已经保存。

## 结果如何使用

```mermaid
flowchart TD
    A[Feature 与测试登记表] --> B[gdUnit 测试入口]
    B --> C[真实测试报告]
    C --> D[Skill 记录并核对测试证据]
    E[适用的人工验收] --> D
    F[Agent 直接执行脚本解析和 lint] --> G[读取退出码和原始报告]
    D --> H[Agent 综合全部适用检查]
    G --> H
    R[用户指定的评审条件] --> H
    H --> I[通过后记录完成]
```

`record-tests` 只导入测试报告。证据脚本通过不能证明静态检查已执行。 Agent 必须单独确认解析和 lint 的真实结果；未解决的必要检查失败不能宣称完成。 失败报告和未完成任务需要的历史保留，不用旧成功掩盖后来失败。

人工验收的清单准备、JSON 结果读取与口头反馈沿用完成记录入口，格式及确切命令见 [人工验收文件契约](../methodology/manual-acceptance-files.md)。命令成功只表示记录成功， 结果仍可能为 `pending` 或 `rejected`；它不调用任何验收应用，也不判断注释的语义。

## 内部实现

| 文件 | 职责 |
| --- | --- |
| `feature_evolution.py` | Feature/测试登记表演进与引用规则 |
| `test_selection.py` | 根据已确定的验收方案和台账选择测试；不从空清单猜测验收方式 |
| `test_run_evidence.py` | 核对真实 JUnit、发现集合、诊断及运行报告 |
| `feature_completion_evidence.py` | 当前源码指纹、真实测试依据和适用人工接受；不记录复审计数 |
| `manual_acceptance.py` | 人工清单覆盖与快照绑定、逐项结果对照和原件复核 |
| `gdunit_process.py` | Windows 子进程归属、超时与退出处理 |
| `gdunit_diagnostics.py` | 解释真实引擎诊断，保留失败事实 |

`testing/` 中 `gdunit_evidence_runner.gd` 启动测试并记录发现， `gdunit_diagnostic_session.gd` 关联运行诊断， `gdunit_diagnostic_logger.gd` 接收 Godot Logger 回调。 这是 gdUnit 运行扩展，不是 Agent 动作 Hook。
