# Resource 身份、保存与 Schema

## 身份与路径

- Resource UID、`res://` 路径、`resource_name` 和玩法上的业务 ID 是不同的身份域，规则见 [Godot 资源与身份引用](../00-core/godot-resource-references.md)。
- 移动或重命名 Resource，按[资源路径、UID 与移动](../60-assets/naming-paths-and-moves.md#移动重命名与复制)使用能保持 UID 的流程。不手工修改 `resource_path` 来修复身份。
- 游戏运行时需要的 Resource 不放在含 `.gdignore` 的目录下：编辑器不扫描这类目录，其中的文件不会被导入，也不会进入导出包。`.gdignore` 的使用见[源文件与派生资源](../60-assets/source-and-derived-assets.md)。

## 保存

- 存档、设置和运行时可变状态保存到 `user://`。玩法代码和导出后的游戏不写入 `res://` 下的定义或配置 `.tres`。
- 编辑器插件和工具在明确的编辑流程中，可以写入 `res://` 下的项目 Resource。
- 检查 `ResourceSaver.save()` 的返回值。返回 `OK` 只说明写入成功，不说明 UID 已正确持久化。
- 注意：游戏运行时（非编辑器）保存 Resource，新生成的 UID 不会被保存。要成为仓库正式文件的生成 Resource，在编辑器或 `@tool` 流程中生成，或生成后在编辑器中导入并检查 UID。不手写或猜测 UID。
- 保存生成的项目 Resource 后，用 `ResourceLoader` 重新加载，检查 UID 与路径、自定义类型、字段值和依赖。
- 在编辑器外以文本方式修改 `.tres` 后，让编辑器重新扫描文件系统，或在新的 Godot 进程中验证，避免读到编辑器缓存中的旧内容；再用 [`resave_godot_files.gd`](../../tools/README.md#resave_godot_filesgd) 重新保存一次，让文件与编辑器保存的格式一致。

## Schema

自定义 Resource 的导出属性及其默认值就是持久化的 schema。

- 修改导出属性的默认值会改变行为：之前保存的 `.tres` 省略了等于旧默认值的字段，加载时会得到新的默认值。修改前找出受影响的文件。
- 重命名、删除属性或修改属性类型，以及修改 `class_name`、脚本路径或基类型时，把仓库中的 `.tres` 一次迁移到新 schema，不长期保留旧格式的兼容分支。
- 区分有稳定默认值的可选字段和必填字段。缺少必填数据时报告错误，不悄悄补上。加载成功之后，还要检查领域不变量。
- 玩家存档等仓库外的持久化数据，需要 schema 版本号和迁移代码。迁移失败时保留原始文件：先在内存或临时文件中迁移并验证，再替换。

## 构造

- 可持久化的自定义 Resource 类写在独立的脚本文件中，不定义为内部类。
- 会被保存、在检查器中创建、通过 `ResourceLoader` 加载、复制或设为场景本地的自定义 Resource，`_init()` 的每个参数都要有默认值；否则加载和 `duplicate()` 会失败。
- 必需的不变量通过工厂函数、校验函数或构造后的检查保证，不靠必需的 `_init()` 参数；不把数据迁移藏在 `_init()` 里。
