# 60 资源管线规则

适用于源图像、音频和字体，`.import` 元数据，Godot 导入缓存，自定义导入器，路径与 UID，来源与许可证，变体和资源验证。

```text
Source Asset
+ <asset>.import configuration
-> Godot Importer
-> .godot/imported generated cache
-> ResourceLoader
-> .tscn, .tres and .gd consumers
-> Export
```

上面的流程依次为：源资源加上 `<asset>.import` 配置 → Godot 导入器 → `.godot/imported` 生成缓存 → ResourceLoader → `.tscn`、`.tres` 和 `.gd` 使用方 → 导出。

| 文档 | 何时阅读 |
| --- | --- |
| `source-and-derived-assets.md` | 新增源美术或其他源资源，判断内容属于源文件、生成内容还是运行时内容，对资源做版本控制，或创建变体和副本 |
| `import-configuration.md` | 修改 `.import` 配置、导入类型或导入设置，或重新导入资源 |
| `paths-uid-and-moves.md` | 移动、重命名、复制或删除资源 |
| `naming-and-organization.md` | 给文件和目录命名，或组织资源 |
| `ignored-and-raw-files.md` | 使用 `.gdignore`，或通过 FileAccess 读取原始文件 |
| `textures-and-images.md` | 导入或修改纹理和图像 |
| `audio-assets.md` | 导入或修改音频 |
| `font-assets.md` | 导入或修改字体 |
| `custom-importers.md` | 编写或修改自定义导入器 |
| `asset-provenance-and-licenses.md` | 新增或修改第三方资源 |
| `validation.md` | 任何资源修改：确定需要做哪些验证 |
