# 操作手册

本册解释框架是什么、项目对象怎样分工、配置保存在哪里，以及工具与 Skill 能做什么。具体情境的执行流程由场景手册承担，本册不重复列场景处理步骤。

## 框架与项目的边界

| 对象 | 职责 |
| --- | --- |
| 框架维护仓库 | 保存创建器、可复制源材料、集中提示词与维护文档 |
| `project-source/` | 可复制材料的源目录，尚未初始化为实际游戏项目 |
| 生成后的项目 | 独立维护自己的配置、需求、代码、测试与 Git 历史，不查询框架或接受自动同步 |

[创建器](../../commands/create_project.py)按照[复制清单](../../project-files.json)复制、重命名并建立独立 Git 仓库与本地初始提交。它不负责准备运行环境、启动 Godot、执行测试或推送远程。两本手册和完整提示词库留在框架仓库，不进入生成项目。

## 需求、任务与完成依据

以下路径均相对实际游戏项目根目录。源模板中名称不同的文件，以复制清单的目标路径为准。

| 项目对象 | 用途与关系 |
| --- | --- |
| `docs/product/` | 保存玩家行为、模块要求与专业规格引用 |
| `docs/feature-list.json`、`docs/features/` | 保存任务索引及每项 Feature 的范围、AC、依赖和验证责任 |
| `docs/feature-list-revisions.json` | 保存规划基线与来源变化的同步修订 |
| `docs/test-registry.json` | 保存组件、测试与验证映射；登记不等于测试已运行 |
| `docs/feature-completion-evidence.json` | 按实际需要保存测试与人工依据的引用；文件存在不等于任务完成 |
| `docs/progress.md` | 保存当前停点、待办与必要历史入口，帮助继续原任务 |
| `docs/resource-requirements/` | 保存具体范围的资源准备与消费关系，不替代真实素材 |

Product 表达要做什么，Feature 把范围变为可实现、可验证的工作单元。自动测试通过、人工接受和 Feature 正式完成分别判断；只有项目要求的适用条件全部满足，才能更新正式完成状态。

字段与状态定义以 [Feature 规范](../../../project-source/methodology/02-feature-list-schema.md)、[执行规范](../../../project-source/methodology/03-execute-loop.md)、[测试策略](../../../project-source/methodology/08-testing-strategy.md)为准。

## 配置在哪里

生成项目使用 `docs/methodology-config.json`，初始材料是 [Project_Workflow_Config.json](../../../project-source/Project_Workflow_Config.json)。

| 字段 | 含义 |
| --- | --- |
| `document_language` | 持久项目文档的自然语言，独立于当前聊天语言 |
| `python_executable` | 实际使用的 Python；准备环境时核实解释器，按本机规则填写完整路径 |
| `engine_executable` | 实际 Godot 可执行文件路径，可为绝对路径或相对项目根目录的路径 |

可执行文件字段不包含命令参数或额外引号；JSON 内的反斜杠需要转义。模板路径不证明本机已有该工具。环境检查、实际测试和人工体验各自只证明对应范围。

Godot 的主场景、窗口和插件设置由项目自己的 `project.godot` 管理，初始来源见 [Godot 默认配置](../../../project-source/defaults/project.godot)。不要把机器工具路径和 Godot 项目配置混为同一个文件。

## Skill、Agent 与提示词

Skill 提供专项工作方法；Agent 是实际执行主体；提示词说明本次目标、输入与特有限制。更换 Skill 通常由同一个当前 Agent 完成，不意味着每个 Skill 都要新建一个 Agent。

生成项目的 Skill 位于 `.agents/skills/<名称>/SKILL.md`。常用入口及边界如下，完整权威列表见[方法总览](../../../project-source/methodology/00-overview.md)。

| Skill | 主要职责 |
| --- | --- |
| [feature-plan](../../../project-source/skills/feature-plan/SKILL.md) | 将当前 Product 拆分为计划；已有计划的变化由同步入口处理 |
| [feature-sync](../../../project-source/skills/feature-sync/SKILL.md) | 根据已确认来源变化增量同步计划与登记，不实施代码修改 |
| [engineering-change-plan](../../../project-source/skills/engineering-change-plan/SKILL.md) | 准备独立工程任务，包括已交付行为的独立 Bug |
| [feature-execute](../../../project-source/skills/feature-execute/SKILL.md) | 承接 Feature 的适用方案、实现、验证、记录与交付 |
| [design-ui-spec](../../../project-source/skills/design-ui-spec/SKILL.md) | 维护界面与交互规格，规格本身不创建实际原型 |
| [content-asset-integration](../../../project-source/skills/content-asset-integration/SKILL.md) | 提供资源接入方法；实际修改由获准任务承接 |
| [project-next-step-advisor](../../../project-source/skills/project-next-step-advisor/SKILL.md) | 根据现状给出下一步建议，不替代已授权实施 |

已有角色源配置为 [researcher](../../../project-source/agents/researcher.toml) 和 [independent-reviewer](../../../project-source/agents/independent-reviewer.toml)，复制后位于 `.codex/agents/`。前者承担受委派的调研；后者只在指定范围内独立审核，不兼任修复、人工接受或完成标记。配置文件存在不证明客户端已经加载角色或提供有效隔离。

正式提示词只维护在 [framework/prompts.json](../../prompts.json)。按“Project → 分类 → 条目”取出正文，填写输入占位符后发送；文件本身不会执行命令。具体项目规则、已有授权和所选入口的有效约束共同决定执行边界。

## 工具的输入、输出与副作用

以下工具在生成项目的 `tools/` 下使用。完整参数与命令示例直接见[项目工具说明](../../../project-source/tools/README.md)，此处只说明各自职责。

| 工具 | 输入与输出 | 副作用 |
| --- | --- | --- |
| `checks/check-project-environment.py` | 读取配置，报告结构或 `--require-ready` 就绪检查结果 | 就绪检查可能启动 Godot 版本探测；不运行游戏测试 |
| `checks/check-feature-list.py` | 读取台账与登记；检查一致性，`--eligible` 查询候选 | 只读，不授予实现权限 |
| `features/merge-test-registry.py` | 接收已批准组件候选 | 修改固定登记表，保留现存测试，不生成测试代码 |
| `testing/run-gdunit-tests.py` | 读取任务、范围与配置，产生真实运行结果 | 适用时启动 Godot 并写报告；合法空集不冒充测试通过 |
| `features/record-feature-completion.py` | 导入测试或人工依据，或展示、校验现有记录 | 写入子命令修改完成依据；不运行测试或替用户验收 |

Feature 测试报告按 `reports/gdunit-wrapper/<Feature-ID>/run-<id>/` 保存。导入工具读取真实原件，不能通过手写“通过”替代运行。直接解析与 lint 使用 [Godot 和插件现有命令](../../../project-source/methodology/gdscript-lint.md)，不由完成依据工具代办。

本册后续按概念、项目对象、配置、工具用法拆分专题；只有正文形成后才创建对应目录。维护时保留本册职责，具体场景不在这里扩写。
