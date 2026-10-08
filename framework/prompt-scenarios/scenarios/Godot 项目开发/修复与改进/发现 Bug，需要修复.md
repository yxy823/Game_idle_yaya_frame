# 发现 Bug，需要修复

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

测试、试玩或检查中发现某个 Feature 的行为偏离仍有效的要求。例如数值计算错误、效果显示异常，或操作失败却播放成功反馈，都可使用本入口，不必先判断问题属于规则、表现还是二者接入，也不必先判断 Feature 是否已经交付。

需要的材料：

- 所属 Feature ID，例如 `F003`；不确定时说明问题出现在哪个功能，由 Agent 对照 Progress 和 Feature 记录确认。
- 问题证据：预期与实际、触发条件的原话，以及已有日志或截图的路径；无须凑齐。

有效要求、完成状态、完成记录和实现由 Agent 直接读取。

## 前置条件与适用范围

正式交付以项目规定的 Feature 完成状态和完成记录为准，不以测试通过、代码提交或用户试玩作为单独依据。Agent 在 S1 按这两项判断走哪条路线：

| 所属 Feature | 路线 | 使用的 Skill |
| --- | --- | --- |
| 尚未正式交付 | 原 Feature 修复：留在原 Feature，不新建独立 Bug 任务 | [$feature-execute](<../../../../../project-source/skills/feature-execute/SKILL.md>) |
| 已正式交付 | 独立 Bug Feature：原 Feature 的完成事实与历史保持真实 | [$engineering-change-plan](<../../../../../project-source/skills/engineering-change-plan/SKILL.md>) 规划，再由 `feature-execute` 实施 |

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 修复与改进 → 发现 Bug，需要修复”。填入上述材料。

**S1｜判断交付状态并记录现场**

当前 Agent 读取所属 Feature 的完成状态和完成记录，确定走哪条路线；再核对仍有效要求（已交付时是已交付契约）、实际失败，保留触发条件与已有证据。需要定位原因时使用 [bug-diagnosis-godot](../../../../../project-source/skills/bug-diagnosis-godot/SKILL.md)，按实际问题追查规则结果、表现或接入，复用已有证据并检查实现及直接消费者；区分已证实根因与假设，简述修复位置、受影响模块和复验范围（独立 Bug Feature 还要写明旧行为回归），然后返回所选路线。

**S2｜按路线修复**

- 原 Feature 修复：当前 Agent 使用 `feature-execute` 留在原 Feature 修复。
- 独立 Bug Feature：当前 Agent 先使用 `engineering-change-plan` 的 bug 模式提出独立 Bug Feature：ID、AC、`bug_diagnosis`，验收模式默认规划为 manual，用户另行批准时按批准的模式。方案取得用户批准后写入，再使用 `feature-execute` 修复；当前请求已明确批准具体方案及其执行时沿用。

两条路线共同的要求：

- 按[共用变更规则](../../../../../project-source/Project_AGENTS.md#任务范围)控制影响，保持无需变化的 API、依赖和代码风格。
- 为实际缺陷补必要回归；无法自动覆盖时保留原因与可重复的人工路径。
- 本专用入口在适用验证完成（验收模式为 manual 时包括用户明确的实际验收）且用户明确允许本次提交前，不创建任何本地提交，包括计划和阶段性 checkpoint。修复授权、验收通过或普通“继续”不单独构成提交许可；已有明确许可沿用。

**S3｜完成复验**

当前 Agent 完成受影响自动测试与项目支持的适用解析、lint 或类型检查。验收模式沿用原 Feature 或按已批准的 Bug Feature：manual 时向用户提供实际体验入口并记录明确结果；automated 时以自动 AC 与回归验证为准，不记录未发生的人工决定。未通过继续在授权内修复。

**S4｜返回完成检查**

当前 Agent 核对测试原件、适用的人工接受，以及用户指定的评审结果；检查最终差异没有无关改动，说明关键文件、修复理由及具体剩余风险。取得本次提交许可后，按本次提交约束办理完成检查：原 Feature 修复返回原 Feature 的完成检查，独立 Bug Feature 对自身完成检查。尚缺许可时保留差异并报告待提交。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 交付状态及依据已写明；预期与实际、触发条件和所属 Feature 已写明；根因或待验证假设已标明 |
| S2 | 原 Feature 修复：修复差异已完成，原 AC 未改动。独立 Bug Feature：方案已获批写入（`check-feature-list` PASS），修复差异已完成，原 Feature 的 AC 未改动。两者都有回归测试或写明的人工回归路径 |
| S3 | 受影响测试与解析、lint 的实际结果；manual 时有用户的明确结论 |
| S4 | 最终差异已核对；有提交哈希，或待提交的差异说明 |

## 资源与文件影响

实现、回归测试和所属任务记录修改。原 Feature 修复时，原 Feature 继续承担范围和验收，既有自动通过不覆盖新的失败；独立 Bug Feature 时，原 Feature 的 AC、完成状态与验收历史只读，不为新缺陷重写。

## 阻塞、异常与范围变化

- 要求实质改变：改用[要求已经改好，同步受影响的 Feature](<../任务规划/要求已经改好，同步受影响的 Feature.md>)。
- 还说不清是 Bug、要改要求还是只需调值：先用[已有内容表现不对，先判断是 Bug、要改要求还是只需调值](<已有内容表现不对，先判断是 Bug、要改要求还是只需调值.md>)。
- 无关功能缺陷：另按所属场景处理。
- 只要求诊断：改用[发现异常，先定位原因，不修改实现](<发现异常，先定位原因，不修改实现.md>)。
- 无法复现：保留证据缺口，不宣称修复。
- 缺少方案批准（独立 Bug Feature）、适用的人工接受或本次提交许可：保留真实停点和差异，不提交，不把该停点写成正式完成。

## 完成状态与验证标准

- 原 Feature 修复：原 Feature 的新增实际失败已消除，必要复验已完成（manual 时含用户实际接受），获准提交后返回原任务完成检查。
- 独立 Bug Feature：满足其适用验证（manual 时含实际人工接受），并在用户明确允许后完成提交与收尾，原交付历史保持真实。

## 流程关联与衔接关系

依据：[任务路由表](<../../../../../project-source/methodology/00-overview.md#任务路由表>)、[Bug 的归属与路由](<../../../../../project-source/methodology/07-engineering-change.md#bug-的归属与路由>)、07 的[流程](<../../../../../project-source/methodology/07-engineering-change.md#流程>)、[Bug Feature 契约](<../../../../../project-source/methodology/07-engineering-change.md#bug-feature-契约>)。
