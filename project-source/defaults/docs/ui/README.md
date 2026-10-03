# 界面规格目录

这里保存具体界面的布局、交互呈现、状态差异、显示条件和界面专用资源规格。每个可独立进入、退出且有自身交互流程的屏幕或弹层使用 `<interface>-design.md`，例如 `inventory-design.md`；从属面板、标签页和 HUD 部件在宿主界面分节，显隐本身不构成独立界面。示例不代表已有需求，实例规则见[界面文档边界](../../methodology/11-specialist-workflows.md#ui-document-boundaries)。

同一控件或对话框行为被第二个独立界面实际采用或纳入比较时，共用正文迁入 `components/<component-key>-design.md`，消费者保留调用上下文与引用；已有独立对话框正文一并迁移，不留两份。共享组件仍有消费者时沿用固定路径，仅共享外观则引用美术规范。资源按[资源规格约定](../../methodology/01-product-doc-structure.md#resource-requirements-and-handoff)保存。

界面属于表现职责。说明操作发起的请求及成功、失败的显示，游戏规则引用所属 GDD；区分按钮悬停等界面状态与金币、库存等业务状态。职责与实际接入文档的关系见[游戏职责与项目组织](../game-organization.md)。

界面在实际交互位置引用相关[游戏表现](../presentation/README.md)，并在末尾维护“关联游戏表现”导航。普通控件状态可就地描述；跨界面共用的表现引用同一份正文，保留各界面的触发与使用信息。

当前尚无界面规格。新增、改名或移除界面/组件规格，以及用途、关联 Product 或组件消费者变化时，在本页维护受影响条目的“文档链接、用途、关联 Product、消费界面”；无需另建组件索引或审查无关目录内容，具体要求保留在各规格正文。职责见 [专业工作约定](../../methodology/11-specialist-workflows.md)。
