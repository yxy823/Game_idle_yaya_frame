# 配置参考

[返回手册](../README.md) · 相关：[首次使用](../getting-started/first-use.md)、[命令与验证](commands-and-validation.md)

项目实际机器配置由 `docs/methodology-config.json` 保存。这里解释当前默认值和使用方法；修改时仍先读取目标项目的现值。

## 环境与流程配置

初始来源是 [Project_Workflow_Config.json](../../../../project-source/Project_Workflow_Config.json)。

| 字段 | 初始值 | 含义与修改注意事项 |
| --- | --- | --- |
| `document_language` | `zh-CN` | 持久项目知识的语言；与当前聊天语言独立 |
| `engine` | `Godot 4.7` | 固定技术栈标识，不能通过随意改字段宣称支持其他引擎 |
| `language` | `GDScript` | 编程语言，不是文档语言 |
| `test_framework` | `gdunit4` | 当前实现支持的测试适配器标识 |
| `environment_bootstrap.status` | `incomplete` | 环境尚未确认；确认后使用 `ready` |
| `environment_bootstrap.engine_executable` | `E:\GameTools\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe` | 已预填路径，须核对实际文件；不自动寻找替代安装 |
| `environment_bootstrap.engine_version` | 空字符串 | 填写实际 `Godot --version` 的完整输出，不只填 `4.7` |
| `python_executable` | `python` | 模板占位名称；准备环境时填写已确认解释器，当前机器使用个人规则指定的完整路径 |
| `test_cmd` | 空字符串 | 保存真实 Python 测试入口命令；执行时追加当前 Feature 和 scope |
| `test_unit_root` | `tests/unit` | 组件单元测试根目录约定 |
| `test_feature_root` | `tests/features` | Feature 验收与相关回归测试根目录约定 |
| `test_invariant_root` | `tests/invariants` | 跨 Feature 不变量测试根目录约定 |

完整路径和测试命令分别保存，避免把带参数的命令放进可执行文件字段。字段之间的位置关系和实际脚本入口需要核对，不能仅凭 JSON 能解析就认为环境可运行。

测试登记表固定为项目根目录下的 `docs/test-registry.json`。合并工具、台账校验器、测试选择器及完成检查均使用这一位置；配置和 Feature 索引不再重复保存它的路径。测试文件本身按配置表中的测试根目录与登记表映射组织。

## 路径与命令的写法

以下是**配置片段示例**，不是可覆盖整个配置文件的 ready 配置；其中 Godot 路径必须换成该项目已经确认的值：

```json
{
  "python_executable": "C:\\Users\\89523\\anaconda3\\envs\\codex-python\\python.exe",
  "test_cmd": "\"C:\\Users\\89523\\anaconda3\\envs\\codex-python\\python.exe\" -B tools/testing/run-gdunit-tests.py --godot-binary \"C:\\Godot\\Godot.exe\""
}
```

JSON 中反斜杠写成 `\\`，命令内的双引号写成 `\"`。路径字段本身不需要额外嵌入引号：带空格的可执行文件路径仍是完整的一个值。不能把 `$env:...`、`&` 或 `--version` 当作可执行文件路径的一部分。

