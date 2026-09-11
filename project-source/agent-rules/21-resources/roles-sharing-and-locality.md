# Resource Roles, Sharing, and Locality

Classify a Resource before deciding whether mutation/sharing/local-to-scene behavior is correct.

## Roles

- **[MUST]** Classify a Resource as Definition/Config, instance-local state, or explicit runtime mutable shared state.
- **[MUST]** Definition/Config Resources are runtime read-only by default.
- **[MUST]** External `.tres` versus SubResource does not by itself prove shared versus unique semantics.

### Data-driven authoring

- **[PREFER]** Use typed custom Resources for inspector-editable definitions such as item data, skills, enemy parameters, level configuration, or dialogue.
- **[PREFER]** Keep repository source Resources in VCS-friendly `.tres` format because it is text, reviewable, and diffable.
- **[MUST]** Do not require a manual `.tres` to `.res` conversion before release solely for packaging; the Godot export pipeline may handle binary packaging. Author `.res` directly only for an explicit size, performance, or binary-source requirement.
- **[MUST]** A Resource is data, not a SceneTree Node; it has no `_process` callback and does not participate in per-frame processing.

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

Create an `EnemyStats` `.tres` through FileSystem → New → Resource and edit it in the Inspector. Load it with `load()` when selected at runtime or assign it through an explicit `@export` reference.

### Change notification

- **[MUST]** A custom Resource does not automatically emit `changed` when an exported value changes. If consumers rely on change notification, emit it from the setter while preserving the property invariant.

```gdscript
@export var hp: int = 100:
	set(value):
		if hp != value:
			hp = value
			emit_changed()
```

## Local-to-scene

- **[MUST]** Use `resource_local_to_scene` only when each PackedScene instance genuinely needs its own Resource copy semantics.
- **[MUST]** Changing `resource_local_to_scene` at runtime does not retroactively clone already-instantiated Resources.
- **[MUST]** `_setup_local_to_scene()` initializes the instance-local copy; it must not mutate the external/source Resource as a side effect.
- **[MUST]** Override `_setup_local_to_scene()` for local-to-scene initialization. Business or Agent code must not manually call deprecated `setup_local_to_scene()`; let the scene-instantiation lifecycle invoke it.
- **[PREFER]** Keep local-to-scene initialization deterministic; inject/own RNG when randomness is required.
