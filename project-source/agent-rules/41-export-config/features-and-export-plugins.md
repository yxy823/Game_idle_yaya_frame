# 导出 Feature 与导出插件

本页规定自定义导出 feature 的命名与验证、导出插件怎样读取预设，以及 `EditorExportPlugin` 的写法和缓存。新增、重命名或读取自定义导出 feature，或编写、修改 `EditorExportPlugin` 时读。

自定义导出 feature 是区分大小写的构建 API；`EditorExportPlugin` 是能改变最终包内容的构建管线代码。feature 覆盖与其他 ProjectSettings 值的叠加关系见[生效值与 Feature 覆盖](../40-project-config/authoring-and-scope.md#生效值与-feature-覆盖)。

## 自定义 Feature

- 自定义 feature 名称使用稳定的小写 `snake_case`。
- 重命名或删除 feature 时，迁移每个使用方：`export_presets.cfg`、项目设置中的覆盖、代码、测试和插件。
- 在编辑器中运行（F5 或 F6）不能证明预设的自定义 feature 生效。验证 feature 的行为要用实际导出的构建。
- 不要用 `debug` 表示“导出的调试构建”；在编辑器中运行也带有 `debug`。
- 导出后的运行时代码用 `OS.has_feature()` 判断实际的 feature。

## 在导出插件中读取预设

- `EditorExportPlugin` 通过 `get_export_preset().get_custom_features()` 读取目标预设的自定义 feature，不用编辑器所在机器上的 `OS.has_feature()` 推断。
- 需要目标预设覆盖后的 ProjectSetting 时，用 `EditorExportPreset.get_project_setting()`。编辑器中 `ProjectSettings` 的值不代表目标预设的生效值。

## 导出插件

- 修改 `EditorExportPlugin` 同时是 GDScript 修改和构建管线修改。改动文件的包含、跳过、重映射或资源定制时，用实际导出验证。
- 不要用 `path.contains("test")` 这类子串推断决定包里放什么。按项目明确的目录或清单决定。
- `skip()` 只在 `_export_file()` 中调用，跳过当前正在处理的文件。
- `add_file(path, file, remap)` 只有在 `_export_file()` 中调用且 `remap` 为 `true` 时，才用新文件替换当前文件。用 `add_file()` 添加的文件不经过导入器；要替换已导入的资源，用 `_customize_resource()` 或 `_customize_scene()`。
- `_get_name()` 返回稳定且唯一的名称。注意：Godot 在导出前按这个名称给插件排序。多个插件影响同一产物时，写明各自负责的部分，并检查最终的包。

## 资源定制的缓存

- `_get_customization_configuration_hash()` 的返回值覆盖所有影响定制结果的选项，再加上一个定制实现的版本号。
- 注意：只修改插件脚本时，只要这个哈希值没变，Godot 就不会重新调用 `_customize_resource()` 和 `_customize_scene()`。改了定制算法，就递增版本号。
- 相同的源文件、预设和配置，定制结果必须相同。不要在结果中引入系统时间、随机数、UUID、无序遍历的顺序或本机绝对路径。