PowerShell 直接调用路径变量时使用调用运算符，并把参数分开传入：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectPython = $projectConfig.python_executable
$projectGodot = $projectConfig.environment_bootstrap.engine_executable
& $projectPython -B tools/checks/check-project-environment.py --require-ready
$LASTEXITCODE
```

`test_cmd` 是一整条命令文本，不能用 `& $projectConfig.test_cmd` 把它当作一个可执行文件名。日常调用可按已确认命令展开为独立参数，示例见 [命令参考](commands-and-validation.md)。

Godot 的 `engine_executable` 必须是实际文件路径，可以是绝对路径，也可以相对项目根目录；环境检查和测试运行器使用同一解析方式，不去 PATH 寻找同名安装。`python_executable` 仍支持完整路径或 PATH 中的命令名。路径字段不含额外 shell 引号或参数，带空格和非 ASCII 字符的完整工具路径可保留。

项目输出目录禁止中文或空白，与工具路径字段能否包含空格是两个不同约束。不要把创建器的目录限制误套到所有配置字符串上。

## 检查能力边界

`tools/checks/check-project-environment.py` 只读取配置。普通调用检查字段与基本语言标签形式，允许合法 incomplete；`--require-ready` 再核对 ready 及以下内容。`--config` 可指定文件，项目根按该配置的上两级目录解析，不能任意把一份临时配置当作另一个项目。

| 对象 | 检查器实际做什么 | Agent 仍需核对什么 |
| --- | --- | --- |
| Python | 完整路径/项目相对路径，或裸命令的 PATH 解析结果是否为文件 | 独立执行所选解释器，确认 Python 3.12+ 与所需依赖；检查器不启动 Python 版本探针 |
| Godot | 按项目相对或绝对文件路径解析，启动 `--version`，要求进程成功、输出与记录一致且为 4.7.x | 路径不可用时说明原因；项目资源、脚本和测试是否可运行需要实际调用 |
| `test_cmd` | 从 Windows 命令文本提取首个程序，检查其解析结果为文件 | 后续测试脚本是否存在、引号/参数/工作目录是否正确；完整命令是否实际成功 |
| `document_language` | 基本字符、子段与连接形式 | 完整标签有效性及用户已确认的持久文档语言 |

文件存在不等于程序能够执行；测试命令中找到 Python 也不证明其余参数正确。就绪检查不会创建主场景、执行编辑器扫描、运行测试、解析/lint 或 Git 初始化。首次准备的顺序、报告与 Git 授权见 [首次使用](../getting-started/first-use.md)。

## 文档语言

`document_language` 控制新生成的 Product、Feature 自然语言、Progress 和项目知识。`zh-CN` 与 `en` 是当前规范明确给出示例的语言；其他合规语言标签按现有规范处理，不扩展验证声明。

环境检查器会检查基本字符和分段形式，拒绝 `zh_CN`、包含空白、空子段或子段超过八个字符等输入，并保留原值的大小写。它不验证完整 BCP 47 子段顺序或注册信息，也不代替用户确认；特殊标签的合法性和使用选择仍由 Agent 按语言规范核对。

JSON 键、Feature ID、`pending` 等状态、`manual` 等枚举、文件路径、Skill 名称、命令和测试 ID 保持不变。聊天换语言不会自动翻译项目。修改已建立的文档语言需要核对活动文档、标题锚点和历史范围；只改一个配置字段不等于完成迁移。

复制阶段不会把英文模板翻译成中文。后续生成内容遵循已确认的语言与模板结构，不删除不适用章节来缩短模板，也不建立平行的翻译版 Skill 树。详见 [文档语言约定](../../../../project-source/methodology/05-document-language.md)。

用户发送的任务提示词可以使用当前会话语言；其产出的持久项目内容仍遵循 `document_language`，不因此翻译工作流规范或 Skill。

## Godot 默认配置

实际文件是 [defaults/project.godot](../../../../project-source/defaults/project.godot)。

| 配置区域 | 当前设置 | 对使用者的影响 |
| --- | --- | --- |
| application | 名称 `New Godot Project`；features 包含 `4.7` | 表示目标版本和显示名，不证明工具已安装 |
| application | 没有 `run/main_scene` | 后续任务创建并配置启动场景 |
| editor_plugins | 启用 gdUnit4 | GDScript linter 随项目提供，但默认未在此列表启用其编辑器面板 |
| gdunit4 session_hooks | 使用 `gdunit_diagnostic_session.gd` | 测试运行关联真实引擎诊断 |
| gdunit4 report | 打开 push error、script error 和 orphan 诊断 | 测试需要保留引擎错误事实 |
| gdunit4 flaky check | `false` | 不以自动重复运行替代失败调查 |
| gdunit4 test lookup | `tests` | 项目测试位于业务测试区域 |

默认文件没有业务 Autoload、Input Map、导出预设或玩法参数。新增这些内容遵循对应工程规则和实际需求。Godot 目标 API 以配置中的真实版本核对，不凭目录名或版本标签推断兼容性。

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

长度和复杂度是代码审查线索。物理行数与代码行数、词法复杂度与真实控制流不是同一指标，不应为了降低数值删除必要说明或增加无意义转发层。更改阈值、排除项和检查开关属于明确的工程配置修改，不作为临时消除报错的方法。

## 插件和文本约定

本仓库当前 gdUnit4 的 `plugin.cfg` 标记 `6.2.0`，GDScript linter 标记 `3.3.0`。这是**随仓库保存的插件版本**，不是上游最新版本声明。linter 另有本地修改，原因与维护范围记录在 [YAYA_PATCH.md](../../../../project-source/addons/gdscript-linter/YAYA_PATCH.md)；升级前需核对补丁和许可证。

`.editorconfig` 默认 UTF-8、LF、末尾换行并清理行尾空白，Markdown 保留行尾空格；GDScript、Shader 及 Shader include 使用 Tab（显示宽度 4），Python 使用 4 空格，JSON/YAML 使用 2 空格。Windows `.bat`、`.cmd` 使用 CRLF。

`.gitattributes` 与上述换行约定一致，明确将 Godot 文本场景、资源、导入元数据及 SVG/glTF/OBJ 等可读资源按文本处理，将常见图片、音视频、字体、二进制模型和 Godot 二进制场景/资源按二进制处理。二进制标记不表示忽略文件，也不自动启用 Git LFS；默认忽略范围见 [Git、Godot 忽略文件与报告](project-layout.md#gitgodot-忽略文件与报告)。跨机器调整时读取实际文件，不把控制台显示问题当作文件编码错误。
