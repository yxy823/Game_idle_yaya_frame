# GDScript 生命周期、信号、异步与输入

本页规定节点生命周期、信号与 `await`、Tween 与 AnimationPlayer、切换场景和接收输入的写法，使用这些机制时读。

行为依赖下面这些生命周期语义时，在真实的 SceneTree 路径中验证。

## 节点生命周期

- 父节点的 `_enter_tree()` 先于子节点，子节点的 `_ready()` 先于父节点。`_init()` 时子节点和 `@onready` 成员都还不存在，不在其中访问它们。
- `_ready()` 每个 Node 实例只运行一次。被移除的 Node 再次进入树时需要重新运行，就在重新加入之前调用 `request_ready()`；需要重新运行的子节点要分别请求。
- `remove_child()` 只把 Node 移出树，不释放它；不再使用时调用 `queue_free()`。正常玩法路径用 `queue_free()`，不用立即执行的 `free()`。
- 已调用 `queue_free()` 的 Node 在当前帧结束前仍然有效，用 `is_queued_for_deletion()` 识别。
- 删除空的 `_process()`、`_physics_process()` 等回调；已定义的处理回调即使为空也会每帧调用。暂时不需要处理时用 `set_process(false)`、`set_physics_process(false)` 关闭。
- `process_mode` 和暂停行为是玩法契约，不在重构中顺带修改。
- `CharacterBody2D.velocity` 的单位是像素每秒，直接赋予期望速度，不乘 `delta`，`move_and_slide()` 内部会使用物理步长；只有把加速度（例如重力）累加到速度上时才乘 `delta`。`is_on_floor()` 等接触查询反映的是最近一次 `move_and_slide()` 的结果。

## 信号与异步

- 信号连接跟随两端的所有权。长期存在的对象不能积累重复或失效的连接。
- 注意：`await` 期间如果脚本所在的对象被释放，挂起的函数会被丢弃，不再继续执行，所以 `await` 之后不需要检查 `is_instance_valid(self)`。等待这个函数的调用方也不会继续执行。
- `await` 之后，重新检查挂起期间可能变化的状态：是否已排队删除、是否还在树中，以及这次完成是否仍属于当前操作。操作可能被取消、替换或重入时，用操作代数或取消标记确认；对象有效不能说明这一点。
- 随离开场景而结束的工作，离开后不能再修改状态。按实际使用的对象选择清理方式：
  - Tween：`Node.create_tween()` 创建的 Tween 绑定到该节点，节点在树外时暂停，节点释放时 Tween 被终止。
  - SceneTreeTimer：没有 `stop()`，超时信号仍会发出；用操作代数让过期的完成回调失效。
- 不为了让时序问题消失而添加 `call_deferred()`；延迟执行要对应真实的顺序要求。

```gdscript
extends Control

const MESSAGE_SECONDS: float = 1.5

var _message_generation: int = 0


func _exit_tree() -> void:
	# 离开树会使本次在树期间发起的等待全部失效。
	_message_generation += 1
	visible = false


func show_message() -> void:
	_message_generation += 1
	var generation: int = _message_generation
	visible = true
	# process_always 为 false：计时器随 SceneTree 暂停，并受时间缩放影响。
	await get_tree().create_timer(MESSAGE_SECONDS, false).timeout
	if generation != _message_generation or is_queued_for_deletion():
		return
	visible = false
```

新消息和离开树都会让之前的等待失效。不会重叠、也不会中途离开树的简单操作，不需要操作代数。

### 动画与音频的完成

- 等待播放完成之前，确认信号一定会发出：循环动画不发出 `AnimationMixer.animation_finished`；调用 `stop()` 或播放中离开 SceneTree 时，`AudioStreamPlayer.finished` 不发出。
- 等待可被中断的播放时，所属方还要处理取消、替换和退出路径，并在这些路径中恢复临时状态或输入权限。播放器被复用时，修改状态前确认这次完成属于当前操作。
- 修改依赖播放的流程时，检查自然完成、循环、中断和退出四种路径的最终玩法或 UI 状态，而不只看动画或声音是否停止。

## Tween 与 AnimationPlayer 的选择

- 建议：运行时才确定目标值的少量属性插值，用 Tween。
- 建议：跨多个属性或节点、需要在编辑器中调整关键帧的预制时间线，用 AnimationPlayer。
- 建议：逐像素或逐顶点的视觉效果用 Shader，GPU 粒子的状态用粒子 Shader，规则见 [30 Shader 规则](../30-shaders/README.md)。
- Tween 绑定到节点时用 `create_tween()`，不用 `get_tree().create_tween()` 创建未绑定的 Tween，除非它确实要在节点释放后继续运行。

## 切换场景

- `change_scene_to_file()` 和 `change_scene_to_packed()` 会销毁当前主场景，Autoload 保留。
- 实例化 `PackedScene` 用 `instantiate()`，不用 Godot 3 的 `instance()`。
- 建议：运行时选定的大型场景用后台加载，流程见[Resource 与加载](state-resources-and-loading.md#resource-与加载)。

## 输入处理

Input Action 的定义、按键绑定、`Input.get_vector()`、重复触发和改键，遵循 [InputMap 配置](../40-project-config/input-map.md)。本节只规定 GDScript 怎样接收输入。

- 按住状态在 `_physics_process()` 或 `_process()` 中通过 `Input` 单例的 Action 轮询；离散事件在输入回调中处理。
- 玩法输入在 `_unhandled_input()` 或 `_unhandled_key_input()` 中处理，让 GUI 先消费事件。只有必须在 GUI 之前看到事件时才用 `_input()`，并在注释中写明原因。
