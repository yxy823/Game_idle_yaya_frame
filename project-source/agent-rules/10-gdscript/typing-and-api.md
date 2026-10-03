# GDScript 类型与公共 API

优先使用明确、便于审查的契约；动态类型只留在真正的动态边界。

## 类型

- **[必须]** 稳定的项目自有 API 和内部函数，给参数和返回值标注类型（包括 `-> void`），除非真正的动态边界需要 Variant。
- **[必须]** 给成员、导出变量、`@onready` 成员、信号和稳定的容器标注类型。类型推断无歧义时，局部变量优先用 `:=`。
- **[优先]** 稳定的 schema 使用带类型的 Array 和 Dictionary，或带类型的模型。不受限制的 Variant 只留在解析、迁移、反射、插件或其他真正动态的边界。
- **[必须]** 负载已知的自定义信号，参数要带类型。
- **[必须]** 不靠把稳定 API 放宽成 Variant 来解决类型不匹配，除非这个领域确实是动态的。
- **[优先]** 给集合元素指定具体类型，包括 `Array[T]` 和目标 Godot 版本支持的带类型 Dictionary 写法。嵌套泛型元素类型的支持有限；更深的结构需要稳定契约时，使用带类型的模型。
- **[必须]** 带类型集合的插入失败是需要修复的契约违规，不是去掉集合类型的理由。
- **[必须]** 使用 `as` 转换时，把 Object 转换失败作为 `null` 处理；不用 `as` 把字符串转换成内置类型，因为内置类型转换失败会产生运行时错误。

## 风格与命名

