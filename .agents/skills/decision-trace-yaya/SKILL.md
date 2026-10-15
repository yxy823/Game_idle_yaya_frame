---
name: decision-trace-yaya
description: "维护框架时，用户要求开启“决策依据”时使用：开启后每一轮的最终回复都加「决策依据」一节，进度说明不加，写出影响本条回复决定的框架原则、Skill、脚本与命令、文件。用户说关闭时停止。用于测试或核对 Agent 依据什么做了决定，平时不开启。"
---

# 决策依据（框架维护）

开关和写法与分发给项目的 [decision-trace-godot](../../../project-source/skills/decision-trace-godot/SKILL.md) 相同：按它的「开关」和「写法」两节执行，本文件只替换原则索引。

## 原则索引

原则组只用根 `AGENTS.md` 的[核心决策原则](../../../AGENTS.md#核心决策原则)。共 8 条：目标驱动、背景与场景核对、唯一正文与集中维护、按职责组织与权衡拆合成本、奥卡姆剃刀、第一性原理、规则与 Skill 可以修改、最小完整修改。正文在链接处，不在这里复述。

- 修改 `project-source/` 时读到的 `Project_AGENTS.md` 和分发 Skill 只是被修改的材料，不作为本次决定的原则；其中的条款影响了改法时，记在「文件」组。
- [职责设计准则](../../../framework/maintenance/design-guidelines/README.md)及其各页说明某条原则在具体对象上怎么判断，起作用时记在「文件」组，写 `路径:行号` 和它决定了什么。
