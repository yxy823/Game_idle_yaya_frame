# Feature 交付前发现 Bug

[返回场景索引](../../scenario-index.md#问题修复) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

当前 Feature 尚未交付，发现本次改动不符合原要求。例如，自动测试已经通过，但试玩时发现了新的 Bug。

## 前置条件与适用范围

正式交付以项目规定的 Feature 完成状态和对应完成记录为准；测试通过、代码提交或用户试玩均不能单独作为判定依据。核对 `docs/feature-list.json`、对应 Feature 详情及完成依据与交付记录；记录缺失或相互矛盾时，先核实交付状态。

本页处理当前未完成 Feature 引入的缺陷，原要求仍然有效，且本次已授权修复。能够访问项目和现场材料即可开始调查，不要求先稳定复现。

已交付行为发生独立回归时，使用[Feature 交付后发现 Bug](../completed-feature/bug-after-delivery.md)。以下情况不进入本页修复：

- **要求变化：** 用户希望改变既有行为或专业要求，转入对应的要求变更流程。
- **范围外问题：** 缺陷与当前 Feature 无关，先确认任务归属和修复范围。
- **只请求诊断：** 仅交付调查结果与尚缺证据，不执行未经授权的修复。

## 参与角色与职责边界

用户提供期望、实际表现和现场材料，并完成适用的人工复验。Agent 在原任务内定位、修复和验证；测试工具与 Godot 提供真实运行结果。

## 流程概览

问题调查 → 修复与回归 → 验证 → 返回原 Feature 的完成检查。

## 执行步骤

使用 [集中提示词库](../../../../prompts.json)中的“Godot 项目开发 → 修复与改进 → 定位与修复 Bug”。填入当前 Feature ID、有效预期、实际表现、触发条件和日志或截图，明确问题由当前未完成任务引入；遵循该入口当前有效的提交约束。

当前 Agent 使用 [$feature-execute](../../../../../project-source/skills/feature-execute/SKILL.md)在原任务内继续，沿用已有修复授权。本场景不调用 `engineering-change-plan` 新建独立 Bug 任务，也不需要专门的 Bug Agent。

**S1｜记录问题与现场**

Agent 检查 `git status --short`、当前差异、Feature 详情及有效要求来源，记录版本、触发步骤和期望/实际差异，保留原始失败日志与已有测试报告。

**S2｜查明根因**

Agent 在已授权环境中复现问题，检查相关代码、场景、资源及调用关系，使用必要的日志或定点测试验证原因假设。将已证实原因与尚待核实判断分开记录。

**S3｜修复并补充回归**

Agent 按 `feature-execute` 的实现与测试要求，先补充能暴露原错误的回归检查，再实施最小完整修复，并维护必要的测试登记。自动回归不适用时，记录具体原因和可重复的人工复验方法。

**S4｜验证最终内容**

Agent 使用项目配置的 Python/Godot，按 [解析与 lint 规范](../../../../../project-source/methodology/gdscript-lint.md)及 [测试策略](../../../../../project-source/methodology/08-testing-strategy.md)执行受影响验证。适用的最终 Feature 测试使用 `tools/testing/run-gdunit-tests.py --feature <当前真实ID> --scope auto`；已确定需要 full 时将范围参数改为 `--scope full`。等待运行结束并检查退出码及报告。

需要保存自动依据时，用 `tools/features/record-feature-completion.py record-tests --feature <当前真实ID> --run <真实result.json路径>` 导入整组有效结果。命令在游戏项目根目录执行，使用已确认 Python 并加 `-B`；导入会替换测试引用，失败可能清除旧引用，完整调用见[结果导入恢复](../../verification/existing-results/import-passed-tests.md#执行步骤)。适用的人工复验由用户实际操作并确认。

**S5｜返回原 Feature 的完成检查**

Agent 在当前任务中保存根因、修复位置、回归结果及待完成事项，按 `feature-execute` 接续原 Feature 的完成检查；核对实际人工结果、完成依据及本次有效提交约束，不以错误暂时消失直接标记完成。

## 步骤产出与状态变化

| 步骤 | 可以进入下一步的条件 |
| --- | --- |
| S1 | 现象、版本和要求来源可核实，原失败材料已保留 |
| S2 | 根因得到证据支持，可以确定修复位置 |
| S3 | 修改针对已确认根因，回归检查覆盖原错误 |
| S4 | 当前验证通过；需人工复验时，已取得有效的人工复验结果 |
| S5 | 原任务中可找到本次处置结果与待完成事项，可继续完成检查 |

## 资源与文件影响

| 项目内对象 | 影响 |
| --- | --- |
| 当前 Feature 索引与详情 | 读取范围和状态，在原任务中补充诊断与进展 |
| 已确认需求与验收条件（AC） | 读取并保留，不为迎合错误实现而改写 |
| 出错的代码、场景或资源 | 修改本次授权范围内的实现 |
| 测试代码及 `docs/test-registry.json` | 补充实际需要的回归与登记 |
| 原始现场材料、本次运行报告及完成依据 | 保留失败事实，保存和引用真实验证结果 |

## 阻塞、异常与范围变化

- **证据不足：** 保留调查过程和具体未知，补充所需证据后继续 S2。一次未复现不能作为修复依据。
- **验证受阻或失败：** 环境无法运行时保留错误，补齐条件后回到 S4；原问题仍在时返回 S2。不会因既有自动测试处于通过状态而忽略新的实际失败结果。
- **归属或要求变化：** 发现问题属于已交付行为的独立回归、范围外缺陷或新要求时，保留现场，转入对应处理流程。

## 完成状态与验证标准

原问题已有根因与修复证据，受影响验证和适用的人工复验通过，当前任务记录已补齐，可以继续原 Feature 的完成检查。这表示本次缺陷处置完成，不直接把整个 Feature 标为完成。

## 流程关联与衔接关系

后续为原 Feature 的完成检查。相关流程：[Feature 交付后发现 Bug](../completed-feature/bug-after-delivery.md)、[结果导入恢复](../../verification/existing-results/import-passed-tests.md)。

**依据：** [工程变更与 Bug 归属](../../../../../project-source/methodology/07-engineering-change.md)、[回归与完成依据](../../../../../project-source/methodology/08-testing-strategy.md)、[Feature 完成规范](../../../../../project-source/methodology/03-execute-loop.md#stage-7--mark-complete)。
