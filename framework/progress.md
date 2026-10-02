# 框架待办

只保留未完成事项，完成并通过必要验证后删除，历史查 Git。维护约定见 [根规则](../AGENTS.md#维护边界与查阅)。

| 待办 | 剩余工作与完成条件 |
| --- | --- |
| 游戏职责与文档导航试读 | 用户从[游戏逻辑、表现与协作](docs/operation-manual/框架基础/game-logic-and-presentation.md)的商店购买案例出发，并结合[项目 README](../project-source/Project_README.md)与[游戏组织指南](../project-source/defaults/docs/game-organization.md)，确认能理解规则、界面、获得反馈、实际协作与验收分别在哪里记录。静态检查与阅读版构建不替代实际阅读体验确认；确认完成后删除[当次需求变更依据](docs/framework-maintenance/game-logic-presentation-change-requirements.md)及其导航，历史由 Git 保存。 |
| 开发场景关系图试读、次数保存与箭头确认 | 用户在当前 Graph_Map 中用“打开图目录”选择 `framework/docs/workflow-maps`，只将 `scene-085` 的次数从 3 改为 4 并 Ctrl+S，确认主图无 Git 差异，刷新重开仍恢复 4 次；本地次数文件已迁移并忽略。确认场景名称换行、缩放阅读和跨区连线辨识，包括新增游戏表现规划节点及其 6 条按需关系；同时确认原有 151 条双向箭头是否符合实际衔接方向，该配置已保留。格式与节点名称集合校验不替代实际查看和关系判断。格式及维护方法见 [说明](docs/workflow-maps/README.md)。 |
| 文档系统关系图试读 | 用户在 Graph_Map 打开同一目录并选择 `document-system.readable.json`，确认框架区与项目区、四类连线、标题文件名或命名模式、备注路径和本地链接能帮助查找资料；沿 GDD → UI/表现 → Product/Feature → 验证证据的实际问题检查缩放阅读与长线辨识。图中按需产物不代表项目已经生成正文，格式、链接与路径覆盖检查不替代阅读体验确认。见[文档关系图说明](docs/workflow-maps/README.md#文档系统关系图)。 |
| 工作台具体体验确认 | 用户确认组合听感、编排节奏与截尾、分组与抢占、保存后的消费体验；已有画面验收不重复列入。从[示例使用说明](../project-source/asset_workbench/examples/README.md)进入第四工作台或对应消费场景，自动测试不代替这些人工体验。 |
| 编辑器插件兼容性缺口 | 资源表格已安装但默认停用，组合退出泄漏根因未确定；完整默认图形组合仍有 gdUnit4 重复连接与退出诊断，其单独基线也有错误。后续分别定位并在指定外部项目重验，不能把当前功能断言通过当作完整兼容；证据见 [插件版本记录](docs/framework-maintenance/editor-plugin-versions.md#godot-验证)。 |
| 编辑器插件人工验收 | 待确认 Script-IDE 分屏/搜索、Inspector Tabs 标签切换、Kanban 拖放、资源表格编辑撤销，以及 Signal Lens 运行中信号捕获和远程图；范围见 [插件验证说明](docs/framework-maintenance/editor-plugin-versions.md#godot-验证)。 |
| 创建器符号链接边界复验 | 本轮真实 Windows junction 拒绝与目标未写入检查已通过；普通文件、外部目录和内部文件的符号链接用例因本机创建权限不足而跳过。需在允许创建符号链接的环境运行 [test_project_copy.py](tests/repository/test_project_copy.py) 的 `test_nested_file_and_directory_symlinks_are_rejected`，确认三个子场景均实际执行且通过后删除本项。 |
