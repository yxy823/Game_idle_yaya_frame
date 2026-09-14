# 命令、测试范围与结果解释

[返回手册](../README.md) · 相关：[配置参考](configuration.md)、[故障排查](troubleshooting.md)

所有项目命令在**生成后的项目根目录**运行。按当前任务调用所需入口，以下命令参考不意味着每次都要整页执行。涉及写记录的命令遵循对应 Skill 和已有授权。

## 调用准备

先确认项目配置已经就绪。本页 PowerShell 示例共用以下变量：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectPython = $projectConfig.python_executable
$projectGodot = $projectConfig.environment_bootstrap.engine_executable
```

在本机，`python_executable` 应是个人规则指定并已确认的完整解释器路径。`F001` 和示例脚本路径都需换成实际存在的任务与文件。每条原生命令后立即读取 `$LASTEXITCODE`；缺失退出码不能当作 0。

新项目首次 CLI 测试或项目脚本运行前，按 [首次扫描说明](../../../../project-source/tools/README.md#首次-godot-扫描) 处理编辑器准备；配置 ready 不代替这次扫描。

## 入口与副作用

| 入口 | 常用参数 | 行为 |
| --- | --- | --- |
| `tools/checks/check-project-environment.py` | `--require-ready`、`--config` | 读配置；就绪检查可能启动 Godot `--version`，不写配置 |
| `tools/checks/check-feature-list.py` | `--eligible`、`--completion-feature F001`、`--repo-root` | 读 Feature/测试登记表/历史和依赖，不修改台账、不运行测试 |
| `tools/testing/run-gdunit-tests.py` | `--godot-binary`、`--feature` 或 `--target`、`--phase`、`--scope` | 启动真实 Godot 测试进程，写隔离的运行目录 |
| `.agents/skills/execute-next-feature/scripts/record-feature-completion.py` | 子命令与 `--feature`；全局 `--repo-root` 在子命令之前 | 写入测试/人工/复审记录，或只读展示、校验已有依据 |
| `.agents/skills/generate-feature-list/scripts/merge_test_registry.py` | `--components` | 在项目根目录运行，将批准的组件合并到固定的 `docs/test-registry.json`；属于规划写操作 |

测试登记表合并应使用 `generate-feature-list` 提供的实际输入结构与约束，不用临时生成的空文件替代历史测试登记表。它不负责生成真实测试或证明测试通过。

## 环境与台账检查

```powershell
& $projectPython -B tools/checks/check-project-environment.py --require-ready
$LASTEXITCODE
& $projectPython -B tools/checks/check-feature-list.py
$LASTEXITCODE
& $projectPython -B tools/checks/check-feature-list.py --eligible
$LASTEXITCODE
```

就绪检查细节见 [首次使用](../getting-started/first-use.md)。台账检查读取完整索引、详情、测试登记表和修订关系，检查 ID、字段、引用、路径、依赖与历史规则。`--eligible` 校验后输出依赖已满足的 pending Feature ID 集合，不能代替实现授权。

规划或同步完成后使用这个完整入口即可，它已经包含 JSON 解析；单文件语法检查只用于定位具体错误。Agent 仍需核对需求覆盖、真实依赖和历史保留，这些语义不能由结构检查代替。

`--completion-feature F001` 额外要求当前待完成任务的直接自动验证映射处于 active 状态。正常历史检查可以接受可追溯退役的旧测试；当前完成不能拿已退役测试替代实际验证。

## 三种常见测试调用

在已经批准的任务范围内，按用途选用：

```powershell
# Stage 3：已有安全网，不包含尚未创建的 planned 测试。
& $projectPython -B tools/testing/run-gdunit-tests.py --godot-binary $projectGodot --feature F001 --phase baseline --scope auto
$LASTEXITCODE
```

```powershell
# TDD 或定点诊断：替换成实际已存在的套件或目录。
& $projectPython -B tools/testing/run-gdunit-tests.py --godot-binary $projectGodot --target tests/features/F001/example_test.gd
$LASTEXITCODE
```

```powershell
# Stage 4：读取当前 Feature/测试登记表和已批准范围。
& $projectPython -B tools/testing/run-gdunit-tests.py --godot-binary $projectGodot --feature F001 --scope auto
$LASTEXITCODE
```

`--feature` 与 `--target` 互斥；两者都不传时 target 默认为 `tests`。`--phase` 支持 `baseline`、`final`，默认 final。baseline 和 focused/target 运行用于基线或调试，不能直接作为当前 Feature 完成依据。

其他参数：`--timeout-seconds` 默认 120，必须是大于 0 的有限数；`--require-test` 使用 `<suite-path>::<test-case>` 格式，要求原始报告确实覆盖该用例；`--continue` 传给 gdUnit 的 `-c`，不表示继续一个已有 Yaya 任务或复用上次报告。

运行器启动真实引擎和测试，而非纯文件检查。所需权限、窗口行为与运行范围按当前项目和任务确认；不能因为名字含“测试”就认为无副作用。

## 测试范围怎样计算

Stage 1 的完整测试范围规则见测试规范中的 [Test Impact Review](../../../../project-source/methodology/08-testing-strategy.md#test-impact-review) 与 [Runtime Test Impact selection](../../../../project-source/methodology/08-testing-strategy.md#runtime-test-impact-selection)。下文用中文说明 Required、affected、full 与命令的对应关系。

```text
Required Test Set =
  当前 Feature 的自动验收测试
  + 当前 Feature 的回归测试
  + 影响组件已登记的 unit_test_paths
  + 与影响组件相交的 active 历史回归
  + 与影响组件相交的 active 不变量
  + 已批准的 additional_tests

