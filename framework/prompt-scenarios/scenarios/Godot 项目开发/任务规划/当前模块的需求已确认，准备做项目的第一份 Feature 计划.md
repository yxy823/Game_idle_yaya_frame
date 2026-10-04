# 当前模块的需求已确认，准备做项目的第一份 Feature 计划

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

当前模块的需求已确认，准备做项目的第一份 Feature 计划。

需要的材料：

- 规划依据：已细化的当前 Product、相关 GDD 和专业来源。
- 规划范围：本次规划范围。

## 前置条件与适用范围

项目已有真实 GDD，当前 Product 已细化，Feature 索引与修订均为空，采用来源已确认。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 任务规划 → 当前模块的需求已确认，准备做项目的第一份 Feature 计划”。填入上述材料。本页使用 [$feature-plan](<../../../../../project-source/skills/feature-plan/SKILL.md>)。

**S1｜核对首次入口**

当前 Agent 用 feature-plan 读取 GDD、当前 Product 交付范围与顺序，确认空 Feature 记录与规划工作区条件。

**S2｜展示并确认拆分**

一次覆盖当前 Product 的完整必要范围，展示多个 Feature 的数量、逐项范围、AC、依赖和验证。用户已明确授权自主拆分时，展示后直接写入；否则停在这里，等用户确认这份拆分。

**S3｜固定来源并写计划**

来源按规范先提交，写索引、详情、测试登记与仅覆盖采用范围的 R000。

**S4｜检查并交付**

用项目 Python 调用 yaya/tools/checks/check-feature-list.py，再加 --eligible 查询可执行候选，核对覆盖后提交计划。

项目工具命令的使用要求：

- 工作目录：实际游戏项目根目录。
- Python 与调用形式：使用 `docs/methodology-config.json` 中的 `python_executable`，按 `& $projectPython -B <脚本路径> <参数>` 调用，每次立即检查 `$LASTEXITCODE`。
- 参数：尖括号参数替换为实际值。
- 结果边界：命令成功只证明该操作完成。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 首次规划条件成立 |
| S2 | 写入前的具体拆分在授权内 |
| S3 | 计划与真实来源锚点一致 |
| S4 | 有效计划和首项候选可定位 |

## 资源与文件影响

docs/feature-list.json、docs/features/、docs/test-registry.json 和首次修订写入；来源和计划提交分别处理。

## 阻塞、异常与范围变化

GDD 缺失、当前 Product 尚未细化、设计未定、Feature 记录不为空或来源不能核实时停在实际缺口，不重建历史。

## 完成状态与验证标准

来源、AC、登记与 R000 一致，完整的 Feature 记录检查通过且计划提交明确。

## 流程关联与衔接关系

依据：[项目路由依据](<../../../../../project-source/methodology/00-overview.md>)、[计划与修订规范](<../../../../../project-source/methodology/02-feature-list-schema.md>)。
