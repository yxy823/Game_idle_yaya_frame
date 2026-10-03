# Feature 正在开发，已确认要求发生变化

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

Feature 正在开发，已确认要求发生变化。

需要的材料：

- 变更依据：已提交来源差异、批准的需求变化。
- 影响对象：受影响 Feature。

## 前置条件与适用范围

受影响 Feature 进行中，相关 GDD、专业规格或 Product 交付范围已按确认决定改好并提交；本次同步计划。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 任务规划 → Feature 正在开发，已确认要求发生变化”。填入上述材料。本页使用 [$feature-sync](<../../../../../project-source/skills/feature-sync/SKILL.md>)。

**S1｜确认有效差异**

当前 Agent 用 feature-sync 核对来源提交、真实基线及所有适用消费者，不只追直接链接。

**S2｜修订受影响计划**

核对已有实现和证据的受影响范围，修订剩余工作与失效验证义务；保留已完成且仍有效成果。

**S3｜检查并交接**

调用项目 tools/checks/check-feature-list.py，检查 ID、引用与覆盖后提交，交回获准执行。

项目工具命令的使用要求：

- 工作目录：实际游戏项目根目录。
- Python 与调用形式：使用 `docs/methodology-config.json` 中的 `python_executable`，按 `& $projectPython -B <脚本路径> <参数>` 调用，每次立即检查 `$LASTEXITCODE`。
- 参数：尖括号参数替换为实际值。
- 结果边界：命令成功只证明该操作完成。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 变化与消费范围可核实 |
| S2 | 计划变化忠实承接新要求 |
| S3 | 计划对齐不冒充实现完成 |

## 资源与文件影响

- 修改：Feature 索引、详情、测试登记及必要修订。
- 读取与保留：读取 GDD、Product 交付范围与专业来源，不篡改历史完成记录。

## 阻塞、异常与范围变化

来源尚未改好或基线无法核实时先交对应来源或基线恢复场景；不伪造差异。尚未细化的后续 Product 只处理预拆分影响，不提前创建 Feature。

## 完成状态与验证标准

进行中任务的新范围和剩余义务明确，来源与计划一致。

## 流程关联与衔接关系

依据：[项目路由依据](<../../../../../project-source/methodology/00-overview.md>)、[计划与修订规范](<../../../../../project-source/methodology/02-feature-list-schema.md>)。
