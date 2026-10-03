# 项目检查与测试工具

这些命令由 Agent 或使用者显式调用，不监听编辑、对话或工具事件。下文示例中的 `python` 与 Godot 一律换成 `docs/methodology-config.json` 中实际配置的路径。

```text
tools/
├── checks/      环境与台账检查
├── features/    Feature 登记合并、完成记录与人工验收
├── testing/     gdUnit 测试入口及其 Godot 辅助脚本
└── lib/         共享实现
```

| 入口 | 用途 |
| --- | --- |
| [check-feature-list.py](checks/check-feature-list.py) | 检查 Feature、测试登记表、引用和依赖；`--eligible` 列出可开始项 |
| [check-project-environment.py](checks/check-project-environment.py) | 检查配置；`--require-ready` 核对 Python/Godot 文件、固定测试入口文件及实际 Godot 4.7.x 版本，不写配置状态 |
| [run-gdunit-tests.py](testing/run-gdunit-tests.py) | 读取 Feature 与测试登记表，选择并运行 gdUnit 测试，保留实际报告 |
| [merge-test-registry.py](features/merge-test-registry.py) | 将批准的组件合并到测试登记表 |
| [record-feature-completion.py](features/record-feature-completion.py) | 准备人工验收清单，记录测试原件引用与人工决定，查看和检查完成依据 |

命名约定：

- 入口脚本使用连字符命名（如 `run-gdunit-tests.py`），只作为命令运行，不被其他代码导入。
- `lib/` 中的共享模块使用下划线命名，供入口以 `tools.lib.<模块>` 导入；`tools/__init__.py` 与 `lib/__init__.py` 使这种导入成立。
- Skill 只引用这些命令并说明调用时机，不另写命令副本。

资源工作台的分析后端不属于本目录，见[资源工作台说明](../asset_workbench/README.md)。

台账检查、登记表合并和运行选择共用同一套 JSON 解码规则：

- 重复对象键、非标准数值（`NaN`、`Infinity`）以及解析后溢出为无穷的浮点数（如 `1e400`）都会报错；
- 合并器在写回前拒绝这类输入，并保留原件；共享 JSON 写入也拒绝非有限数值；
- 组件候选接受数组，或含 `components` 数组的对象；各入口分别校验自身的数据结构。

## 首次 Godot 扫描

