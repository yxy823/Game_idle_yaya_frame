# Resource 角色、共享与场景本地化

先给 Resource 归类，再判断对它的修改、共享或场景本地行为是否正确。

## 角色

- **[必须]** 把 Resource 归为以下一类：定义或配置数据、实例本地状态、明确的运行时可变共享状态。
- **[必须]** 定义与配置类 Resource 默认在运行时只读。可变的运行时状态属于单独的所属方（见[持久化资源图](duplication-and-runtime-state.md#持久化资源图)），并按[保存规则](identity-paths-and-saving.md#保存与生成)保存。
- **[必须]** Resource 是外部 `.tres` 还是 SubResource，本身不能证明它是共享的还是唯一的。

### 数据驱动的编辑

- **[优先]** 物品数据、技能、敌人参数、关卡配置或对话等可在检查器中编辑的定义，使用带类型的自定义 Resource。
- **[优先]** 仓库中的源 Resource 保持 `.tres` 格式，因为它是文本，版本控制可以审查和比对差异。
- **[必须]** 不要求在发布前仅为打包而手工把 `.tres` 转换为 `.res`；Godot 的导出流程可以处理二进制打包。只有明确的体积、性能或二进制源文件需求时，才直接编写 `.res`。
- **[必须]** Resource 是数据，不是 SceneTree 中的 Node；它没有 `_process` 回调，不参与逐帧处理。

```gdscript
# res://resources/enemy_stats.gd
class_name EnemyStats
extends Resource

@export var enemy_name: String = ""
@export var max_health: int = 100
@export var attack: int = 10
@export var icon: Texture2D
@export var loot_table: Array[ItemData] = []
```

通过 FileSystem → New → Resource 创建 `EnemyStats` 的 `.tres`，并在检查器中编辑。运行时才选定时用 `load()` 加载，或者通过明确的 `@export` 引用指定。

### 变更通知

- **[必须]** 导出值变化时，自定义 Resource 不会自动发出 `changed`。如果消费方依赖变更通知，在 setter 中发出它，同时保持属性的不变量。

```gdscript
@export var hp: int = 100:
	set(value):
		if hp != value:
			hp = value
			emit_changed()
```

## 场景本地

- **[必须]** 只有每个 PackedScene 实例确实需要自己的一份 Resource 副本时，才使用 `resource_local_to_scene`。
- **[必须]** 在运行时修改 `resource_local_to_scene`，不会回溯克隆已经实例化的 Resource。
- **[必须]** `_setup_local_to_scene()` 用于初始化实例本地的副本；它不能顺带修改外部的源 Resource。
- **[必须]** 场景本地的初始化通过重写 `_setup_local_to_scene()` 实现。业务代码或 Agent 代码不手动调用已弃用的 `setup_local_to_scene()`；让场景实例化的生命周期去调用它。
- **[优先]** 场景本地的初始化保持确定；需要随机性时，注入或自行持有 RNG。
