# 40 项目配置规则

覆盖 `project.godot` 和 ProjectSettings 的语义。`export_presets.cfg` 中的构建与分发设置属于 `41-export-config`。

| 文档 | 何时阅读 |
| --- | --- |
| `authoring-and-scope.md` | 任何 `project.godot` 或 ProjectSettings 修改：编辑文件、生效值与 feature tag 覆盖、持久化，或删除和重命名有名称的设置 |
| `application-startup.md` | 修改主场景、主循环类型、应用名称或 `user://` 目录 |
| `autoloads.md` | 新增、删除、调整顺序或修改 Autoload，或设计事件总线 |
| `editor-plugins.md` | 启用、禁用、新增或修改编辑器插件 |
| `groups-and-layers.md` | 声明全局分组，或命名、修改物理层、导航层或渲染层 |
| `import-defaults.md` | 修改项目级的导入默认值 |
| `input-map.md` | 新增、修改或删除 Input Action、绑定、死区或重新绑定，或在编辑器代码中读取 Input Action |
| `shader-globals.md` | 声明或修改全局 Shader uniform，或使用 `ShaderGlobalsOverride` |
| `subsystem-settings.md` | 修改音频、物理、本地化、渲染器、视口、拉伸、窗口或 HDR 设置 |
| `validation.md` | 任何项目配置修改：确定需要做哪些验证 |
