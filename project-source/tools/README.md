# 项目检查与测试工具

这些命令由 Agent 或使用者显式调用，不监听编辑、对话或工具事件。下文示例中的 `python` 与 Godot 一律换成 `docs/methodology-config.json` 中实际配置的路径。

```text
yaya/tools/
├── checks/      环境、Feature 记录与文件格式检查
├── features/    Feature 登记合并、完成记录与人工验收
├── testing/     gdUnit 测试入口及其 Godot 辅助脚本
├── godot/       由 Godot 执行的项目文件维护脚本
└── lib/         共享实现
```

| 入口 | 用途 |
| --- | --- |
| [check-feature-list.py](checks/check-feature-list.py) | 检查 Feature、测试登记表、引用和依赖；`--eligible` 列出可开始项 |
| [check-project-environment.py](checks/check-project-environment.py) | 检查配置；`--require-ready` 核对 Python/Godot 文件、固定测试入口文件及实际 Godot 4.7.x 版本，不写配置状态 |
| [check-markdown-links.py](checks/check-markdown-links.py) | 检查 Markdown 中的相对链接目标和标题锚点是否存在 |
| [check-godot-resource-format.py](checks/check-godot-resource-format.py) | 检查 `.tscn`、`.tres` 是否按编辑器格式保存：带 UID、没有 `load_steps` |
| [run-gdunit-tests.py](testing/run-gdunit-tests.py) | 读取 Feature 与测试登记表，选择并运行 gdUnit 测试，保留实际报告 |
| [merge-test-registry.py](features/merge-test-registry.py) | 将批准的组件合并到测试登记表 |
| [record-feature-completion.py](features/record-feature-completion.py) | 准备人工验收清单，记录测试原件引用与人工决定，查看和检查完成依据 |
| [resave_godot_files.gd](godot/resave_godot_files.gd) | 用 Godot 自己的格式重新保存 `project.godot` 和指定的 `.tscn`、`.tres` |

命名约定：

- Python 入口脚本使用连字符命名（如 `run-gdunit-tests.py`），只作为命令运行，不被其他代码导入；GDScript 脚本按 GDScript 约定使用下划线。
- `lib/` 中的共享模块使用下划线命名，供入口以 `tools.lib.<模块>` 导入；`yaya/tools/__init__.py` 与 `lib/__init__.py` 使这种导入成立。
- Skill 只引用这些命令并说明调用时机，不另写命令副本。

资源工作台的分析后端不属于本目录，见[资源工作台说明](../asset_workbench/README.md)。

Feature 记录检查、登记表合并和运行选择共用同一套 JSON 解码规则：

- 重复对象键、非标准数值（`NaN`、`Infinity`）以及解析后溢出为无穷的浮点数（如 `1e400`）都会报错；
- 合并器在写回前拒绝这类输入，并保留原件；共享 JSON 写入也拒绝非有限数值；
- 组件候选接受数组，或含 `components` 数组的对象；各入口分别校验自身的数据结构。

## 首次 Godot 扫描

