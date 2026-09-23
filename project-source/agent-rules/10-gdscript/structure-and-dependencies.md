# GDScript Structure and Dependencies

Keep ownership and dependency direction explicit rather than discovering collaborators through the SceneTree.

## Responsibilities

- **[MUST]** A script should have one primary responsibility. Do not split files mechanically only to satisfy a metric threshold; split on real responsibility/dependency boundaries.
- **[MUST]** Mutable business state has one authoritative owner. Other systems mutate it through the owner-defined API/Command path.
- **[PREFER]** Prefer composition for independent capabilities. Use inheritance only for a stable `is-a` relationship and supported shared contract.
- **[REVIEW]** Use abstract classes only where the target Godot version and architecture need a real abstract contract; do not create inheritance scaffolding for speculative reuse.

## Dependency direction

- **[PREFER]** Use `$` or `%` for scene-internal references. Do not discover cross-module dependencies with deep parent/root paths or recursive `find_child()` searches.
- **[MUST]** Cross-module dependencies use explicit APIs, dependency injection, a coordinator, or another intentional boundary.
- **[MUST]** Use Command/API down and Event/Signal up as the default dependency direction. Sibling modules communicate through an owner/coordinator rather than reaching into each other.
- For signal API choice and dynamic-boundary exceptions, apply [Exports, properties, and signals](typing-and-api.md#exports-properties-and-signals).
- **[MUST]** Groups are behavior classification/broadcast mechanisms, not a hidden global service locator.

### Communication example

The parent owns coordination and may call a child API. A child reports an event upward; it does not discover or mutate its parent through `get_parent()`.

```gdscript
# parent.gd
extends Node

@onready var inventory: Node = $Inventory
@onready var hud: Control = $HUD

func _ready() -> void:
	$Player.item_collected.connect(_on_player_item_collected)

func _on_player_item_collected(item_id: String) -> void:
	inventory.add_item(item_id)
	hud.show_item_pickup(item_id)
```

```gdscript
# player.gd
extends Node

signal item_collected(item_id: String)

func collect_item(item_id: String) -> void:
	item_collected.emit(item_id)
	return
```

Do not replace this with `get_parent().get_node("HUD")` or a sibling lookup. If forwarding the signal through several Scene levels would create a signal maze, use the focused Autoload event-bus pattern described in `40-project-config/autoloads.md`.

## Global services and testability

- **[MUST]** Autoload is for true global lifetime/ownership, not a convenience service locator for arbitrary dependencies.
- **[MUST]** Test/debug adapters invoke the same production API/Command boundaries; do not create arbitrary reflection setters or universal `set_property` backdoors.
- **[PREFER]** Separate pure/domain logic from SceneTree, I/O, VFX, and external services where that reflects the real architecture and improves testability.
