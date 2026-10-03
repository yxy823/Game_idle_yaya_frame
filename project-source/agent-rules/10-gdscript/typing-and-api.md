# GDScript Typing and Public API

Prefer explicit, reviewable contracts while keeping dynamic typing at true dynamic boundaries.

## Typing

- **[MUST]** Type function parameters and return values, including `-> void`, for stable project-owned APIs and internal functions unless a true dynamic boundary requires Variant.
- **[MUST]** Type members, exported variables, `@onready` members, signals, and stable containers. Prefer `:=` for locals when inference is unambiguous.
- **[PREFER]** Use typed Arrays and Dictionaries, or typed models, for stable schemas. Keep unrestricted Variant at parsing, migration, reflection, plugin or other genuinely dynamic boundaries.
- **[MUST]** Custom signals with known payloads use typed arguments.
- **[MUST]** Do not solve a type mismatch by broadening stable APIs to Variant unless the domain is genuinely dynamic.
- **[PREFER]** Give collection elements concrete types, including `Array[T]` and the typed Dictionary form supported by the target Godot version. Nested generic element types are limited; use a typed model when deeper structure needs a stable contract.
- **[MUST]** Treat insertion failures from typed collections as contract violations to fix, not as a reason to remove the collection type.
- **[MUST]** For an `as` cast, handle a failed Object cast as `null`; do not use `as` as a string-to-built-in conversion because failed built-in casts are runtime errors.

## Style and naming

