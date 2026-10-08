# 界面规格目录

本目录保存具体界面的布局、交互呈现、状态差异、显示条件和界面专用资源规格。界面属于表现职责：游戏规则引用所属 GDD，界面只说明怎样呈现请求、结果和状态。整体关系见[游戏职责与项目组织](../game-organization.md)。

## 文件放在哪里

- 每个可以独立进入、退出且有自身交互流程的屏幕或弹层，使用一份 `<interface>-design.md`，例如 `inventory-design.md`。界面键与该界面在 `game/` 中的模块和调试台中的调试对象用同一个名称，文件名用连字符、Godot 目录与调试对象用下划线，例如 `talent-tree-design.md` 对应 `game/talent_tree/` 和调试对象 `talent_tree`。
- 被两个以上独立界面共用的控件或对话框行为，使用 `components/<component-key>-design.md`。
- 何时独立成文、何时迁入共享组件，见[UI 文档边界](../../yaya/methodology/11-specialist-workflows.md#ui-文档边界)；与表现文档的关系见[游戏表现文档](../../yaya/methodology/11-specialist-workflows.md#游戏表现文档)；资源规格的归属见[资源需求与交接](../../yaya/methodology/11-specialist-workflows.md#资源需求与交接)。

## 界面与共享组件导航

新增、改名或移除界面或组件规格时，或者用途、关联 Product、组件消费者变化时，更新下表中受影响的条目。具体要求只写在各规格正文里。

| 文档链接 | 用途 | 关联 Product | 消费界面 |
| --- | --- | --- | --- |
