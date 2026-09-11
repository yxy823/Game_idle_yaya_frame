# Export Features and Overrides

Custom export features are case-sensitive build APIs whose runtime behavior exists in exported builds.

## Features

- **[MUST]** Custom export features are validated in an actual exported build; editor Play/F5/F6 does not prove the feature is present.
- **[MUST]** Once consumed by code/config/extensions, a custom feature name is a stable build API; rename/remove migrates all consumers.
- **[MUST]** Do not use `debug` alone to mean 'exported debug build' because editor contexts also expose debug semantics.
- **[MUST]** Custom feature tags use stable lowercase `snake_case` project naming.
- **[MUST]** An `EditorExportPlugin` reads target custom features from the current `EditorExportPreset`, for example through `get_export_preset().get_custom_features()`; do not infer them from the Editor host's `OS.has_feature()`.
- **[MUST]** Read a ProjectSetting after target-preset feature overrides through `EditorExportPreset.get_project_setting()`. The Editor host's `ProjectSettings` value is not proof of the target preset's effective value.
- **[MUST]** Exported runtime code may use `OS.has_feature()` for its actual runtime feature set; do not substitute that runtime contract for preset-aware Editor export logic.
