# GDScript Lifecycle, Signals, Async, Groups, and Input

Godot lifecycle semantics must remain explicit and validated in real SceneTree paths when behavior depends on them.

## Node lifecycle

- **[MUST]** Do not treat `_init`, `_enter_tree`, `_ready`, `_process`, `_physics_process`, `_exit_tree`, and deferred deletion as interchangeable phases.
- **[MUST]** Account for SceneTree callback order when behavior depends on parent/child initialization: parent `_enter_tree()` runs before child `_enter_tree()`, while child `_ready()` runs before parent `_ready()`.
- **[MUST]** Treat `_ready()` as once per Node instance by default. If a removed Node must run it on a later tree entry, call `request_ready()` before re-adding it; request readiness separately for children that also require another `_ready()` call.
- **[MUST]** A queued-for-deletion Node may remain valid until deferred deletion occurs. Revalidate references after awaits/deferred work when lifetime can change.
- **[MUST]** Use `queue_free()`/lifecycle ownership deliberately; `remove_child()` removes from the tree but does not free ownership by itself.
- **[MUST]** Process/pause behavior is an explicit contract. Do not change `process_mode` or pause semantics as a cosmetic refactor.

### Callback timing reference

| Callback | Timing | Intended use |
| --- | --- | --- |
| `_init()` | Object creation, before the SceneTree exists | State independent of child Nodes and tree services |
| `_enter_tree()` | Node enters the SceneTree | Registration with external systems |
| `_ready()` | Node and its children have entered the tree | Child references and signal connections |
| `_process(delta)` | Every rendered frame | Presentation, animation, and UI updates |
| `_physics_process(delta)` | Every fixed physics frame | Movement, collision, and deterministic physics work |
| `_exit_tree()` | Node leaves the SceneTree | Deregistration and cleanup |

Keep `$Child` access out of `_init()`. `add_child()` causes a not-yet-ready child to enter the tree and eventually run `_ready()`; reparenting an already-ready node does not re-run `_ready()` automatically unless `request_ready()` was called before it re-entered the tree.

```gdscript
extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D

func _init() -> void:
	# Child nodes do not exist at this point.
	velocity = Vector2.ZERO

func _ready() -> void:
	sprite.visible = true

func _physics_process(delta: float) -> void:
	# Physics, movement, and collision belong to the fixed-step callback.
	move_and_slide()

func _process(delta: float) -> void:
	# Presentation can interpolate using the rendered-frame delta.
	sprite.rotation = lerp_angle(sprite.rotation, rotation, delta * 8.0)
```

Remove empty processing callbacks or disable them with `set_process(false)` / `set_physics_process(false)`; an enabled empty callback still runs every frame.

### CharacterBody movement

- **[MUST]** Keep `CharacterBody2D.velocity` in pixels per second and `CharacterBody3D.velocity` in world units per second (normally meters per second). Assign the desired velocity without multiplying it by `delta`: `move_and_slide()` uses the physics step internally. Apply `delta` when integrating acceleration, such as gravity, into velocity. See the Godot 4.7 references for [CharacterBody2D](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html) and [CharacterBody3D](https://docs.godotengine.org/en/4.7/classes/class_characterbody3d.html).
- **[MUST]** Interpret `is_on_floor()` and slide-collision queries as results of the last `move_and_slide()` call. Read after movement when the current step's collisions are required; a check before movement intentionally uses the previous move's result. Read floor/wall normals only when the corresponding contact predicate is true.
- **[REVIEW]** When changing CharacterBody movement, check displacement over equal simulated time and the timing of floor/wall transitions. Keep the physics tick rate and time scale explicit when comparing runs, so timing differences are not mistaken for a velocity fix.

## Signals and async

- **[MUST]** Signal connection lifetime follows endpoint ownership. Persistent endpoints must not accumulate duplicate or stale test/runtime subscriptions.
- **[MUST]** After an `await`, revalidate object/state assumptions that may have changed while suspended.
- **[MUST]** Do not add `call_deferred()` merely to make a lifecycle race disappear. Deferred execution must correspond to a real production ordering requirement.

```gdscript
func show_message_for_a_second() -> void:
	visible = true
	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
	visible = false
```

### Animation and audio completion

- **[MUST]** Check the emission conditions before awaiting playback completion. Looping animations do not emit `AnimationMixer.animation_finished`; `AudioStreamPlayer.finished` is not emitted by `stop()` or by leaving the SceneTree during playback. An interruption is not a natural completion. See the Godot 4.7 references for [AnimationMixer](https://docs.godotengine.org/en/4.7/classes/class_animationmixer.html) and [AudioStreamPlayer](https://docs.godotengine.org/en/4.7/classes/class_audiostreamplayer.html).
- **[MUST]** When gameplay or UI waits for interruptible playback, its owner must also handle cancellation, replacement, and exit paths that the feature permits. Restore temporary state or input access in those paths; cleanup only after a natural-finish `await` is insufficient. If a player is reused, completion must still belong to the current operation before changing its state.
- **[REVIEW]** For changes to a playback-dependent flow, verify natural completion and the relevant loop/interruption/exit paths, including pending work and state cleanup. Check the resulting gameplay or UI behavior, not only whether the animation or sound stopped.

## Scene changes and node lifetime

- **[MUST]** Replace the main Scene with `change_scene_to_file()` or `change_scene_to_packed()` deliberately; the old Scene is destroyed except for Autoloads.
- **[PREFER]** Preload stable transition targets or use the official threaded `ResourceLoader` request/status/get lifecycle for large runtime-selected Scenes.
- **[MUST]** Instantiate a `PackedScene` with `instantiate()` and destroy Nodes with `queue_free()`, not Godot 3's `instance()` or immediate `free()` in normal gameplay paths.

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

## Input and groups

- **[MUST]** Gameplay input is expressed through Input Actions rather than hard-coded Key/Button values, except where the feature is specifically rebinding/text/IME/diagnostics/device semantics.
- **[MUST]** Built-in `ui_*` actions are for UI/focus/navigation, not gameplay semantics.
- **[MUST]** Distinguish continuous Input singleton polling from InputEvent routing. Held-state sampling through Input Actions in `_physics_process()` is valid for fixed-step gameplay; event callbacks serve discrete routed events.
- **[PREFER]** Route gameplay events through `_unhandled_input()` or `_unhandled_key_input()` so GUI Controls can consume them first. Use `_input()` only when the behavior must observe or handle an event before GUI routing, and document that priority when it is not self-evident.
- **[MUST]** Use physical key identity for position-dependent controls and logical keycode/unicode for semantic shortcuts/text according to actual input intent.
- **[PREFER]** Use `Input.get_vector()` or equivalent action-based composition for standard 2D movement when appropriate.
- **[MUST]** Do not rely on OS keyboard echo as authoritative gameplay repeat; implement deterministic repeat where repeat timing matters.
