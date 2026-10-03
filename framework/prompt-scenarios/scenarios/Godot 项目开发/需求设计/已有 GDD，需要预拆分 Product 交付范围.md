# 已有 GDD，需要预拆分 Product 交付范围

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

项目已有 GDD，需要把当前约定范围组织成可按顺序推进的 Product 交付单元。

需要的材料：

- 设计依据：项目内 GDD 入口与相关完整章节。
- 交付边界：当前约定采用范围、项目约束和已知依赖。

## 前置条件与适用范围

docs/gdd/ 已有实际游戏设计正文。空目录、仅作目录导航的 README 和待填写提示不算 GDD；本页只形成交付预拆分，不创建详细 Product 或 Feature。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 需求设计 → 已有 GDD，需要预拆分 Product 交付范围”。填入上述材料。当前 Agent 使用 [$product-author](<../../../../../project-source/skills/product-author/SKILL.md>)，必要交付取舍使用 [$product-spec-elicitor](<../../../../../project-source/skills/product-spec-elicitor/SKILL.md>) 澄清。

**S1｜核对设计与采用范围**

读取相关完整 GDD 章节及 `docs/gdd/open-questions.md` 中相关问题，区分已确认设计、候选设想和内部冲突，核对本次范围与直接依赖。按[开放问题规范](../../../../../project-source/methodology/01-product-doc-structure.md#开放问题)判断哪些交付决定受阻；Product 引用对应问题说明依赖，不复制问题正文，也不要求先解决无关问题。

**S2｜组织交付单元**

在 docs/product.md 保存交付边界、GDD 来源映射、依赖和建议顺序。Product 可以跨系统或只覆盖一个系统的部分，不把 GDD 章节逐项转成执行任务。

**S3｜检查覆盖与衔接**

对照当前约定范围检查遗漏、重复和依赖。确认当前准备推进的交付单元，后续细化使用对应入口；已有明确后续授权继续有效。

## 资源与文件影响

修改 docs/product.md；设计正文继续由 GDD 与所属专业来源持有，不在总览复制。后续 Product 详细正文、Feature、AC 和测试登记保持未创建。

## 阻塞、异常与范围变化

当前交付依赖的真实设计不足时说明缺口，停止依赖它的拆分；形成或修订 GDD 交给 [design-gdd](../../../../../project-source/skills/design-gdd/SKILL.md)，本入口不自行扩大为设计创作。已有具体设计授权直接沿用，关键冲突仅阻塞依赖部分。

## 完成状态与验证标准

当前约定范围已有可解释的交付预拆分，来源映射、边界和依赖明确，未来详细规划保持按需展开。

## 流程关联与衔接关系

依据：[项目路由](<../../../../../project-source/methodology/00-overview.md>)、[GDD 与 Product 分工](<../../../../../project-source/methodology/01-product-doc-structure.md>)。预拆分完成后，可按有效授权进入[当前 Product 细化](<Product 已预拆分，准备细化当前交付范围.md>)；本页完成不代表已生成 Feature 或已实现游戏。