适用条件见[环境配置约定](../methodology/06-project-environment.md#project-environment-bootstrap)。在已获准的首次 CLI 测试或项目脚本运行前，尚未由编辑器扫描的新项目可在项目根目录执行：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectGodot = (Resolve-Path -LiteralPath $projectConfig.engine_executable -ErrorAction Stop).Path
& $projectGodot --headless --editor --path . --quit | Out-Host
$LASTEXITCODE
```

- 按项目 `AGENTS.md` 的本机权限约束执行；`Out-Host` 用于等待 Windows GUI 程序结束。
- 读取退出码和扫描、导入诊断。失败时保留原文，并停止依赖这次准备的运行。
- 正常完成后执行原定测试或脚本；扫描成功本身不证明用例或业务行为通过。

首次测试若报找不到 `GdUnitTestCIRunner` 或 `GdUnitTestSuite`，先核对项目是否已完成扫描。没有发现或执行用例的解析失败，不是 TDD 的业务 RED。完成扫描后仍失败时，继续核对插件文件和具体解析错误，不反复扫描或删除缓存来掩盖原因。生成的 `.import`、`.uid` 与 `.godot` 按[资产规则](../agent-rules/60-assets/README.md)和[引用规则](../agent-rules/00-core/godot-resource-references.md)处理。

## 调用

`python_executable` 支持完整路径、项目相对路径或 PATH 中的命令名；`engine_executable` 使用完整路径或项目相对文件路径，不查询 PATH。两者都不包含 shell 引号或参数。

```powershell
python -B tools/checks/check-project-environment.py --require-ready
python -B tools/checks/check-feature-list.py
python -B tools/testing/run-gdunit-tests.py --feature F001 --scope auto
python -B tools/features/record-feature-completion.py record-tests --feature F001 --run reports/gdunit-wrapper/F001/run-ID/result.json
```

参数名以各脚本的 `--help` 为准。除特别说明外，`--repo-root` 默认是脚本所在的项目，相对路径以目标项目为准，不依赖命令启动时所在的目录。

### check-feature-list.py

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `--repo-root <目录>` | 要检查的项目 | 脚本所在项目 |
| `--completion-feature F0XX` | 另外要求该 Feature 当前映射的自动测试均为 `active` | 不检查 |
| `--eligible` | 通过检查后，以 JSON 输出依赖已满足的待开始 Feature | 不输出 |

退出码：`0` 检查通过；`2` 台账无效或参数错误。

### check-project-environment.py

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `--config <文件>` | 要检查的配置文件；项目根目录取该文件的上两级 | `docs/methodology-config.json` |
| `--require-ready` | 额外核对工具文件、固定测试入口和实际 Godot 版本 | 只检查配置结构 |

退出码：`0` 配置有效（带 `--require-ready` 时表示已就绪）；`2` 配置无效、未就绪或参数错误。

### run-gdunit-tests.py

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `--feature F0XX` | 从当前 Feature 与测试登记表选择测试；与 `--target` 互斥 | 不使用 |
| `--target <路径>` | focused/TDD 运行指定路径；不产生完成证据 | `tests` |
| `--scope <范围>` | 仅在 `--feature` 时决定选择范围：`required` 为必需测试集，`affected` 为受影响测试（含必需测试集），`full` 为 `tests/` 全量，`auto` 在需要全量升级时运行 `full`，否则运行 `affected` | `auto` |
| `--phase <阶段>` | `baseline` 跳过尚未实现的 `planned` 测试，用于已有安全网，不能支持完成；`final` 为最终验证 | `final` |
| `--require-test <套件路径>::<用例>` | 要求本次运行实际执行该用例，否则判为失败；同时禁止返回 `not_required` | 不要求 |
| `--continue` | 传给 gdUnit 的 `-c`：遇到失败后继续执行完整测试集 | 首个失败即停止 |
| `--timeout-seconds <秒>` | 测试进程的最长墙钟时间，须为大于 0 的有限数 | `120` |
| `--godot-binary <路径>` | 仅为本次运行临时替换 Godot 可执行文件 | 配置中的 `engine_executable` |

需要全量时，`--scope auto` 会按批准范围自动升级为 `full`；显式 `--scope full` 用于在迭代中主动运行全量。没有独立的计划文件。

退出码：`0` 测试通过，或返回 `not_required`；`1` 测试失败、选择失败、超时或结果与计划不符；`2` 参数错误。

`not_required` 的条件与含义：

- 只在使用 `--feature`、未指定 `--scope full` 或 `--require-test`，且必需、受影响测试集均为空、也没有全量义务时出现。合法的空基线，或无自动测试义务的 manual 最终验证，属于这种情况。
- 此时 stdout 输出 `status: not_required` 的 JSON，不启动 Godot、不读取引擎配置、不创建运行报告，也不调用 `record-tests`。
- 这不表示测试通过。显式 full 或必需用例、缺失路径以及未解决的最终失败，仍须处理。

### merge-test-registry.py

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `--components <文件>` | 必填。组件候选 JSON，绝对路径或相对目标项目的路径；候选中的测试路径同样以目标项目为准 | 无 |
| `--repo-root <目录>` | 要修改的项目 | 脚本所在项目 |

退出码：`0` 合并成功；`2` 输入或现有登记表冲突、无效，此时不写入（参数错误同样为 `2`）。

### record-feature-completion.py

`--repo-root <目录>` 写在子命令之前，默认是脚本所在项目。所有子命令都要求 `--feature F0XX`。

| 子命令 | 其他参数 | 作用 |
| --- | --- | --- |
| `prepare-manual` | `--checklist <文件>`（必填，位于 `reports/manual-acceptance` 下的待验收清单） | 把清单绑定到当前快照，准备人工验收 |
| `record-tests` | `--run <result.json>`（必填，可重复，用于多次不重叠的真实运行） | 导入真实测试结果引用；被拒绝时清除旧引用，原始报告保留 |
| `record-acceptance` | `--status accepted\|rejected`，或 `--result <文件> --checklist <文件>`（二选一；`--result` 与 `--checklist` 必须同时提供） | 记录口头决定，或导入用户提交的结果 JSON |
| `show` | 无 | 显示该 Feature 的已存记录，不判断能否完成 |
| `validate` | 无 | 检查当前测试与人工依据能否支持完成 |

退出码：`0` 成功（`validate` 表示依据有效）；`2` 依据不足、记录无效、输入被拒绝或参数错误。

人工验收的清单格式、结果 JSON 与确切命令见[人工验收文件契约](../methodology/contracts/manual-acceptance-files.md)。命令成功只表示记录成功，结果仍可能为 `pending` 或 `rejected`；它不调用任何验收应用，也不判断注释的语义。

### 静态检查与资源导入

脚本解析与 lint 由 Agent 直接调用 Godot 和插件，见[直接检查说明](../methodology/contracts/gdscript-lint.md)。没有静态检查的 Python 包装器、静态 manifest 或静态结果登记命令。资源导入由 Godot 处理。

### 运行结果的保存

- **位置**：Feature 运行保存到 `reports/gdunit-wrapper/<Feature-ID>/run-<id>/`，focused/TDD 运行保存到 `reports/gdunit-wrapper/focused/run-<id>/`。
- **内容**：每次测试只写一份 `result.json`，关联引擎日志、实际发现集合、JUnit 和诊断原件。运行中、失败与通过都记录在该文件；完成检查从原件计算覆盖，不维护第二份尝试日志。
- **历史读取警告**：历史结果无法读取或头部无效时，启动阶段在 stderr 提示 `WARNING: invalid run history`，保留原件并继续本次验证；警告不决定本次测试成败。
- **快照失败**：当前快照读取失败时，仍保存本次 `failed` 结果并返回非零，不启动 Godot。
- **完成检查范围**：运行顺序和完成检查只读取当前 Feature 目录。目录内不可读、格式损坏或 Feature 不符的记录会阻止完成，须查明原因后按授权处理。正常的失败须由同一 Feature、同一内容的后续充分验证解决。
- **写入失败**：目录或结果文件写入失败时如实报告 I/O 错误，不能声称结果已经保存。

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

`record-tests` 只导入测试报告，证据检查通过不能证明静态检查已执行。Agent 必须单独确认解析和 lint 的真实结果；未解决的必要检查失败不能宣称完成。失败报告和未完成任务需要的历史要保留，不用旧的成功掩盖后来的失败。

`show --feature F001` 只检查记录可读取、基本结构有效且属于 F001，然后显示原文数据。它不查询 Git，不重读测试或人工验收原件；待验收或已失效的引用不构成查看失败。缺失、损坏或属于另一项 Feature 的记录使 `show` 返回非零，且不会修改原件。判断当前测试与人工依据能否支持完成，使用 `validate --feature F001`。

## 内部实现

| 文件 | 职责 |
| --- | --- |
| `feature_evolution.py` | Feature/测试登记表演进与引用规则 |
| `test_selection.py` | 根据已确定的验收方案和台账选择测试；不从空清单猜测验收方式 |
| `test_run_evidence.py` | 核对真实 JUnit、发现集合、诊断及运行报告 |
| `feature_completion_evidence.py` | 完成记录的结构、快照关联及测试与人工依据的聚合判断；不记录复审计数 |
| `verification_snapshot.py` | Git 提交与当前内容指纹；测试和人工依据共用，不判断任务完成 |
| `atomic_json.py` | 关闭文件流后原子替换 JSON，失败时保留目标原件并清理临时文件 |
| `manual_acceptance.py` | 人工清单覆盖与快照绑定、逐项结果对照和原件复核 |
| `gdunit_process.py` | Windows 子进程归属、超时与退出处理 |
| `gdunit_diagnostics.py` | 解释真实引擎诊断，保留失败事实 |

`testing/` 中的 Godot 脚本是 gdUnit 运行扩展，不是 Agent 动作 Hook：

- `gdunit_evidence_runner.gd` 启动测试并记录发现；
- `gdunit_diagnostic_session.gd` 关联运行诊断；
- `gdunit_diagnostic_logger.gd` 接收 Godot Logger 回调。
