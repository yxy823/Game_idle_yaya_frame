# 前一个模块已完成，准备规划下一个 Product

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

前一个模块已完成，准备规划下一个 Product。

需要的材料：

- 规划对象与前置：下一 Product、已完成前置模块。
- 当前记录：现有计划与修订。

## 前置条件与适用范围

项目已有真实 GDD，前一个 Product 所需任务已真实完成，轮到尚未规划的下一交付单元。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 任务规划 → 前一个模块已完成，准备规划下一个 Product”。填入上述材料。本页使用 [$product-author](<../../../../../project-source/skills/product-author/SKILL.md>)、[$feature-plan](<../../../../../project-source/skills/feature-plan/SKILL.md>)。

**S1｜核对模块顺序**

当前 Agent 核对前置任务真实完成，对照最新 GDD 复核 Product 预拆分及本次完整来源，不能只看 ID 或同步锚点之后的差异。

**S2｜细化当前交付范围**

product-author 编写当前 Product 的纳入与排除范围、来源映射和已有功能衔接，不复制 GDD 正文。交付取舍使用 product-spec-elicitor 澄清；必要游戏设计差异由 design-gdd 处理，数值主题按需使用 design-balance。按来源约定提交后进入规划。

**S3｜展示本次完整拆分**

feature-plan 一次覆盖当前 Product 的完整必要范围，展示多个 Feature 的范围、依赖、AC 和验证安排。用户已明确授权自主拆分时，展示后直接写入；否则等用户确认这份拆分。

**S4｜追加并检查**

追加新 ID 与详情，保留旧索引、历史和同步锚点；调用 check-feature-list.py 检查并提交。

项目工具命令的使用要求：

- 工作目录：实际游戏项目根目录。
- Python 与调用形式：使用 `docs/methodology-config.json` 中的 `python_executable`，按 `& $projectPython -B <脚本路径> <参数>` 调用，每次立即检查 `$LASTEXITCODE`。
- 参数：尖括号参数替换为实际值。
- 结果边界：命令成功只证明该操作完成。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 下一个模块确实具备规划条件 |
| S2 | 当前交付范围与最新设计一致 |
| S3 | 完整拆分有当前来源依据 |
| S4 | 新计划与旧历史并存一致 |

## 资源与文件影响

编写当前 Product 及必要来源引用，追加 Feature 与必要测试登记；不提前细化未来 Product，不重置 R000 或历史同步锚点。

## 阻塞、异常与范围变化

前项尚未完成或当前模块已有计划时退出追加，改用其真实处理入口。

## 完成状态与验证标准

下一 Product 的交付范围已细化，完整 Feature 计划已追加并检查，旧 ID、历史及锚点完整。

## 流程关联与衔接关系

依据：[项目路由依据](<../../../../../project-source/methodology/00-overview.md>)、[计划与修订规范](<../../../../../project-source/methodology/02-feature-list-schema.md>)。
