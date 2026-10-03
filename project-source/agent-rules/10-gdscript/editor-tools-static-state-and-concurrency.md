# GDScript 编辑器工具、静态状态与并发

约束只在编辑器中执行的代码、全局状态和线程。

## 编辑器与工具代码

- **[必须]** 只在确有编辑器期行为时使用 `@tool`。明确分开编辑器路径和运行时路径，并保护只应在编辑器中发生的副作用。
- **[必须]** 在可作为工具运行的代码中，用 `Engine.is_editor_hint()` 区分编辑器执行和游戏执行。不把 `OS.has_feature("editor")` 当作等价的运行环境判断；从编辑器启动的游戏，仍可能使用带编辑器功能的可执行文件。
- **[必须]** 工具脚本在编辑器中实例化另一个 GDScript，或访问其实例成员或方法时，被依赖的脚本也必须支持 `@tool` 执行。静态方法、常量和枚举例外；不在工具上下文中读取非工具脚本的静态变量，因为它们会解析为 `null`。
- **[必须]** 继承一个 `@tool` 脚本，不会让子脚本成为工具脚本。需要在编辑器中执行的子脚本，必须自己声明 `@tool`。
- **[必须]** 用户可以作为一次操作执行的编辑器修改，要接入编辑器相应的撤销与重做机制。
- **[优先]** 可复用的脚本，如果其依赖或配置由编辑器指定、且可能无效，考虑实现 `_get_configuration_warnings()`，并在这些输入变化时调用 `update_configuration_warnings()` 刷新。配置警告需要 `@tool` 执行：保证这条编辑器路径安全，只在确有编辑需要时使用。实际的失败仍由运行时验证处理。参见 Godot 4.7 的 [Node 配置警告契约](https://docs.godotengine.org/en/4.7/classes/class_node.html#class-node-private-method-get-configuration-warnings)。

## 静态与全局状态

- **[复核]** 可变的 `static var` 是进程级全局状态。要求它有明确的所属方、生命周期和重置策略；不用它绕开依赖注入或权威的所有权。
- **[必须]** 静态初始化保持确定、轻量。避免在静态初始化中暗中访问文件、网络或 SceneTree。
- **[必须]** 测试对 Autoload、静态状态或全局登记表做的修改，要重置或用进程隔离。

```gdscript
class_name MathUtils
extends Object

static var instance_count: int = 0

static func _static_init() -> void:
	# 类加载时的工作保持确定，且不依赖 SceneTree。
	instance_count = 0

static func clamp_angle(angle: float) -> float:
	return fposmod(angle + PI, TAU) - PI
```

- **[必须]** 静态函数不能访问 `self` 或实例成员。Lambda 不能是静态的；参见 [Lambda 与 Callable 边界](typing-and-api.md#lambda-与-callable-边界)。
- **[复核]** 静态变量通常在整个运行进程中存续。需要明确的全局所有权时用 Autoload；需要跨多次运行保留的状态用 Resource 或文件；不依赖与版本有关的 `@static_unload` 行为。

## Godot 特有的性能示例

- **[复核]** 只有在性能分析证明存在分配热点后，才对高频创建的对象（例如子弹、粒子或伤害数字）使用对象池。
- **[必须]** 用明确的所有权和处理策略停用池中的 Node，例如 `hide()`、`set_process(false)` 和 `set_physics_process(false)`。不让它们保持继承来的处理模式，又期望 CPU 开销为零。
- **[必须]** 不把 `set_deferred("process_mode", ...)` 当作通用的对象池停用机制。
- **[复核]** 数量非常大的同类对象，在测量之后，考虑使用 `MultiMeshInstance2D`、`MultiMeshInstance3D` 或 RenderingServer API。
- **[优先]** 把重复的 `get_node()` 查找缓存到 `@onready` 成员中；在热路径中避免逐帧拼接字符串。
- **[复核]** Debugger → Monitors 中 Orphan Nodes 数量持续上升，说明有 Node 从树中移除后没有被释放。调查它们的生命周期。

```gdscript
func release_to_pool() -> void:
	hide()
	set_process(false)
	set_physics_process(false)

func acquire_from_pool(spawn_position: Vector2) -> void:
	global_position = spawn_position
	show()
	set_process(true)
	set_physics_process(true)
```

## 并发

- **[复核]** 只为有充分理由的工作负载使用线程。并发不能实质改善系统时，优先使用更简单的单线程逻辑。
- **[必须]** 工作线程不直接与活动的 SceneTree 交互，也不修改主线程拥有的 Node 状态。对活动树的修改，转交到主线程上合适的边界执行。
- **[必须]** 只有在确认的 Godot 4.7 配置下，涉及的每个 API 和对象都线程安全时，才允许在树外、线程本地地构建 Node 或场景。构建过程只由一个工作线程负责修改，把结果加入活动 SceneTree 之前先回到主线程。
- **[必须]** 不从多个线程修改同一个 Resource。共享的可变数据要有明确的同步与所有权策略。改变容器大小的 Array 或 Dictionary 操作需要同步。
- **[复核]** 加锁区段内可能调用回调或发出信号时，检查跨线程等待、加锁顺序，以及回调是否会看到更新到一半的状态。Godot 的 [Mutex 是可重入的](https://docs.godotengine.org/en/4.7/classes/class_mutex.html)：同一线程重复加锁本身不会死锁，每次成功加锁都需要一次对应的解锁。这并不会让共享状态或引擎 API 变得线程安全。
- **[复核]** 渲染、物理、导航和其他 Server API 各有不同的线程安全要求。把这些工作移出主线程前，核实目标 API 和所需的 ProjectSettings。
