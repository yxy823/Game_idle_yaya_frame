# InputMap Configuration

Input Actions are stable semantic abstractions across devices and user rebinding.

## Actions

- **[MUST]** Custom gameplay actions use stable `snake_case` business semantics.
- **[MUST]** Gameplay consumes Input Actions rather than hard-coded device events except rebinding/text/IME/diagnostics/special device behavior.
- **[MUST]** Built-in `ui_*` actions remain UI/focus/navigation actions.
- **[MUST]** Choose physical key identity for position-based controls, logical keycodes for semantic shortcuts, and text/unicode for text input.
- **[MUST]** When constructing `InputEventKey`, set the intended identity semantics; do not fill every key field 'for safety'.
- **[PREFER]** Display physical-key bindings using current keyboard layout rather than assuming a fixed label.

## Analog/repeat/rebinding

- **[MUST]** Persistent/script-created actions set deadzone deliberately rather than relying on API/editor default drift.
- **[PREFER]** Use `Input.get_vector()` for common two-axis movement where it matches control contract.
- **[REVIEW]** One physical event mapped to multiple gameplay actions requires intentional context/precedence.
- **[MUST]** Use deterministic project repeat logic where repeat timing matters; do not depend on OS key echo.
- **[MUST]** Player rebindings persist under `user://`; project defaults remain restore-default source.
- **[MUST]** Action rename/delete migrates code, scenes, tests, and persisted rebind data where supported.

## Automation semantics

- **[MUST]** In an `EditorPlugin` or `@tool` context, do not treat `InputMap` singleton results as the project's Input Map: methods such as `action_get_events()` return Editor action bindings there.
- **[MUST]** Editor authoring of project actions/bindings reads and writes `ProjectSettings` `input/*` settings or uses verified structured project tooling; runtime `InputMap` and Editor action maps remain separate.
- **[MUST]** Polling tests use `Input.action_press/release`; event-route tests use `Input.parse_input_event`/runner simulation. Do not confuse these paths.
