# Editor Plugins

Enabling an editor plugin adds code that runs in the editor, together with lifecycle responsibilities.

## Plugins

- **[REVIEW]** Enabling or adding an editor plugin adds code that runs in the editor. Verify its necessity and its compatibility with the Godot and tool versions.
- **[MUST]** Do not permanently enable a plugin only to complete one Agent task.
- **[MUST]** A plugin that is installed or present is not necessarily enabled; these are different states.
- **[MUST]** Plugin enable and disable cleanup is symmetric. A plugin does not leave behind Autoloads, docks, settings or editor state that it owns.
- **[MUST]** Excluding a plugin's files from export does not remove an Autoload entry persisted in `project.godot`. A plugin-owned Autoload, including a test-only one, needs symmetric unregistration or stripping from the export.
- **[MUST]** Plugin cleanup does not delete user-owned project assets.
- **[MUST]** Third-party addons follow the vendor rules; do not refactor their style by default.
- **[MUST]** Validate persistent enablement in a fresh editor process, not only in the current editor's memory.
- **[PREFER]** Maintained plugins survive enable, disable and enable again without duplicate or residual state.
- **[MUST]** Editor-only plugin functionality cannot be a hidden prerequisite for exported gameplay unless an explicit runtime component is packaged.
- **[MUST]** Distinguish editor execution from game execution under [Editor and tool code](../10-gdscript/editor-tools-static-state-and-concurrency.md#editor-and-tool-code); `Engine.is_editor_hint()` and OS or feature-tag detection answer different questions.
