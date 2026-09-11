# ProjectSettings Authoring and Scope

`project.godot` is behavior configuration, not a text-cleanup target.

## Authoring

- **[MUST]** Keep `project.godot` diffs minimal. Do not sort unrelated keys, expand every default, reorder sections, or normalize unrelated content.
- **[MUST]** For built-in ProjectSettings, a missing key uses the target Godot 4.7 engine default; for a custom setting, absence from `project.godot` and `ProjectSettings.set_setting()` means the setting is not defined, so do not assume a Godot default.
- **[MUST]** Treat effective ProjectSettings as layered: built-in engine default, explicit `project.godot` value, configured override source such as `override.cfg` or `application/config/project_settings_override`, then feature-tag override. Validate the actual effective value and its override source in a fresh process.
- **[MUST]** `ProjectSettings.get_setting()` reads without automatically applying feature overrides; use `get_setting_with_override()` when the effective feature-overridden value is the contract.
- **[REVIEW]** Explicitly pin a critical setting when project correctness must not drift with engine defaults; do not dump every default into the file.
- **[MUST]** Before changing a setting, verify exact Godot 4.7 name, type, legal values, default/deprecation, and renderer/platform scope.
- **[MUST]** Prefer ProjectSettings/Editor/structured tooling for structural settings changes. A small deterministic text patch is acceptable only with exact format knowledge and fresh-process validation.

## Runtime versus persisted config

- **[MUST]** ProjectSettings configuration is not necessarily current runtime state. Use DisplayServer/RenderingServer/AudioServer/etc. for runtime truth.
- **[MUST]** Editor in-memory ProjectSettings is not proof that `project.godot` was persisted. Persistent changes require fresh-process evidence.
- **[MUST]** EditorPlugin/tool changes intended to persist to `project.godot` must explicitly save through `ProjectSettings.save()` or an equivalent structured authoring tool, and check the returned `Error`.
- **[MUST]** Persist ProjectSettings changes before launching a child/editor/game process that will read them; in-memory changes are not enough for Autoload, plugin, or other subprocess configuration.
- **[MUST]** Player runtime settings normally persist under `user://` and use runtime APIs; gameplay does not rewrite project configuration.

## Deletion and names

- **[MUST]** Before deleting/renaming a Project Setting, Input action, Autoload, group, shader global, or layer name, migrate all consumers including dynamic registries where applicable.
- **[MUST]** Named project-level settings are cross-file APIs once consumed.
