# Scene UI and Script Binding

Respect Control/Container ownership and script/resource compatibility.

## UI

- **[MUST]** Use Control/Container layout semantics instead of manually fighting a Container-owned rect.
- **[MUST]** A viewport-filling UI scene with a `Control` root must establish an explicit Full Rect or equivalent root sizing contract. Do not assume a newly created `Control` root automatically fills the viewport; its default anchors and offsets do not establish that contract.
- **[PREFER]** A non-fullscreen widget, popup, tooltip, or embedded panel may use an intentional intrinsic or minimum-size contract instead of Full Rect; make that sizing ownership explicit.
- **[REVIEW]** Repeated per-node theme overrides may indicate a shared Theme/ThemeVariation should own styling; do not duplicate overrides without reason.
- **[MUST]** UI reparenting must consider anchors, offsets, size flags, mouse/focus behavior, theme propagation, and container ownership.

## Scripts

- **[MUST]** An attached script must compile under Godot 4.7 and its base type must be compatible with the Node type.
- **[PREFER]** Keep substantial business logic in external `.gd` scripts rather than embedding logic into scene serialization.
- **[MUST]** Test/debug instrumentation must not become persistent production scene pollution.

## Signal connection style

| Connection style | Use it for |
| --- | --- |
| Editor connection | Nodes that already exist in one authored Scene |
| Code `connect()` / signal `Callable` | Runtime-instantiated Nodes or intentionally cross-Scene wiring |

- **[PREFER]** Keep one project convention. Editor connections remain visible in `.tscn` and its diff; code connections centralize runtime wiring in `_ready()` but are not visible when inspecting the Scene file.

```gdscript
signal start_requested

# Static nodes authored in the Scene can use an editor connection to this method.
func _on_start_button_pressed() -> void:
	start_requested.emit()

func _ready() -> void:
	# Runtime-created controls must be connected in code.
	var button: Button = _create_dynamic_button()
	button.pressed.connect(_on_dynamic_button_pressed)

func _on_dynamic_button_pressed() -> void:
	queue_redraw()
```
