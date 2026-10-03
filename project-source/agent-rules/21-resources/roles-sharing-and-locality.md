# Resource 角色、共享与复制

先确定 Resource 的角色，再判断对它的修改、共享、复制或场景本地化是否正确。

## 角色

- 每个 Resource 归为一类：定义或配置数据、实例本地状态、有意共享的运行时可变状态。
- 定义与配置类 Resource（包括 `res://` 下的 `.tres`）在运行时只读。它们会被所有加载者共享，运行时修改会影响每个使用者。可变的运行时状态由单独的所属方或模型持有，保存位置见[保存](identity-saving-and-schema.md#保存)。
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
