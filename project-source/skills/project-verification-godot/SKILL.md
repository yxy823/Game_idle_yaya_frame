---
name: project-verification-godot
description: 运行用户要求的 Godot 解析、lint、已有自动测试或限定范围的场景检查，并报告实际结果。有无 Feature 的工作都适用；不实现修复，也不确认交付已完成。
---

# 运行要求的验证

从当前任务确认要做的检查、检查对象和允许的运行操作。复用已配置的工具和仍然有效的准备结果；只有确实依赖环境、且在任务授权范围内时，才使用 [project-environment-godot](../project-environment-godot/SKILL.md)。

## 选择匹配的检查

下表路径相对项目根目录。只读这次请求需要的分支，不必读全部验证方法。

| 要求的结果 | 权威方法 |
| --- | --- |
| 脚本解析或 lint | `methodology/contracts/gdscript-lint.md` 中的 **直接运行**，包括它要求的内部扫描范围、退出码和原始输出的处理方式 |
| 已有 Feature 的测试 | `methodology/08-test-traceability-and-evidence.md` 中的 **运行时的测试影响选择**、该 Feature 和测试登记表（Registry）中的实际义务，以及 `tools/README.md` 中的运行器约定 |
| 没有 Feature 时指定的测试套件或组件 | `tools/README.md` 和 methodology 08 中的定向目标路线；不需要 Feature、计划或完成记录 |
| 实际启动，或观察指定的场景、资源 | 要求的场景、通过 `AGENTS.md` 找到的项目工程规则，以及实际配置的 Godot 环境；只有缺少准备时，才按 `tools/README.md` 中的首次扫描说明处理 |

在已有的 worktree 中检查时，如果有关数据或清理去向未知或发生了变化，在运行会写入的工具之前，先读 [Godot worktree 运行准备](../worktree-create-godot/references/godot-worktree-runtime.md)。这包括测试和编辑器、导入操作，不只是运行游戏。复用仍然有效的准备结果；该参考不要求调用创建 Skill、另建工作目录，也不要求把这次检查扩大成完整的交付运行。

只运行要求的检查种类，同时保留每种方法要求的范围和已有义务。一次定向的诊断运行，不能满足更大的交付要求。要求的限制与必需的方法或权限冲突时，说明具体冲突，不要悄悄降低检查标准或扩大任务。

本方法不为了通过而修改实现、测试、AC 或检查策略。失败交回已有的负责方；诊断或修复按任务的实际授权进行。原始结果按 `methodology/09-records-reports-and-handoff.md` 的 **报告与清理** 保留。允许的仓库写入，按 `methodology/15-task-scope-git-and-reporting.md` 和任务的提交条件执行。

## 报告并继续

报告实际的检查对象、命令、退出码、原始证据路径、结果和未执行的范围。区分检查通过、失败、中断，以及运行器合法返回的 `not_required` 结果。场景能启动或自动测试通过，都不构成实际的人工验收。

任务还要求导入或修复自动化证据时，使用 [verification-evidence-godot](../verification-evidence-godot/SKILL.md)。否则直接返回结果，不制造完成记录。只要求检查的请求，可以在如实报告失败后结束；这不代表被检查的工作已经通过。所属任务继续已经获得授权的工作，并按已有约定判断是否完成，不新增 Stage，也不重复请求批准。
