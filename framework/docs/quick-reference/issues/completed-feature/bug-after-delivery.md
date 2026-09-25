# Feature 交付后发现 Bug

[返回场景索引](../../scenario-index.md#问题修复) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

某项 Feature 已正式交付，后来使用或修改其他内容时，发现其行为不符合仍然有效的要求，需要独立修复。

## 前置条件与适用范围

正式交付以项目规定的 Feature 完成状态和对应完成记录为准；测试通过、代码提交或用户试玩均不能单独作为判定依据。核对 `docs/feature-list.json`、对应 Feature 详情及完成依据与交付记录；记录缺失或相互矛盾时，先核实交付状态。

本页处理已交付行为的独立缺陷，原要求仍然有效，且本次已授权独立 Bug 修复。建立新任务前满足项目的干净工作区要求，保留已有未提交内容。

问题由当前未完成 Feature 引入时，使用[Feature 交付前发现 Bug](../current-feature/bug-after-tests.md)。以下情况不进入本页修复：

- **要求变化：** 用户希望改变既有行为或专业要求，转入对应的要求变更流程。
- **范围外问题：** 另外发现的缺陷不在本次修复范围内，先确认任务归属和修复范围。
- **只请求诊断：** 仅交付调查结果与尚缺证据，不执行未经授权的修复。

## 参与角色与职责边界

用户提供期望、实际表现和现场材料，并完成适用的人工复验。Agent 建立独立 Bug 任务，负责定位、修复和验证；测试工具与 Godot 提供真实运行结果。

## 流程概览

确认问题与任务归属 → 修复与回归 → 验证 → 返回本次 Bug 任务的完成检查。

## 执行步骤

使用 [集中提示词库](../../../../prompts.json)中的“Godot 项目开发 → 修复与改进 → 定位与修复 Bug”。填入原 Feature ID、有效预期、实际表现、现场材料及本次独立修复范围，遵循该入口当前有效的提交约束。

当前 Agent 先使用 [$engineering-change-plan](../../../../../project-source/skills/engineering-change-plan/SKILL.md)的 `bug` 模式建立独立任务，再使用 [$feature-execute](../../../../../project-source/skills/feature-execute/SKILL.md)实施。两个 Skill 由同一主 Agent 衔接，不需要新建“Bug Agent”。

**S1｜记录问题与现场**

Agent 检查工作区和原 Feature 的完成状态、完成记录及有效要求，保存当前版本、触发步骤、期望/实际差异与原始现场，保留原完成历史。

**S2｜建立独立 Bug 任务**

Agent 使用 `engineering-change-plan` 的 `bug` 模式说明修复目标、范围、AC、受影响模块、回归责任和必要诊断。沿用已确认的具体方案，缺少实质决定时由用户补齐。

按该 Skill 写入独立 Feature 索引与详情，合并必要组件登记并检查台账。独立工程 Bug 不伪装为 Product 要求变化，不重开原 Feature；提交安排遵循本次入口当前有效的约束。

**S3｜查明根因并修复**

Agent 切换到 `feature-execute`，读取新 Bug Feature，按已有授权复现并确认根因，补充可暴露原错误的回归检查，再实施最小完整修复。自动回归不适用时，保存原因和可重复的人工复验方法。

**S4｜验证最终内容**

Agent 使用项目配置的 Python/Godot，按 [解析与 lint 规范](../../../../../project-source/methodology/gdscript-lint.md)及 [测试策略](../../../../../project-source/methodology/08-testing-strategy.md)完成受影响验证。适用的最终测试使用 `tools/testing/run-gdunit-tests.py --feature <新Bug真实ID> --scope auto`；已确定需要 full 时将范围参数改为 `--scope full`。等待结束并检查退出码与报告。

需要保存自动依据时，用 `tools/features/record-feature-completion.py record-tests --feature <新Bug真实ID> --run <真实result.json路径>` 导入整组有效结果。命令在游戏项目根目录执行，使用已确认 Python 并加 `-B`；导入会替换测试引用，失败可能清除旧引用，完整调用见[结果导入恢复](../../verification/existing-results/import-passed-tests.md#执行步骤)。用户完成适用的人工复验，旧 Feature 的历史验收不作为本次修复验收。

**S5｜返回本次 Bug 任务的完成检查**

Agent 按 `feature-execute` 保存根因、触发条件、回归经验和待完成事项，再接续新 Bug Feature 的完成检查。核对本次记录、实际验收及有效提交约束，保留原 Feature 的 AC 和完成历史。

## 步骤产出与状态变化

| 步骤 | 可以进入下一步的条件 |
| --- | --- |
| S1 | 现象、版本和要求来源可核实，能够对应原完成历史 |
| S2 | 独立 Bug 任务与回归责任明确，原 Feature 保留完成状态 |
| S3 | 根因得到证据支持，修复和回归检查针对同一问题 |
| S4 | 当前验证通过；需人工复验时，已取得有效的人工复验结果 |
| S5 | 本次修复任务中可找到必要经验与待完成事项，可继续完成检查 |

## 资源与文件影响

| 项目内对象 | 影响 |
| --- | --- |
| 原 Feature、原验收和历史报告 | 读取并保留，不重开原 Feature 或改写当时的完成事实 |
| 已确认需求与原验收条件（AC） | 读取并保留，不为迎合错误实现而改写 |
| 新 Bug 任务索引与详情 | 创建独立任务，记录诊断、验证责任和修复经验 |
| 出错的代码、场景或资源 | 修改本次授权范围内的实现 |
| 测试代码及 `docs/test-registry.json` | 补充实际需要的回归与登记 |
| 原始现场材料、本次运行报告及完成依据 | 保留失败事实，保存和引用真实验证结果 |
| Git 工作区与提交 | 遵循本次有效提交约束，不混入无关改动 |

## 阻塞、异常与范围变化

- **证据不足：** 无法核实原完成记录或有效预期时，先补充所需证据。根因仍不明确时继续 S3 的调查，不宣称已经修复。
- **验证受阻或失败：** 环境不足时保留错误，补齐条件后回到 S4；回归失败或人工复验未通过时返回 S3。原 Feature 的历史验收不能替代本次修复验证。
- **归属或要求变化：** 发现问题由当前未完成 Feature 引入，或实际属于范围外缺陷、新要求时，保留现场，转入对应处理流程。

## 完成状态与验证标准

独立 Bug 任务归属明确，根因和修复有证据，受影响验证和适用的人工复验通过，修复经验已保存，原 Feature 历史未改写。此时可以继续本次 Bug 任务的完成检查；完成记录、约定提交和交接仍按该任务继续，不能仅凭错误消失便标为完成。

## 流程关联与衔接关系

后续为本次 Bug 任务的完成检查。相关流程：[Feature 交付前发现 Bug](../current-feature/bug-after-tests.md)、[结果导入恢复](../../verification/existing-results/import-passed-tests.md)。

**依据：** [工程 Bug 规范](../../../../../project-source/methodology/07-engineering-change.md)、[Feature 完成规范](../../../../../project-source/methodology/03-execute-loop.md#stage-7--mark-complete)、[工程规划入口](../../../../../project-source/skills/engineering-change-plan/SKILL.md)。提示词正文见[集中提示词库](../../../../prompts.json)。
