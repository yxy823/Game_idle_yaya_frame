# 框架待办

只保留未完成事项，完成并通过必要验证后删除，历史查 Git。维护约定见 [根规则](../AGENTS.md#维护边界与查阅)。

| 待办 | 剩余工作与完成条件 |
| --- | --- |
| 项目工具外部回归 | 用户本次选择暂不运行外部项目回归。后续在明确指定的外部项目核对并同步本次工具，保留机器路径并将环境配置转为顶层字段；运行项目工具回归，覆盖公共入口迁移、实时版本判定、合法空选择与失败阻断，以及仍待验证的 full 范围、Registry 身份、按结果创建完成记录和按 Feature 保存报告。入口见 [按需检查](README.md#按需检查)。 |
| 文档重构与场景样稿讨论 | 用户试读[八篇 Markdown 样稿](docs/quick-reference/scenario-index.md)，重点确认 Skill、执行 Agent、提示词输入与逐步操作是否足以实际使用，以及交付前后 Bug 的归属与完成检查出口。讨论后按[整体目录与迁移范围](docs/README.md)拆分[集中保存的原材料](docs/framework-maintenance/migration-source/README.md)，补齐操作手册专题与全部旧场景，删除重复正文和已迁完原材料。HTML 暂缓，重新引入时再适配保留的构建工具。 |
| 清理被占用的旧文档空目录 | 旧 `framework/docs/blank-project/quick-reference/` 已无文件，但 Windows 报目录被其他进程占用，两次删除均失败。占用释放后检查仍为空，再删除该目录及其空父目录；文档已迁到新入口，无需重复迁移。 |
| 完整项目流程抽样 | 在明确指定的外部项目执行一个新微型需求到 Feature 收尾的全过程，确认当前流程能够实际走通，并抽样核对空台账首次规划建立 R000、来源变更同步及后续 Product 不推进旧锚点；现有工作台专项回归未覆盖此项。见 [流程抽样说明](docs/framework-maintenance/validating-framework.md#一次有意义的流程抽样)。 |
| researcher 实际使用验证 | 在实际项目核实角色的客户端加载、完整委派和来源返回，并按任务需要验证报告写入；现有配置检查与 anysearch 单独调用不能替代。见 [调研使用说明](docs/framework-maintenance/migration-source/guides/project-knowledge.md#按需搜索与保存调研)。 |
| 工作台具体体验确认 | 用户确认组合听感、编排节奏与截尾、分组与抢占、保存后的消费体验；已有画面验收不重复列入。待确认范围见 [E7 交付边界](review/reports/asset-workbench-e7-review-and-delivery-2026-09-22.md)。 |
