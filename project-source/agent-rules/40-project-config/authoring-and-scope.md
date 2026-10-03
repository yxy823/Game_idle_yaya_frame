# ProjectSettings Authoring and Scope

`project.godot` is behavior configuration, not a target for text cleanup.

## Authoring

- **[MUST]** Keep `project.godot` diffs minimal. Do not sort unrelated keys, expand every default, reorder sections or normalize unrelated content.
- **[MUST]** For a built-in ProjectSetting, a missing key uses the engine default of the target Godot 4.7. For a custom setting, absence from both `project.godot` and `ProjectSettings.set_setting()` means that the setting is not defined; do not assume a Godot default.
- **[REVIEW]** Explicitly pin a critical setting when project correctness must not drift with engine defaults. Do not dump every default into the file.
- **[MUST]** Before changing a setting, verify its exact Godot 4.7 name, type, legal values, default and deprecation status, and its renderer and platform scope.
- **[MUST]** Prefer ProjectSettings, the Editor or structured tooling for structural settings changes. A small deterministic text patch is acceptable only with exact knowledge of the format and validation in a fresh process.

## Effective values and feature overrides

- **[MUST]** Treat effective ProjectSettings as layered: the built-in engine default, the explicit `project.godot` value, a configured override source such as `override.cfg` or `application/config/project_settings_override`, then a feature-tag override. Validate the actual effective value and its override source in a fresh process.
- **[MUST]** `ProjectSettings.get_setting()` reads a setting without applying feature overrides. Use `get_setting_with_override()` when the effective, feature-overridden value is the contract.
- **[MUST]** Use feature-tag overrides for differences between builds, platforms and environments, not for dynamic gameplay state.
- **[MUST]** When the precedence between several feature overrides matters, verify the actual resolution in the target Godot instead of guessing.
- **[MUST]** Naming, `debug` semantics, renaming and export validation of custom features follow [Export features and overrides](../41-export-config/features-and-overrides.md).

## Runtime versus persisted configuration

- **[MUST]** ProjectSettings configuration is not necessarily the current runtime state. Use DisplayServer, RenderingServer, AudioServer and similar server APIs for runtime truth.
- **[MUST]** In-memory ProjectSettings in the Editor do not prove that `project.godot` was persisted. Persistent changes require evidence from a fresh process.
- **[MUST]** EditorPlugin or tool changes intended to persist to `project.godot` explicitly save through `ProjectSettings.save()` or an equivalent structured authoring tool, and check the returned `Error`.
- **[MUST]** Persist ProjectSettings changes before launching a child, editor or game process that will read them. In-memory changes are not enough for Autoload, plugin or other subprocess configuration.
- **[MUST]** Player runtime settings normally persist under `user://` through runtime APIs; gameplay does not rewrite project configuration.

## Deletion and names

- **[MUST]** Before deleting or renaming a ProjectSetting, an Input Action, an Autoload, a group, a shader global or a layer name, migrate all consumers, including dynamic registries where applicable.
- **[MUST]** Named project-level settings become cross-file APIs once they are consumed.
