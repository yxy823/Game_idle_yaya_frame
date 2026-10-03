# GDScript 生命周期、信号、异步与输入

明确 Godot 的生命周期语义；行为依赖这些语义时，在真实的 SceneTree 路径中验证。

## 节点生命周期

- **[必须]** 不把 `_init`、`_enter_tree`、`_ready`、`_process`、`_physics_process`、`_exit_tree` 和延迟删除当作可以互换的阶段。
- **[必须]** 行为依赖父子节点的初始化时，考虑 SceneTree 的回调顺序：父节点的 `_enter_tree()` 先于子节点的 `_enter_tree()`，而子节点的 `_ready()` 先于父节点的 `_ready()`。
- **[必须]** 默认把 `_ready()` 视为每个 Node 实例只运行一次。被移除的 Node 如果需要在之后再次进入树时运行它，在重新加入之前调用 `request_ready()`；同样需要再次调用 `_ready()` 的子节点，要分别请求。
- **[必须]** 已排队等待删除的 Node，在延迟删除真正发生之前可能仍然有效。生命周期可能变化时，在 `await` 或延迟执行的工作之后重新检查引用。
- **[必须]** 有意识地使用 `queue_free()` 和生命周期所有权。`remove_child()` 只把 Node 从树中移除，不释放它。
- **[必须]** 处理模式和暂停行为是明确的契约。不在表面重构中修改 `process_mode` 或暂停语义。

### 回调时机参考

| 回调 | 时机 | 用途 |
| --- | --- | --- |
| `_init()` | 对象创建时，此时 SceneTree 还不存在 | 不依赖子节点和树服务的状态 |
| `_enter_tree()` | Node 进入 SceneTree | 向外部系统注册 |
| `_ready()` | Node 及其子节点都已进入树 | 获取子节点引用、连接信号 |
| `_process(delta)` | 每个渲染帧 | 表现、动画和 UI 更新 |
| `_physics_process(delta)` | 每个固定物理帧 | 移动、碰撞和确定性的物理工作 |
| `_exit_tree()` | Node 离开 SceneTree | 注销与清理 |

不在 `_init()` 中访问 `$Child`。`add_child()` 会让尚未就绪的子节点进入树，并最终运行 `_ready()`；对已经就绪的节点更换父节点，不会自动重新运行 `_ready()`，除非它重新进入树之前调用过 `request_ready()`。

```gdscript
extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D

func _init() -> void:
	# 此时子节点还不存在。
	velocity = Vector2.ZERO

func _ready() -> void:
	sprite.visible = true

func _physics_process(delta: float) -> void:
	# 物理、移动和碰撞放在固定步长回调中。
	move_and_slide()

func _process(delta: float) -> void:
	# 表现可以用渲染帧的 delta 做插值。
	sprite.rotation = lerp_angle(sprite.rotation, rotation, delta * 8.0)
```

删除空的处理回调，或用 `set_process(false)`、`set_physics_process(false)` 关闭它；已启用的空回调仍会每帧运行。

### CharacterBody 移动

