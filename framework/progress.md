# 框架待办

只保留未完成事项，完成并通过必要验证后删除，历史查 Git。维护约定见 [根规则](../AGENTS.md#维护边界与查阅)。

| 待办 | 剩余工作与完成条件 |
| --- | --- |
| 项目工具外部回归 | 用户本次选择暂不运行外部项目回归。后续在明确指定的外部项目核对并同步本次工具，保留机器路径并将环境配置转为顶层字段；运行项目工具回归，覆盖公共入口迁移、实时版本判定、合法空选择与失败阻断，以及仍待验证的 full 范围、Registry 身份、按结果创建完成记录和按 Feature 保存报告。入口见 [按需检查](README.md#按需检查)。 |
| 阅读版人工检查 | 用户检查 [阅读版](docs/blank-project/blank-project-handbook.html) 中创建与环境配置、首次规划基线、Feature 测试与完成记录（含报告目录和 not_required）、Bug 及语言场景，以及维护章节“说明的组织与措辞”的排版和交互，确认目录跳转、表格与图表阅读正常。具体检查方式见 [阅读版检查说明](docs/blank-project/maintenance/updating-the-blank-project.md#生成离线阅读版)。 |
| 速查样稿试读 | 用户试读[独立速查阅读版](docs/blank-project/quick-reference/quick-reference-handbook.html)的八个场景，核对 11 栏是否方便查找、第 5/6 栏同编号对照、正常等待与阻塞及场景终点是否清楚；检查顶部跳转、宽窄窗口表格和两份阅读版各自恢复位置。具体观察点见[样稿入口](docs/blank-project/quick-reference/README.md#试读时重点看什么)。收到反馈后确定栏目呈现及原检查单重叠正文的处理范围。 |
| 完整项目流程抽样 | 在明确指定的外部项目执行一个新微型需求到 Feature 收尾的全过程，确认当前流程能够实际走通，并抽样核对空台账首次规划建立 R000、来源变更同步及后续 Product 不推进旧锚点；现有工作台专项回归未覆盖此项。见 [流程抽样说明](docs/blank-project/maintenance/validating-framework.md#一次有意义的流程抽样)。 |
| researcher 实际使用验证 | 在实际项目核实角色的客户端加载、完整委派和来源返回，并按任务需要验证报告写入；现有配置检查与 anysearch 单独调用不能替代。见 [调研使用说明](docs/blank-project/guides/project-knowledge.md#按需搜索与保存调研)。 |
| 工作台具体体验确认 | 用户确认组合听感、编排节奏与截尾、分组与抢占、保存后的消费体验；已有画面验收不重复列入。待确认范围见 [E7 交付边界](review/reports/asset-workbench-e7-review-and-delivery-2026-09-22.md)。 |
