# Resource 验证

- **[必须]** 用目标 Godot 4.7 解析和加载。
- **[必须]** 验证 Resource UID 与路径，以及预期的 Resource 类型或自定义类型。
- **[必须]** 验证导出值、必填字段、不变量和依赖兼容性。
- **[必须]** 修改类、属性、默认值或 schema 时，验证所有受影响的仓库 Resource 和有代表性的消费方。

复制后的共享引用检查、生成 Resource 的保存与重新加载检查、外部编辑后的缓存刷新，分别由 `duplication-and-runtime-state.md` 和 `identity-paths-and-saving.md` 规定。
