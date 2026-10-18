# 前一个模块已完成，准备规划下一个 Product

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

例如 Product 01 的必要 Feature 都已 `done`，预拆分里排第二的 Product 02 还只有一行大纲；现在要细化它并拆出它的 Feature。

需要的材料：

- 下一个 Product（可选）：预拆分中的名称或编号。不提供时按预拆分顺序取轮到的那一个。
- 自主拆分授权（可选）：明确写“授权自主拆分，展示后直接写入”时，Agent 展示拆分预览后不再等待确认。不写时停在预览，等你确认这份拆分。

前一个 Product 的完成情况、GDD、预拆分顺序和现有计划由 Agent 直接读取。

## 前置条件与适用范围

项目已有真实 GDD，前一个 Product 所需任务已真实完成，轮到尚未规划的下一交付单元。

## 执行步骤

使用[预设提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 规划 Product 与 Feature → 前一个模块已完成，准备规划下一个 Product”。填入上述材料。本页使用 [$product-author](<../../../../../project-source/skills/product-author/SKILL.md>)、[$feature-plan](<../../../../../project-source/skills/feature-plan/SKILL.md>)。

**S1｜核对模块顺序**

当前 Agent 核对前置任务真实完成，对照最新 GDD 复核 Product 预拆分及本次完整来源，不能只看 ID 或同步锚点之后的差异。

**S2｜细化当前交付范围**

product-author 编写当前 Product 的纳入与排除范围、来源映射和已有功能衔接，不复制 GDD 正文；交付文档已细化时，只对照最新 GDD 复核。交付取舍使用 product-spec-elicitor 澄清；必要游戏设计差异由 design-gdd 处理，数值主题按需使用 design-balance。按来源约定提交后进入规划。

**S3｜展示本次完整拆分**

feature-plan 一次覆盖当前 Product 的完整必要范围，按[拆分预览](<../../../../../project-source/methodology/02-feature-list-schema.md#拆分预览>)展示，包括需求覆盖核对；Feature 数量从完整范围推导。有自主拆分授权时展示后直接写入；否则等你确认这份拆分。

**S4｜追加并检查**

追加新 ID、详情和必要的组件登记（测试 ID 在执行时登记），保留旧索引、历史和同步锚点。然后在游戏项目根目录运行：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectPython = $projectConfig.python_executable
& $projectPython -B yaya/tools/checks/check-feature-list.py
$LASTEXITCODE
```

打印 `FEATURE LIST CHECK: PASS` 且退出码为 0，只证明 Feature 记录的结构、引用和依赖一致，不证明需求覆盖或实现完成。检查通过后提交计划。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 前一个 Product 的必要 Feature 均为 `done`；下一个 Product 已确定 |
| S2 | 当前 Product 交付文档已写好并提交 |
| S3 | 拆分预览与需求覆盖核对已展示；已获确认或已有自主拆分授权 |
| S4 | 新 Feature ID 已追加，旧记录无差异；`FEATURE LIST CHECK: PASS` 和计划提交哈希 |

## 资源与文件影响

编写当前 Product 及必要来源引用，追加 Feature 与必要的组件登记，Progress 的下一步改为第一个可以开始的 Feature；不提前细化未来 Product，不重置 R000 或历史同步锚点。

## 阻塞、异常与范围变化

前项尚未完成或当前模块已有计划时退出追加，改用其真实处理入口。

## 完成状态与验证标准

下一 Product 的交付范围已细化，完整 Feature 计划已追加并检查，旧 ID、历史及锚点完整。

## 流程关联与衔接关系

依据：methodology 02 的[逐个 Product 规划](<../../../../../project-source/methodology/02-feature-list-schema.md#逐个-product-规划>)和[拆分预览](<../../../../../project-source/methodology/02-feature-list-schema.md#拆分预览>)。
