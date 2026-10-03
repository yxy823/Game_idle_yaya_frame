# GDScript Editor Tools, Static State, and Concurrency

Keep editor-only execution, global state and threads constrained.

## Editor and tool code

- **[MUST]** Use `@tool` only for real editor-time behavior. Separate editor and runtime paths explicitly, and guard editor-only side effects.
- **[MUST]** Use `Engine.is_editor_hint()` to distinguish editor execution from game execution inside tool-capable code. Do not treat `OS.has_feature("editor")` as an equivalent runtime-context check; a game launched from the editor may still use an editor-enabled binary.
- **[MUST]** When a tool script instantiates another GDScript or accesses its instance members or methods in the editor, that dependency must also support `@tool` execution. Static methods, constants, and enums are exceptions; do not read a non-tool script's static variables from tool context because they resolve to `null`.
- **[MUST]** Extending an `@tool` script does not make the derived script a tool script. A derived script that requires editor execution must declare `@tool` itself.
- **[MUST]** Integrate editor modifications that users can perform as operations with the appropriate Editor undo and redo mechanism.
- **[PREFER]** For a reusable script with editor-assigned dependencies or configuration that can be invalid, consider `_get_configuration_warnings()` and refresh it with `update_configuration_warnings()` when those inputs change. Warnings require `@tool` execution: keep that editor path safe and use it only for a real authoring need. Runtime validation still handles actual failures. See the Godot 4.7 [Node configuration warning contract](https://docs.godotengine.org/en/4.7/classes/class_node.html#class-node-private-method-get-configuration-warnings).

## Static and global state

- **[REVIEW]** A mutable `static var` is process-global state. Require a clear owner, lifetime and reset policy, and do not use it to bypass dependency injection or authoritative ownership.
- **[MUST]** Keep static initialization deterministic and lightweight. Avoid hidden file, network or SceneTree work during static initialization.
- **[MUST]** Reset or process-isolate mutations that tests make to Autoloads, static state or global registries.

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

- **[MUST]** A static function cannot access `self` or instance members. Lambdas cannot be static; see [Lambdas and callable boundaries](typing-and-api.md#lambdas-and-callable-boundaries).
- **[REVIEW]** Static variables normally live for the running process. Use an Autoload for explicit global ownership and a Resource or file for state that must survive across application runs; do not rely on version-specific `@static_unload` behavior.

## Godot-specific performance examples

- **[REVIEW]** Pool objects created at high frequency (for example, projectiles, particles or damage numbers) only after profiling demonstrates an allocation hotspot.
- **[MUST]** Deactivate pooled Nodes with an explicit ownership and processing policy, such as `hide()`, `set_process(false)` and `set_physics_process(false)`. Do not leave them in the inherited processing mode while expecting zero CPU cost.
- **[MUST]** Do not use `set_deferred("process_mode", ...)` as a generic pool deactivation mechanism.
- **[REVIEW]** For very large numbers of homogeneous objects, consider `MultiMeshInstance2D`, `MultiMeshInstance3D` or RenderingServer APIs after measurement.
- **[PREFER]** Cache repeated `get_node()` lookups in `@onready` members and avoid per-frame string concatenation in hot paths.
- **[REVIEW]** A rising Orphan Nodes count in Debugger → Monitors indicates Nodes removed from the tree without being freed. Investigate their lifetime.

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
- **[MUST]** Do not mutate one Resource from multiple threads. Shared mutable data uses an explicit synchronization and ownership strategy. Array or Dictionary operations that change the container size require synchronization.
- **[REVIEW]** When a locked section can invoke callbacks or emit signals, inspect cross-thread waits, lock ordering and whether callbacks can observe partially updated state. Godot's [Mutex is reentrant](https://docs.godotengine.org/en/4.7/classes/class_mutex.html): same-thread relocking alone is not a deadlock, and each successful lock requires a matching unlock. This does not make shared state or engine APIs thread-safe.
- **[REVIEW]** Rendering, physics, navigation, and other Server APIs have distinct thread-safety requirements. Verify the target API and required ProjectSettings before moving that work off the main thread.
