# 首次使用与环境准备

[返回手册](../README.md) · 前一步：[创建项目](create-project.md) · 本任务下一步：[需求与规划](../guides/product-and-planning.md)

复制完成后，你在目标项目中向 Agent 发送“准备 Godot 开发环境”提示词，并提供项目名称、文档语言或工具位置等尚未确定的选择。Agent 核实配置、记录真实准备结果，之后即可按授权进入需求整理与开发。已有设计文档可直接使用 [GDD 入口](../guides/product-and-planning.md#接入已有-gdd)。

| 操作 | 产物或结果 | 与下一步的关系 |
| --- | --- | --- |
| 你在目标项目发送准备请求，Agent 核对工具与选择 | 填写 `docs/methodology-config.json`，完成就绪检查 | 正式开发复用该配置 |
| Agent 按初始化授权处理 Git | 保留已有仓库，或建立本地仓库 | 默认提示词不提交，初始基线另按授权处理 |
| Agent 记录准备结果 | 初始化报告与 Progress 中的续接说明 | 记录实际准备范围，不表示游戏已验证 |
| Agent 在首次获授权的项目命令前完成 Godot 扫描 | 引擎所需的类缓存与导入结果 | 仅做配置时可留到首次运行 |

## 打开正确的工作目录

你将 Coding Agent 的工作目录切换到生成项目。Agent 先读取项目自己的 `AGENTS.md`、`README.md`、`docs/methodology-config.json` 和 `docs/progress.md`，再按任务加载 Skill 与规则。

不要在 `project-source/` 中打开业务开发任务。那里文件名和目录尚处于复制前形态，例如 Skill 位于 `skills/`，配置也不在项目最终位置。

从完整框架的 [集中提示词](../../../prompts.json) 中选择“Godot 项目开发 → 项目初始化 → 准备 Godot 开发环境”，填写后在目标项目发送。只有独立阅读包时，需要另取该提示词正文；生成项目运行时不依赖框架目录。

## 环境准备需要确认的内容

| 内容 | 如何确认 | 保存位置 |
| --- | --- | --- |
| Python | 使用本机已确认的 Python 3.12+；本机个人规则指定 `codex-python` 解释器 | `python_executable` |
| Godot | 直接核对已配置路径，执行 `--version` 并保留真实输出 | `environment_bootstrap` |
| 插件 | 检查项目 `addons/gdUnit4/` 与 `addons/gdscript-linter/` 的实际文件 | 初始化报告；不建立另一份插件清单 |
| 测试入口 | 按项目工具实际参数组成可调用命令 | `test_cmd` |
| 显示名称 | 用户提供名称时修改；未提供时保留现值 | `project.godot` 的 `config/name` |
| 文档语言 | 使用已确认的持久文档语言；生成 Product 前解决尚未确认的选择 | `document_language` |

初始 Godot 路径已经写入配置，准备环境时直接使用它。路径不可用就报告该路径和失败原因；只有用户要求更换位置或提供新路径时才修改。预填路径不证明安装存在，也不应自动搜索另一个版本替代。

Godot 配置按绝对路径或相对项目根目录的文件路径解析，不通过 PATH 查找。使用相对路径时，直接命令也从项目根目录运行，并保留 `./` 等路径前缀以明确选择项目内文件。

可执行文件字段保存单独的完整路径，不附加参数或 shell 引号；带参数的测试命令保存在 `test_cmd`。具体字段和转义示例见 [配置参考](../reference/configuration.md)。

## 配置就绪的判定

Agent 核对工具与命令、填写真实配置，将 `environment_bootstrap.status` 设为 `ready` 后运行就绪检查。失败时恢复或保持 `incomplete`，在 Progress 与初始化报告记录原因。

以下是 Agent 在目标项目根目录使用的检查命令；普通检查与就绪检查的结果含义见表格：

```powershell
& 'C:\Users\89523\anaconda3\envs\codex-python\python.exe' -B tools/checks/check-project-environment.py
$LASTEXITCODE
& 'C:\Users\89523\anaconda3\envs\codex-python\python.exe' -B tools/checks/check-project-environment.py --require-ready
$LASTEXITCODE
```

| 检查 | 能说明什么 | 仍不能说明什么 |
| --- | --- | --- |
| 不带 `--require-ready` | 配置满足脚本检查的结构要求，合法的 `incomplete` 可以通过 | 工具已可用、路径正确、游戏可运行 |
| 带 `--require-ready` | 已标记 ready；Python/Godot 路径及测试命令首个可执行文件可用；实时 Godot 4.7.x 版本与记录匹配 | 测试命令的全部参数正确、测试执行成功、脚本解析和 lint 已通过 |

检查器不会自动安装依赖、配置项目、运行测试或初始化 Git。准备环境的 Agent 仍需核对测试脚本与参数；一个字符串能找到解释器，不代表整个测试命令已经实际成功。

普通 Feature 复用已确认配置。安装位置、工具版本或命令改变，以及实际调用失败需要诊断时，再进行相关就绪核对；不用为每项任务重复搜索安装位置。

## 首次 Git 状态如何处理

创建器本身不建立 Git 仓库。当前集中管理的环境准备提示词**显式授权**：若目标没有自己的仓库，先核对不位于其他仓库内，再执行本地 `git init`；同时明确要求本次初始化**不提交、不创建远程、不 push**。

因此，按该提示词完成环境准备后看到尚未提交的初始文件是预期结果。获准提交初始基线后，可以继续同一次初始化，核对并仅提交已知初始文件及本次环境准备的改动；工作区干净后再开始新的修改任务。不能把初始化提示词当作初始提交授权，也不能把这些文件混入第一个业务 Feature。

如果使用其他初始化请求，以该请求已经给出的范围为准。已有仓库保留原状态；仓库发现和文件归属存在疑问时先查清，不执行清理、覆盖或自动暂存。

## 没有主场景与业务测试时

初始 `project.godot` 没有 `run/main_scene`，默认目录也没有游戏脚本或测试套件。此时可以说明项目已经复制、工具环境已经确认，但不能声称游戏启动或业务测试通过。

主场景、业务目录、测试根目录及首个可运行行为由后续获批任务按需要建立。初次 Product 规划通常先安排可运行基础，再按依赖实现行为；不要为了给初始化报告填写成功结果而虚构一个 Feature 或测试。

## 首次命令行运行前的扫描

配置 ready 不会生成 Godot 的全局类缓存或导入资源。新项目尚未在编辑器中打开时，直接运行 CLI 测试可能报找不到 `GdUnitTestCIRunner`；此时用例尚未执行，不能当作业务测试 RED。

Agent 在首次获授权的命令行测试或项目脚本运行前，让配置中的 Godot 完成一次编辑器扫描，确认进程结束并检查退出码和解析、导入错误。已正常打开过的项目可复用已有准备；失败时按实际错误排查。

仅核对配置时可以暂不扫描，Agent 在初始化报告中注明未执行；实际扫描遵守项目 `AGENTS.md` 的权限与审批约束。完整命令见 [项目工具的首次扫描说明](../../../../project-source/tools/README.md#首次-godot-扫描)，独立阅读包用户应在完整框架或生成项目的 `tools/README.md` 查阅。

生成文件按项目资产与引用规则处理，不能把 `.import`、`.uid` 与 `.godot` 都当作可删除缓存。

## 初始化报告和下一步

Agent 将实际过程写入 `reports/initialization.md`，已有报告追加并保留失败；`docs/progress.md` 保存当前结果、阻塞、下一步和报告链接。

你查看报告中的工具版本、修改、命令结果、未执行项和 Git 状态，便可判断准备是否完成以及剩余问题。后续 Agent 也从这些记录续接。

仅使用环境准备提示词时，交付准备结果后结束；已有具体后续授权则继续其范围。准备完成后通常先处理初始基线，再从 [想法或 GDD 整理 Product](../guides/product-and-planning.md)；只讨论设计可以提前进行。

## 对应源文件

[环境配置约定](../../../../project-source/methodology/05-document-language.md#project-environment-bootstrap) 定义准备要求，[环境检查器](../../../../project-source/tools/checks/check-project-environment.py) 定义实际检查，[初始化提示词](../../../prompts.json) 限定当前动作与 Git 授权，[项目规则](../../../../project-source/Project_AGENTS.md) 约束后续开发。
