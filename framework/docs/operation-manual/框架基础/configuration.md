# 配置参考

[操作手册](../README.md)

项目实际机器配置由 `docs/methodology-config.json` 保存。这里解释当前默认值和使用方法；修改时仍先读取目标项目的现值。

## 环境与流程配置

初始来源是 [Project_Workflow_Config.json](../../../../project-source/Project_Workflow_Config.json)。

| 字段 | 初始值 | 含义与修改注意事项 |
| --- | --- | --- |
| `document_language` | `zh-CN` | 持久项目知识的语言；与当前聊天语言独立 |
| `engine_executable` | `E:\GameTools\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe` | 已预填路径，须核对实际文件；不自动寻找替代安装 |
| `python_executable` | `python` | 模板占位名称；准备环境时填写已确认解释器，当前机器使用个人规则指定的完整路径 |

技术栈固定为 Godot 4.7、GDScript 和 gdUnit4，不另存三份标签。配置只保存文档语言与工具路径，实际版本与准备结果由检查输出和初始化报告记录；测试使用固定入口 `tools/testing/run-gdunit-tests.py`，执行时指定 Feature 和 scope，不重复保存整条命令。

- **登记表位置：** 测试登记表固定为项目根目录下的 `docs/test-registry.json`。合并工具、台账校验器、测试选择器及完成检查均使用这一位置；配置和 Feature 索引不重复保存它的路径。
- **测试位置与选择：** 测试统一放在 `tests/` 下，按 `unit/`、`features/`、`invariants/` 分层；full 递归选择整个 `tests/`，局部运行按登记表映射选择。

## 路径与命令的写法

以下是**配置片段示例**，不是可覆盖整个配置文件的完整配置；其中 Godot 路径必须换成该项目已经确认的值：

```json
{
  "python_executable": "C:\\Users\\89523\\anaconda3\\envs\\codex-python\\python.exe",
  "engine_executable": "C:\\Godot\\Godot.exe"
}
```

JSON 中反斜杠写成 `\\`。路径字段不额外嵌入引号：带空格的可执行文件路径仍是完整的一个值。不能把 `$env:...`、`&` 或 `--version` 当作可执行文件路径的一部分。

