# 已有 GDD，需要预拆分 Product 交付范围

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

GDD 已写好核心循环、背包和商店，`docs/product.md` 还只有用途说明，需要决定先交付哪一块、后面按什么顺序推进。

需要的材料：

- 交付规划范围：本次预拆分覆盖哪部分设计，例如“只规划核心循环和背包”；不写时覆盖 GDD 描述的整个游戏，GDD 定义了游戏版本时按《设计范围与边界》中当前的版本范围。
- 顺序偏好或外部约束（可选）：例如“先做能试玩的循环”“商店要等美术到位”。

GDD、开放问题、项目规则和现有交付总览由 Agent 直接读取。

## 前置条件与适用范围

docs/gdd/ 已有实际游戏设计正文。空目录、仅作目录导航的 README 和待填写提示不算 GDD；本页只形成交付预拆分，不创建详细 Product 或 Feature。

## 执行步骤

使用[预设提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 规划 Product 与 Feature → 已有 GDD，需要预拆分 Product 交付范围”。填入上述材料。当前 Agent 使用 [$product-author](<../../../../../project-source/skills/product-author/SKILL.md>)，必要交付取舍使用 [$product-spec-elicitor](<../../../../../project-source/skills/product-spec-elicitor/SKILL.md>) 澄清。

**S1｜核对设计与采用范围**

读取相关完整 GDD 章节及 `docs/gdd/open-questions.md` 中相关问题，区分已确认设计、备选方案和内部冲突，核对本次范围与直接依赖。按[开放问题](../../../../../project-source/methodology/01-product-doc-structure.md#开放问题)判断哪些交付决定受阻；Product 引用对应问题说明依赖，不复制问题正文，也不要求先解决无关问题。

**S2｜组织交付单元**

在 docs/product.md 保存交付边界、GDD 来源映射、依赖和建议顺序。Product 可以跨系统或只覆盖一个系统的部分，不把 GDD 章节逐项转成执行任务。

**S3｜检查覆盖与衔接**

对照交付规划范围检查遗漏、重复和依赖。在回复中说明建议先推进的交付单元；需要保存时写在 Progress 的当前状态，不在 `product.md` 标注当前 Product。

## 资源与文件影响

修改 docs/product.md；设计正文继续由 GDD 与所属专业来源持有，不在总览复制。后续 Product 详细正文、Feature、AC 和测试登记保持未创建。

## 阻塞、异常与范围变化

当前交付依赖的真实设计不足时说明缺口，停止依赖它的拆分；形成或修订 GDD 交给 [design-gdd](../../../../../project-source/skills/design-gdd/SKILL.md)，本入口不自行扩大为设计创作；关键冲突只阻塞依赖它的部分。

## 完成状态与验证标准

交付规划范围已有可解释的交付预拆分，来源映射、边界和依赖明确，未来详细规划保持按需展开。

## 流程关联与衔接关系

依据：[设计与交付结构](<../../../../../project-source/methodology/01-product-doc-structure.md#设计与交付结构>)、[`product.md` 标准章节](<../../../../../project-source/methodology/01-product-doc-structure.md#productmd-标准章节>)。预拆分完成后，细化第一项用[Product 已预拆分，准备细化当前交付范围](<Product 已预拆分，准备细化当前交付范围.md>)。
