# Export Features and Overrides

Custom export features are case-sensitive build APIs whose runtime behavior exists in exported builds. How feature-tag overrides layer with other ProjectSettings values is described in [Effective values and feature overrides](../40-project-config/authoring-and-scope.md#effective-values-and-feature-overrides).

## Features

- **[MUST]** Validate custom export features in an actual exported build; editor Play (F5 or F6) does not prove that the feature is present.
- **[MUST]** Once code, configuration or extensions consume a custom feature name, it is a stable build API. Renaming or removing it migrates every consumer, including `export_presets.cfg`, project overrides, code, tests and extension or plugin consumers.
- **[MUST]** Do not use `debug` alone to mean "exported debug build", because editor contexts also expose debug semantics.
- **[MUST]** Custom feature tags use stable lowercase `snake_case` project names.
- **[MUST]** An `EditorExportPlugin` reads the target's custom features from the current `EditorExportPreset`, for example through `get_export_preset().get_custom_features()`. Do not infer them from `OS.has_feature()` on the Editor host.
- **[MUST]** Read a ProjectSetting after the target preset's feature overrides through `EditorExportPreset.get_project_setting()`. The `ProjectSettings` value on the Editor host does not prove the target preset's effective value.
- **[MUST]** Exported runtime code may use `OS.has_feature()` for its actual runtime feature set; do not substitute that runtime contract for preset-aware Editor export logic.
