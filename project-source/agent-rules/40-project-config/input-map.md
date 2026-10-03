# InputMap Configuration

Input Actions are stable semantic abstractions across devices and user rebinding. GDScript event routing follows [Input handling](../10-gdscript/godot-lifecycle-and-input.md#input-handling).

## Actions

- **[MUST]** Custom gameplay actions use stable `snake_case` names with business meaning.
- **[MUST]** Gameplay consumes Input Actions rather than hard-coded Key or Button events. The exceptions are rebinding, text and IME input, diagnostics and device-specific behavior.
- **[MUST]** Built-in `ui_*` actions remain UI, focus and navigation actions; they do not carry gameplay semantics.
- **[MUST]** Choose physical key identity for position-based controls, logical keycodes for semantic shortcuts, and text or Unicode values for text input.
- **[MUST]** When constructing an `InputEventKey`, set the intended identity semantics; do not fill every key field "for safety".
- **[PREFER]** Display physical-key bindings using the current keyboard layout rather than assuming a fixed label.

## Analog input, repeat, and rebinding

- **[MUST]** Persistent and script-created actions set their deadzone deliberately rather than relying on API or editor defaults that may drift.
- **[PREFER]** Use `Input.get_vector()` for common two-axis movement where it matches the control contract.
- **[REVIEW]** One physical event mapped to several gameplay actions requires an intentional context or precedence.
- **[MUST]** Use deterministic project repeat logic where repeat timing matters; do not depend on the OS key echo.
- **[MUST]** Player rebindings persist under `user://`; the project defaults remain the source for restoring defaults.
- **[MUST]** Renaming or deleting an action migrates code, scenes, tests and, where supported, persisted rebinding data.

## Automation semantics

- **[MUST]** In an `EditorPlugin` or `@tool` context, do not treat `InputMap` singleton results as the project's Input Map: methods such as `action_get_events()` return Editor action bindings there.
- **[MUST]** Editor authoring of project actions and bindings reads and writes the `ProjectSettings` `input/*` settings or uses verified structured project tooling. The runtime `InputMap` and the Editor action maps remain separate.
- **[MUST]** Polling tests use `Input.action_press()` and `Input.action_release()`; event-route tests use `Input.parse_input_event()` or the runner's event simulation. Do not confuse these paths.
