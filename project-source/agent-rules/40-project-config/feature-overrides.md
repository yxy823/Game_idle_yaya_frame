# Project Feature Overrides

ProjectSettings feature overrides are build/environment selection, not runtime gameplay state.

## Feature overrides

- **[MUST]** Feature tags are case-sensitive; custom project tags use stable lowercase `snake_case`.
- **[MUST]** Use feature overrides for build/platform/environment differences, not dynamic gameplay state.
- **[MUST]** Distinguish base setting lookup from effective overridden setting.
- **[MUST]** Godot `debug` includes editor contexts; do not equate it with exported-debug-only semantics.
- **[MUST]** A custom export feature is validated in an actual exported build; editor play does not prove custom feature exists.
- **[MUST]** Feature rename/remove migrates `export_presets.cfg`, project overrides, code, tests, and extension/plugin consumers.
- **[MUST]** When precedence between feature overrides matters, verify actual target Godot resolution instead of guessing.
