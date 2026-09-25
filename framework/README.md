# 维护工具

本目录保存创建器、复制清单、集中提示词、文档和审核/回归材料。项目使用说明从 [文档总入口](docs/README.md) 进入，维护原则见 [维护与同步说明](docs/framework-maintenance/updating-the-blank-project.md)。这些材料不复制到生成项目。

## 文件与职责

| 路径 | 职责 |
| --- | --- |
| [progress.md](progress.md) | 仍需推进的工作、验证缺口和必要决定；完成即删，历史查 Git |
| [project-files.json](project-files.json) | 唯一复制映射，每项只有 source 与 target |
| [commands/create_project.py](commands/create_project.py) | 预检、复制与重命名，建立独立 Git 仓库及本地初始提交 |
| [prompts.json](prompts.json) | 框架维护与实际项目开发的全部手写任务提示词 |
| [commands/check_scenario_prompt_paths.py](commands/check_scenario_prompt_paths.py) | 从 JSON 名称和目录文件名核对提示词与场景一对一，不读取场景正文 |
| [commands/export_advisor_prompt_examples.py](commands/export_advisor_prompt_examples.py) | 显式导出 advisor 精选表达参考，不承担流程或同步职责 |
| [docs/README.md](docs/README.md) | 操作手册、场景手册与维护说明的统一入口 |
| [commands/build_blank_project_handbook.py](commands/build_blank_project_handbook.py) | 暂缓调用的 HTML 构建器；保留 [模板](commands/blank-project-handbook-page.html)、[交互源码](commands/blank-project-handbook-interactions.js) 和回归 |
| [commands/run_project_tool_tests.py](commands/run_project_tool_tests.py) | 对明确指定的外部项目运行现有工具回归，不创建或更新项目 |
| [tests/](tests/) | 创建器、导出器、路径映射、文档指纹、人工文件等维护回归 |
| [tests/project/](tests/project/) | 外部项目工具与真实 Godot 夹具，不进入复制清单 |
| [review/README.md](review/README.md) | 长期准则、基线与按次审核报告的导航 |

职责评价见 [Skill、脚本、提示词设计准则](review/baselines/skill-script-prompt-design.md)，场景用途见 [覆盖清单](review/baselines/scenario-coverage.md)，结构判断见 [设计基线](review/baselines/design-quality.md)。当次报告保留被审版本、检查范围与实际结果，不成为新增工作授权。

## 复制入口

在框架根目录使用已确认的 Python 3.12+；本机解释器遵循个人规则：

```powershell
python -B framework/commands/create_project.py --output D:\Games\MyGodotGame
```

source 相对维护仓库、target 相对项目。目录内容按清单复制，文件可重命名，原文不渲染。预检允许目录合并，拒绝重复文件、文件/目录冲突及不满足边界的目标；目标必须外部、不存在或为空，完整路径不能含中文或空白。

复制后需要 Git 身份来建立本地初始提交。复制/Git 失败保留现场，不自动清理；没有环境探测、测试、推送或项目同步。完整使用契约见 [框架与创建器](docs/operation-manual/framework-and-project.md)。

## 提示词与场景路径检查

JSON 顶层保留两个 Project：Yaya 框架维护、Godot 项目开发；categories 下叶子键是名称，字符串是完整正文。场景路径直接为 `docs/quick-reference/<Project>/<分类>/<提示词名称>.md`。一条提示词只对应一个场景，名称一致；不同验收目标或进入状态不能用一个通用正文覆盖。

```powershell
python -B framework/commands/check_scenario_prompt_paths.py
```

可传 `--prompts <JSON>`、`--scenarios <目录>`。只读检查缺少、多余、重复与非法路径；根级 README.md、scenario-index.md 是导航排除项，不保存额外映射。退出 0 为集合一致，1 为缺少或多余，2 为输入/结构错误。它不检查正文 H1、具体步骤、授权、语义和运行结果，相关部分仍须内容审核。

新增或修改正文后同步同名场景及覆盖清单；填写输入、角色与使用边界见 [Skill、Agent 与提示词](docs/operation-manual/skills-and-agents.md)。完整提示词留在 JSON，不复制到 README 或规则中。后续口语续接遵循 [会话约定](docs/framework-maintenance/updating-the-blank-project.md#后续用口语继续)。

## 导出 advisor 精选表达参考

prompts.json 是唯一手写来源。导出器的 SELECTION 精确选择分类与名称，生成 project-source/skills/project-next-step-advisor/references/prompt-examples.md 及其 prompt-examples/ 分类正文，不另建选择配置。

```powershell
python -B framework/commands/export_advisor_prompt_examples.py
python -B framework/commands/export_advisor_prompt_examples.py --check
```

入选正文、Skill 名称或范围改变后显式导出。全部来源有效后才写输出；正文/占位符原样保留，UTF-8、LF、无时间戳。--check 只比较内容，缺失/过期返回非零且不写入。生成结果随本次逻辑变更保存，相关回归见 [导出器测试](tests/test_advisor_prompt_examples.py)。

创建器只复制已有静态参考；完整 JSON 和导出器不进入项目，项目不访问维护源。advisor 仅按需借鉴措辞，实际规则与当前授权决定行动，详见 [精选参考](docs/operation-manual/skills-and-agents.md#advisor-的精选表达参考)。

## 按需检查

维护层回归使用系统临时目录，包括复制、路径映射、导出、文档指纹与人工验收文件契约：

```powershell
python -B -m unittest discover -s framework/tests -p test_*.py
```

文档指纹和人工文件测试只建立中立 Git 夹具，不创建业务项目或运行游戏；合成结果不证明真实人工体验。项目工具回归需要明确指定且已对应本次修改的外部项目：

```powershell
python -B framework/commands/run_project_tool_tests.py --project D:\Games\MyGodotGame
```

这个入口只运行已有 unittest，不创建或配置项目、不写示例业务台账，也不顺带执行 Godot、人工验收或发布。所测项目的机器配置与无关文件保留。仅静态任务不执行这些回归命令。

真实引擎、lint、gdUnit、Analyzer 协议、资源工作台、保存/恢复、渲染、规模和消费导出夹具按实际变化选择，依赖、位置与结果边界集中在 [专项验证说明](docs/framework-maintenance/validating-framework.md#工作台专项验证入口)。Python 工具通过与真实引擎运行分别记录；夹具文件存在也不证明本轮已执行。

## HTML 工具保留边界

当前只交付 Markdown，不运行手册构建或 Mermaid 阅读版。现有生成器仍含旧目录和章节约定；以后重新引入时再适配两本独立手册，并由用户检查浏览器排版与交互，见 [阅读版说明](docs/framework-maintenance/updating-the-blank-project.md#html-阅读版暂缓)。

维护脚本解决可重复的文件/数据操作，Agent 决定任务范围与结果意义。不增加逐动作监督、重复状态、发布资格或自动同步；共享解析和指纹函数可复用，独立用户命令按实际职责区分。