适用条件见[环境配置约定](../methodology/06-project-environment.md#项目环境准备)。在已获准的首次 CLI 测试或项目脚本运行前，尚未由编辑器扫描的新项目可在项目根目录执行：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectGodot = (Resolve-Path -LiteralPath $projectConfig.engine_executable -ErrorAction Stop).Path
& $projectGodot --headless --editor --path . --quit | Out-Host
$LASTEXITCODE
```

- 按项目 `AGENTS.md` 的本机权限约束执行；`Out-Host` 用于等待 Windows GUI 程序结束。
- 读取退出码和扫描、导入诊断。失败时保留原文，并停止依赖这次准备的运行。
- 正常完成后执行原定测试或脚本；扫描成功本身不证明用例或业务行为通过。

新增脚本或资源后，Godot 在下一次扫描时才为它们生成 `.uid`；`.uid` 计入内容指纹，所以先用上面的命令扫描一次，再做最终测试运行，避免运行结束后才生成的 `.uid` 让证据失效。

首次测试若报找不到 `GdUnitTestCIRunner` 或 `GdUnitTestSuite`，先核对项目是否已完成扫描。没有发现或执行用例的解析失败，不是 TDD 的业务 RED。完成扫描后仍失败时，继续核对插件文件和具体解析错误，不反复扫描或删除缓存来掩盖原因。生成的 `.import`、`.uid` 与 `.godot` 按[资产规则](../agent-rules/60-assets/README.md)和[引用规则](../agent-rules/00-core/godot-resource-references.md)处理；首次扫描为插件资源生成的 `.import` 随项目提交。

## 启动场景冒烟检查

确认一个场景能加载并运行若干帧时，在项目根目录执行（`$projectGodot` 的取法同上一节）：

```powershell
& $projectGodot --headless --path . res://main/main.tscn --quit-after 120 2>&1 | Tee-Object -FilePath <日志路径> | Out-Host
$LASTEXITCODE
```

- 把 `res://main/main.tscn` 换成要检查的场景；`--quit-after` 是运行的帧数上限，到达后 Godot 自行退出。
- `| Out-Host` 让 PowerShell 等 Godot 结束后再读退出码；`2>&1` 把错误输出一起写进日志。日志目录按 [09 的报告与清理](../methodology/09-records-reports-and-handoff.md#报告与清理) 选择。
- 退出码非 `0` 表示启动失败，例如场景文件不存在或无法加载。
- 退出码 `0` 不代表没有脚本错误：脚本解析错误和运行时脚本错误都只打印在输出里，退出码仍是 `0`。所以要检查输出中的 `ERROR`、`SCRIPT ERROR` 和紧随其后的 `at:` 行（错误所在的文件和行号）。
- 这项检查只证明场景能加载并运行到帧数上限。`--headless` 不渲染画面，不能说明画面正确；能启动也不等于人工验收。

## 本地导出检查

导出一个 debug 包，在本机独立运行，确认游戏离开编辑器也能正常工作。这不是发布：不涉及签名、商店或分发配置。

**一次性准备**：

- **导出模板**：版本必须和项目的 Godot 一致，在编辑器的“编辑器 → 管理导出模板”中下载安装，由用户完成。
- **导出预设**：新项目没有 `export_presets.cfg`。第一次导出前，在项目根目录写一份只含一个 Windows Desktop 预设的最小文件，名称 `Windows Local`，导出路径留空：

  ```ini
  [preset.0]

  name="Windows Local"
  platform="Windows Desktop"
  runnable=true
  export_filter="all_resources"
  include_filter=""
  exclude_filter="tests/*, addons/gdUnit4/*, reports/*, dev/*, yaya/tools/*, yaya/asset_workbench/ui/*, yaya/asset_workbench/analyzer/*"
  export_path=""

  [preset.0.options]

  binary_format/embed_pck=false
  ```

  排除的依据见 [资源与过滤](../agent-rules/41-export-config/resources-and-filters.md) 和 [测试目录与导出](../agent-rules/70-tests/production-isolation.md#测试目录与导出)。没有写出的字段由 Godot 使用默认值，写好后直接用实际导出验证，通过后提交。注意：`[preset.0.options]` 下至少要有一个键，空段会被当成不存在，导出时报 `Cannot get keys from nonexistent section`。之后结构性的预设修改，在编辑器的“项目 → 导出”中进行。

**导出并启动**（在项目根目录执行，`$projectGodot` 的取法见[首次 Godot 扫描](#首次-godot-扫描)）：

```powershell
$exportDirectory = 'reports/exports/<日期>'
New-Item -ItemType Directory -Path $exportDirectory -Force | Out-Null
& $projectGodot --headless --path . --export-debug 'Windows Local' "$exportDirectory/game.exe" 2>&1 | Tee-Object -FilePath "$exportDirectory/export.log" | Out-Host
$LASTEXITCODE
& "$exportDirectory/game.exe" --headless --quit-after 120 2>&1 | Tee-Object -FilePath "$exportDirectory/run.log" | Out-Host
$LASTEXITCODE
```

- 输出放在 `reports/exports/` 下：这个目录不进 Git，也不会被 Godot 当成项目资源扫描。目标目录必须事先存在，否则导出失败。
- 导出成功时，目录中有 `game.exe`、`game.pck` 和 `game.console.exe`（带控制台窗口的启动器，双击它可以看到运行输出）。导出退出码非 `0`、缺少这些文件，或日志中有退出时资源泄漏提示（`leaked`、`still in use`、`PagedAllocator`）以外的 `ERROR`，表示导出有问题；常见原因是缺少对应版本的导出模板，或预设名称写错。
- 导出包的启动检查和[启动场景冒烟检查](#启动场景冒烟检查)一样：退出码 `0` 不代表没有脚本错误，要检查输出中的 `ERROR`、`SCRIPT ERROR` 和 `at:` 行。常见的问题是运行时用到的文件被过滤掉了，或者代码引用了 `res://` 下只在编辑器中存在的路径。
- 这项检查只证明导出包能启动并运行到帧数上限。画面、声音和操作是否正常，需要用户直接双击 `game.exe` 实际试玩。

## 调用

`python_executable` 支持完整路径、项目相对路径或 PATH 中的命令名；`engine_executable` 使用完整路径或项目相对文件路径，不查询 PATH。两者都不包含 shell 引号或参数。

```powershell
python -B yaya/tools/checks/check-project-environment.py --require-ready
python -B yaya/tools/checks/check-feature-list.py
python -B yaya/tools/testing/run-gdunit-tests.py --feature F001 --scope auto
python -B yaya/tools/features/record-feature-completion.py record-tests --feature F001 --run reports/gdunit-wrapper/F001/run-ID/result.json
```

参数名以各脚本的 `--help` 为准。除特别说明外，`--repo-root` 默认是脚本所在的项目，相对路径以目标项目为准，不依赖命令启动时所在的目录。

### check-feature-list.py

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `--repo-root <目录>` | 要检查的项目 | 脚本所在项目 |
| `--completion-feature F0XX` | 另外要求该 Feature 当前映射的自动测试均为 `active` | 不检查 |
| `--eligible` | 通过检查后，以 JSON 输出依赖已满足的待开始 Feature | 不输出 |

通过时打印 `FEATURE LIST CHECK: PASS`；带 `--eligible` 时标准输出只有 JSON，便于直接解析。

退出码：`0` 检查通过；`2` Feature 记录无效或参数错误。

### check-project-environment.py

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `--config <文件>` | 要检查的配置文件；项目根目录取该文件的上两级 | `docs/methodology-config.json` |
| `--require-ready` | 额外核对工具文件、固定测试入口和实际 Godot 版本 | 只检查配置结构 |

退出码：`0` 配置有效（带 `--require-ready` 时表示已就绪）；`2` 配置无效、未就绪或参数错误。

### check-markdown-links.py

移动、重命名文档或修改标题后运行，也可以在整理文档后整体运行一次：

```powershell
python -B yaya/tools/checks/check-markdown-links.py
```

检查范围：

- **检查的链接**：行内链接、`<路径>` 写法与引用式定义中的本地目标；目标是 Markdown 文件且带 `#锚点` 时，再核对锚点。
- **锚点规则**：按 GitHub 规则由标题生成，即去掉标点和格式符号、转小写、空格变 `-`，中文保留；重名标题依次加 `-1`、`-2`。`<a id="…">` 也算锚点。
- **不检查**：外部网址、代码块和行内代码里的内容。以 `/` 开头的路径不可移植，直接报告。
- **默认排除**：任意层级名为 `.git`、`.godot`、`.claude`、`tmp`、`addons`、`__pycache__` 的目录中的 Markdown 不检查；指向这些目录的链接仍会核对目标。

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `--root <目录>` | 要检查的目录 | 脚本所在项目 |
| `--exclude <路径>` | 另外排除相对 `--root` 的路径，可重复 | 只用默认排除 |
| `--json` | 以 JSON 输出文件数、链接数和失效列表 | 逐行输出 |

退出码：`0` 没有失效链接；`1` 存在失效链接；`2` 参数或读取错误。通过只证明链接目标存在，不证明读者能找到所需内容。

### check-godot-resource-format.py

以文本方式写过 `.tscn`、`.tres` 却漏了[重新保存](#resave_godot_filesgd)，下次打开编辑器时会被改写，产生与当前工作无关的差异。本检查在 Feature 完成时运行，也可以在重存后单独运行：

```powershell
python -B yaya/tools/checks/check-godot-resource-format.py
```

- **检查内容**：文件头带 `uid`、不含 `load_steps`，每条 `[ext_resource]` 带 `uid`。
- **默认范围**：项目内全部 `.tscn`、`.tres`；跳过任意层级名为 `.git`、`.godot`、`.claude`、`tmp`、`reports`、`addons` 的目录和含 `.gdignore` 的目录。也可以在参数中列出相对项目根目录的文件，只查这些。
- **局限**：只发现漏掉重存这一种情况；编辑器保存时的其他格式调整不在检查范围内。

退出码：`0` 全部符合；`1` 有文件不符合，逐行列出位置和原因，用 `resave_godot_files.gd` 重存后重跑；`2` 项目根目录不存在或文件读取失败。

### run-gdunit-tests.py

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `--feature F0XX` | 从当前 Feature 与测试登记表选择测试；与 `--target` 互斥 | 不使用 |
| `--target <路径>` | focused/TDD 运行指定路径；可重复，多个路径在同一次运行中全部执行，重叠的目标只运行一次；不产生完成证据 | `tests` |
| `--scope <范围>` | 仅在 `--feature` 时决定选择范围：`required` 为必需测试集，`affected` 为受影响测试（含必需测试集），`full` 为 `tests/` 全量，`auto` 在需要全量升级时运行 `full`，否则运行 `affected` | `auto` |
| `--phase <阶段>` | `baseline` 跳过尚未实现的 `planned` 测试，用于已有安全网，不能支持完成；`final` 为最终验证 | `final` |
| `--require-test <套件路径>::<用例>` | 要求本次运行实际执行该用例，否则判为失败；同时禁止返回 `not_required` | 不要求 |
| `--continue` | 传给 gdUnit 的 `-c`：遇到失败后继续执行完整测试集 | 首个失败即停止 |
| `--verbose` | 把 Godot 的完整输出打印到控制台 | 只打印摘要：用例数、每个未通过用例的位置与原因，以及 `engine.log` 路径；找不到 JUnit 报告时打印输出的最后 20 行 |
| `--timeout-seconds <秒>` | 测试进程的最长墙钟时间，须为大于 0 的有限数 | `120` |
| `--godot-binary <路径>` | 仅为本次运行临时替换 Godot 可执行文件 | 配置中的 `engine_executable` |

完整输出始终保存在运行目录的 `engine.log`；摘要不够判断时先读它，不必重跑。需要全量时，`--scope auto` 会按批准范围自动升级为 `full`；显式 `--scope full` 用于在迭代中主动运行全量。没有独立的计划文件。

退出码：`0` 测试通过，或返回 `not_required`；`1` 测试失败、选择失败、超时或结果与计划不符；`2` 参数错误。

所选范围的登记用例缺失时报告 FAIL。

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

`--repo-root <目录>` 写在子命令之前，默认是脚本所在项目。所有子命令都要求 `--feature F0XX`，记录写在该 Feature 自己的 `docs/features/F0XX-evidence.json`，第一次记录时创建。

| 子命令 | 其他参数 | 作用 |
| --- | --- | --- |
| `prepare-manual` | `--checklist <文件>`（必填，位于 `reports/manual-acceptance` 下的待验收清单） | 把清单绑定到当前快照，准备人工验收 |
| `record-tests` | `--run <result.json>`（必填，可重复，用于多次不重叠的真实运行） | 导入真实测试结果引用；被拒绝时清除旧引用，原始报告保留 |
| `record-acceptance` | `--checklist <文件>`（必填，已绑定的清单，状态已按用户的结论填写）；`--confirm-unrelated-changes`（可选，绑定之后变化的文件都不涉及本 Feature 时使用） | 从清单的状态推导并记录验收结论；同一结论重复记录时给出提示 |
| `show` | 无 | 显示该 Feature 的已存记录，不判断能否完成 |
| `validate` | 无 | 检查当前测试与人工依据能否支持完成 |

退出码：`0` 成功（`validate` 表示依据有效）；`2` 依据不足、记录无效、输入被拒绝或参数错误。

人工验收的清单格式、怎样在清单中记录用户的结论，以及确切命令见[人工验收文件契约](../methodology/contracts/manual-acceptance-files.md)。命令成功只表示记录成功，结果仍可能为 `pending` 或 `rejected`；它不调用任何验收应用，也不判断注释的语义。

### resave_godot_files.gd

Agent 以文本方式新建或修改 `project.godot`、`.tscn` 或 `.tres` 后，调用本工具重新保存。工具在编辑器模式下补齐场景和资源的文件头与外部引用 UID，移除 `load_steps`；重复重存保持稳定。

```powershell
& $projectGodot --headless --editor --path . --script res://yaya/tools/godot/resave_godot_files.gd -- project.godot res://main/main.tscn | Out-Host
$LASTEXITCODE
```

- `--` 之后列出要重新保存的文件：`project.godot`，或 `res://` 下的 `.tscn`、`.tres`。
- 新建的依赖场景或资源也要一起传入，已有但尚无 UID 的依赖同样需要列出。工具只重存传入文件，不自动扩展依赖列表。
- 工具等待编辑器扫描和导入完成，再重存场景和资源；随后主动重扫并重存第二轮，补齐同批资源之间的引用 UID。调用方不需要另跑两轮命令。
- `project.godot` 重新保存时，等于引擎默认值的设置会被删除；依赖默认值时按[项目设置规则](../agent-rules/40-project-config/authoring-and-scope.md#编写)在测试中断言生效值。
- `project.godot` 只在首轮保存，不参与资源的第二轮重存。
- 场景和资源保存回原路径，已有的资源 ID 保留；文字里的 `\n` 转义会改写成真实换行，只发生一次。
- 真正在编辑器中编辑并保存场景，还可能生成节点 `unique_id` 或省略默认属性；本工具不承诺这次编辑器保存后没有文本差异。
- 退出码：`0` 全部保存成功；`1` 路径不支持或有文件无法加载、保存，原因见 `ERROR` 输出；`2` 未在编辑器模式运行或没有传入文件。
- 编辑器模式退出时可能打印 RID 或 ObjectDB 泄漏信息，这是引擎退出时的输出，不代表保存失败；以退出码和上面的 `ERROR` 为准。
- 编辑器开着时，用户切回编辑器窗口，Godot 会弹出“文件已在 Godot 外部被修改”，列出 `project.godot`。选“从磁盘重新加载”即可读到这次修改；选“忽略外部修改”后再在编辑器里保存，会覆盖这次修改。所以修改了 `project.godot` 时，在交付中提醒用户看到这个提示时选“从磁盘重新加载”。

### 静态检查与资源导入

脚本解析与 lint 由 Agent 直接调用 Godot 和插件，见[直接检查说明](../methodology/contracts/gdscript-lint.md)。它们没有 Python 包装器、静态 manifest 或静态结果登记命令。资源导入由 Godot 处理。

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
| `test_selection.py` | 根据已确定的验收方案和 Feature 记录选择测试；不从空清单猜测验收方式 |
| `test_run_evidence.py` | 核对真实 JUnit、发现集合、诊断及运行报告 |
| `feature_completion_evidence.py` | 完成记录的结构、快照关联及测试与人工依据的聚合判断；不记录复审计数 |
| `verification_snapshot.py` | Git 提交与当前内容指纹；测试和人工依据共用，不判断任务完成 |
| `atomic_json.py` | 关闭文件流后原子替换 JSON，失败时保留目标原件并清理临时文件 |
| `manual_acceptance.py` | 人工清单覆盖与快照绑定、逐项结果对照和原件复核 |
| `gdunit_process.py` | Windows 子进程归属、超时与退出处理 |
| `gdunit_diagnostics.py` | 解释真实引擎诊断，保留失败事实 |

`godot/resave_godot_files.gd` 只在显式调用时运行，用法见上文。`testing/` 中的 Godot 脚本是 gdUnit 运行扩展，不是 Agent 动作 Hook：

- `gdunit_evidence_runner.gd` 启动测试并记录发现；
- `gdunit_diagnostic_session.gd` 关联运行诊断；
- `gdunit_diagnostic_logger.gd` 接收 Godot Logger 回调。
