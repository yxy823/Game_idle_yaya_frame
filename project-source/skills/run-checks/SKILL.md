---
name: run-checks
description: 运行用户要求的 Godot 解析、lint、已有自动测试或限定范围的场景检查，并报告实际结果。有无 Feature 的工作都适用；不实现修复，也不确认交付已完成；已有测试证据的引用、过时或中断用 verification-evidence。
---

# 运行要求的验证

从当前任务确认要做的检查、检查对象和允许的运行操作。复用已配置的工具和仍然有效的准备结果；只有确实依赖环境、且在任务授权范围内时，才使用 [environment-setup](../environment-setup/SKILL.md)。

## 选择匹配的检查

下表路径相对项目根目录。只读这次请求需要的分支，不必读全部验证方法。

| 要求的结果 | 权威方法 |
| --- | --- |
| 脚本解析或 lint | `yaya/methodology/contracts/gdscript-lint.md` 中的 **直接运行**，包括它要求的内部扫描范围、退出码和原始输出的处理方式 |
| 已有 Feature 的测试 | 用 `yaya/tools/testing/run-gdunit-tests.py --feature`，参数见 `yaya/tools/README.md` 的 **run-gdunit-tests.py**；选择依据见 `yaya/methodology/08-test-traceability-and-evidence.md` 的 **运行时的测试影响选择**，以及该 Feature 和测试登记表（Registry）中的实际义务 |
| 没有 Feature 时指定的测试套件或组件 | 用同一入口的 `--target`，参数见 `yaya/tools/README.md` 的 **run-gdunit-tests.py**；不需要 Feature、计划或完成证据 |
| 没有 Feature 时按已有变更选择测试 | 用同一入口的 `--changed`，参数见 `yaya/tools/README.md` 的 **run-gdunit-tests.py**；选择依据见 08 号规范的 **运行时的测试影响选择** |
| 实际启动，或观察指定的场景、资源 | 要求的场景、通过 `AGENTS.md` 找到的项目工程规则，以及实际配置的 Godot 环境；启动方法见 `yaya/tools/README.md` 的 **启动场景冒烟检查**，只有缺少准备时，才按同一文件的 **首次 Godot 扫描** 处理 |
| 导出一个包并在本机启动 | `yaya/tools/README.md` 的 **本地导出检查**；修改了导出配置时，再按 `yaya/agent-rules/41-export-config/README.md` 的 **验证** 检查对应的产物 |

运行 gdUnit 测试只用上述入口，不直接调用 `addons/gdUnit4/runtest.*`，也不用 `--headless` 直接运行 gdUnit。测试失败需要解读时，读 `yaya/agent-rules/70-tests/gdunit4-profile.md`。

在已有的 worktree 中检查时，如果有关数据或清理去向未知或发生了变化，在运行会写入的工具之前，先读 [在独立检出目录中准备 Godot](../worktree-create/references/godot-worktree-runtime.md)。这包括测试和编辑器、导入操作，不只是运行游戏。复用仍然有效的准备结果；该参考不要求调用创建 Skill、另建工作目录，也不要求把这次检查扩大成完整的交付运行。

只运行要求的检查种类，同时保留每种方法要求的范围和已有义务。一次定向的诊断运行，不能满足更大的交付要求。要求的限制与必需的方法或权限冲突时，说明具体冲突，不要悄悄降低检查标准或扩大任务。

本方法不为了通过而修改实现、测试、AC 或检查策略。失败交回已有的负责方；诊断或修复按任务的实际授权进行。原始结果按 `yaya/methodology/09-records-reports-and-handoff.md` 的 **报告与清理** 保留。允许的仓库写入，按 `AGENTS.md` 的 **Git 与提交** 和任务的提交条件执行。

## 报告并继续

报告实际的检查对象、命令、退出码、原始证据路径、结果和未执行的范围。区分检查通过、失败、中断，以及运行器合法返回的 `not_required` 结果。场景能启动或自动测试通过，都不构成实际的人工验收。

任务还要求导入或修复自动化证据时，使用 [verification-evidence](../verification-evidence/SKILL.md)。否则直接返回结果，不制造完成证据。只要求检查的请求，可以在如实报告失败后结束；这不代表被检查的工作已经通过。所属任务继续已经获得授权的工作，并按已有约定判断是否完成，不新增 Stage，也不重复请求批准。
