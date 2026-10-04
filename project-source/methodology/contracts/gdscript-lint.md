# GDScript lint 的约定与证据

Godot 解析器和随附的 linter 检查的内容不同。解析器判断脚本能否在目标 Godot 版本上编译。linter 按项目的 `gdlint.json` 报告风格和规模方面的信号。Agent 直接运行这两者；没有包装脚本。

本页说明 Agent 怎样解读它们的结果。linter 打过补丁的行为和实现细节记录在 [YAYA_PATCH.md](../../addons/gdscript-linter/YAYA_PATCH.md)。

运行 Godot 编辑器检查或导入检查之前，按 [Windows 编辑器检查](../../agent-rules/00-core/windows-editor-check.md) 操作。

## 直接运行

使用 `docs/methodology-config.json` 中记录的 Godot 可执行文件，从项目目录运行：

```powershell
# $godot 是配置的可执行文件路径；从项目目录运行。
& $godot --headless --path . --check-only --script res://path/to/changed_script.gd | Out-Host
$LASTEXITCODE
# 把 F001 换成实际的 Feature；需要时使用一个未用过的运行子目录。
$reportDirectory = 'reports/features/F001'
New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
& $godot --headless --path . --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --json --output "$reportDirectory/lint.json" res:// | Out-Host
$LASTEXITCODE
```

- 使用 Windows GUI 可执行文件时，PowerShell 管道会等待进程结束。立即读取 `$LASTEXITCODE`；退出值为空不代表检查成功。
- 按实际影响，解析改动过的项目脚本以及依赖它们的脚本。
- lint CLI 对完整的 `res://` 范围运行，它遵循 `gdlint.json`。当任务本身修改了某个依赖时，该文件中对这个依赖的排除不能豁免检查。
- 不属于 Feature 的工作使用 `reports/maintenance/<task>/`。保存的解析输出放在同一个任务目录，不放进 scratch。路径的选择和原件的保留按[报告与清理](../09-records-reports-and-handoff.md#报告与清理)处理。

## lint 的退出码

| 退出码 | 含义 |
| --- | --- |
| 0 | 没有问题，或只有 Info 级发现 |
| 1 | 有 Warning 级发现 |
| 2 | 有 Critical 级发现 |
| 3 | 输入无效或为空、配置文件缺失或无法读取、`--check` ID 未知，或 JSON 输出出错 |

退出码 3 永远不能借助降级策略或关闭检查变成一次成功的运行。显示过滤器不能改变结论。

## 解读结果

立即检查每条命令的退出码和原始输出。

- 保留失败结果。不要覆盖尚未解决的任务仍需要的报告；要保留之前的运行时，使用不同的文件名或运行子目录。
- 报告实际检查的范围、Critical、Warning 和 Info 的数量，以及没有运行的检查。数量未知不等于零。
- 必需的解析或 lint 失败尚未解决时，即使测试证据辅助工具通过，也会阻塞完成。跟踪这一点是 Agent 的工作；没有记录它的状态文件。

### 指标只是信号

行数、复杂度和嵌套深度是审核信号，不是证明。选择修复方式之前，先阅读报告的数值和函数的职责。

| 字段 | 含义 |
| --- | --- |
| `physical_lines` | 物理源码行数，包括空行和注释。空文本为零行，末尾的换行不增加行数，CRLF 和 LF 计数相同。 |
| `code_lines` | 屏蔽注释和字符串之后，包含代码或字面量内容的行；空行和只有注释的行不计入。它不是语句数。 |
| 函数范围 | 从具名声明开始，到它自己的函数体结束，包括多行签名的各行。不包括之后缩进更浅的成员和下一个函数的文档注释；多行字符串或表达式不会让函数提前结束。 |
| `complexity` | 1 加上每个 `if`、`elif`、`for`、`while`、`match`、`and`、`or`、`&&` 和 `\|\|`；三元 `if` 计一次。注释和字符串不计入。它是词法上的指标，不是控制流证明；match 分支和 lambda 不单独建模。 |
| `max_nesting` | 函数体各行的相对缩进，忽略注释和续行。它是缩进指标，不是 AST 深度。 |

- `gdlint.json` 中的 `metrics.file_length` 和 `metrics.function_length` 选择 `physical` 或 `code`；字段缺失时为 `physical`。两种值都会报告，每个函数还会报告它选用的 `length_metric` 和 `line_count`。
- 把某个阈值改成 `code` 属于配置修改，要经过工程变更评审。不要悄悄改变阈值的含义。
- 保留必要的注释。删掉说明，或把连贯的工作拆成只做转发的函数，都不是质量改进。
- 私有、静态和多行方法按同样的方式度量。私有名称不能豁免指标或返回类型检查。引擎虚方法只能通过明确的名称清单免除返回类型检查。匿名 lambda 不算作具名方法。
- 未使用名称的检查是词法上的启发式判断。原生编译器的诊断仍是权威。
- 魔法数字的 Info 是审核信号。检查用具名常量是否会让代码更好；不要为了消除误报而重命名标识符或修改阈值。`get_sha256` 这类标识符中的数字和字符串中的数字不会被报告。

### `engine-parameter-contract` Info

Godot 的 `Logger._log_error` 虚回调要求八个参数，所以它的参数个数由引擎决定。linter 对这个回调仍会报告 `params: 8`。当项目的参数上限更低时，它会追加一条 `engine-parameter-contract` Info，说明这一项参数个数指标属于引擎接口。

- 回调签名保持引擎定义的样子。
- 这条 Info 只涉及参数个数。长度、复杂度、嵌套和原生签名校验仍然适用。
- 其他任何八参数方法仍会得到正常的参数个数发现。哪些声明符合条件，见 [YAYA_PATCH.md](../../addons/gdscript-linter/YAYA_PATCH.md)。
- 不能用文件名、忽略指令或全局阈值来获得这种处理。

## 编辑器面板与资源导入

可选的编辑器面板从同一个 `gdlint.json` 读取分析设置。个人的显示、导出和过滤偏好保存在编辑器设置中。打开面板不会保存配置；只有明确编辑分析设置时才会保存。生成的项目默认不启用 linter 编辑器插件。

资源导入是普通的 Godot 编辑器工作，不是 Feature 的 Stage，也不是静态检查的一个步骤。项目准备未完成时，报告实际的依赖或缓存问题。脚本解析和 lint 不能证明资源已经导入。

## 依赖维护

`addons/gdscript-linter/YAYA_PATCH.md` 记录本地修改和上游归属。保留许可信息。用配置的引擎测试改动后的 linter 行为；版本标签或之前的报告不能证明新的修改有效。
