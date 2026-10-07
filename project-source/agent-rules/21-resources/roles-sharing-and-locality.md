# Resource 角色、共享与复制

先确定 Resource 的角色，再判断对它的修改、共享、复制或场景本地化是否正确。

## 角色

- 每个 Resource 归为一类：定义或配置数据、实例本地状态、有意共享的运行时可变状态。
- 定义与配置类 Resource（包括 `res://` 下的 `.tres`）在运行时只读。它们会被所有加载者共享，运行时修改会影响每个使用者。唯一的例外是调试台修改[调参资源](#调参资源)。可变的运行时状态由单独的所属方或模型持有，保存位置见[保存](identity-saving-and-schema.md#保存)。
- 外部 `.tres` 还是内嵌的 SubResource，不能说明它是共享的还是唯一的；按实际引用关系判断。
- 建议：物品、技能、关卡配置这类可在检查器中编辑的定义，用带类型的自定义 Resource，存为文本 `.tres`。不需要手工转成 `.res`：项目设置 `editor/export/convert_text_resources_to_binary` 默认开启，导出时会转为二进制。
- 因为导出后扩展名可能变化，代码用 `load()` 或 `ResourceLoader` 读取 Resource，不用 `FileAccess` 按路径读取 `.tres` 文本。

## 变更通知

- 自定义 Resource 的导出属性变化时，不会自动发出 `changed`。消费方依赖这个通知时，在 setter 中调用 `emit_changed()`：

```gdscript
@export var max_level: int = 10:
	set(value):
		if max_level != value:
			max_level = value
			emit_changed()
```

## 调参资源

调参资源是 `game/<对象>/tuning/**/*.tres` 下供调试台修改的配置类 Resource，保存参数、选中的候选和候选参数。它在流程中的用途见[调参资源](../../methodology/13-debug-console-and-validation.md#调参资源)。

- 每份调参资源是独立的 `.tres` 文件，不内嵌在 `.tscn` 中。曲线、渐变作为它的内嵌子资源，不单独存文件。
- 运行时只有调试台修改它；游戏代码按只读使用。
- 调参字段的 setter 调用 `emit_changed()`，写法见[变更通知](#变更通知)。持久状态（尺寸、主题色、循环中的音乐）的使用方连接 `changed` 后重新应用；一次性效果在每次触发时读取。
- 游戏不对调参资源调用 `duplicate()`，也不开启 `resource_local_to_scene`。调试台修改的是加载缓存中的那个实例，副本收不到修改。
- 一份资源只属于一个插槽，一个插槽只绑一份资源；不同用途的参数混在一份资源中时，拆成两份。
- 有候选的插槽声明一个候选字段 `candidate`（`PackedScene`、`AudioStream`、`Script` 或按顺序播放的一组音效）和 `candidate_params: Resource`。候选自带的参数放在 `candidate_params` 中，它的脚本随候选放置；有多个可替换部分时拆成多个插槽。
- 字段的值是另一份调参资源时，这是共享参数的链接，只在它所属的插槽中调。

## 复制

- 复制前决定顶层 Resource、容器、内部子资源和外部 Resource 中哪些共享、哪些复制：
  - `duplicate(false)`：只复制顶层；嵌套的 Array、Dictionary 和 Resource 与原件共享。
  - `duplicate(true)`：递归复制嵌套容器，但只复制内部（本地）子资源，外部 `.tres` 仍然共享。
  - `duplicate_deep(mode)`：用 `DEEP_DUPLICATE_NONE`、`DEEP_DUPLICATE_INTERNAL` 或 `DEEP_DUPLICATE_ALL` 选择子资源的复制范围。
- 深度复制时，原资源图中被引用多次的同一个 Resource 只复制一次，副本中仍是同一个对象。身份重要时，测试复制结果中的共享关系，而不只比较值。
- 建议：持久化的资源图保持无环，子资源不反向引用所属的父资源。业务上确实有环或关联的数据，用稳定 ID 加查找表示。

## 场景本地

- 只有每个场景实例确实需要自己的副本时，才开启 `resource_local_to_scene`。运行时修改这个属性，不影响已经创建的副本。
- 场景本地副本的初始化写在重写的 `_setup_local_to_scene()` 中，不修改源 Resource。不手动调用已弃用的 `setup_local_to_scene()`，由 `PackedScene.instantiate()` 调用。
- 建议：场景本地的初始化需要随机性时，注入或自行持有 RNG，见[随机数](../10-gdscript/state-resources-and-loading.md#随机数)。
