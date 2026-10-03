# Product 已预拆分，准备细化当前交付范围

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

Product 已有交付预拆分，当前这一项已经轮到，需要写出供 Feature 规划使用的交付范围。

需要的材料：

- 当前单元：Product 预拆分、前置完成依据和已确认交付边界。
- 设计与现状：相关完整 GDD、专业规格及已实现功能。

## 前置条件与适用范围

项目已有真实 GDD，当前 Product 已轮到且尚无可用的详细交付范围。本页只细化当前 Product，不生成 Feature 或实现功能。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 需求设计 → Product 已预拆分，准备细化当前交付范围”。填入上述材料；已有对话直接补齐输入，不必重发入口。当前 Agent 使用 [$product-author](<../../../../../project-source/skills/product-author/SKILL.md>)，必要交付范围问题由 [$product-spec-elicitor](<../../../../../project-source/skills/product-spec-elicitor/SKILL.md>) 澄清；游戏设计变化交给 [design-gdd](../../../../../project-source/skills/design-gdd/SKILL.md)。

**S1｜复核当前范围**

对照最新 GDD、交付预拆分和已有实现确认本次纳入、排除与直接依赖。影响当前实现的跨系统规则须足够明确，不为此提前编写未来 Product。

**S2｜保存交付范围**

编写 docs/product/NN-name.md，记录 GDD 与专业来源映射、已有功能衔接和交付场景，必要时更新总览本项边界与链接。GDD 保存游戏设计正文，Product 不复制玩法、状态或数值。

按[交付决定归属](../../../../../project-source/methodology/01-product-doc-structure.md#delivery-decision-ownership)，将总览中仅涉及本项的未决交付问题正文迁入详情，总览保留引用；跨 Product 分工、前置或顺序问题继续归总览，游戏设计问题引用 GDD 开放问题。

**S3｜检查可规划性**

核对当前交付范围、设计依据、已实现功能和必要衔接，明确尚未解决的缺口；已确认设计需要修改时，在原授权内由 design-gdd 或对应专业入口维护所属来源并重新核对。

## 资源与文件影响

写入当前 Product 详细文档及总览对应项。必要设计变化保存至已有 GDD 或所属专业规格；不创建未来 Product 详细文档、Feature、AC 或测试登记。

## 阻塞、异常与范围变化

缺少真实 GDD 时说明缺口并停止。当前 Product 尚未轮到或关键范围无法确定时，只处理实际前置，不用占位正文制造可规划状态。

## 完成状态与验证标准

当前 Product 的交付范围、来源、衔接和交付场景已明确保存，可支持一次完整 Feature 拆分；本页没有生成任务。

## 流程关联与衔接关系

依据：[GDD 与 Product 分工](<../../../../../project-source/methodology/01-product-doc-structure.md>)、[规划规范](<../../../../../project-source/methodology/02-feature-list-schema.md>)。需要正式规划时按有效授权进入相应 Feature 规划入口，完整覆盖当前 Product 的必要范围；该 Product 全部必要 Feature 真实完成后再细化下一项。
