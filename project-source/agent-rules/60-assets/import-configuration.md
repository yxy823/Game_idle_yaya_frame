# 导入配置与导入器

本页规定导入设置怎样修改、项目导入默认值的作用、重新导入的方法和自定义导入器的写法。修改 `.import`、导入设置或项目导入默认值，在编辑器外新增或修改素材后重新导入，或编写自定义导入器时读。

`.import` 文件记录导入器、导入设置和生成的身份字段，决定使用方拿到的 Resource 类型和参数。它是由工具管理的配置。

## 修改导入设置

- 通过编辑器的导入面板或 Godot 的导入流程修改设置，然后重新导入。没有编辑器界面时，只手改 `.import` 中 `[params]` 下的设置行，再按[重新导入](#重新导入)导入；导入后生成字段的变化由 Godot 写入，不手工改动。
- `.import` 中的 `uid`、`path`、`dest_files`、`source_file` 等生成字段不手工修改，见[生成文件与工具管理文件](../00-core/third-party-generated-and-temporary-files.md#生成文件与工具管理文件)。
- 按素材的运行时用途选择导入设置和预设，不只按扩展名统一处理。
- 修改导入器或 Import As 会改变使用方拿到的 Resource 类型，修改后检查使用方。
- 注意：Import As 选 “Keep File (exported as is)” 时文件不导入、原样导出；选 “Skip File (not exported)” 时文件不导入、也不导出。
- 注意：纹理在 3D 中被使用时，导入器会按 `detect_3d/compress_to` 自动把压缩方式改为 VRAM 压缩、开启 `mipmaps/generate`，并重新导入。出现这类 `.import` 差异时，先查清是哪个使用方触发的，再决定保留还是还原。

## 项目导入默认值

导入面板中的 “Set as Default” 把当前设置写入项目设置的 `importer_defaults/<导入器名>`。

- 修改默认值是改变项目的素材策略，只影响之后新导入的素材。按素材的实际用途选择默认值，允许个别素材例外。
- 已导入素材的参数保存在各自的 `.import` 中，修改默认值后只重新导入不会采用新值。需要采用时，逐个修改它们的导入参数或预设，再重新导入并验证。
- 默认值或自定义导入器配置引用的文件，是编辑器打开项目时的依赖，保持它们存在。

## 重新导入

- 在编辑器外新增或修改素材后，用 `--headless --import` 启动 Godot，让它扫描并导入后退出；读取输出中的导入错误。读取引擎路径和等待进程结束的写法，参考[首次 Godot 扫描](../../tools/README.md#首次-godot-扫描)。
- 编辑器脚本中：
  - 新建的文件先用 `EditorFileSystem.update_file()` 或 `scan()` 登记；`update_file()` 不会导入文件，之后还要重新导入；
  - 已有素材用 `reimport_files()` 有针对性地重新导入；
  - 扫描或导入进行中时，不启动另一次 `scan()` 或 `reimport_files()`，等它完成后再重新加载和验证。
- 素材看起来过期时，先按上面的方式重新导入，不删除 `.godot/imported/` 或整个 `.godot/`；缓存的处理见[生成文件与工具管理文件](../00-core/third-party-generated-and-temporary-files.md#生成文件与工具管理文件)。

## 自定义导入器

- `_get_importer_name()` 是导入器的稳定 ID，重构时不改名。确需改名时，迁移受影响素材的 `.import`。
- 输出的 Resource 格式不兼容地变化时，递增 `_get_format_version()`，然后确认已有素材能正确重新导入。
- 依赖其他导入结果的导入器，用 `_get_import_order()` 保证依赖先导入。
- 额外生成的每个 `res://` 文件都加入 `gen_files`。生成的文件本身也需要导入时，只在 `_import()` 中调用 `append_import_external_resource()`，并检查返回的 `Error`。
- 只有整个导入过程（包括依赖、共享状态和生成的输出）都线程安全时，`_can_import_threaded()` 才返回 `true`。
- 导出的游戏使用打包好的导入结果，不在玩家运行时依赖仅限编辑器的导入器。
