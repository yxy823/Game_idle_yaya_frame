# 已选定 worktree 中的成果，带回目标分支

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

已决定采用某个 worktree 的成果，需要进入指定目标分支。也可在同一整合任务中接着处理已经发生的冲突；不需要重新创建 worktree。

## 前置条件与适用范围

有明确来源、目标和带回范围，或者这些事实能从有效上下文中核实。原任务的需求、验证、人工验收和提交条件继续适用；仍在比较采用哪套方案时，先完成那个选择。

## 参与角色与职责边界

当前 Agent 使用 [worktree-integrate-godot](../../../../../project-source/skills/worktree-integrate-godot/SKILL.md) 整合。必要的真实验收和不能从既有决定推导的业务取舍由用户作出；无文本冲突不免除组合验证。

## 执行步骤

使用[集中提示词库](../../../prompts/godot-development-prompts.json)中的“Godot 项目开发 → 实施与调参 → 已选定 worktree 中的成果，带回目标分支”。提供已知来源、目标、选定成果及相关证据；复用已有明确决定。

**S1｜核实范围与可用整合方式**

查看两端实际状态、相关提交和差异，确定必要依赖能否和无关改动分离。识别所选命令的自动提交或目标分支前移行为；未满足先验收或先验证条件时，不先执行默认提交的操作。

**S2｜带回选定成果并处理实际冲突**

在正确目标实施授权范围内的整合。只有冲突出现时才读取 [冲突处理参考](../../../../../project-source/skills/worktree-integrate-godot/references/merge-conflicts.md)，按双方意图和已确认目标解决；未决定的业务矛盾保留为具体选择，不能靠“全部取某一方”掩盖。

**S3｜验证组合并交付**

使用 [project-verification-godot](../../../../../project-source/skills/project-verification-godot/SKILL.md) 执行适用检查，核对脚本、场景、资源及依赖的组合行为。需要判断证据是否仍有效时使用 [verification-evidence-godot](../../../../../project-source/skills/verification-evidence-godot/SKILL.md)；原任务要求实际人工验收时，用 [manual-acceptance-godot](../../../../../project-source/skills/manual-acceptance-godot/SKILL.md) 为组合结果准备清单。按原任务的提交、验收条件交付，更新必要记录。

## 资源与文件影响

改变目标工作目录中的选定文件及获准的 Git 状态，可能产生整合提交。源 worktree、分支和仍需保留的证据不因整合完成自动删除；不自动推送或改写历史。

## 条件分支与路径规则

整合可以没有冲突；出现冲突也不改变采用成果的目标。原任务同时要求实际人工验收与明确提交许可时（[提交](../../../../../project-source/Project_AGENTS.md#提交)），两者都满足前不做任何本地提交，包括解决冲突的中间提交和 checkpoint 提交，也不通过 merge、cherry-pick 的自动提交绕过。已有许可直接复用，不重复索取。

## 阻塞、异常与范围变化

来源或目标含糊、依赖纠缠、业务意图矛盾或必要验证失败时，说明实际停点与恢复条件，保留现场；不自动 abort、reset 或清理。尚有获准且不受影响的检查时继续执行。

## 完成状态与验证标准

选定成果进入正确目标，必要验证覆盖实际组合，适用的验收和提交条件均已满足。若仍待决定、人工验收或提交许可，明确标出，不将 Git 命令成功写成功能交付完成。

## 流程关联与衔接关系

需要先建立试验目录时使用[创建 worktree 场景](<想保留当前实现，另开 worktree 尝试另一种方案.md>)；只需独立代码审核时进入[变更审核](<../审核与人工验收/独立审核：已准备好变更的代码.md>)。操作边界以[项目 Git 规范](../../../../../project-source/Project_AGENTS.md#git-与提交)和原任务为准。
