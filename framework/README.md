# 维护工具

这里保留文件复制、手册生成和可显式调用的回归入口。修改不需要任务登记、源码清单续接、
发布身份、升级计划或专门的哈希状态。

面向空白项目使用者的完整说明见 [空白项目使用手册](docs/blank-project/README.md)。
桌面浏览器可直接打开 [离线 HTML 阅读版](docs/blank-project/blank-project-handbook.html)，
生成命令和依赖见 [生成离线阅读版](docs/blank-project/maintenance/updating-the-blank-project.md#生成离线阅读版)。
修改源材料前先查阅入口与受影响专题，修改后按
[维护与同步说明](docs/blank-project/maintenance/updating-the-blank-project.md) 更新对应章节。
手册属于框架，不复制到生成项目。

| 路径 | 职责 |
| --- | --- |
| [commands/create_project.py](commands/create_project.py) | 读取相对路径清单，检查目标后复制 |
| [project-files.json](project-files.json) | 唯一复制清单；每项只有 source 与 target |
| [prompts.json](prompts.json) | 集中管理框架维护与实际项目开发的全部操作提示词；不复制到项目 |
| [docs/blank-project/README.md](docs/blank-project/README.md) | 空白项目详细使用手册与维护指引；不复制到项目 |
| [commands/build_blank_project_handbook.py](commands/build_blank_project_handbook.py) | 从手册 Markdown 与 [页面模板](commands/blank-project-handbook-page.html) 生成包含 SVG 图表的单文件 HTML |
| [commands/run_project_tool_tests.py](commands/run_project_tool_tests.py) | 用户需要时，对指定外部项目执行已有项目工具回归 |
| [tests/test_project_copy.py](tests/test_project_copy.py) | 复制选择、重命名、目标路径与覆盖边界回归 |
| [tests/test_documentation_fingerprint.py](tests/test_documentation_fingerprint.py) | 用中立临时 Git 夹具核对使用 README、知识 Markdown 与验证契约的指纹边界 |
| tests/project/ | 当前项目工具的回归源码；不进入空白项目 |
| tests/project/gdscript_lint_contracts.gd | 按需在外部项目运行的真实引擎 lint 契约；unittest 不执行它 |
| tests/project/gdunit_runner_contracts.gd | 真实运行器回归：普通/参数化断言、预期错误与受控生命周期失败；不进入空白项目 |
| [review/design-quality.md](review/design-quality.md) | 设计判断依据、当前静态基线与待观察成本 |
| [review/scenario-coverage.md](review/scenario-coverage.md) | 按层级编号的场景职责、覆盖依据及提示词使用清单 |

## 提示词

`prompts.json` 顶层是数组，包含两个独立 Project；每项仍使用 `project` 与
`categories`，不增加另一套提示词配置格式：

- `Yaya 框架维护`：9 条，包含新增能力、外部框架借鉴、修复/删减、复盘、压缩包审核、动态全流程审核、外部结果复核、按需验证与新线程交接。
- `Godot 项目开发`：27 条，覆盖创建、旧项目复制迁移、环境、讨论澄清与术语、原型实验、需求、规划、开发、架构调查、资源/性能/数据、验证与经验沉淀。

各 Project 的 `categories` 按用途组织；叶子键为提示词名称，字符串值为完整文本，
换行保存为 JSON 的 `\n`。36 条提示词均有完整正文；有 `${1:说明}` 等
输入占位符时，发送前填写实际信息，已有授权在会话中继续有效。按需选用某一条，
不要求每个任务按清单逐条发送。
需要准备新项目时，使用“Godot 项目开发 → 项目初始化 → 准备 Godot 开发环境”。
已有旧框架成果需要保留时，使用“Godot 项目开发 → 项目初始化 → 复制并迁移旧框架项目”；
输入、授权及原件保留方式见[复制迁移说明](docs/blank-project/getting-started/migrate-existing-project.md)。
`prompts.json` 只保存提示词，不执行命令，也不要求项目读取维护目录。
新增提示词前先核对 [使用场景清单](review/scenario-coverage.md#提示词使用场景清单)，
合并目的和授权边界相同的场景；正文确定后写入 JSON，并同步场景用途。
外部框架借鉴先比较实际价值，阶段总结先核对已有覆盖；不自动把每个优点或经验
变成规则、脚本或新机制。项目提示词不要求项目连接或跟随维护源变化。
提示词正文及清单做静态核对；不把工具回归当成已逐条运行全部提示词。

框架提示词先读取手册入口与维护说明，再按任务范围查阅受影响专题。实施后同步对应说明；
只读复盘、验证与交接按原范围核对并报告，具体边界见
[通过提示词开始维护](docs/blank-project/maintenance/updating-the-blank-project.md#通过提示词开始维护)。

后续可以直接用口语补充：相关框架工作继续沿用既有原则，最新明确要求只调整对应的目标或限制。
从评估转入实施、检查范围与输出格式如何沿用，见
[后续用口语继续](docs/blank-project/maintenance/updating-the-blank-project.md#后续用口语继续)。

需要重新检查整个框架及空白项目时，选择
`Yaya 框架维护 → 维护与复盘 → 复盘框架设计与场景`。
它默认做整体静态审查，输出包含覆盖范围、文件依据、问题详情、处理顺序和未验证项的详细报告；
也可限定模块、提供历史对照，或指定报告文件路径。输入与报告边界见
[整体重检与详细报告](docs/blank-project/maintenance/updating-the-blank-project.md#整体重检与详细报告)。

将 `Game_idle_yaya_frame.zip` 交给其他模型独立审核时，选择
`Yaya 框架维护 → 维护与复盘 → 审核框架压缩包并输出报告`，将正文与附件一起发送。
它按压缩包快照审核，不依赖原机磁盘或 Git 历史；规定十个审核主题、九节报告及问题证据格式。
交付文件名为 `Game_idle_yaya_frame-audit-report.md`，不支持文件输出时直接给出完整正文。
准备与边界见 [压缩包审核说明](docs/blank-project/maintenance/updating-the-blank-project.md#把压缩包交给其他模型审核)。

要通过实际操作检验流程，选择
`Yaya 框架维护 → 维护与复盘 → 通过实际任务动态审核框架流程`。
在指定的新建外部项目中完成一个小 Product、一个 Feature 和适用 Stage，实际执行引擎验证与收尾。
输入、提交授权、条件阶段及阻塞处理见
[动态流程审核说明](docs/blank-project/maintenance/updating-the-blank-project.md#用一个实际任务动态审核流程)。

收到外部审核报告后，选择
`Yaya 框架维护 → 维护与复盘 → 复核外部审核结果并讨论取舍`。
它对照当前材料逐项判断问题是否成立、建议是否值得采用，列出必要修改与过度设计的具体原因。
先交付分析并讨论，收到明确的实施选择后再修改；用法见
[外部结果复核说明](docs/blank-project/maintenance/updating-the-blank-project.md#复核外部审核结果与讨论取舍)。

任务对话过长或需要换线程时，在原线程选择对应入口：

- 框架维护：`Yaya 框架维护 → 维护与复盘 → 生成新线程交接提示词`，只读当前会话与仓库。
- 项目开发：`Godot 项目开发 → 验证与收尾 → 整理进度与任务交接`，先整理必要的现有项目记录。

两者都输出一个已填入实际目标、目录、进展、授权、检查结果与下一步的完整代码块。
由使用者复制到同一工作区的新线程，接收方先核对实际文件再继续；原线程输出后停止实施。
具体用法见 [换到新线程继续](docs/blank-project/guides/project-knowledge.md#换到新线程继续)。

## 复制入口

```powershell
python -B framework/commands/create_project.py --output D:\Games\MyGodotGame
```

清单路径相对本维护源，target 相对新项目。文件可重命名；目录包含其子目录内容。
脚本不做内容替换，所以初始默认文件必须已经可直接复制。
`Project_AGENTS.md → AGENTS.md` 由清单表达，不另设模板引擎。

脚本只做必要的路径检查和文件复制。缺文件、无权限、非空目标等错误直接返回，
保留现场；不增加事务目录、复制身份、文件归属表或恢复状态机。
修改清单时检查有无重复目标以及不应交付的文件。

## 按需检查

维护层回归（复制器与文档指纹边界）：

```powershell
python -B -m unittest discover -s framework/tests -p test_*.py
```

这些回归使用系统临时目录。文档指纹检查只建立中立 Git 夹具，不创建游戏或运行项目测试。

项目工具回归：

```powershell
python -B framework/commands/run_project_tool_tests.py --project D:\Games\MyGodotGame
```

后者只运行已有 unittest，不替用户生成或配置项目，不写示例业务台账，
不顺带执行 Godot、人工验收或发布流程。项目工具测试可能使用临时文件及子进程。
真实引擎、静态检查和场景启动按具体任务单独决定。

本轮用户只要求静态审查时，上述命令均不执行。

## 这些维护入口各自负责什么

从第一性原理看，创建项目需要“按确定清单搬运文件”，一个脚本即可完成；
不需要版本管理、发布判定或跨项目同步来支撑复制。

手册生成器负责重复的格式转换、链接重写和图表内嵌，正文仍由 Markdown 维护；
生成文件可直接离线阅读，不需要网站服务，也不承担项目创建或验证职责。

项目工具仍有独立回归源码，维护者需要明确指定被测项目。验证入口只承担传递路径、
执行回归和返回退出码的重复操作，不决定当前任务是否必须运行它。
Skill 直接调用的项目命令保留；自动事件及其专用测试已删除。
保留实际成果检查，删除逐动作监督和多余包装；Skill 引用某个命令，
不代表必须保留该命令内部所有旧机制。删除机制时同步删除其专用测试，
不因存在测试就默认继续保留其设计。
