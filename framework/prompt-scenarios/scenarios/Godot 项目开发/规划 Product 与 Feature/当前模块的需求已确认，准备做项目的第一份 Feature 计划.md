# 当前模块的需求已确认，准备做项目的第一份 Feature 计划

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

例如 GDD 和 `docs/product/01-*.md` 都已确认并提交，`docs/feature-list.json` 里还没有任何 Feature；现在要一次拆出当前 Product 的全部 Feature。

需要的材料：

- 自主拆分授权（可选）：明确写“授权自主拆分，展示后直接写入”时，Agent 展示拆分预览后不再等待确认。不写时停在预览，等你确认这份拆分。

GDD、当前 Product、专业来源和空的 Feature 记录由 Agent 直接读取。

## 前置条件与适用范围

项目已有真实 GDD，当前 Product 已细化，Feature 索引与修订均为空，采用来源已确认。

## 执行步骤

使用[预设提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 规划 Product 与 Feature → 当前模块的需求已确认，准备做项目的第一份 Feature 计划”。填入上述材料。本页使用 [$feature-plan](<../../../../../project-source/skills/feature-plan/SKILL.md>)。

**S1｜核对首次入口**

当前 Agent 用 feature-plan 读取 GDD、当前 Product 交付范围与顺序，确认空 Feature 记录与规划工作区条件。

**S2｜展示并确认拆分**

一次覆盖当前 Product 的完整必要范围，按[拆分预览](<../../../../../project-source/methodology/02-feature-list-schema.md#拆分预览>)展示，包括需求覆盖核对；Feature 数量从完整范围推导。有自主拆分授权时展示后直接写入；否则停在这里，等你确认这份拆分。

**S3｜固定来源并写计划**

来源按规范先提交，写索引、详情、组件登记（测试 ID 在执行时登记），以及只覆盖采用范围的 V000，见[初始规划基线](<../../../../../project-source/methodology/02-feature-list-schema.md#初始规划基线>)。

**S4｜检查并交付**

在游戏项目根目录运行：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectPython = $projectConfig.python_executable
& $projectPython -B yaya/tools/checks/check-feature-list.py
$LASTEXITCODE
& $projectPython -B yaya/tools/checks/check-feature-list.py --eligible
$LASTEXITCODE
```

第一条打印 `FEATURE LIST CHECK: PASS` 且退出码为 0，只证明 Feature 记录的结构、引用和依赖一致，不证明需求覆盖；第二条的标准输出是依赖已满足的待开始 Feature 的 JSON。核对覆盖后提交计划。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 当前 Product 已确定，Feature 索引与修订确认为空 |
| S2 | 拆分预览与需求覆盖核对已展示；已获确认或已有自主拆分授权 |
| S3 | 索引、详情、组件登记和 V000 已写入，V000 的锚点是来源提交 |
| S4 | `FEATURE LIST CHECK: PASS`、可开始的 Feature 列表和计划提交哈希 |

## 资源与文件影响

docs/feature-list.json、docs/features/、docs/test-registry.json 和首次修订写入，Progress 的下一步改为第一个可以开始的 Feature；来源和计划提交分别处理。

## 阻塞、异常与范围变化

GDD 缺失、当前 Product 尚未细化、设计未定、Feature 记录不为空或来源不能核实时停在实际缺口，不重建历史。

## 完成状态与验证标准

来源、AC、登记与 V000 一致，完整的 Feature 记录检查通过且计划提交明确。

## 流程关联与衔接关系

依据：methodology 02 的[逐个 Product 规划](<../../../../../project-source/methodology/02-feature-list-schema.md#逐个-product-规划>)、[拆分预览](<../../../../../project-source/methodology/02-feature-list-schema.md#拆分预览>)和[初始规划基线](<../../../../../project-source/methodology/02-feature-list-schema.md#初始规划基线>)。

下一步：

- 计划已批准且依赖满足：[Feature 已规划并可开始，现在实施这一项](<../实施与调参/Feature 已规划并可开始，现在实施这一项.md>)
- 来源基线无法核实：[要求已经改好，同步受影响的 Feature](<../要求变了/要求已经改好，同步受影响的 Feature.md>)
