# Input and Command Testing

Separate physical input, Godot event routing, UI adapters and production business Commands.

## Input layers

- **[MUST]** `Input.action_press()` and `Input.action_release()` test the polled action state; they do not prove event propagation through `_input()` or `_unhandled_input()`.
- **[MUST]** Use `Input.parse_input_event()` or the runner's real event simulation when event routing or GUI consumption is the contract.
- **[MUST]** `InputEventAction('attack')` proves action semantics, not the physical Key, Mouse or Joypad binding.
- **[PREFER]** Gameplay business tests use semantic Actions or production Commands rather than binding to the current default key.
- **[REVIEW]** Test physical bindings, modifiers, `exact_match`, deadzones, axis direction and device-specific behavior with actual physical InputEvents.
- **[MUST]** When GUI consumption, focus, `mouse_filter` or Viewport routing matters, test through the real Viewport event path rather than calling handlers directly.

## UI versus business behavior

- **[MUST]** Treat UI interaction wiring, UI state and downstream business behavior as separate test targets.
- **[MUST]** When the contract is "the user can click this control", directly emitting the control's signal or calling its handler is not sufficient evidence.
- **[MUST]** Do not force business rules to be tested through the mouse or UI when a Command or domain API is the actual behavior boundary.

## Commands

- **[PREFER]** Automatable gameplay operations execute through production Command and API boundaries.
- **[MUST]** Test and debug harnesses do not bypass production validation, state ownership, costs, phase checks or event emission by directly mutating internals.
- **[MUST]** Commands express stable business intent, not an arbitrary `set_property`, `call_method` or reflective mutation.
- **[REVIEW]** A fixture or scenario builder may establish a legal initial state quickly, but the setup and the operation under test are distinct.
- **[MUST]** Normal fixture builders create states that satisfy the current domain invariants. Invalid or corrupt states are constructed only by tests that explicitly target recovery or validation.
- **[MUST]** Text debug or console command harnesses parse, resolve and dispatch typed production Commands; they do not reimplement business logic.
- **[MUST]** Parser tests and Command behavior tests are separate.
- **[MUST]** Entity references in Commands use stable business or slot identities, not volatile SceneTree NodePaths or UI names.
- **[MUST]** Separate mutating Commands from read-only Queries. Queries do not secretly repair, create or advance state.
- **[PREFER]** Business assertions read authoritative domain snapshots or queries rather than inferring state from deep UI Nodes.
- **[PREFER]** Fallible Commands return or emit structured, stable results; human-readable log text is not the only success or failure API.
- **[MUST]** Tests of rejected Commands assert both the failure and the absence of any partial mutation of authoritative state.
- **[PREFER]** Reproduce a complex bug from a legal initial scenario, deterministic seed and time inputs, and a sequence of production Commands.
- **[MUST]** Input Action IDs and domain Command IDs are separate namespaces; adapters map contextual input intent to a business Command.
