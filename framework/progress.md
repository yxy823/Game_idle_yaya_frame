# 框架待办

只保留未完成事项，完成并通过必要验证后删除，历史查 Git。维护约定见 [根规则](../AGENTS.md#维护边界与查阅)。

| 待办 | 剩余工作与完成条件 |
| --- | --- |
| Godot worktree 与 wayfinder 入口实施 | 用户已确认创建与整合分开、冲突方法归整合入口按需参考，并授权实施[拟改报告](review/reports/godot-worktree-wayfinder-skill-proposal-2026-09-29.md)。澄清入口已改名；继续完成三个新增入口、提示词及两份场景图同步和独立审核。本轮按用户选择只做分发材料、静态检查与情境审核，真实运行留到指定外部项目后进行。 |
| 开发场景关系图首版试读 | 用户导入 [JSON 图文件](docs/workflow-maps/game-development-workflow.json)，确认场景名称换行、缩放阅读和跨区连线辨识；格式与节点名称集合校验不替代实际查看。格式及维护方法见 [说明](docs/workflow-maps/README.md)。 |
| 工作台具体体验确认 | 用户确认组合听感、编排节奏与截尾、分组与抢占、保存后的消费体验；已有画面验收不重复列入。待确认范围见 [E7 交付边界](review/reports/asset-workbench-e7-review-and-delivery-2026-09-22.md)。 |
| 编辑器插件兼容性缺口 | 资源表格已安装但默认停用，组合退出泄漏根因未确定；完整默认图形组合仍有 gdUnit4 重复连接与退出诊断，其单独基线也有错误。后续分别定位并在指定外部项目重验，不能把当前功能断言通过当作完整兼容；证据见 [插件版本记录](docs/framework-maintenance/editor-plugin-versions.md#godot-验证)。 |
| 编辑器插件人工验收 | 待确认 Script-IDE 分屏/搜索、Inspector Tabs 标签切换、Kanban 拖放、资源表格编辑撤销，以及 Signal Lens 运行中信号捕获和远程图；范围见 [插件验证说明](docs/framework-maintenance/editor-plugin-versions.md#godot-验证)。 |
