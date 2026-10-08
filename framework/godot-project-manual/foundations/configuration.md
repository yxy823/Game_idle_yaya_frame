# 配置参考

[Godot 项目手册](../README.md)

生成项目的机器配置保存在 `docs/methodology-config.json`。本页解释各配置的默认值和用法；修改某个项目时，先读取该项目当前的值。

## 环境与流程配置

初始来源是 [defaults/docs/methodology-config.json](../../../project-source/defaults/docs/methodology-config.json)。

| 字段 | 初始值 | 含义与修改注意事项 |
| --- | --- | --- |
| `document_language` | `zh-CN` | 持久项目知识默认使用中文，无需再次确认；与当前聊天语言独立 |
| `engine_executable` | `E:\GameTools\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe` | 已预填路径，须核对实际文件；不自动寻找替代安装 |
| `python_executable` | `python` | 初始命令名；准备环境时改为已确认的 Python 3.12+ 解释器 |
| `analyzer_python_executable` | 不预填 | 可选；资源 Analyzer 专用环境的解释器，要用 Analyzer 时才填写 |

配置文件只保存文档语言和工具路径。其他信息都有固定位置，不写进配置：

- **技术栈**：固定为 Godot 4.7、GDScript 和 gdUnit4，不在配置中另存标签；实际安装的版本以检查输出和初始化报告为准。
- **测试入口**：固定为 `yaya/tools/testing/run-gdunit-tests.py`，运行时再指定 Feature 和 scope。
- **测试登记表**：固定为 `docs/test-registry.json`，合并工具、Feature 记录检查、测试选择和完成检查都读这个位置。
- **测试目录**：测试都放在 `tests/` 下，分为 `unit/`、`features/`、`invariants/`。full 运行整个 `tests/`，其他范围按登记表的映射选择。

## 路径与命令的写法

下面是一个**配置片段**，不是完整配置文件；两个路径都要换成该项目已确认的值：

```json
{
  "python_executable": "C:\\Python312\\python.exe",
  "engine_executable": "C:\\Godot\\Godot.exe"
}
```

写路径时注意：

- JSON 中的反斜杠写成 `\\`。
- 路径值本身不加引号；含空格或非 ASCII 字符的完整路径照常写成一个值。
- 不要把 `$env:...`、`&` 或 `--version` 写进路径值。

