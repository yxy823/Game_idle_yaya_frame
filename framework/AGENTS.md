# framework/ 的维护约定

本文件只写 `framework/` 下三类文件的规则；仓库通用的约束、决策原则和提交规则见根 [AGENTS.md](../AGENTS.md)，目录说明见框架入口的[目录与职责](README.md#目录与职责)。

## 框架待办

框架维护任务开始或续接时，按当前主题核对 [todo.md](todo.md)：

- **只保留**：仍需推进的工作、真实的验证缺口、阻塞和必要的待决定事项，写明下一步和必要依据。条目不授予实施权限。
- **及时删除**：完成并通过必要验证的事项立即删除；还有人工验收时，只保留具体的待验收项。无待办时清空文件。
- **不保留历史**：历史由 Git 保存，不写完成记录、成果汇总或长期搁置的设想。
- **何时更新**：相关状态发生实质变化时，在本次允许写入的范围内及时更新，提交或交接前核对一致。只读任务在回复中指出需要更新的条目；没有实质变化不为改而改。

## 提示词维护

新增、修改、重命名、调整分类或删除预设提示词时，使用 [prompt-and-graph-maintenance-yaya](../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md)，按本次变化核对同名场景、导航、开发场景图与 advisor 引用。两份提示词库的结构、一对一场景和命名规则见[提示词与场景准则](maintenance/design-guidelines/prompts-and-scenarios.md)；提示词正文不写进 README、规则或工具说明。

advisor 通过固定绝对路径 `D:/A_Games/Game_idle_yaya_frame/framework/prompt-scenarios/prompts/godot-development-prompts.json` 只读使用 Godot 提示词库。移动或改名该文件时，同步 `project-source/skills/project-next-step-advisor/SKILL.md`；已创建的项目是否更新由用户决定。

## Lessons

[lessons.md](lessons.md) 记录框架维护中 Agent 自己的流程失误，规则沿用生成项目的[Lessons](../project-source/methodology/09-records-reports-and-handoff.md#lessons)，只有下面几处不同：

- **何时读**：框架维护任务开始或续接时，和 [todo.md](todo.md) 一起读。
- **何时写**：框架维护没有 Stage 7，只在用户纠正 Agent 后写。
- **升级去向**：失误的性质按 04 号的[经验的归宿与规则提升](../project-source/methodology/04-project-rules.md#经验的归宿与规则提升)判断，位置按 [framework-retro-yaya](../.agents/skills/framework-retro-yaya/SKILL.md) 的归属表选；写进用户全局 `CLAUDE.md` 的只提拟议文字。
