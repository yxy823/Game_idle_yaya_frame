# 框架维护入口

本目录保存框架维护材料：创建器与复制清单、维护命令、两本手册、集中提示词与场景、关系图和回归夹具。这些材料不复制到生成项目；框架自用 Skill 放在仓库根目录的 `.agents/skills/`。维护约定以根 [AGENTS.md](../AGENTS.md) 为准。

## 目录与职责

本表是 `framework/` 的唯一目录说明；子目录 README 只说明自身内容，不再重画上层目录。

| 路径 | 职责 |
| --- | --- |
| [progress.md](progress.md) | 仍需推进的工作、验证缺口和必要决定；完成即删，历史查 Git |
| [commands/](commands/README.md) | 创建器、唯一复制清单与跨多处使用的维护脚本；README 是全部维护命令用法的唯一说明，包括放在各对象 `tools/` 中的脚本 |
| [docs/](docs/README.md) | 文档总入口、框架术语、操作手册与框架维护文档 |
| [docs/operation-manual/](docs/operation-manual/README.md) | 操作手册：框架概念、配置、职责与工具用法，按专题分四个子目录 |
| [docs/framework-maintenance/](docs/framework-maintenance/README.md) | 维护与同步、验证范围、插件版本记录；职责设计准则按评价对象分页放在 `design-guidelines/` |
| [prompt-scenarios/](prompt-scenarios/scenarios/README.md) | `prompts/` 两份集中提示词库，`scenarios/` 每条提示词对应的同名场景页、场景索引与编写要求，`tools/` 提示词、场景与场景图的检查和链接脚本 |
| [relationship-maps/](relationship-maps/README.md) | 文档系统关系图、开发场景图、读图与维护说明、[Graph_Map 文件格式](relationship-maps/graph-map-format.md)；`tools/` 存放文档图覆盖检查脚本 |
| [tests/repository/](tests/repository/) | 从仓库根目录运行的维护回归 |
| [tests/external-project/](tests/external-project/) | 需要指定外部项目的工具回归、工作台与插件夹具，各子目录 README 说明放置与运行；不进入复制清单 |

操作手册放在 `docs/`；场景速查手册与提示词同放在 `prompt-scenarios/`，便于按名称一一对应；关系图同时覆盖两者，单独放在 `relationship-maps/`。两册不互相引用，三者由[文档总入口](docs/README.md)统一导航。

## 从哪里开始

| 要做什么 | 入口 |
| --- | --- |
| 修改框架或分发材料，判断要同步哪些说明、选择哪种验证 | [维护与同步](docs/framework-maintenance/maintenance-and-sync.md) |
| 新增或调整文档、Skill、脚本、提示词与场景的职责 | [职责设计准则](docs/framework-maintenance/design-guidelines/README.md) |
| 运行创建器、检查命令或回归 | [维护命令](commands/README.md) |
| 编写或整理框架说明 | [Yaya 框架文档编写 Skill](../.agents/skills/technical-documentation-writing-yaya/SKILL.md) |
| 修改提示词、场景或关系图 | [提示词与关系图维护 Skill](../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md) |

总体取舍依据[根规则的核心原则](../AGENTS.md#核心决策原则)。维护脚本只处理可重复的文件与数据操作，任务范围与结果意义由 Agent 判断；不增加逐动作监督、重复状态、发布资格或自动同步。
