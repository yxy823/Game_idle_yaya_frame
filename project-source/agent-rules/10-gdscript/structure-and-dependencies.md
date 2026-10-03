# GDScript Structure and Dependencies

Keep ownership and dependency direction explicit rather than discovering collaborators through the SceneTree.

## Responsibilities

- **[MUST]** Give each script one primary responsibility. Do not split files mechanically only to satisfy a metric threshold; split on real responsibility and dependency boundaries.
- **[MUST]** Mutable business state has one authoritative owner. Other systems mutate it through the API or Command path that the owner defines. Presentation-local state such as hover or display interpolation belongs to its presentation owner and is not a second authority for gameplay values.
- **[PREFER]** Prefer composition for independent capabilities. Use inheritance only for a stable `is-a` relationship and supported shared contract.
- **[REVIEW]** Use abstract classes only where the target Godot version and architecture need a real abstract contract; do not create inheritance scaffolding for speculative reuse.

## Dependency direction

- **[PREFER]** Use `$` or `%` for references inside a scene. Do not discover cross-module dependencies with deep parent or root paths or with recursive `find_child()` searches.
- **[MUST]** Cross-module dependencies use explicit APIs, dependency injection, a coordinator, or another intentional boundary.
- **[MUST]** Use Commands or API calls downward and events or signals upward as the default dependency direction. Sibling modules communicate through an owner or coordinator rather than reaching into each other.
- **[MUST]** Choose the signal API, including dynamic-boundary exceptions, under [Exports, properties, and signals](typing-and-api.md#exports-properties-and-signals).
- **[MUST]** Groups classify behavior and broadcast to members; they are not a hidden global service locator.

### Communication example

The parent owns coordination and may call a child API. A child reports an event upward; it does not discover or mutate its parent through `get_parent()`.

Distinguish a requested action from its accepted result and from reading current state, as explained in `docs/game-organization.md`. The example below assumes an accepted collection that can be added; if adding can fail, handle that result before showing success feedback. Showing current inventory when opening the HUD should not by itself replay pickup events.

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
```

Do not replace this with `get_parent().get_node("HUD")` or a sibling lookup. If forwarding the signal through several Scene levels would create a signal maze, use the focused Autoload event-bus pattern described in `40-project-config/autoloads.md`.

## Global services and testability

- **[MUST]** Use an Autoload only under the [Autoload scope rules](../40-project-config/autoloads.md#scope); it is not a convenience service locator.
- **[MUST]** Test and debug adapters invoke the same production API and Command boundaries. Do not create arbitrary reflection setters or universal `set_property` backdoors.
- **[PREFER]** Separate independently testable rule calculations from the SceneTree, I/O, VFX and external services where that reflects the real architecture and improves testability. Gameplay that depends on physics or scene lifetime still owns its game-rule decisions; a Node is not automatically a presentation object.