- **[MUST]** Use Godot official GDScript style conventions: tabs for indentation, UTF-8 without BOM, LF line endings, final newline, one statement per line, and the official naming and member-order conventions.
- **[MUST]** Keep lines within the configured linter limit; `gdlint.json` owns the exact value.
- **[PREFER]** Document public APIs where semantics, constraints, lifecycle, units, side effects or failure modes are not self-evident.
- **[MUST]** Use `class_name` only for intentional project-global type or API identity, not as a convenience for every script. Do not leave temporary or backup `.gd` copies declaring the same global class in directories Godot scans. Choose their location under the [temporary-file rules](../00-core/third-party-generated-and-temporary-files.md#temporary-backup-and-scratch); `.gdignore` use follows [import visibility rules](../60-assets/ignored-and-raw-files.md#ignored-files).
- **[MUST]** Keep a script filename in the lowercase `snake_case` form of its `class_name` when the script declares one, so case-sensitive platforms resolve the same API.
- **[PREFER]** Write numeric literals with both sides of a decimal point (`0.5`, `2.0`) and use separators for large integers (`1_000_000`) when that improves reviewability.
- **[MUST]** Keep new members consistent with the versioned [Godot 4.7 code order](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html#code-order). In particular, place `_static_init()` before remaining static methods, built-in virtual overrides before custom overrides and remaining methods, and inner classes last; within one category, keep public members before private members. Do not reorder unrelated existing code solely for formatting.

## Exports, properties, and signals

- **[MUST]** Use `@export` only for real design-time persistent configuration, not for arbitrary runtime scratch state.
- **[PREFER]** Use Inspector-aware export annotations such as `@export_range`, `@export_enum`, `@export_file`, `@export_dir`, `@export_color_no_alpha`, `@export_multiline`, `@export_node_path`, and `@export_group` when they express a real design-time constraint.
- **[PREFER]** Use setters and getters for local property invariants, not for hidden workflows across several systems.
- **[MUST]** Use `@onready` for values resolved after the SceneTree is ready. Do not combine `@export` and `@onready` on one property; the latter overwrites the serialized value during `_ready()`.
- **[MUST]** In an inline property setter or getter, direct access to that property is the engine's non-recursive backing access. A helper called by the setter does not receive that exception; use a backing field or keep the assignment in the setter to avoid recursion.
- **[MUST]** For a statically known signal, use the signal object's `.emit()` API and `Signal.connect()` with a typed `Callable`. Do not fall back to stringly typed `Object.emit_signal()` or `Object.connect()` merely from Godot 3 habits.
- **[REVIEW]** `Object.connect()` and `Object.emit_signal()` remain valid Godot 4 APIs at a genuine dynamic string boundary, such as configuration-driven signal names, plugins, or reflective schemas. Validate the dynamic signal name and callable contract at that boundary instead of manufacturing a static wrapper that hides the dynamism.

## Lambdas and callable boundaries

- **[PREFER]** Use a lambda for small temporary behavior and a named normal function for reused or non-trivial behavior. Name non-trivial lambdas so failures remain diagnosable.
- **[MUST]** Invoke a lambda through `.call(...)`; do not treat the lambda variable as a normal function call.
- **[MUST]** Account for closure capture semantics: captured scalar values are copied, while referenced Arrays, Dictionaries, and Objects remain shared.
- **[MUST]** Do not declare lambdas as static. Use a normal static function for reusable static behavior.
- **[PREFER]** Avoid `filter`, `map` and other Callable-heavy functional operations in per-frame or large hot paths unless measurement supports them.

## Collection and control-flow safety

- **[MUST]** Do not mutate an Array or other collection while iterating it in a way that can skip entries or invalidate indexes; filter, iterate backward, or collect removals first.
- **[MUST]** Use GDScript's `value_if_true if condition else value_if_false` conditional expression syntax; do not copy C-style `?:` syntax from another language.

## Stable APIs and identifiers

- **[MUST]** Persisted enum values require stable explicit identity. Do not rely on declaration order for serialized values.
- **[PREFER]** Use StringName, enum or typed IDs where they express a stable closed domain. Do not turn display text into behavior identity.
- **[PREFER]** Use Dictionary for maps and dynamic boundaries. Model stable record-like schemas with typed structures, Resources or domain objects rather than anonymous Dictionaries everywhere.
- **[MUST]** Changing a public function, signal, enum, `class_name`, persisted identifier or stable field is a change that requires migrating its consumers, not a local rename.

## Reference examples

### Typed declarations

```gdscript
# Prefer inference when the right-hand type is clear.
var speed := 100.0
var enemies: Array[Enemy] = []
var position := Vector2(10, 20)

# Annotate when inference is unclear or a constraint matters.
@onready var sprite: Sprite2D = $Sprite2D
var damage: int = stats.attack

func apply_damage(target: Node, amount: int) -> void:
	target.health -= amount

func find_nearest_enemy(from: Vector2) -> Enemy:
	# The nullable result is part of this API's contract.
	return null
```

### Member order

Keep a complete script in the established order so the public surface is easy to scan:

```gdscript
@tool
class_name PlayerController
extends CharacterBody2D

## Controls movement and health for the player character.

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

# Custom overrides from a project base class belong here, after built-in
# virtual overrides and before remaining methods.

func take_damage(amount: int) -> void:
	current_health -= amount
	health_changed.emit(current_health)

func _on_health_changed(new_value: int) -> void:
	pass

class HealthSnapshot:
	var current: int
	var maximum: int
```

### Exports, properties, and signals

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

The backing-access exception for inline setters does not extend to a helper that the setter calls:

```gdscript
var guarded_hp: int = 100:
	set(value):
		_assign_hp(value)

func _assign_hp(value: int) -> void:
	guarded_hp = value # Infinite recursion: this helper is not the setter itself.
```

Use a backing field such as `_guarded_hp` when the setter needs a helper.

### Callable and lambda usage

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
print(counter) # Still 0: captured scalar values are copied.

var items: Array[int] = []
var add_item := func() -> void: items.append(1)
add_item.call()
print(items) # [1]: captured reference contents remain shared.
```

### Documentation comments and control flow

```gdscript
## Controls the player character.
##
## Handles movement, jumping, and attacks. Input collection belongs to
## [InputHandler], not this class.
class_name DocumentedPlayer
extends CharacterBody2D

## Current health. Emits [signal died] when it reaches zero.
var current_health: int = 100

## Applies [param amount] damage from [param source].
## The amount must be non-negative. Returns the remaining health.
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

For collection edits, filter, iterate backward, or collect removals first; never invalidate the collection being traversed:

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
