# 40 项目配置规则

覆盖 `project.godot` 和 ProjectSettings 的语义。`export_presets.cfg` 见 `41-export-config`。

| 文件 | 何时阅读 |
| --- | --- |
| `authoring-and-scope.md` | 任何 `project.godot` 或 ProjectSettings 修改都读：编辑方式、生效值与 feature 覆盖、持久化、主场景与应用名称、改名与删除 |
| `autoloads-and-plugins.md` | 新增、删除、调整顺序或修改 Autoload，设计事件总线，或启用、禁用、修改编辑器插件 |
| `input-map.md` | 新增、修改或删除 Input Action、绑定、死区或改键，或在编辑器代码中读取 Input Action |
| `subsystem-settings.md` | 修改音频、物理、本地化、渲染器、HDR、视口、拉伸或窗口设置，或声明全局分组、命名各类层 |

全局 Shader uniform 的声明见[全局 uniform](../30-shaders/uniforms-and-material-contracts.md#全局-uniform)。项目级的导入默认值见[项目导入默认值](../60-assets/import-configuration.md#项目导入默认值)。

## 验证

`project.godot` 能成功解析只是最低一层的验证。

| 改动类型 | 需要的验证 |
| --- | --- |
| 任何设置修改 | 在新的 Godot 进程中读取实际生效值，并运行使用该设置的测试 |
| Autoload 或插件 | 在新进程中确认注册和启用状态，运行启动流程和 headless 测试 |
| 主场景或应用名称 | 运行项目启动流程；改名时确认 `user://` 中已有数据的迁移或兼容 |
| Input Action | 运行对应的 Action 测试和事件路由测试，写法见[输入与 Command 测试](../70-tests/input-and-command-testing.md) |
| 渲染器、视口、拉伸、HDR | 在项目实际的渲染器和分辨率下运行，留下渲染证据 |
| 音频、本地化 | 运行时确认实际的总线、设备或语言区域 |
| 与导出相关的 feature 覆盖 | 按 `41-export-config` 做实际导出 |