- **[必须]** `CharacterBody2D.velocity` 的单位是像素每秒，`CharacterBody3D.velocity` 的单位是世界单位每秒（通常是米每秒）。直接赋予期望的速度，不乘以 `delta`：`move_and_slide()` 内部会使用物理步长。把加速度（例如重力）累加到速度上时才乘以 `delta`。参见 Godot 4.7 的 [CharacterBody2D](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html) 和 [CharacterBody3D](https://docs.godotengine.org/en/4.7/classes/class_characterbody3d.html) 参考。
- **[必须]** 把 `is_on_floor()` 和滑动碰撞查询理解为上一次 `move_and_slide()` 调用的结果。需要本步碰撞时，在移动之后读取；在移动之前检查，得到的有意就是上一次移动的结果。只有对应的接触判断为 true 时，才读取地面或墙面法线。
- **[复核]** 修改 CharacterBody 移动时，检查相同模拟时间内的位移，以及接触地面、墙面状态切换的时机。对比多次运行时，明确物理帧率和时间缩放，避免把时序差异误当成速度问题已修复。

## 信号与异步

- **[必须]** 信号连接的生命周期跟随两端的所有权。长期存在的端点不能积累重复或失效的测试或运行时订阅。
- **[必须]** `await` 之后，重新检查挂起期间可能变化的对象和状态假设。如果操作可能被取消、替换或重入，在修改状态之前，还要确认这次完成仍属于当前的操作。仅凭对象有效不能确认这一点；使用符合契约的已有状态、操作标识或取消机制。
- **[必须]** 契约随离开场景而结束的工作，之后不能再修改状态。按实际使用的计时器、Tween 或订阅选择清理方式：绑定到节点的 Tween 在树外会暂停，在其绑定节点被释放时被终止；而 SceneTreeTimer 没有与 `Timer.stop()` 等价的方法。停止效果与使待完成的回调失效是两件不同的事。参见 Godot 4.7 的 [Tween 绑定](https://docs.godotengine.org/en/4.7/classes/class_tween.html#class-tween-method-bind-node) 和 [SceneTreeTimer](https://docs.godotengine.org/en/4.7/classes/class_scenetreetimer.html)。
- **[必须]** 不为了让生命周期竞态消失而添加 `call_deferred()`。延迟执行必须对应真实的生产顺序要求。

```gdscript
extends Control

const MESSAGE_DURATION_SECONDS: float = 1.0

var _message_generation: int = 0

func _exit_tree() -> void:
	# 之后再次进入树时，不能接受本次在树期间的完成回调。
	_message_generation += 1
	visible = false

func show_message_for_a_second() -> void:
	_message_generation += 1
	var generation: int = _message_generation
	visible = true
	# 使用受缩放的游戏时间；计时器随 SceneTree 一起暂停。
	await get_tree().create_timer(MESSAGE_DURATION_SECONDS, false).timeout
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
	if not is_inside_tree() or generation != _message_generation:
		return
	visible = false
```

这个示例假设调用发生在 Control 位于树中时。新消息会使旧的等待失效；离开树会使本次在树期间的所有等待失效。不会重叠的简单操作不需要代数计数器。

### 动画与音频的完成

- **[必须]** 等待播放完成之前，先检查信号的发出条件。循环动画不会发出 `AnimationMixer.animation_finished`；`stop()` 或播放中离开 SceneTree，都不会发出 `AudioStreamPlayer.finished`。中断不等于自然完成。参见 Godot 4.7 的 [AnimationMixer](https://docs.godotengine.org/en/4.7/classes/class_animationmixer.html) 和 [AudioStreamPlayer](https://docs.godotengine.org/en/4.7/classes/class_audiostreamplayer.html) 参考。
- **[必须]** 玩法或 UI 等待可被中断的播放时，其所属方还必须处理功能允许的取消、替换和退出路径。在这些路径中恢复临时状态或输入权限；只在自然完成的 `await` 之后清理是不够的。播放器被复用时，在修改其状态之前，仍要确认这次完成属于当前操作。
- **[复核]** 修改依赖播放的流程时，验证自然完成，以及相关的循环、中断和退出路径，包括待处理的工作和状态清理。检查最终的玩法或 UI 行为，而不只是动画或声音是否停止。

## 切换场景与节点生命周期

- **[必须]** 有意识地用 `change_scene_to_file()` 或 `change_scene_to_packed()` 替换主场景；被替换的场景会被销毁，而 Autoload 会保留。
- **[优先]** 稳定的切换目标用预加载；运行时选定的大型场景，使用官方的 `ResourceLoader` 多线程请求、状态查询和获取流程。
- **[必须]** 在正常的玩法路径中，用 `instantiate()` 实例化 `PackedScene`，用 `queue_free()` 销毁 Node；不使用 Godot 3 的 `instance()` 或立即执行的 `free()`。

```gdscript
const LEVEL_2: PackedScene = preload("res://levels/level2.tscn")

func go_to_level_2() -> void:
	get_tree().change_scene_to_packed(LEVEL_2)

func spawn_enemy(enemy_scene: PackedScene) -> Node:
	var enemy: Node = enemy_scene.instantiate()
	add_child(enemy)
	return enemy

func despawn_enemy(enemy: Node) -> void:
	if is_instance_valid(enemy):
		enemy.queue_free()
```

## 输入处理

输入动作（Input Action）的语义、按键身份、`Input.get_vector()`、重复触发时机和改键，遵循 [InputMap 配置](../40-project-config/input-map.md)。下面的规则说明 GDScript 如何接收输入。

- **[必须]** 区分通过 `Input` 单例的持续轮询，与 InputEvent 的事件路由。在 `_physics_process()` 中通过输入动作采样按住状态，适用于固定步长的玩法；事件回调用于离散的路由事件。
- **[优先]** 玩法事件通过 `_unhandled_input()` 或 `_unhandled_key_input()` 接收，让 GUI Control 先有机会消费它们。只有行为必须在 GUI 路由之前观察或处理事件时，才使用 `_input()`；这种优先级不明显时，写明原因。
