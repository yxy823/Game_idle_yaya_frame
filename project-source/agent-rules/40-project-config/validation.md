# Project Configuration Validation

A successfully parsed `project.godot` is only the lowest validation layer. The topic documents add their own evidence: a fresh process for persisted settings (`authoring-and-scope.md`) and Autoload changes (`autoloads.md`), fresh import and reimport for import defaults (`import-defaults.md`), and renderer or platform evidence for subsystem settings (`subsystem-settings.md`).

- **[MUST]** Validate changed settings against their Godot 4.7 name, type, legal values and semantics.
- **[MUST]** Run concrete consumer tests for the affected settings domain.
- **[MUST]** For Input changes, include the appropriate action and event-routing tests.
- **[MUST]** Behavior of custom export features is also validated under `41-export-config`.
