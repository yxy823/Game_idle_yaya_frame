# Autoload Configuration

Autoloads are ordered, global-lifetime application dependencies.

## Identity and lifecycle

- **[MUST]** Use stable PascalCase Autoload names and migrate all consumers on rename/remove.
- **[MUST]** Do not collide an Autoload name with unrelated `class_name`; Autoload backing scripts normally do not need `class_name`.
- **[MUST]** Script Autoloads inherit Node. Use Scene Autoload when global service genuinely needs a stable internal Node tree.
- **[MUST]** Autoload list order is semantic where startup dependencies exist; do not alphabetize it.
- **[PREFER]** Complex startup dependencies use explicit initialize/bootstrap phases rather than incidental `_ready` ordering.
- **[MUST]** Autoload startup must not require gameplay Main/HUD to already exist unless that dependency is intentionally part of bootstrap.
- **[MUST]** Autoload Nodes are global lifetime and must not free themselves during normal application life.

## Scope

- **[MUST]** Use Autoload only for true global lifetime/ownership. Do not make it a convenience service locator for arbitrary dependencies.
- **[MUST]** Autoload expands execution surface of every project-resolved/editor/subprocess operation; startup code must be safe/lightweight.
- **[MUST]** Temporary test Autoloads use isolated test configuration or plugin lifecycle and do not permanently pollute production `project.godot`.
- **[MUST]** Persistent Autoload changes are validated from disk in a fresh Godot process.
- **[MUST]** Plugin-owned Autoloads have symmetric register/unregister or export-stripping lifecycle.
- **[PREFER]** Appropriate uses include cross-Scene persistence (save data, settings, progression), focused global services (audio, Scene transitions, localization, input mapping), a focused event bus, and read-only global configuration.
- **[MUST]** Keep Autoloads presentation-free and read-heavy. Expose queries, meaningful commands, and signals instead of inviting arbitrary external field mutation.
- **[MUST]** Do not put single-Scene state, convenience-only globals, or broad domain behavior in an Autoload that can grow into a God Object.

### Focused event bus example

Use an event bus only when forwarding through several Scene or module boundaries would otherwise create a signal maze. Nearby communication remains direct parent/coordinator wiring.

```gdscript
# res://autoload/events.gd, registered as the Events Autoload
extends Node

signal player_died
signal score_changed(new_score: int)
signal level_completed(level_id: String)
```

Consumers use the typed signal object API:

```gdscript
Events.player_died.emit()
Events.score_changed.connect(_on_score_changed)
```

Group bus signals by domain and keep the bus focused; do not turn it into a universal service locator.
