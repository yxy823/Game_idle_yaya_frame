# 06 · 项目环境

本页说明 `docs/methodology-config.json` 中保存的工具路径，以及 Agent 怎样让新创建的项目能运行这些工具。该文件中的另一项设置是文档语言，见[文档语言](05-document-language.md)。

## 工具配置

`docs/methodology-config.json` 保存供项目工具使用的机器设置：

| 字段 | 取值 |
| --- | --- |
| `python_executable` | 运行项目工具所用的 Python 可执行文件路径或命令名。不含脚本路径和参数。 |
| `engine_executable` | Godot 可执行文件的完整路径，可以是绝对路径，也可以相对项目根目录。不含 shell 引号和参数；不会在 `PATH` 中查找。 |
| `analyzer_python_executable` | 可选。资源 Analyzer 专用 Python 环境的解释器，写法同 `python_executable`。只在项目要用 Analyzer 时填写，安装方法见 `yaya/tools/analyzer/README.md`。 |

这个文件只保存工具选择，不保存环境是否就绪、观察到的 Godot 版本、阻塞清单或插件清单。这些值从不翻译；修改文档语言时，它们逐字节保持不变。

按原样使用配置的 `engine_executable`，不要另找 Godot 安装。路径不可用时，报告原因。用户要求 Agent 准备环境时，Agent 可以把找到的 Python 和 Godot 路径写进这个文件。执行其他任务时，只有用户要求使用新的工具位置才修改路径。路径已填写不代表工具已经可用。

命令从项目根目录运行。测试入口固定为 `yaya/tools/testing/run-gdunit-tests.py`；它读取配置的 Godot 路径，`--godot-binary` 只在单次运行中覆盖该路径。脚本解析和 lint 直接调用 Godot 和 linter 插件，见 [GDScript lint 的约定与证据](contracts/gdscript-lint.md)。

## 项目环境准备

项目环境准备（Project Environment Bootstrap）是用户要求准备环境时，由 Agent 为本项目准备运行环境。它是 Agent 执行的一项任务，不是单独的安装程序，也不依赖 GDD。

1. **确认工具。** 检查 Python 和 Godot 的路径以及所需依赖，把路径写进配置。用户提供了项目名称时，把 `project.godot` 的 `application/config/name` 改为它。以文本方式新建或修改 `project.godot` 后，用 [`resave_godot_files.gd`](../tools/README.md#resave_godot_filesgd) 重新保存。
2. **运行首次 Godot 扫描。** 项目从未打开过时，在第一条需要项目脚本的命令之前，让配置的 Godot 编辑器完成资源导入和全局类扫描。按[首次 Godot 扫描](../tools/README.md#首次-godot-扫描)操作。只要求填写配置的环境准备请求，可以把扫描留到第一次获准的运行；这时要说明扫描尚未运行。之后的 Feature 复用已完成的扫描；没有导入包装脚本，也没有逐个 Feature 的导入步骤。
3. **检查是否就绪。** 运行：

   ```powershell
   python -B yaya/tools/checks/check-project-environment.py --require-ready
   ```

4. **记录结果。** 把做了什么、发现了什么写进 `reports/initialization.md`。文件已存在时，追加一条新记录，保留之前的失败。Progress 记录当前结果、阻塞、下一步和指向该报告的链接。

`reports/initialization.md` 是给人看的报告，没有工具把它当作关卡。默认的项目 `.gitignore` 让它只留在本地，提交 Progress 时不会包含它。只有用户要求时才提交这份报告。

## 就绪检查能证明什么

| 模式 | 检查内容 |
| --- | --- |
| 不带 `--require-ready` | 配置结构。允许 Godot 路径为空，不声称工具可用。 |
| 带 `--require-ready` | Python 和 Godot 可执行文件存在，测试运行器文件存在，并实际探测 Godot 版本，结果为 4.7.x。它会打印观察到的版本。 |

这项检查不准备编辑器缓存、不安装依赖、不运行测试、不解析脚本、不运行 lint，也不初始化 Git。通过它只说明工具可用；实际结果由 Stage 4 的测试、解析和 lint 运行证明。准备失败时，把原因记在 Progress 和初始化报告里，不写进配置文件。
