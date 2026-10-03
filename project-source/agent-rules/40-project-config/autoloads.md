# Autoload Configuration

Autoloads are ordered application dependencies with global lifetime.

## Identity and lifecycle

- **[MUST]** Use stable PascalCase Autoload names, and migrate all consumers when renaming or removing one.
- **[MUST]** Do not let an Autoload name collide with an unrelated `class_name`. Autoload backing scripts normally do not need a `class_name`.
- **[MUST]** Script Autoloads inherit from Node. Use a scene Autoload when a global service genuinely needs a stable internal Node tree.
- **[MUST]** The order of the Autoload list is semantic where startup dependencies exist; do not alphabetize it.
- **[PREFER]** Express complex startup dependencies through explicit initialization or bootstrap phases rather than incidental `_ready` ordering.
- **[MUST]** Autoload startup does not require the gameplay main scene or HUD to exist already, unless that dependency is intentionally part of the bootstrap.
- **[MUST]** Autoload Nodes have global lifetime and do not free themselves during normal application life.

## Scope

- **[MUST]** Use an Autoload only for true global lifetime or ownership. Do not make it a convenience service locator for arbitrary dependencies.
- **[MUST]** An Autoload runs in every operation that resolves the project, including the editor and subprocesses, so keep its startup code safe and lightweight.
- **[MUST]** Temporary test Autoloads use an isolated test configuration or the plugin lifecycle and do not permanently pollute the production `project.godot`.
- **[MUST]** Validate persistent Autoload changes from disk in a fresh Godot process.
- **[MUST]** Autoloads that a plugin registers follow the plugin cleanup rules in [Editor plugins](editor-plugins.md#plugins).
- **[PREFER]** Appropriate uses include cross-Scene persistence (save data, settings, progression), focused global services (audio, Scene transitions, localization, input mapping), a focused event bus and read-only global configuration.
- **[MUST]** Keep Autoloads free of presentation and mostly read by others. Expose queries, meaningful commands and signals instead of inviting arbitrary external field mutation.
- **[MUST]** Do not put single-Scene state, convenience-only globals or broad domain behavior in an Autoload that can grow into a God Object.

### Focused event bus example

Use an event bus only when forwarding a signal through several Scene or module boundaries would otherwise create a signal maze. Nearby communication remains direct wiring through the parent or coordinator.

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
