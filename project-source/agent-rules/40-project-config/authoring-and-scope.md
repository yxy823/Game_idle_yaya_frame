# ProjectSettings 的编写与作用范围

`project.godot` 是行为配置，不是文本整理的对象。

## 编写

- **[必须]** `project.godot` 的差异保持最小。不要给无关的键排序、展开所有默认值、调整节的顺序或规范化无关内容。
- **[必须]** 内置 ProjectSetting 缺少键时，使用目标 Godot 4.7 的引擎默认值。自定义设置如果既不在 `project.godot` 中，也没有通过 `ProjectSettings.set_setting()` 设置，就表示未定义；不要假定存在 Godot 默认值。
- **[复核]** 项目正确性不能随引擎默认值漂移时，明确固定关键设置。不要把所有默认值都写进文件。
- **[必须]** 修改设置前，核实它在 Godot 4.7 中的准确名称、类型、合法值、默认值和弃用状态，以及它适用的渲染器和平台。
- **[必须]** 结构性的设置修改优先使用 ProjectSettings、编辑器或结构化工具。只有准确掌握文件格式，并在新进程中验证时，才可以使用小而确定的文本补丁。

## 生效值与 Feature 覆盖

- **[必须]** 把 ProjectSettings 的生效值看作分层结果：引擎内置默认值、`project.godot` 中的显式值、配置的覆盖来源（例如 `override.cfg` 或 `application/config/project_settings_override`），最后是 feature tag 覆盖。在新进程中验证实际生效值及其覆盖来源。
- **[必须]** `ProjectSettings.get_setting()` 读取设置时不应用 feature 覆盖。契约是经过 feature 覆盖后的生效值时，使用 `get_setting_with_override()`。
- **[必须]** feature tag 覆盖用于不同构建、平台和环境之间的差异，不用于动态的玩法状态。
- **[必须]** 多个 feature 覆盖之间的优先级有影响时，在目标 Godot 中核实实际解析结果，不要猜。
- **[必须]** 自定义 feature 的命名、`debug` 语义、重命名和导出验证遵循[导出 Feature 与覆盖](../41-export-config/features-and-overrides.md)。

## 运行时配置与持久化配置

- **[必须]** ProjectSettings 中的配置不一定是当前的运行时状态。运行时的真实状态用 DisplayServer、RenderingServer、AudioServer 等服务器 API 获取。
- **[必须]** 编辑器内存中的 ProjectSettings 不能证明 `project.godot` 已持久化。持久化修改需要新进程的证据。
- **[必须]** EditorPlugin 或工具要把修改持久化到 `project.godot` 时，明确通过 `ProjectSettings.save()` 或等效的结构化编写工具保存，并检查返回的 `Error`。
- **[必须]** 启动会读取这些设置的子进程、编辑器进程或游戏进程之前，先持久化 ProjectSettings 的修改。对 Autoload、插件或其他子进程配置来说，只改内存不够。
- **[必须]** 玩家的运行时设置通常通过运行时 API 持久化到 `user://`；玩法不改写项目配置。

## 删除与命名

- **[必须]** 删除或重命名 ProjectSetting、Input Action、Autoload、分组、Shader 全局变量或层名称之前，迁移所有使用方，包括有动态注册表时的注册表。
- **[必须]** 有名称的项目级设置一旦被使用，就成为跨文件的 API。