- **[必须]** 遵循 Godot 官方 GDScript 风格约定：用 Tab 缩进，UTF-8 无 BOM，LF 换行，文件末尾有换行，每行一条语句，并遵循官方的命名和成员顺序约定。
- **[必须]** 行长不超过已配置的 linter 上限；确切值由 `gdlint.json` 规定。
- **[优先]** 公共 API 的语义、约束、生命周期、单位、副作用或失败方式不明显时，为它写文档。
- **[必须]** 只为有意设立的项目全局类型或 API 身份使用 `class_name`，不是每个脚本都为了方便加上。在 Godot 会扫描的目录中，不留下声明同一个全局类的临时或备份 `.gd` 副本。这些副本的位置按[临时文件规则](../00-core/third-party-generated-and-temporary-files.md#临时备份与草稿文件)选择；`.gdignore` 的使用遵循 [导入可见性规则](../60-assets/ignored-and-raw-files.md#忽略文件)。
- **[必须]** 脚本声明了 `class_name` 时，文件名使用该 `class_name` 的小写 `snake_case` 形式，让区分大小写的平台解析到同一个 API。
- **[优先]** 能提高可读性时，小数点两侧都写数字（`0.5`、`2.0`），大整数使用分隔符（`1_000_000`）。
- **[必须]** 新成员遵循 Godot 4.7 版本的[代码顺序](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html#code-order)。特别是：`_static_init()` 放在其余静态方法之前；内置虚方法的重写放在自定义重写和其余方法之前；内部类放在最后；同一类别中，公共成员在私有成员之前。不只为格式而重排无关的已有代码。

## 导出、属性与信号

- **[必须]** `@export` 只用于真正在设计期持久保存的配置，不用于任意的运行时临时状态。
- **[优先]** 当 `@export_range`、`@export_enum`、`@export_file`、`@export_dir`、`@export_color_no_alpha`、`@export_multiline`、`@export_node_path`、`@export_group` 等能被检查器识别的导出注解能表达真实的设计期约束时，使用它们。
- **[优先]** setter 和 getter 用于维护属性自身的不变量，不用于隐藏跨多个系统的流程。
- **[必须]** 场景树就绪后才能解析的值使用 `@onready`。不在同一个属性上同时使用 `@export` 和 `@onready`；后者会在 `_ready()` 期间覆盖序列化的值。
- **[必须]** 在内联的属性 setter 或 getter 中直接访问该属性，是引擎提供的非递归后备访问。setter 调用的辅助函数不享有这个例外；使用后备字段，或把赋值留在 setter 中，以免无限递归。
- **[必须]** 对静态已知的信号，使用信号对象的 `.emit()` API，以及以带类型 `Callable` 调用的 `Signal.connect()`。不仅凭 Godot 3 的习惯退回到用字符串的 `Object.emit_signal()` 或 `Object.connect()`。
- **[复核]** 在真正的动态字符串边界上，例如由配置驱动的信号名、插件或反射式 schema，`Object.connect()` 和 `Object.emit_signal()` 仍是有效的 Godot 4 API。在这个边界上验证动态信号名和 callable 契约，不制造一个隐藏动态性的静态包装。

## Lambda 与 Callable 边界

- **[优先]** 小的临时行为用 lambda；复用的或不简单的行为用具名的普通函数。给不简单的 lambda 命名，以便出错时能够诊断。
- **[必须]** 通过 `.call(...)` 调用 lambda；不把 lambda 变量当作普通函数调用。
- **[必须]** 考虑闭包捕获的语义：捕获的标量值会被复制，而引用的 Array、Dictionary 和 Object 仍然共享。
- **[必须]** 不把 lambda 声明为静态。可复用的静态行为使用普通的静态函数。
- **[优先]** 在逐帧或大型热路径中，避免 `filter`、`map` 等大量使用 Callable 的函数式操作，除非测量结果支持使用。

## 集合与控制流安全

- **[必须]** 不在遍历 Array 或其他集合时，以可能跳过元素或使索引失效的方式修改它；先过滤、倒序遍历，或先收集要移除的元素。
- **[必须]** 使用 GDScript 的 `value_if_true if condition else value_if_false` 条件表达式语法；不照搬其他语言的 C 风格 `?:` 语法。

## 稳定 API 与标识符

- **[必须]** 持久化的枚举值需要稳定、显式的身份。序列化的值不依赖声明顺序。
- **[优先]** 表达稳定的封闭取值域时，使用 StringName、枚举或带类型的 ID。不把显示文本变成行为身份。
- **[优先]** 映射和动态边界使用 Dictionary。稳定的、类似记录的 schema，用带类型的结构、Resource 或领域对象建模，而不是处处使用匿名 Dictionary。
- **[必须]** 修改公共函数、信号、枚举、`class_name`、持久化标识符或稳定字段，是需要迁移消费方的修改，不是局部重命名。

## 参考示例

### 类型声明

```gdscript
# 右侧类型清楚时优先使用推断。
var speed := 100.0
var enemies: Array[Enemy] = []
var position := Vector2(10, 20)

# 推断不清楚或需要约束时显式标注。
@onready var sprite: Sprite2D = $Sprite2D
var damage: int = stats.attack

func apply_damage(target: Node, amount: int) -> void:
	target.health -= amount

func find_nearest_enemy(from: Vector2) -> Enemy:
	# 可能返回 null 是这个 API 契约的一部分。
	return null
```

### 成员顺序

完整的脚本保持既定顺序，便于快速浏览公共接口：

```gdscript
@tool
class_name PlayerController
extends CharacterBody2D

## 控制玩家角色的移动和生命值。

signal health_changed(new_health: int)
signal died

enum State { IDLE, RUNNING, JUMPING }

const MAX_HEALTH: int = 100
const JUMP_VELOCITY: float = -400.0

static var instance_count: int = 0

@export var speed: float = 200.0
@export var max_jumps: int = 2

var current_health: int = MAX_HEALTH
var current_state: State = State.IDLE

var _jumps_remaining: int = 0
var _last_damage_source: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox

static func _static_init() -> void:
	instance_count = 0

static func get_max_health() -> int:
	return MAX_HEALTH

func _init() -> void:
	instance_count += 1

func _ready() -> void:
	health_changed.connect(_on_health_changed)

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

# 来自项目基类的自定义重写放在这里：
# 在内置虚方法重写之后、其余方法之前。

func take_damage(amount: int) -> void:
	current_health -= amount
	health_changed.emit(current_health)

func _on_health_changed(new_value: int) -> void:
	pass

class HealthSnapshot:
	var current: int
	var maximum: int
```

### 导出、属性与信号

```gdscript
signal health_changed(new_health: int)
signal died

@export var speed: float = 100.0
@export_range(0, 100, 1) var health: int = 100
@export_range(0.0, 1.0, 0.01) var volume: float = 1.0
@export_enum("Easy", "Normal", "Hard") var difficulty: int = 1
@export_file("*.json") var config_path: String = ""
@export_dir var save_dir: String = ""
@export_color_no_alpha var tint: Color = Color.WHITE
@export_multiline var description: String = ""
@export_node_path("Sprite2D") var sprite_path: NodePath
@export_group("Movement")
@export var movement_speed: float = 100.0
@export var jump_height: float = 64.0
@export_group("")

var hp: int = 100:
	set(value):
		if hp != value:
			hp = value
			health_changed.emit(hp)
	get:
		return hp

var display_name: String = "":
	set(value):
		display_name = value
		_update_label()

func notify_health() -> void:
	health_changed.emit(hp)
	died.emit()
```

内联 setter 的后备访问例外，不延伸到 setter 调用的辅助函数：

```gdscript
var guarded_hp: int = 100:
	set(value):
		_assign_hp(value)

func _assign_hp(value: int) -> void:
	guarded_hp = value # 无限递归：这个辅助函数不是 setter 本身。
```

setter 需要辅助函数时，使用 `_guarded_hp` 这样的后备字段。

### Callable 与 lambda 用法

```gdscript
button.pressed.connect(_on_button_pressed)
button.pressed.connect(_on_button_pressed.bind("attack"))
timer.timeout.connect(_on_timeout, CONNECT_ONE_SHOT)
some_signal.connect(_on_some_signal, CONNECT_DEFERRED)

var sorted: Array[Enemy] = enemies.duplicate()
sorted.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.threat > b.threat)

var damages: Array[int] = []
for enemy: Enemy in enemies:
	damages.append(enemy.attack)

var compute_damage := func compute(base: int, multiplier: float) -> int:
	return int(base * multiplier)
print(compute_damage.call(10, 1.5))
```

```gdscript
var counter: int = 0
var increment := func() -> void: counter += 1
increment.call()
print(counter) # 仍为 0：捕获的标量值是副本。

var items: Array[int] = []
var add_item := func() -> void: items.append(1)
add_item.call()
print(items) # [1]：捕获的引用，其内容仍然共享。
```

### 文档注释与控制流

```gdscript
## 控制玩家角色。
##
## 处理移动、跳跃和攻击。输入采集由 [InputHandler] 负责，
## 不属于这个类。
class_name DocumentedPlayer
extends CharacterBody2D

## 当前生命值。降到零时发出 [signal died]。
var current_health: int = 100

## 施加来自 [param source] 的 [param amount] 点伤害。
## amount 必须非负。返回剩余生命值。
func take_damage(amount: int, source: Node) -> int:
	return current_health

func apply_damage(target: Node, amount: int) -> int:
	if not is_instance_valid(target):
		return 0
	if amount <= 0:
		return 0
	var actual_damage: int = _calculate_damage(target, amount)
	target.health -= actual_damage
	return actual_damage
```

编辑集合时，先过滤、倒序遍历，或先收集要移除的元素；绝不让正在遍历的集合失效：

```gdscript
var to_remove: Array[Enemy] = []
for enemy: Enemy in enemies:
	if enemy.is_dead:
		to_remove.append(enemy)
for enemy: Enemy in to_remove:
	enemies.erase(enemy)

var status: String = "alive" if hp > 0 else "dead"
var first: Variant = items[0] if not items.is_empty() else null
```
