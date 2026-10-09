# Product 已预拆分，准备细化当前交付范围

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

`docs/product.md` 里排在前面的 Product 所需 Feature 都已完成（或这是第一项），下一项“背包整理”还没有 `docs/product/NN-<delivery>.md`，需要先写出它的交付范围，才能拆分 Feature。

需要的材料：

- 要细化的 Product：预拆分中的候选名称，例如“背包整理”；不写时，Agent 按预拆分顺序和已有 Feature 的完成情况确定下一项，并在回复中说明。
- 对话中已确认、尚未保存的交付边界（可选）：用原话写，例如“这次不做键盘导航”。

其余（GDD、预拆分、专业规格、已有实现和 Feature 状态）由 Agent 直接读取。

## 前置条件与适用范围

项目已有真实 GDD，当前 Product 已轮到且尚无可用的详细交付范围。本页只细化当前 Product，不生成 Feature 或实现功能。

## 执行步骤

使用[预设提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 规划 Product 与 Feature → Product 已预拆分，准备细化当前交付范围”。填入上述材料。当前 Agent 使用 [$product-author](<../../../../../project-source/skills/product-author/SKILL.md>)，必要交付范围问题由 [$product-spec-elicitor](<../../../../../project-source/skills/product-spec-elicitor/SKILL.md>) 澄清；游戏设计变化交给 [design-gdd](../../../../../project-source/skills/design-gdd/SKILL.md)。

**S1｜复核当前范围**

对照最新 GDD、交付预拆分和已有实现确认本次纳入、排除与直接依赖。影响当前实现的跨系统规则在拆分 Feature 前确定，不为此提前编写未来 Product。

**S2｜保存交付范围**

编写 docs/product/NN-<delivery>.md，记录 GDD 与专业来源映射、已有功能衔接和交付场景；总览中本项的边界或链接与详情不一致时，同步更新总览。GDD 保存游戏设计正文，Product 不复制玩法、状态或数值。

按[交付决策的归属](../../../../../project-source/methodology/01-product-doc-structure.md#交付决策的归属)，将总览中仅涉及本项的未决交付问题正文迁入详情，总览保留引用；跨 Product 分工、前置或顺序问题继续归总览，游戏设计问题引用 GDD 开放问题。

**S3｜检查可规划性**

核对当前交付范围、设计依据、已实现功能和必要衔接，明确尚未解决的缺口；已确认设计需要修改时，在原授权内由 design-gdd 或对应专业入口维护所属来源并重新核对。

## 资源与文件影响

写入当前 Product 详细文档及总览对应项；当前 Product 或下一步因此改变时，更新 Progress 的当前状态（`product.md` 不标注当前 Product）。必要设计变化保存至已有 GDD 或所属专业规格；不创建未来 Product 详细文档、Feature、AC 或测试登记。

## 阻塞、异常与范围变化

缺少真实 GDD 时说明缺口并停止。当前 Product 尚未轮到或关键范围无法确定时，只处理实际前置，不用占位正文制造可规划状态。

## 完成状态与验证标准

当前 Product 的交付范围、来源、衔接和交付场景已保存在 `docs/product/NN-<delivery>.md`，可支持一次完整 Feature 拆分。

## 流程关联与衔接关系

依据：[`product/NN-<delivery>.md` 标准章节](<../../../../../project-source/methodology/01-product-doc-structure.md#productnn-deliverymd-标准章节>)、[逐个 Product 规划](<../../../../../project-source/methodology/02-feature-list-schema.md#逐个-product-规划>)。当前 Product 包含新界面、而 Art Bible 只有占位时，可以建议先用[当前资产的美术方向不明确，需要定下来](<../美术、声音、界面与表现/当前资产的美术方向不明确，需要定下来.md>)定下方向；这只是建议，不阻塞规划。拆分 Feature 时，项目的第一份计划用[当前模块的需求已确认，准备做项目的第一份 Feature 计划](<当前模块的需求已确认，准备做项目的第一份 Feature 计划.md>)；该 Product 全部必要 Feature 真实完成后，再细化下一项。
