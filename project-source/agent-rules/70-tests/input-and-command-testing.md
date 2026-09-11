# Input and Command Testing

Separate physical input, Godot event routing, UI adapters, and production business Commands.

## Input layers

- **[MUST]** `Input.action_press/release` tests polling action state; it does not prove `_input()`/`_unhandled_input()` event propagation.
- **[MUST]** Use `Input.parse_input_event` or runner's real event simulation when event routing/GUI consumption is contract.
- **[MUST]** `InputEventAction('attack')` proves action semantics, not physical Key/Mouse/Joypad binding.
- **[PREFER]** Gameplay business tests use semantic Actions or production Commands rather than binding to current default key.
- **[REVIEW]** Physical binding, modifiers, exact_match, deadzones, axis direction, and device-specific behavior use actual physical InputEvent tests.
- **[MUST]** When GUI consumption/focus/mouse_filter/Viewport routing matters, test through real Viewport event path rather than directly calling handlers.

## UI versus business

- **[MUST]** Distinguish UI interaction wiring, UI state, and downstream business behavior as separate test targets.
- **[MUST]** When contract is 'user can click this control', directly emitting control signal or calling handler is not sufficient evidence.
- **[MUST]** Do not force business rules to be tested through mouse/UI when Command/domain API is actual behavior boundary.

## Commands

- **[PREFER]** Automatable gameplay operations execute through production Command/API boundaries.
- **[MUST]** Test/debug harnesses do not bypass production validation, state ownership, costs, phase checks, or event emission by directly mutating internals.
- **[MUST]** Commands express stable business intent, not arbitrary `set_property`, `call_method`, or reflection mutation.
- **[REVIEW]** A fixture/scenario builder may establish legal initial state quickly, but setup and operation under test are distinct.
- **[MUST]** Normal fixture builders create states satisfying current domain invariants; invalid/corrupt states are constructed only by tests explicitly targeting recovery/validation.
- **[MUST]** Text debug/console command harnesses parse/resolve/dispatch production typed Commands; they do not reimplement business logic.
- **[MUST]** Parser tests and Command behavior tests are separate.
- **[MUST]** Command entity references use stable business/slot identities, not volatile SceneTree NodePaths/UI names.
- **[MUST]** Separate mutating Commands from read-only Queries; queries do not secretly repair/create/progress state.
- **[PREFER]** Business assertions read authoritative domain snapshots/queries rather than inferring state from deep UI Nodes.
- **[PREFER]** Fallible Commands return/emit structured stable results; human log text is not only success/failure API.
- **[MUST]** Rejected Commands assert both failure and absence of partial authoritative-state mutation.
- **[PREFER]** Complex bug reproduction is legal initial scenario + deterministic seed/time inputs + production Command sequence.
- **[MUST]** Input Action IDs and Domain Command IDs are separate namespaces; adapters map contextual input intent to business Command.
