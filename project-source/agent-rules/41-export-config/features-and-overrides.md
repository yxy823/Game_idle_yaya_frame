# 导出 Feature 与覆盖

自定义导出 feature 是区分大小写的构建 API，它的运行时行为存在于导出的构建中。feature tag 覆盖如何与其他 ProjectSettings 值分层，见[生效值与 Feature 覆盖](../40-project-config/authoring-and-scope.md#生效值与-feature-覆盖)。

## Feature

- **[必须]** 在实际导出的构建中验证自定义导出 feature；在编辑器中运行（F5 或 F6）不能证明该 feature 存在。
- **[必须]** 自定义 feature 名称一旦被代码、配置或扩展使用，就是稳定的构建 API。重命名或删除它时，迁移每个使用方，包括 `export_presets.cfg`、项目覆盖、代码、测试，以及扩展或插件。
- **[必须]** 不要只用 `debug` 表示“导出的调试构建”，因为编辑器环境也带有 debug 语义。
- **[必须]** 自定义 feature tag 使用稳定的小写 `snake_case` 项目名称。
- **[必须]** `EditorExportPlugin` 从当前的 `EditorExportPreset` 读取目标的自定义 feature，例如通过 `get_export_preset().get_custom_features()`。不要从编辑器主机上的 `OS.has_feature()` 推断。
- **[必须]** 通过 `EditorExportPreset.get_project_setting()` 读取应用目标预设 feature 覆盖后的 ProjectSetting。编辑器主机上的 `ProjectSettings` 值不能证明目标预设的生效值。
- **[必须]** 导出后的运行时代码可以用 `OS.has_feature()` 获取实际运行时的 feature 集合；不要用这个运行时契约代替编辑器中考虑预设的导出逻辑。
