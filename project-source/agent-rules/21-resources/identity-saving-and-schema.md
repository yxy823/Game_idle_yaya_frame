# Resource 身份、保存与 Schema

本页规定 Resource 的身份与路径、保存位置与保存后的检查、导出属性构成的 schema，以及自定义 Resource 的构造。移动、重命名或保存 Resource，生成 `.tres`，或修改自定义 Resource 的导出属性、默认值、`class_name` 或 `_init()` 时读。

## 身份与路径

- Resource UID、`res://` 路径、`resource_name` 和玩法上的业务 ID 是不同的身份域，规则见 [Godot 资源与身份引用](../00-core/godot-resource-references.md)。
- 移动或重命名 Resource，按[移动、重命名与复制](../60-assets/naming-paths-and-moves.md#移动重命名与复制)使用能保持 UID 的流程。不手工修改 `resource_path` 来修复身份。
- 游戏运行时需要的 Resource 不放在含 `.gdignore` 的目录下：编辑器不扫描这类目录，其中的文件不会被导入，也不会进入导出包。`.gdignore` 的使用见[源素材与派生素材](../60-assets/source-and-derived-assets.md)。

## 保存

- 存档、设置和运行时可变状态保存到 `user://`。玩法代码和导出后的游戏不写入 `res://` 下的定义或配置 `.tres`。
- 存档只保存源状态，例如升级等级和资源数量；产出速率、倍率等派生值在读档后重新计算，平衡数值改动后旧存档仍和公式一致。存档结构与运行时状态的互相转换集中在一处，规则代码不直接读写存档结构。
- 测试存档或设置的保存结果时，新建一个读取方，从 `user://` 中的文件重新加载后再断言；不读写入方的内存状态，也不以界面上的“已保存”提示为证据。存档是 Resource 时，默认加载会复用缓存，按 [Node 与 Resource](../70-tests/fixtures-and-isolation.md#node-与-resource) 绕过缓存。
- 编辑器插件和工具在明确的编辑流程中，可以写入 `res://` 下的项目 Resource。
- 调试台是游戏运行中写入 `res://` 的唯一例外：它保存 `dev/debug/` 下的插槽预设与组合，并在用户采纳到游戏时写入调参资源、移动候选文件。预设与组合不是游戏资源，不补 UID。采纳写入的调参资源和移动的场景、资源缺少外部资源 UID，由 Agent 按[收尾步骤](../../../dev/debug/_shared/README.md#收尾步骤)用 `resave_godot_files.gd` 补回并提交。
- 检查 `ResourceSaver.save()` 的返回值。返回 `OK` 只说明写入成功，不说明 UID 已正确持久化。
- 注意：游戏运行时（非编辑器）保存 Resource，新生成的 UID 不会被保存。要成为仓库正式文件的生成 Resource，在编辑器或 `@tool` 流程中生成，或生成后在编辑器中导入并检查 UID。不手写或猜测 UID。
- 保存生成的项目 Resource 后，用 `ResourceLoader` 重新加载，检查 UID 与路径、自定义类型、字段值和依赖。
- 在编辑器外以文本方式新建或修改 `.tres` 后，用 [`resave_godot_files.gd`](../../tools/README.md#resave_godot_filesgd) 规范化保存格式与资源 UID，漏掉的由 [`check-godot-resource-format.py`](../../tools/README.md#check-godot-resource-formatpy) 报告；验证时让编辑器重新扫描文件系统，或在新的 Godot 进程中加载，避免读到缓存中的旧内容。

## Schema

自定义 Resource 的导出属性及其默认值就是持久化的 schema。

- 修改导出属性的默认值会改变行为：之前保存的 `.tres` 省略了等于旧默认值的字段，加载时会得到新的默认值。修改前找出受影响的文件。
- 重命名、删除属性或修改属性类型，以及修改 `class_name`、脚本路径或基类型时，把仓库中的 `.tres` 一次迁移到新 schema，不长期保留旧格式的兼容分支。
- 调参资源的字段改名或删除时，同时迁移 `dev/debug/` 下该插槽预设中的字段；调参资源改名或移动、插槽编号随之变化时，同时迁移预设的 `slot_id` 和组合中的条目。没有迁移的预设载入时，对不上的项会退回游戏原值。
- 区分有稳定默认值的可选字段和必填字段。缺少必填数据时报告错误，不悄悄补上。加载成功之后的领域不变量，按[加载、打包与信任](../50-data-files/data-lifecycle-and-authority.md#加载打包与信任)区分项目自带数据与外部数据。
- 玩家存档等仓库外的持久化数据，需要 schema 版本号和迁移代码。迁移失败时保留原始文件：先在内存或临时文件中迁移并验证，再替换。
- 正式存档存在、但校验或迁移失败时，把它改名保留，停止自动存档写入这个存档槽位，并告诉玩家。否则游戏按新档运行后，下一次自动存档会覆盖坏文件，进度无法再恢复。

## 构造

- 可持久化的自定义 Resource 类写在独立的脚本文件中，不定义为内部类。
- 会被保存、在检查器中创建、通过 `ResourceLoader` 加载、复制或设为场景本地的自定义 Resource，`_init()` 的每个参数都要有默认值；否则加载和 `duplicate()` 会失败。
- 必需的不变量通过工厂函数、校验函数或构造后的检查保证，不靠必需的 `_init()` 参数；不把数据迁移藏在 `_init()` 里。