PowerShell 直接调用路径变量时使用调用运算符，并把参数分开传入：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectPython = $projectConfig.python_executable
& $projectPython -B tools/checks/check-project-environment.py --require-ready
$LASTEXITCODE
```

测试入口默认读取配置中的 Godot 路径，临时更换时可显式传入 `--godot-binary <路径>`；示例见 [命令参考](../方法与工具/commands-and-evidence.md)。

- **Godot 路径：** `engine_executable` 必须是实际文件路径，可以是绝对路径，也可以相对项目根目录；环境检查和测试运行器使用同一解析方式，不去 PATH 寻找同名安装。
- **Python 路径：** `python_executable` 仍支持完整路径或 PATH 中的命令名。
- **字段格式：** 路径字段不含额外 shell 引号或参数，带空格和非 ASCII 字符的完整工具路径可保留。

项目输出目录禁止中文或空白，与工具路径字段能否包含空格是两个不同约束。不要把创建器的目录限制误套到所有配置字符串上。

## 检查能力边界

`tools/checks/check-project-environment.py` 只读取配置。

- **普通调用：** 检查字段与基本语言标签形式，允许 Godot 路径暂时为空。
- **`--require-ready`：** 根据以下实际检查判定就绪，不读写状态字段。
- **`--config`：** 可指定文件，项目根按该配置的上两级目录解析，不能任意把一份临时配置当作另一个项目。

| 对象 | 检查器实际做什么 | Agent 仍需核对什么 |
| --- | --- | --- |
| Python | 完整路径/项目相对路径，或裸命令的 PATH 解析结果是否为文件 | 独立执行所选解释器，确认 Python 3.12+ 与所需依赖；检查器不启动 Python 版本探针 |
| Godot | 按项目相对或绝对文件路径解析，启动 `--version`，要求进程成功、输出为 4.7.x；打印实际版本，不要求手填版本或锁定补丁版本 | 路径不可用时说明原因；项目资源、脚本和测试是否可运行需要实际调用 |
| 测试入口 | 检查固定文件 `tools/testing/run-gdunit-tests.py` 存在 | 按任务范围实际运行测试；文件存在不代表测试通过 |
| `document_language` | 基本字符、子段与连接形式 | 完整标签有效性及用户已确认的持久文档语言 |

文件存在不等于程序能够执行。就绪检查不会创建主场景、执行编辑器扫描、运行测试、解析/lint 或 Git 初始化。初始文件与检查结果的区别见 [框架与项目边界](framework-and-project.md#环境就绪的含义)。

## 文档语言

`document_language` 控制新生成的 Product、Feature 自然语言、Progress 和项目知识。`zh-CN` 与 `en` 是当前规范明确给出示例的语言；其他合规语言标签按现有规范处理，不扩展验证声明。

环境检查器会检查基本字符和分段形式，拒绝 `zh_CN`、包含空白、空子段或子段超过八个字符等输入，并保留原值的大小写。它不验证完整 BCP 47 子段顺序或注册信息，也不代替用户确认；特殊标签的合法性和使用选择仍由 Agent 按语言规范核对。

- **保持不变的标识：** JSON 键、Feature ID、`pending` 等状态、`manual` 等枚举、文件路径、Skill 名称、命令和测试 ID。
- **聊天语言：** 聊天换语言不会自动翻译项目。
- **已有文档迁移：** 修改已建立的文档语言需要核对活动文档、标题锚点和历史范围；只改一个配置字段不等于完成迁移。

复制阶段不会把英文模板翻译成中文。后续生成内容遵循已确认的语言与模板结构，不删除不适用章节来缩短模板，也不建立平行的翻译版 Skill 树。详见 [文档语言约定](../../../../project-source/methodology/05-document-language.md)。

用户发送的任务提示词可以使用当前会话语言；其产出的持久项目内容仍遵循 `document_language`，不因此翻译工作流规范或 Skill。

## Godot 默认配置

实际文件是 [defaults/project.godot](../../../../project-source/defaults/project.godot)。

| 配置区域 | 当前设置 | 对使用者的影响 |
| --- | --- | --- |
| application | 名称 `New Godot Project`；features 包含 `4.7` | 表示目标版本和显示名，不证明工具已安装 |
| application | `run/main_scene="res://main/main.tscn"` | 已有最小入口供后续组装；没有预置玩法，创建时不运行 |
| display/window/size | viewport 默认 `1600×900` | 新建项目、单对象/组合工作台沿用此尺寸；之后可按游戏需求显式调整，编辑器嵌入运行仍受宿主区域约束 |
| editor_plugins | 启用 gdUnit4、Script-IDE、Inspector Tabs、Kanban Tasks | 其余随带插件按需启用，具体用途与限制见下文 |
| gdunit4 session_hooks | 使用 `gdunit_diagnostic_session.gd` | 测试运行关联真实引擎诊断 |
| gdunit4 report | 打开 push error、script error 和 orphan 诊断 | 测试需要保留引擎错误事实 |
| gdunit4 flaky check | `false` | 不以自动重复运行替代失败调查 |
| gdunit4 test lookup | `tests` | 项目测试位于业务测试区域 |

默认文件没有业务 Autoload、Input Map、导出预设或玩法参数。新增这些内容遵循对应工程规则和实际需求。Godot 目标 API 以实际检查输出的版本核对，不凭目录名或版本标签推断兼容性。

## GDScript lint 默认配置

实际文件是 [defaults/gdlint.json](../../../../project-source/defaults/gdlint.json)，指标含义见 [lint 契约](../../../../project-source/methodology/gdscript-lint.md)。

| 配置 | 当前值 |
| --- | --- |
| 文件 / 函数长度指标 | 均为 `physical`，包含空行与注释 |
| 文件长度 soft / hard | 400 / 600 |
| 函数长度 / critical | 40 / 70 |
| 参数数量 / 嵌套 / 行宽 | 5 / 3 / 100 |
| complexity warning / critical | 10 / 15 |
| God class 函数 / Signal / export 数量 | 20 / 10 / 15 |
| 扫描 | 尊重 `.gdignore` 和 ignore directives；`scan_addons: false` |
| 路径排除 | `addons/`、`.godot/` |
| ASCII 检查 | `ascii_only: true`，`ascii_only_project_wide: false` |

还启用了类型、返回类型、命名、未使用变量/参数、TODO、print、空函数、magic number、注释代码、strict limits、sealed 等检查；精确开关以 JSON 为准。

CLI 和可选编辑器面板都以项目根 `gdlint.json` 为分析配置来源。

- **机器偏好：** 面板不会用机器级旧阈值或检查开关覆盖项目；机器设置只保存显示等偏好。
- **修改影响：** 在面板中调整分析设置会修改项目 JSON，属于项目标准变更，其他未修改字段应保留。
- **启用状态：** 面板仍默认不启用。

长度和复杂度是代码审查线索。物理行数与代码行数、词法复杂度与真实控制流不是同一指标，不应为了降低数值删除必要说明或增加无意义转发层。更改阈值、排除项和检查开关属于明确的工程配置修改，不作为临时消除报错的方法。

## 插件和文本约定

本仓库当前 gdUnit4 的 `plugin.cfg` 标记 `6.2.0`，GDScript linter 标记 `3.3.0`。这是**随仓库保存的插件版本**，不是上游最新版本声明。linter 另有本地修改，原因与维护范围记录在 [YAYA_PATCH.md](../../../../project-source/addons/gdscript-linter/YAYA_PATCH.md)；升级前需核对补丁和许可证。

空白项目还随带 Script-IDE、Inspector Tabs、Kanban Tasks、Edit Resources as Table 2 和 Signal Lens。前三个默认启用。资源表格插件在当前组合中有退出泄漏诊断，因此保留安装、按需启用；Signal Lens 也按需启用，它会注册调试用 Autoload，停用时移除。Kanban 是使用者独立维护的灵感看板，与框架开发任务记录没有读取或同步关系。

这五个插件的上游链接、固定源码版本、包内版本差异、启用边界与实测结果集中在[编辑器插件版本记录](../../framework-maintenance/editor-plugin-versions.md)。记录只保留在框架维护目录，不进入生成项目；项目内的简短使用入口见 [README](../../../../project-source/Project_README.md#编辑器效率插件)。

`.editorconfig` 约定：

- **通用格式：** 默认 UTF-8、LF、末尾换行并清理行尾空白，Markdown 保留行尾空格。
- **缩进：** GDScript、Shader 及 Shader include 使用 Tab（显示宽度 4），Python 使用 4 空格，JSON/YAML 使用 2 空格。
- **Windows 命令文件：** `.bat`、`.cmd` 使用 CRLF。

`.gitattributes` 与上述换行约定一致，明确将 Godot 文本场景、资源、导入元数据及 SVG/glTF/OBJ 等可读资源按文本处理，将常见图片、音视频、字体、二进制模型和 Godot 二进制场景/资源按二进制处理。二进制标记不表示忽略文件，也不自动启用 Git LFS；默认忽略范围见 [Git、Godot 忽略文件与报告](project-layout.md#git-与-godot-扫描的区别)。跨机器调整时读取实际文件，不把控制台显示问题当作文件编码错误。
