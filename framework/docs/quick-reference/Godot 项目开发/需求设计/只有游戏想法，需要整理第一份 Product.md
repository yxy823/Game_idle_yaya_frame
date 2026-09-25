# 只有游戏想法，需要整理第一份 Product

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

只有游戏想法，需要整理第一份 Product。

需要的材料：

- 想法与玩家：游戏想法、目标玩家。
- 玩法与边界：核心循环和已确认边界。

## 前置条件与适用范围

项目尚无正式 Product，本次形成首份可用需求。

## 执行步骤

使用[集中提示词库](<../../../../prompts.json>)中的“Godot 项目开发 → 需求设计 → 只有游戏想法，需要整理第一份 Product”。填入上述材料；已有对话直接补齐输入，不必重发入口。本页使用 [$product-init-elicitor](<../../../../../project-source/skills/product-init-elicitor/SKILL.md>)、[$product-author](<../../../../../project-source/skills/product-author/SKILL.md>)，具体执行者和切换位置见下文。

**S1｜澄清核心行为**

当前 Agent 用 product-init-elicitor 聚合同类关键问题，复用已明确设计，形成定位与核心循环草稿。

**S2｜保存确认需求**

product-author 维护 docs/product.md 与当前模块，专业细节引用 owning 规格，不补编未来玩法。

**S3｜核对可规划性**

检查行为、状态和可观察验收意图；仅交接当前模块到专用规划入口。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 基本玩法与范围可确定 |
| S2 | 正式来源表达已确认意图 |
| S3 | 来源可供 Feature 规划使用 |

## 资源与文件影响

Product 总览和当前模块文档修改；本页不直接生成 Feature 或实现。

## 阻塞、异常与范围变化

关键行为取舍未定时只停在相应草稿，不用代码偏好代替用户设计。

## 完成状态与验证标准

第一份 Product 已确认并保存，当前模块边界与未决项清楚。

## 流程关联与衔接关系

依据：[项目路由依据](<../../../../../project-source/methodology/00-overview.md>)、[专业职责与来源](<../../../../../project-source/methodology/11-specialist-workflows.md>)。本页达到出口后，仍已明确授权的后续工作按其所属场景继续；准备、诊断、规划或记录完成不替代 Feature 的正式完成。
