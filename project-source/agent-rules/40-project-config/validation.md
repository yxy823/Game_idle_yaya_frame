# 项目配置验证

`project.godot` 能成功解析只是最低一层的验证。各专题文档另有自己的证据要求：

- 持久化设置（`authoring-and-scope.md`）和 Autoload 修改（`autoloads.md`）需要新进程的证据。
- 导入默认值（`import-defaults.md`）需要全新导入和重新导入的证据。
- 子系统设置（`subsystem-settings.md`）需要渲染器或平台的证据。

此外，所有项目配置修改都遵守：

- **[必须]** 按 Godot 4.7 中的名称、类型、合法值和语义验证修改过的设置。
- **[必须]** 对受影响的设置领域运行具体的使用方测试。
- **[必须]** 修改 Input 时，包含对应的 Action 测试和事件路由测试。
- **[必须]** 自定义导出 feature 的行为还要按 `41-export-config` 验证。