affected = Required + 与影响组件相交的 active 验收测试
```

| `--scope` | 用途 |
| --- | --- |
| `auto` | 默认执行 affected；当前计划需要全量时升级为 full |
| `required` | 显式运行 Required，适合局部迭代；不能据此绕过最终 affected/full 要求 |
| `affected` | Required 加相关验收测试 |
| `full` | 运行配置的现有测试根目录范围，并核对必需覆盖 |

影响组件设有 `full_suite_on_change`、已批准的 `full_suite_reasons`、广泛工具链影响或无法界定影响时，需要按规范执行 full；工程维护标签本身不触发升级。附加测试及理由保存在 Feature 的 `verification.test_impact`，没有独立计划文件。

没有单元套件的组件使用 `unit_test_paths: []`，不产生虚构选择器。已登记路径丢失、被选中目录零测试、必需用例跳过或报告缺失都不能记为通过。不存在且未登记的测试层不会贡献全量选择器；这不把空项目变成有成功测试证据的项目。

## 一次运行留下什么

每次调用创建 `reports/gdunit-wrapper/run-<id>/`，输出真实 `result.json` 路径。使用命令打印的路径，不猜测 run ID 或报告文件夹编号。

```text
reports/gdunit-wrapper/run-<id>/
├── result.json                 同一个文件从运行中更新为成功或失败
├── engine.log                  原始引擎输出
├── discovery.json              实际展开后的测试发现集合
└── report_<...>/
    ├── results.xml             原始 JUnit
    └── diagnostics.jsonl       运行诊断
