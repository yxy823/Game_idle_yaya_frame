# Resource Validation

- **[MUST]** Parse and load with the target Godot 4.7.
- **[MUST]** Validate the Resource UID and path and the expected Resource or custom type.
- **[MUST]** Validate exported values, required fields, invariants and dependency compatibility.
- **[MUST]** For class, property, default or schema changes, validate all affected repository Resources and representative consumers.

Alias checks after duplication, save and reload checks for generated Resources, and cache refresh after external edits are defined in `duplication-and-runtime-state.md` and `identity-paths-and-saving.md`.
