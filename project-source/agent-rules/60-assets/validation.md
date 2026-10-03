# 资源验证

```text
Source integrity
-> import metadata
-> required importer or tool
-> fresh import or reimport
-> expected Godot Resource type
-> UID and path
-> representative consumer
-> target export or platform where relevant
```

上面的验证链依次为：源文件完整性 → 导入元数据 → 所需的导入器或工具 → 全新导入或重新导入 → 预期的 Godot Resource 类型 → UID 与路径 → 有代表性的使用方 → 有影响时的目标导出或平台。

- **[必须]** 验证源文件存在且完整，以及所需的导入器依赖。
- **[必须]** 用目标 Godot 版本验证 `.import` 配置，以及全新导入或重新导入的输出。
- **[必须]** 从源 `res://` 路径加载出预期的 Resource 类型。
- **[必须]** 验证有代表性的场景、材质、音频和字体使用方。
- **[必须]** 修改影响打包、编解码器、平台支持、原始文件的运行时可用性、原生库或其他导出特有的行为时，验证目标导出。

移动后的引用检查和干净重建，分别在 `paths-uid-and-moves.md` 和 `source-and-derived-assets.md` 中规定。
