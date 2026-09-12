# 维护工具

这里保留文件复制和可显式调用的回归入口。修改不需要任务登记、源码清单续接、
发布身份、升级计划或专门的哈希状态。

| 路径 | 职责 |
| --- | --- |
| [commands/create_project.py](commands/create_project.py) | 读取相对路径清单，检查目标后复制 |
| [project-files.json](project-files.json) | 唯一复制清单；每项只有 source 与 target |
| [prompts.json](prompts.json) | 集中管理框架维护与实际项目开发的全部操作提示词；不复制到项目 |
| [commands/validate_project.py](commands/validate_project.py) | 用户需要时，对指定外部项目执行已有项目工具回归 |
| [tests/test_generation.py](tests/test_generation.py) | 复制选择、重命名、目标路径与覆盖边界回归 |
| tests/project/ | 当前项目工具的回归源码；不进入空白项目 |
| tests/project/gdscript_lint_contracts.gd | 按需在外部项目运行的真实引擎 lint 契约；unittest 不执行它 |
| tests/project/gdunit_runner_contracts.gd | 真实运行器回归：普通/参数化断言、预期错误与受控生命周期失败；不进入空白项目 |
| [review/design-quality.md](review/design-quality.md) | 设计判断依据、当前静态基线与待观察成本 |
| [review/scenario-coverage.md](review/scenario-coverage.md) | 按层级编号的场景职责、覆盖依据及提示词使用清单 |

## 提示词

`prompts.json` 顶层是数组，包含两个独立 Project；每项仍使用 `project` 与
`categories`，不增加另一套提示词配置格式：

- `Yaya 框架维护`：5 条，包含新增能力、外部框架借鉴、修复/删减、复盘与按需验证。
- `Godot 项目开发`：23 条，覆盖创建、环境、原型实验、需求、规划、开发、资源/性能/数据、验证与经验沉淀。

各 Project 的 `categories` 按用途组织；叶子键为提示词名称，字符串值为完整文本，
换行保存为 JSON 的 `\n`。28 条提示词均有完整正文；输入使用 `${1:说明}` 等
占位符，发送前填写实际信息，已有授权在会话中继续有效。按需选用某一条，
不要求每个任务按清单逐条发送。
需要准备新项目时，使用“Godot 项目开发 → 项目初始化 → 准备 Godot 开发环境”。
`prompts.json` 只保存提示词，不执行命令，也不要求项目读取维护目录。
新增提示词前先核对 [使用场景清单](review/scenario-coverage.md#提示词使用场景清单)，
合并目的和授权边界相同的场景；正文确定后写入 JSON，并同步场景用途。
外部框架借鉴先比较实际价值，阶段总结先核对已有覆盖；不自动把每个优点或经验
变成规则、脚本或新机制。项目提示词不要求项目连接或跟随维护源变化。
提示词正文及清单做静态核对；不把工具回归当成已逐条运行全部提示词。

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

复制器回归：

```powershell
python -B -m unittest discover -s framework/tests -p test_*.py
```

项目工具回归：

```powershell
python -B framework/commands/validate_project.py --project D:\Games\MyGodotGame
```

后者只运行已有 unittest，不替用户生成或配置项目，不写示例业务台账，
不顺带执行 Godot、人工验收或发布流程。项目工具测试可能使用临时文件及子进程。
真实引擎、静态检查和场景启动按具体任务单独决定。

本轮用户只要求静态审查时，上述命令均不执行。

## 为什么保留这两个脚本

从第一性原理看，创建项目需要“按确定清单搬运文件”，一个脚本即可完成；
不需要版本管理、发布判定或跨项目同步来支撑复制。

项目工具仍有独立回归源码，维护者需要明确指定被测项目。验证入口只承担传递路径、
执行回归和返回退出码的重复操作，不决定当前任务是否必须运行它。
Skill 直接调用的项目命令保留；自动事件及其专用测试已删除。
保留实际成果检查，删除逐动作监督和多余包装；Skill 引用某个命令，
不代表必须保留该命令内部所有旧机制。删除机制时同步删除其专用测试，
不因存在测试就默认继续保留其设计。