在 PowerShell 中用变量调用这些路径时，加调用运算符 `&`，参数单独传入：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectPython = $projectConfig.python_executable
& $projectPython -B yaya/tools/checks/check-project-environment.py --require-ready
$LASTEXITCODE
```

路径字段接受的写法不同：

- **`engine_executable`**：必须指向实际文件，可以是绝对路径或相对项目根目录的路径；不会到 PATH 中查找同名程序。环境检查和测试运行器用同一种方式解析。
- **`python_executable`**、**`analyzer_python_executable`**：可以是完整路径、相对项目根目录的路径，或 PATH 中的命令名。

测试运行器默认使用配置中的 Godot 路径，临时换用其他版本时传入 `--godot-binary <路径>`，示例见[命令与验证证据](../methods-and-tools/commands-and-evidence.md)。

创建器要求**项目目录**不含中文或空白，这条限制只针对项目目录，工具路径可以含空格和中文。

## 检查能力边界

`yaya/tools/checks/check-project-environment.py` 只读取配置，不写入任何状态。

- **普通调用**：检查字段结构和语言标签的基本形式；Godot 路径暂时为空也能通过。
- **`--require-ready`**：再按下表实际探测工具，判断环境是否就绪。
- **`--config`**：指定其他配置文件。项目根目录按该文件的上两级目录确定，所以不能拿一份临时配置去检查另一个项目。

| 对象 | 检查器实际做什么 | Agent 仍需核对什么 |
| --- | --- | --- |
| Python | 解析路径或 PATH 命令，确认指向一个文件 | 实际运行该解释器，确认是 Python 3.12+ 且依赖齐全；检查器不探测 Python 版本 |
| Godot | 解析路径并启动 `--version`，要求进程成功且版本为 4.7.x；打印实际版本，不锁定补丁版本 | 路径不可用时说明原因；资源、脚本和测试能否运行要实际调用才知道 |
| 测试入口 | 确认 `yaya/tools/testing/run-gdunit-tests.py` 存在 | 按任务范围实际运行测试 |
| `document_language` | 检查字符、子段与连接符的基本形式 | 完整标签是否有效，是否符合默认中文或用户指定的语言 |

资源 Analyzer 使用独立的 Python 3.13 环境；按 [Analyzer 安装说明](../../../project-source/tools/analyzer/README.md#准备与使用)核对具体版本和依赖，与普通工具的 Python 分开检查。

就绪检查不会创建主场景、执行编辑器扫描、运行测试、解析、lint 或初始化 Git。新项目还需要经过哪些步骤，见[环境就绪的含义](framework-and-project.md#环境就绪的含义)。

## 文档语言

`document_language` 决定新写或修改的项目文档使用什么语言，包括 GDD、Product、Feature 中的自然语言、Progress 和项目知识。

- **默认值**：新项目直接使用 `zh-CN`，不需要再向用户确认。规范中给出示例的语言是 `zh-CN` 和 `en`，其他合规的语言标签按同一规范处理。
- **改用其他语言**：用户明确指定后，保存到配置并直接采用。已有项目沿用当前值。
- **与聊天语言无关**：用户在对话或任务提示词中换用其他语言，不会改变项目文档的语言，也不会触发翻译。
- **不翻译的内容**：JSON 键、Feature ID、`pending` 等状态值、`manual` 等枚举、文件路径、Skill 名称、命令和测试 ID 保持原样。
- **模板与 Skill**：分发的规范、Skill 和模板都是中文。之后生成的内容按配置的语言填写；配置不是中文时，Agent 把模板的标题和说明写成该语言，保留章节结构和机器键，不另建翻译版的模板或 Skill。
- **迁移已有文档**：改变已有项目的文档语言时，要同时处理活动文档、标题锚点和历史范围；只改配置字段不算完成迁移。

环境检查器只检查语言标签的基本形式：会拒绝 `zh_CN`、含空白、有空子段或子段超过八个字符的写法，并保留原值的大小写。它不校验 BCP 47 的完整子段顺序或注册信息；特殊标签由 Agent 按语言规范核对，只有要求不清楚或互相冲突时才向用户确认。规范正文见[文档语言](../../../project-source/methodology/05-document-language.md)。

## Godot 默认配置

实际文件是 [defaults/project.godot](../../../project-source/defaults/project.godot)。

| 配置区域 | 当前设置 | 对使用者的影响 |
| --- | --- | --- |
| application | 名称 `New Godot Project`；features 包含 `4.7` | 表示目标版本和显示名，不证明工具已安装 |
| application | `run/main_scene="res://main/main.tscn"` | 已有最小入口供后续组装；没有预置玩法，创建时不运行 |
| display/window | viewport 默认 `1600×900`，拉伸 `canvas_items` + `expand`；渲染器未设置（Forward+） | 只是起点。第一个 Feature 开工前，项目按美术风格和目标显示器比例确定显示基线（平台固定为 Windows PC），见[视口、窗口与拉伸](../../../project-source/agent-rules/40-project-config/subsystem-settings.md#视口窗口与拉伸)；编辑器嵌入运行仍受宿主区域约束 |
| editor_plugins | 启用 gdUnit4、Script-IDE、Inspector Tabs、Kanban Tasks | 其余随带插件按需启用，具体用途与限制见下文 |
| gdunit4 session_hooks | 使用 `gdunit_diagnostic_session.gd` | 测试运行关联真实引擎诊断 |
| gdunit4 report | 打开 push error、script error 和 orphan 诊断 | 测试需要保留引擎错误事实 |
| gdunit4 flaky check | `false` | 不以自动重复运行替代失败调查 |
| gdunit4 test lookup | `tests` | 项目测试位于业务测试区域 |

默认文件没有业务 Autoload、Input Map、导出预设或玩法参数，需要时按对应工程规则添加。判断 API 兼容性时，以环境检查打印的实际 Godot 版本为准，不看目录名或版本标签。

## GDScript lint 默认配置

实际文件是 [defaults/gdlint.json](../../../project-source/defaults/gdlint.json)，指标含义见 [GDScript lint 的约定与证据](../../../project-source/methodology/contracts/gdscript-lint.md)。

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

CLI 和可选的编辑器面板都以项目根目录的 `gdlint.json` 为准：

- **机器设置**：只保存显示偏好，不会用旧的阈值或检查开关覆盖项目配置。
- **在面板中修改分析设置**：会直接改写项目的 `gdlint.json`，属于项目标准的变更，未改动的字段保持原样。
- **面板默认不启用**。

长度和复杂度只是审查线索：物理行数不同于代码行数，词法复杂度也不等于真实的控制流复杂度。不要为了压低数值删掉必要的注释，或增加没有意义的转发层。调整阈值、排除项和检查开关是明确的工程配置修改，不能用来临时消除报错。

## 插件和文本约定

随项目分发的 gdUnit4 用于测试，GDScript linter 用于静态检查；linter 带有本地补丁，版本以各自的 `plugin.cfg` 为准。

空白项目还附带五个编辑器效率插件：

| 插件 | 默认状态 | 说明 |
| --- | --- | --- |
| Script-IDE、Inspector Tabs | 启用 | 改进脚本编辑区和检查器 |
| Kanban Tasks | 启用 | 使用者自己维护的灵感看板，与框架的开发任务记录没有任何关联 |
| Edit Resources as Table 2 | 安装但停用 | 在当前插件组合中退出时有泄漏诊断，需要时再启用 |
| Signal Lens | 安装但停用 | 启用时注册调试用 Autoload，停用时移除 |

以上七个插件的上游、固定版本、本地修改、兼容性实测与升级核对统一记录在[编辑器插件版本与兼容性记录](../../maintenance/dependencies/editor-plugin-versions.md)，该记录只在框架维护目录，不进入生成项目；项目里的简短说明见 [编辑器效率插件](../../../project-source/Project_README.md#编辑器效率插件)。

`.editorconfig` 约定：

- **通用格式**：默认 UTF-8、LF、末尾换行并清理行尾空白；Markdown 和 `addons/` 保留行尾空格，避免改写第三方插件。
- **缩进**：GDScript、Shader 及 Shader include 使用 Tab（显示宽度 4），Python 使用 4 空格，JSON/YAML 使用 2 空格。
- **Windows 命令文件**：`.bat`、`.cmd` 使用 CRLF。

`.gitattributes` 与上述换行约定一致：Godot 文本场景、资源、导入元数据，以及 SVG、glTF、OBJ 等可读资源按文本处理；常见图片、音视频、字体、二进制模型和 Godot 二进制场景、资源按二进制处理。标为二进制不等于被忽略，也不会自动启用 Git LFS；哪些文件被忽略见[Git 与 Godot 扫描的区别](project-layout.md#git-与-godot-扫描的区别)。在另一台机器上看到乱码时，先读取实际文件确认，不要把控制台显示问题当成文件编码错误。
