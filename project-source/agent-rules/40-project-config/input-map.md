# InputMap 配置

本页规定 Input Action 的命名、绑定、死区、重复触发与改键，以及在编辑器代码中读取项目 InputMap 的方法。修改 Input Action 或绑定、处理改键，或在编辑器代码中读取 Input Action 时读。

Input Action 是与设备和改键无关的语义抽象。GDScript 中的事件路由见[输入处理](../10-gdscript/godot-lifecycle-and-input.md#输入处理)，输入测试见[输入与 Command 测试](../70-tests/input-and-command-testing.md)。

## Action

- 自定义玩法 Action 使用有业务含义、稳定的 `snake_case` 名称。
- 玩法通过 Input Action 读取输入，不硬编码按键或按钮事件。例外是改键界面、文本与 IME 输入、诊断和设备特有的行为。
- 内置的 `ui_*` Action 只用于 UI 焦点和导航，不承载玩法语义。
- 按位置决定的操作用物理键码（`physical_keycode`），语义快捷键用逻辑键码（`keycode`），文本输入用 `unicode`。构造 `InputEventKey` 时只设置需要的那一种，不把每个字段都填上。
- 建议：显示物理按键绑定时，按当前键盘布局转换标签，不假定固定的按键名称。

## 死区、重复与改键

- 死区显式设置。在 `project.godot` 中写明每个 Action 的 `deadzone`；脚本调用 `InputMap.add_action()` 时显式传入 `deadzone`，不依赖参数默认值（4.7 中为 0.2）。
- 建议：双轴移动用 `Input.get_vector()`。
- 一个物理事件映射到多个玩法 Action 时，写明上下文或优先级。
- 重复触发的时机影响玩法时，用项目自己的计时逻辑，不依赖操作系统的按键回显。
- 玩家的改键保存到 `user://`；`project.godot` 中的绑定是恢复默认的来源。
- 重命名或删除 Action 时，迁移代码、场景、测试和已保存的改键数据。

## 编辑器中的 InputMap

- 在 `EditorPlugin` 或 `@tool` 脚本中，`InputMap` 单例返回的是编辑器自己的 Action。要读写项目的 Action 和绑定，读写 `ProjectSettings` 的 `input/*` 设置。
