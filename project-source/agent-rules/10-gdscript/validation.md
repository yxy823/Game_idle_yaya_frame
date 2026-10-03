# GDScript 验证

修改 `.gd` 文件后：

- **[必须]** 用目标 Godot 4.7 的解析器、编译器和导入路径验证，不只用第三方解析器。
- **[必须]** 对改动的项目自有 GDScript 运行已配置的 `graydwarf/godot-gdscript-linter` 检查。确切阈值由 `gdlint.json` 规定。
- **[必须]** 不为了通过检查而添加或扩大 `gdlint:ignore*`、`@warning_ignore`、排除项或 linter 配置。
- **[必须]** 运行 [测试选择与门槛](../70-tests/test-selection-and-gates.md) 要求的受影响行为测试。
- **[必须]** 如果生命周期、Node、Resource、Input、Autoload、线程或其他运行时语义发生了变化，纳入对应的真实 Godot 集成或运行时验证关卡。
