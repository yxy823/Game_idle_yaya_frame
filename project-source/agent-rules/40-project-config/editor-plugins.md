# Editor Plugins

Enabling an editor plugin adds editor-time executable code and lifecycle responsibilities.

## Plugins

- **[REVIEW]** Enabling/newly adding an editor plugin adds editor execution surface; verify Godot/tool version compatibility and necessity.
- **[MUST]** Do not permanently enable a plugin only to complete one Agent task.
- **[MUST]** Installed/present and enabled are different states.
- **[MUST]** Plugin enable/disable lifecycle cleanup is symmetric; a plugin must not leave owned Autoloads, docks, settings, or editor state behind.
- **[MUST]** Plugin cleanup does not delete user-owned project assets.
- **[MUST]** Third-party addons follow vendor rules; do not style-refactor them by default.
- **[MUST]** Persistent enablement is validated in a fresh editor process, not only current editor memory.
- **[PREFER]** Maintained plugins should survive enable -> disable -> enable without duplicate/residual state.
- **[MUST]** Editor-only plugin functionality cannot be hidden prerequisite for exported gameplay runtime unless an explicit runtime component is packaged.
- **[MUST]** `Engine.is_editor_hint()` and OS/feature-tag detection answer different questions; do not substitute them.
