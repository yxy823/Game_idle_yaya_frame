---
name: bug-diagnosis
description: 通过复现、可区分的假设和因果证据调查 Godot 项目中的一个具体缺陷。用于原因未知，或修复前需要可靠诊断时。不用于预期是否成立还不确定的反馈，改用 feedback-triage。
---

# 诊断项目缺陷

查清报告中的触发条件怎样产生错误结果。调查方法使用 `yaya/methodology/07-engineering-change.md` 的 **因果诊断**；Bug 的路由、记录和修复验证也由该规范负责。已经确定的契约和职责归属直接沿用，不重新分诊。

## 选择需要的证据

从已确认的预期行为、实际症状、涉及的实现和现有证据出发。如果还不清楚观察到的现象是否违背已批准的意图，先使用 [feedback-triage](../feedback-triage/SKILL.md)，再选择修复方案。通过项目的 `AGENTS.md` 阅读受影响的工程领域；不要为一个故障加载所有领域或所有诊断方法。

按权威诊断方法取得有用的复现，区分可能的原因，并讲清因果链：

- 在能可运行地复现之前，可以先用已有日志和源码推理调查。
- 运行时证据、诊断用的修改和测试运行，必须符合当前任务的授权范围和项目验证规则；只读请求不授权这些操作。

只有某个方法的证据能回答当前问题时才使用它：

| 需要的证据 | 方法 |
| --- | --- |
| 缺少关于某次状态转换、对象负责方或重复操作的信号 | [diagnostics-instrumentation](../diagnostics-instrumentation/SKILL.md) |
| 可比较的耗时、内存或负载测量 | [diagnostics-performance](../diagnostics-performance/SKILL.md) |
| 持续或重复运行中的累积与稳定性 | [diagnostics-soak-test](../diagnostics-soak-test/SKILL.md) |
| 证据指向 Shader 加载、材质/参数绑定、视觉数据流或渲染开销 | [Shader 诊断](references/shader-diagnostics.md) |

同一次诊断可以按权威方法追查规则结果、状态、反馈以及它们之间的连接。出现视觉症状时，不要求用户判断缺陷属于哪一层，也不拆分它的记录。

## 把诊断交回所属任务

报告下列内容：

- 症状和预期的来源；
- 有用的触发条件；
- 因果结论及支撑证据；
- 有参考价值时，被排除的其他解释；
- 仍然存在的不确定性。

说明实际的调查覆盖范围，以及还必须做的检查。提出证据能支撑的最小修复。不要因为某个变通做法让症状消失了，就把一个假设称为根本原因。

长期保存的 Bug 证据按 methodology 07 处理；保留的结果和临时探测按 `yaya/methodology/09-records-reports-and-handoff.md` 处理。只在已有的 Feature/Progress 位置记录任务需要的内容。保留原始的失败证据，并写明临时诊断代码当前的状态。

只要求诊断的请求，以有依据的结论或明确的阻塞结束；原因未查清就写未查清。修复已获授权时，按职责归属约定把诊断交给当前 Feature 或 [engineering-change-plan](../engineering-change-plan/SKILL.md)。诊断不另设审批关卡，也不代替回归验证、适用的人工验收或已有的完成约定。完成后返回调用方；Skill 返回不会结束它所服务的已授权任务（methodology 03 **授权与续接**）。
