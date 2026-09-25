# 精选提示词表达参考

> 自动生成的表达参考，不是流程规范或当前指令；勿手工修改。
> 框架维护来源：`framework/prompts.json`。生成项目使用自己的副本，不回查框架。
> 模板中的授权、停止条件与占位符仅属于原示例；依据当前用户指令、项目事实、规范及目标 Skill 改写，不据此执行、扩大授权或代作人工验收。

先依据当前项目规范和目标 Skill 确定路线。仅在需要起草续接或交接措辞时，从下表读取对应文件中的相关条目；状态查询无需读取示例。

| 分类 | 按需读取的条目 |
| --- | --- |
| 需求设计 | [只有游戏想法，需要整理第一份 Product](prompt-examples/product.md#example-1)；[已有模块的玩法要求变了，需要更新需求](prompt-examples/product.md#example-2) |
| 任务规划 | [当前模块的需求已确认，准备做项目的第一份 Feature 计划](prompt-examples/planning.md#example-1)；[要求已经改好，开工前需要同步 Feature 计划](prompt-examples/planning.md#example-2) |
| 日常开发 | [Feature 已规划并可开始，现在实施这一项](prompt-examples/development.md#example-1)；[界面布局已经确定，想先做一个能点击的原型](prompt-examples/development.md#example-2) |
| 修复与改进 | [Feature 交付前发现 Bug](prompt-examples/engineering.md#example-1)；[Feature 交付后发现 Bug](prompt-examples/engineering.md#example-2)；[重构目标已经选定，现在调整结构并保持行为](prompt-examples/engineering.md#example-3)；[项目工具需要修改，按工程任务完成](prompt-examples/engineering.md#example-4) |
| 验证与收尾 | [已有变更需要重新运行相关自动测试](prompt-examples/verification.md#example-1)；[Feature 已能体验，需要准备人工验收清单](prompt-examples/verification.md#example-2)；[人工验收 JSON 已填好，需要导入结果](prompt-examples/verification.md#example-3) |
| 项目恢复与交接 | [换了一个对话，想继续上次没做完的 Feature](prompt-examples/resumption.md#example-1)；[Feature 还没做完，准备换一个对话继续](prompt-examples/resumption.md#example-2) |

未选入创建、迁移、框架替换、Goal 或 advisor 自身入口；未收录的任务仍使用现有规范与目标 Skill，不因缺少示例而受阻。
