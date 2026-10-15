---
template: doc
title: 写作与输出规则
---
本页收集关于 Agent 怎样决定写法、哪些写法有自动检查的问答。

## Agent 的各类输出分别按哪里的规则写，哪些有自动检查？

**结论**：按输出落在哪里分。对话回复只按个人规则写，没有自动检查；写进仓库的文件按写作 Skill 写，由措辞检查和术语检查核对，提交时钩子再查一次。

**为什么**：脚本只能扫描文件。对话回复不落盘，所以只能靠 Agent 发出前按个人规则自检；文件可以扫描，所以具体的禁用词集中写在措辞检查的配置里，个人规则只写原则，并说明写进项目文件时以项目的检查为准。

| 输出 | 按哪里写 | 自动检查 |
| --- | --- | --- |
| 对话回复，以及派给子智能体和 Codex 的提示词 | 个人规则 `~/.claude/CLAUDE.md` 的「沟通与回答组织」「子智能体」「Codex 监工模式」 | no 只有「发出前自检」，由 Agent 自己逐项核对 |
| 框架的手册、场景、维护说明和 Q&A | [technical-documentation-writing-yaya](../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) | ok 措辞检查、术语检查；提交钩子再查术语、硬性措辞和链接 |
| 规则、Skill 和提示词 | [规则与提示词文件](../maintenance/design-guidelines/02-instruction-files.md)，写法同上一行 | ok 同上一行，规则文件还要过硬性检查项 |
| 生成项目里的文档 | 项目自带的 technical-documentation-writing-godot | ok 项目自己的措辞检查、术语检查和提交钩子 |
| 提交说明 | [本地提交的做法](../maintenance/maintenance-and-sync.md#本地提交的做法) | no 钩子只检查暂存的 `.md` 和 `.json` 文件 |

**依据**：[检查措辞](../maintenance/tools/README.md#检查措辞)、[提交钩子](../maintenance/tools/README.md#提交钩子)、[两份写作 Skill 的分工](../maintenance/maintenance-and-sync.md#两份写作-skill-的分工)。

## 句长上限为什么分常规值和最大值，而不是一个固定数字？

**结论**：只设一个固定上限，不是太紧就是太松。分成两档后，大多数句子按常规值写；条件或例外拆开后会和动作分到两句时，允许写到最大值，超过最大值必须拆开。措辞检查只按最大值列出超长句，作为待复核项，不阻止提交。

**为什么**：统计框架文档和方法规范的 10646 句，按“。！？；”断句，跳过代码、表格和标题：

句长的中位数是 20 字。超过各个长度的句子占全部句子的比例：

```bar unit=%
超过 30 字: 22.5
超过 40 字: 8.3
* 超过 60 字: 1.0
```

如果把 40 字当作硬上限，约 8% 的句子要拆。其中不少是条件句，拆开后条件在前一句、动作在后一句，反而更难读。把 60 字作为最大值，只有 1% 的句子必须拆，这些基本都是一句话里塞了几件事。步骤句要一句一个动作，所以上限更低。

**依据**：上限数值写在措辞检查的配置 `project-source/tools/checks/wording-check.json`，字段说明见 [check-wording.py](../../project-source/tools/README.md#check-wordingpy)；对话回复的句长要求写在个人规则「具体措辞」一条。
