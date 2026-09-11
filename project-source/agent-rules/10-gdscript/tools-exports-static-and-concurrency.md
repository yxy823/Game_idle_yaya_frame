# GDScript Tooling, Exports, Static State, and Concurrency

Keep editor-only execution, serialized editor configuration, global state, and threads constrained.

## Editor/tool code

- **[MUST]** Use `@tool` only for real editor-time behavior. Separate editor/runtime paths explicitly and guard editor-only side effects.
- **[MUST]** Use `Engine.is_editor_hint()` to distinguish editor execution from game execution inside tool-capable code. Do not treat `OS.has_feature("editor")` as an equivalent runtime-context check; a game launched from the editor may still use an editor-enabled binary.
- **[MUST]** When a tool script instantiates another GDScript or accesses its instance members or methods in the editor, that dependency must also support `@tool` execution. Static methods, constants, and enums are exceptions; do not read a non-tool script's static variables from tool context because they resolve to `null`.
- **[MUST]** Extending an `@tool` script does not make the derived script a tool script. A derived script that requires editor execution must declare `@tool` itself.
- **[MUST]** Editor modifications that are user-editable operations should integrate with the appropriate Editor undo/redo mechanism.
- **[MUST]** `@export` is for real design-time persistent configuration, not arbitrary runtime scratch state.
- **[PREFER]** Use setters/getters for local property invariants, not hidden multi-system workflows.

## Static/global state

- **[REVIEW]** Mutable `static var` is process-global state. Require a clear owner/lifetime/reset story and do not use it to bypass DI or authoritative ownership.
- **[MUST]** Static initialization must be deterministic and lightweight; avoid hidden file/network/SceneTree work during static initialization.
- **[MUST]** Autoload/static/global registry mutations in tests must be reset or process-isolated.

```gdscript
class_name MathUtils
extends Object

static var instance_count: int = 0

static func _static_init() -> void:
	# Keep class-load work deterministic and independent of the SceneTree.
	instance_count = 0

static func clamp_angle(angle: float) -> float:
	return fposmod(angle + PI, TAU) - PI
```

- **[MUST]** A static function cannot access `self` or instance members. A lambda cannot be declared static; use a normal static function for reusable static behavior.
- **[REVIEW]** Static variables normally live for the running process. Use an Autoload for explicit global ownership and a Resource/file for durable state across application runs; do not rely on version-specific `@static_unload` behavior.

## Godot-specific performance examples

- **[REVIEW]** Pool objects created at high frequency (for example, projectiles, particles, or damage numbers) only after profiling demonstrates an allocation hotspot.
- **[MUST]** Deactivate pooled Nodes with an explicit ownership/process policy such as `hide()`, `set_process(false)`, and `set_physics_process(false)`; do not leave them in inherited processing mode while expecting zero CPU cost.
- **[MUST]** Do not use `set_deferred("process_mode", ...)` as a generic pool deactivation mechanism.
- **[REVIEW]** For very large numbers of homogeneous objects, consider `MultiMeshInstance2D`, `MultiMeshInstance3D`, or RenderingServer APIs after measurement.
- **[PREFER]** Cache repeated `get_node()` lookups in `@onready` members and avoid per-frame string concatenation in hot paths.
- **[REVIEW]** Rising Orphan Nodes in Debugger → Monitors indicates Nodes removed from the tree without being freed and should trigger a lifetime investigation.

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

## Concurrency

- **[REVIEW]** Threads are used only for justified workloads. Prefer simpler single-threaded logic when concurrency does not materially improve the system.
- **[MUST]** Worker threads do not interact directly with the active SceneTree or mutate main-thread-owned Node state. Marshal active-tree changes to the appropriate main-thread boundary.
- **[MUST]** Off-tree, thread-local Node or scene construction is allowed only when every API and object involved is thread-safe under the confirmed Godot 4.7 configuration. Keep construction under one worker's mutation ownership, then cross to the main thread before adding the result to the active SceneTree.
- **[MUST]** Do not mutate one Resource from multiple threads. Shared mutable data uses an explicit synchronization and ownership strategy; Array or Dictionary operations that change container size require synchronization.
- **[REVIEW]** Rendering, physics, navigation, and other Server APIs have distinct thread-safety requirements. Verify the target API and required ProjectSettings before moving that work off the main thread.