```

启动或中途失败时，部分原件可能尚未产生；缺失本身就是要读取的结果，不应补造空报告。实际报告还可能包含 gdUnit 生成的其他文件。

运行器核对过程结果、实际发现集合、JUnit 用例和诊断。参数化用例需要对应真实展开后的集合，源码里存在 `test_*` 方法不证明它实际执行。JUnit 看起来成功也不能遮住引擎错误或未完成运行。

同一内容上的较新失败需要由之后覆盖该失败范围的成功解决；更早成功或更窄的通过不能盖掉它。保留原始失败，再说明修复与后续结果。

## 记录完成依据

完成依据入口位于执行 Skill 的 `scripts/`。下表是参数速查，不是让使用者批量填“通过”的步骤：

| 子命令 | 何时使用 |
| --- | --- |
| `initialize --feature F001` | Stage 2 初始化当前 Feature 依据；会写入当前记录，不作为失败恢复按钮 |
| `record-tests --feature F001 --run <result.json>` | 导入真实 final Feature 运行；必要时重复 `--run` 覆盖不同运行 |
| `record-acceptance --feature F001 --status accepted` | manual 模式下，用户已经明确接受当前范围之后 |
| `record-acceptance --feature F001 --status rejected` | 记录真实拒绝与后续修复需要 |
| `record-smell --feature F001 --must-fix N --suggest N --acceptable N` | 实际完成独立需求/代码复审之后；计数来自复审 |
| `show --feature F001` | 只读查看已有记录 |
| `validate --feature F001` | 检查当前内容对应的完成依据 |

真实报告导入示例：

```powershell
& $projectPython -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py record-tests --feature F001 --run reports/gdunit-wrapper/run-actual-id/result.json
$LASTEXITCODE
```

把 `run-actual-id` 换成刚才输出的目录。原件引用和当前内容绑定用于发现错误复用；脚本不接受手填通过次数来创建成功。`record-tests` 失败会清除旧测试引用并保留原始报告，不能改写结果文件绕过失败。

若有效 manual 计划的 Required、affected 都为空且不要求全量测试，省略自动运行和 `record-tests`，保留 `initialize` 生成的 `test_runs: []`。后续仍按真实结果记录人工接受和复审，再运行完成检查；工具从当前计划计算 `not_required`，不生成空的成功报告。任何自动测试义务、无效映射或当前内容上的未解决失败都会阻止这个分支，不能用重新初始化消除失败。

完成检查由两部分配合，Agent 还要单独确认直接静态检查：

```powershell
& $projectPython -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py validate --feature F001
$LASTEXITCODE
& $projectPython -B tools/checks/check-feature-list.py --completion-feature F001
$LASTEXITCODE
```

生产代码、测试、配置、AC、验证计划和测试登记表等语义内容改变时需要核对依据是否失效；仅改完成时间、notes、整理 Progress 历史、知识 Markdown 或普通使用 `README.md` 不自动要求业务测试重跑。例如，在业务测试通过后补充场景 README，可继续使用同一份有效结果，同时检查说明中的事实、链接和示例。

这不等于排除所有 Markdown：规则、Skill、流程、Product 和 Feature 契约目录中的 README 仍参与验证，知识目录中的非 Markdown 文件也仍参与。使用说明不承载正式需求、规则或可执行输入；确切目录与绑定语义见 [测试规范](../../../../project-source/methodology/08-testing-strategy.md)。

## 直接脚本解析与 lint

从项目根目录，使用同一个已确认 Godot 可执行文件：

```powershell
# 替换成实际变更脚本，并按影响解析必要依赖。
& $projectGodot --headless --path . --check-only --script res://path/to/changed_script.gd | Out-Host
$LASTEXITCODE
```

```powershell
# 每次选用不会覆盖仍需保留原件的报告名称。
& $projectGodot --headless --path . --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --json --output reports/lint-current.json res:// | Out-Host
$LASTEXITCODE
```

对 Windows GUI 可执行文件，`Out-Host` 管道用于等待进程，立即检查退出码。lint 扫描完整 `res://` 并遵循项目配置；修改了被默认排除的依赖时，仍需验证该依赖变更本身。

当前 lint CLI 的退出码：0 表示无问题或仅 Info，1 表示 Warning，2 表示 Critical，3 表示输入无效、空发现、配置错误或 JSON 报告写入失败。`--severity` 和 `--top` 只影响显示，不会抹去真实判定。`--output` 支持 JSON 和 HTML 文件；默认文件名 `code_quality_report.html` 仅用于 HTML。报告真实范围与 Critical/Warning/Info 数量，未知数量不能写成零。

解析证明脚本在实际引擎中的相关语法/类型契约，lint 检查配置的质量规则；两者都不替代运行、资源、场景、导出或人工质量判断。需要编辑器检查时遵循本机项目规则的沙箱外审批路径。普通 Feature 不增加单独导入阶段。

## 退出码和结果边界

环境与台账检查成功通常为 0、校验失败为 2；gdUnit 包装器成功为 0、运行失败为 1，参数解析错误可为 2。最终结论仍结合原始输出和检查范围，不能将不同工具的非零值统一解释为业务测试失败。

| 已有结果 | 可以报告 | 不应推断 |
| --- | --- | --- |
| 配置就绪 | 实际环境检查通过 | 游戏或测试通过 |
| 台账通过 | 数据结构、引用和依赖满足该检查 | AC 已实现 |
| focused 通过 | 指定套件在本次运行成功 | 最终 Required/affected/full 已满足 |
| 完成依据校验通过 | 它负责的测试、人工与复审契约满足 | 脚本解析、lint 或所有目标平台已检查 |
| 静态检查通过 | 已执行静态范围通过 | 手感、外观、声音和导出质量已接受 |

实现来源：[项目工具说明](../../../../project-source/tools/README.md)、[测试运行器](../../../../project-source/tools/testing/run-gdunit-tests.py)、[完成依据入口](../../../../project-source/skills/execute-next-feature/scripts/record-feature-completion.py)、[直接 lint 契约](../../../../project-source/methodology/gdscript-lint.md)。
