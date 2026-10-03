# 维护工具

本目录保存创建器、复制清单、集中提示词、文档和审核/回归材料。项目使用说明从 [文档总入口](docs/README.md) 进入，维护原则见 [维护与同步说明](docs/framework-maintenance/updating-the-blank-project.md)。这些维护材料不复制到生成项目；框架自用 Skill 放在仓库根目录的 `.agents/skills/`。

## 文件与职责

| 路径 | 职责 |
| --- | --- |
| [progress.md](progress.md) | 仍需推进的工作、验证缺口和必要决定；完成即删，历史查 Git |
| [project-files.json](commands/project-files.json) | 唯一复制映射，每项只有 source 与 target |
| [commands/README.md](commands/README.md) | 完整命令目录，含创建器、路径/关系图检查和项目工具回归入口 |
| [godot-development-prompts.json](prompt_scenarios/prompts/godot-development-prompts.json) | Godot 项目开发的完整任务提示词；advisor 直接读取的共享来源 |
| [yaya-maintenance-prompts.json](prompt_scenarios/prompts/yaya-maintenance-prompts.json) | Yaya 框架维护的完整任务提示词 |
| [docs/README.md](docs/README.md) | 操作手册、场景手册与维护说明的统一入口 |
| [Codex 指令编写 Skill](../.agents/skills/writing-for-agents-yaya/SKILL.md) | 框架内 Codex 指令的编写、修改与作者自查；框架自用，不分发 |
| [Codex 指令审核 Skill](../.agents/skills/review-agent-instructions-yaya/SKILL.md) | 独立实例对现有指令作正式只读审核；引用共用依据，不接管修复，不分发 |
| [框架文档编写 Skill](../.agents/skills/technical-documentation-writing-yaya/SKILL.md) | 框架自用的手册、场景、维护与审核说明写作方法，独立维护且不分发 |
| [Godot 项目文档编写 Skill](../project-source/skills/technical-documentation-writing-godot/SKILL.md) | 面向游戏项目的文档写作方法，独立维护并整包复制到新项目 |
| [tests/repository/](tests/repository/) | 可从仓库根目录运行的创建器、路径映射、文档指纹与人工文件等维护回归 |
| [tests/external-project/](tests/external-project/) | 需要指定外部项目的工具回归、工作台与插件夹具，不进入复制清单 |
| [维护准则与报告](docs/framework-maintenance/review-materials.md) | 长期准则与当次报告的保留边界 |

总体取舍依据[根规则的核心原则](../AGENTS.md#核心决策原则)，职责评价见 [Skill、脚本、提示词设计准则](docs/framework-maintenance/baselines/skill-script-prompt-design.md)，场景范围见[责任边界](docs/framework-maintenance/baselines/scenario-coverage.md)。当次报告不成为新增工作授权，历史通过 Git 查阅。

## 复制入口

在框架根目录使用已确认的 Python 3.12+；本机解释器遵循个人规则：

```powershell
python -B framework/commands/create_project.py --output D:\Games\MyGodotGame
```

复制入口按以下约定处理路径与文件：

- **路径基准**：source 相对维护仓库，target 相对项目。
- **复制方式**：目录内容按清单复制，文件可重命名，原文不渲染；目录内只排除明确的 Python 缓存，预检使用相同排除范围，详见下方完整契约。
- **预检范围**：允许目录合并；拒绝重复文件、文件/目录冲突及不满足边界的目标。
- **目标要求**：位于框架之外，不存在或为空，完整路径不能含中文或空白。

复制后需要 Git 身份来建立本地初始提交。复制/Git 失败保留现场，不自动清理；没有环境探测、测试、推送或项目同步。完整使用契约见 [框架与创建器](docs/operation-manual/框架基础/framework-and-project.md)。

## 提示词与场景路径检查

两份提示词 JSON 在 `prompt_scenarios/prompts/` 各保存一个 Project：`yaya-maintenance-prompts.json` 保存 `Yaya 框架维护`，`godot-development-prompts.json` 保存 `Godot 项目开发`。每份保留单元素顶层数组；categories 下叶子键是名称，字符串是完整正文。场景路径直接为 `prompt_scenarios/scenarios/<Project>/<分类>/<提示词名称>.md`。一条提示词只对应一个场景，名称一致；不同验收目标或进入状态不能用一个通用正文覆盖。

```powershell
python -B framework/prompt_scenarios/tools/check_scenario_prompt_paths.py
```

路径检查器的参数与结果如下：

- **可选参数**：`--prompts <JSON> [<JSON> ...]`、`--scenarios <目录>`；默认合并两份库的名称检查全部场景，每份只允许一个 Project，跨文件重复 Project 也会报错。
- **检查范围**：只读检查缺少、多余、重复与非法路径；根级 README.md、scenario-index.md 是导航排除项，不保存额外映射。
- **退出码**：
  - `0`：集合一致。
  - `1`：缺少或多余。
  - `2`：输入或结构错误。
- **内容审核**：正文 H1、具体步骤、授权、语义和运行结果不在此工具检查范围内，仍须另行核对。

新增或修改正文后核对同名场景及[场景索引](prompt_scenarios/scenarios/scenario-index.md)，只同步实际变化；填写输入、角色与使用边界见 [Skill、Agent 与提示词](docs/operation-manual/方法与工具/skills-and-agents.md)。完整提示词留在 JSON，不复制到 README 或规则中。后续口语续接遵循 [会话约定](docs/framework-maintenance/updating-the-blank-project.md#后续用口语继续)。

## advisor 的共享场景入口

advisor 在核对项目现状后，直接读取 `D:/A_Games/Game_idle_yaya_frame/framework/prompt_scenarios/prompts/godot-development-prompts.json`，按相关分类与场景名称选择候选，再核对正文的目标、前提和执行边界。它结合当前事实生成具体指令，并区分缺少输入、可适配场景和确实需要补充的场景。

修改 Godot 提示词后，advisor 下次读取同一份正文；不需要导出或维护提示词副本。项目自己的规则、目标 Skill 和有效授权决定实际行动，advisor 只提供建议，不修改共享库。使用说明见 [advisor 场景入口](docs/operation-manual/方法与工具/skills-and-agents.md#advisor-的共享场景入口)。

## 按需检查

维护层回归使用系统临时目录，包括复制、路径映射、文档指纹与人工验收文件契约：

```powershell
python -B -m unittest discover -s framework/tests/repository -p test_*.py
```

文档指纹和人工文件测试只建立中立 Git 夹具，不创建业务项目或运行游戏；合成结果不证明真实人工体验。项目工具回归需要明确指定且已对应本次修改的外部项目：

```powershell
python -B framework/tests/external-project/run_project_tool_tests.py --project D:\Games\MyGodotGame
```

这个入口只运行已有 unittest，不创建或配置项目、不写示例业务台账，也不顺带执行 Godot、人工验收或发布。所测项目的机器配置与无关文件保留。仅静态任务不执行这些回归命令。

真实引擎、lint、gdUnit、Analyzer 协议、资源工作台、保存/恢复、渲染、规模和消费导出夹具按实际变化选择，依赖、位置与结果边界集中在 [专项验证说明](docs/framework-maintenance/validating-framework.md#lint-与运行器专项入口)。Python 工具通过与真实引擎运行分别记录；夹具文件存在也不证明本轮已执行。


维护脚本解决可重复的文件/数据操作，Agent 决定任务范围与结果意义。不增加逐动作监督、重复状态、发布资格或自动同步；共享解析和指纹函数可复用，独立用户命令按实际职责区分。
