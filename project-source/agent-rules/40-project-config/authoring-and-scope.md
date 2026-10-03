# ProjectSettings 的编写与作用范围

`project.godot` 是行为配置。有名称的项目级设置一旦被使用，就是跨文件的 API。

## 编写

- `project.godot` 的差异保持最小：不给无关的键排序，不展开默认值，不调整节的顺序。
- 修改设置前，核实它在 Godot 4.7 中的准确名称、类型、合法值、默认值和弃用状态。
- 注意：自定义设置既不在 `project.godot` 中、也没有用 `ProjectSettings.set_setting()` 设置时，`get_setting()` 返回 `null` 或调用方给的默认值。
- 项目正确性依赖某个引擎默认值时，把这个设置显式写进 `project.godot`。
- 建议：结构性的修改通过编辑器或 ProjectSettings API 完成。手工文本补丁只用于小而确定的修改。

## 生效值与 Feature 覆盖

- 生效值按层叠加：引擎默认值、`project.godot`、`override.cfg` 或 `application/config/project_settings_override` 指定的文件，最后是 feature 覆盖（例如 `application/config/name.windows`）。
- `ProjectSettings.get_setting()` 不应用 feature 覆盖。需要覆盖后的值时用 `get_setting_with_override()`。
- feature 覆盖用于区分构建、平台和环境，不用于玩法状态。多个覆盖同时匹配时，在 Godot 中实际读取结果，不凭推测。
- 自定义 feature 的命名和导出验证见[导出 Feature 与导出插件](../41-export-config/features-and-export-plugins.md)。

## 运行时配置与持久化

- ProjectSettings 中的值不一定是运行时状态。实际状态从 DisplayServer、RenderingServer、AudioServer 等服务器 API 读取。
- 编辑器内存中的 ProjectSettings 不等于已保存。EditorPlugin 或工具要持久化修改时，调用 `ProjectSettings.save()` 并检查返回的 `Error`；在启动会读取这些设置的子进程之前保存。
- 玩家的运行时设置保存到 `user://`；玩法代码不改写 `project.godot`。

## 应用启动

- 不要为了运行测试、截图或加载测试夹具而修改 `application/run/main_scene`。
- 建议：主场景只负责启动所需的引导和组装，不堆放全局逻辑。
- 场景和模块之间不把 `/root/Main/...` 路径当作契约依赖。
- 注意：`application/config/use_custom_user_dir` 为 `false` 时，`user://` 是 `<系统用户数据目录>/Godot/app_userdata/<项目名>`；为 `true` 且 `custom_user_dir_name` 为空时是 `<系统用户数据目录>/<项目名>`。两种情况下修改 `application/config/name` 都会换掉 `user://`。
- 修改项目名或用户目录设置时，为已有的存档、设置和进度提供迁移路径或确认兼容。不要为了回避迁移而擅自启用 `use_custom_user_dir`。

## 改名与删除

- 删除或重命名 ProjectSetting、Input Action、Autoload、分组、全局 Shader uniform 或层名称之前，迁移所有使用方，包括动态注册表。
