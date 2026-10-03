# 41 导出配置规则

覆盖 `export_presets.cfg`、导出目标、打包过滤器、自定义导出 feature、签名与密钥的边界、`EditorExportPlugin` 的行为，以及实际导出验证。`project.godot` 中的运行时设置仍归 `40-project-config`。

| 文档 | 何时阅读 |
| --- | --- |
| `presets-and-targets.md` | 新增或修改导出预设、输出路径、构建模式、模板或目标身份 |
| `resources-and-filters.md` | 修改导出资源的选择或过滤器、运行时读取的原始文件、专用服务器导出，或测试与编辑器插件的隔离 |
| `features-and-overrides.md` | 新增、重命名或读取自定义导出 feature，或读取某个预设下的 ProjectSettings |
| `export-plugins-and-hooks.md` | 编写或修改 `EditorExportPlugin` |
| `secrets-and-signing.md` | 处理导出凭据、签名或公证 |
| `validation.md` | 任何导出配置修改：确定需要做哪些验证 |
