---
name: technical-validation-godot
description: "在实际 Godot 中构建或改进技术验证，回答既定做法能否在真实引擎中实现，例如中断行为、性能、渲染限制或引擎 API 的实际行为。用于用户要求的技术验证，或依赖它的实现开始前必须先确认的可行性问题。不用于比较画面、音效或规则候选和试调参数（debug-console-godot），也不用于没有这类开放问题的 Feature。"
---

# 用技术验证回答引擎可行性问题

先确定要解决的问题、当前任务的授权，以及什么证据能回答它。按 `yaya/methodology/01-product-doc-structure.md` 的 [GDD 前提与职责](../../../yaya/methodology/01-product-doc-structure.md#gdd-前提与职责)执行；验证不能补出缺失的游戏设计，也不能批准拟议的规则。只要求讨论时，可以只定义验证而不构建。

## 确认问题属于技术验证

| 问题 | 去向 |
| --- | --- |
| 既定做法能否在真实引擎中实现，例如中断、性能、渲染或 API 行为 | 本 Skill，方法见 `yaya/methodology/13-debug-console-and-validation.md` 的[技术验证](../../../yaya/methodology/13-debug-console-and-validation.md#技术验证) |
| 布局、观感、音效或规则候选的比较，以及已实现效果的调参 | 游戏已有骨架时用 [debug-console-godot](../debug-console-godot/SKILL.md)；还没有时先按 13 号的[界面的开发顺序](../../../yaya/methodology/13-debug-console-and-validation.md#界面的开发顺序)建骨架 Feature |
| 纯数值问题 | `design-balance` |
| 验证要回答问题，必须先准备或提供资源 | `yaya/methodology/11-specialist-workflows.md` 的[资源需求与交接](../../../yaya/methodology/11-specialist-workflows.md#资源需求与交接) |

默认使用项目自己的 Godot 环境和一个可运行的小场景，按问题决定使用隔离的样例状态，还是必要的真实引擎路径。HTML 不是默认的验证格式，也不是 Godot 验证之前的一个步骤。通过项目 `AGENTS.md` 阅读涉及的专业来源和受影响的工程领域，不加载无关的规格。

## 在任务范围内构建和报告

仍能回答问题的验证直接复用。只构建获准验证需要的状态、控件和观察点，并让假设保持可见。单独的验证按 `yaya/methodology/00-overview.md` 的[任务路由表](../../../yaya/methodology/00-overview.md#任务路由表)中“在调试台比较候选或做技术验证”一行处理；交付工作按所属 Feature 的当前计划进行。运行时检查和修改不超出该任务的实际权限。

返回：

- 可运行的入口；
- 回答了什么问题，以及实际观察到的结果；
- 尚未解决的局限；
- 需要采纳某项决定的来源负责方。

写明哪些没有运行、哪些仍需人的实际体验；截图、静态检查或模拟的状态变化只覆盖它实际展示的内容。notes 或 Progress（进度记录）、来源更新和验证文件的后续处理按 13 号的[技术验证](../../../yaya/methodology/13-debug-console-and-validation.md#技术验证)和[验收](../../../yaya/methodology/13-debug-console-and-validation.md#验收)执行，不另建第二份计划或状态记录文件。

技术验证的验收只覆盖约定的范围，不代表达到正式产品质量，也不代表后续的游戏行为。保留必要的人工反馈，不能从运行成功推断出反馈。

返回调用方；Skill 返回不会结束它所在的已授权任务（methodology 03 的[授权与续接](../../../yaya/methodology/03-execute-loop.md#授权与续接)）。
