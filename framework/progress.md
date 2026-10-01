# 框架待办

只保留未完成事项，完成并通过必要验证后删除，历史查 Git。维护约定见 [根规则](../AGENTS.md#维护边界与查阅)。

| 待办 | 剩余工作与完成条件 |
| --- | --- |
| 游戏职责与文档导航试读 | 用户从[游戏逻辑、表现与协作](docs/operation-manual/框架基础/game-logic-and-presentation.md)的商店购买案例出发，并结合[项目 README](../project-source/Project_README.md)与[游戏组织指南](../project-source/defaults/docs/game-organization.md)，确认能理解规则、界面、获得反馈、实际协作与验收分别在哪里记录。静态检查与阅读版构建不替代实际阅读体验确认。 |
| 开发场景关系图试读、次数保存与箭头确认 | 用户在当前 Graph_Map 中用“打开图目录”选择 `framework/docs/workflow-maps`，只将 `scene-085` 的次数从 3 改为 4 并 Ctrl+S，确认主图无 Git 差异，刷新重开仍恢复 4 次；本地次数文件已迁移并忽略。确认场景名称换行、缩放阅读和跨区连线辨识，包括新增游戏表现规划节点及其 6 条按需关系；同时确认原有 151 条双向箭头是否符合实际衔接方向，该配置已保留。格式与节点名称集合校验不替代实际查看和关系判断。格式及维护方法见 [说明](docs/workflow-maps/README.md)。 |
| 工作台具体体验确认 | 用户确认组合听感、编排节奏与截尾、分组与抢占、保存后的消费体验；已有画面验收不重复列入。待确认范围见 [E7 交付边界](review/reports/asset-workbench-e7-review-and-delivery-2026-09-22.md)。 |
| 编辑器插件兼容性缺口 | 资源表格已安装但默认停用，组合退出泄漏根因未确定；完整默认图形组合仍有 gdUnit4 重复连接与退出诊断，其单独基线也有错误。后续分别定位并在指定外部项目重验，不能把当前功能断言通过当作完整兼容；证据见 [插件版本记录](docs/framework-maintenance/editor-plugin-versions.md#godot-验证)。 |
| 编辑器插件人工验收 | 待确认 Script-IDE 分屏/搜索、Inspector Tabs 标签切换、Kanban 拖放、资源表格编辑撤销，以及 Signal Lens 运行中信号捕获和远程图；范围见 [插件验证说明](docs/framework-maintenance/editor-plugin-versions.md#godot-验证)。 |
