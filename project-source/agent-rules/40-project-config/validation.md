# Project Configuration Validation

A successfully parsed `project.godot` is only the lowest validation layer.

- **[MUST]** Validate changed settings against target Godot 4.7 name/type/legal values and semantics.
- **[MUST]** Validate persisted behavior from a **fresh target Godot process**; editor in-memory state does not prove disk persistence.
- **[MUST]** Run concrete consumer tests for the affected setting domain.
- **[MUST]** Renderer/platform-specific settings require corresponding renderer/platform evidence where behavior depends on it.
- **[MUST]** Autoload/startup changes include fresh startup validation.
- **[MUST]** Input changes include appropriate action/event routing tests.
- **[MUST]** Import-default changes include reimport/fresh-import validation.
- **[MUST]** Custom export-feature behavior also follows `41-export-config`.
