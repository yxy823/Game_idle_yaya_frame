# Export Plugins and Hooks

`EditorExportPlugin` is build-pipeline code capable of changing final packaged content.

## Scope

- **[MUST]** Treat `EditorExportPlugin` changes as build-pipeline changes in addition to GDScript/editor-plugin changes.
- **[MUST]** Changes to file inclusion/skip/remap, scene/resource customization, native library packaging, or export features require an actual export gate.
- **[MUST]** Do not decide production inclusion with ambiguous substring heuristics such as `path.contains('test')`; use explicit project-owned path/role contracts.

## Execution contract

- **[MUST]** Call `skip()` only from `_export_file()` to skip the file currently being handled.
- **[MUST]** `add_file(..., remap = true)` has current-file remap semantics only when called from `_export_file()`. Bytes added with `add_file()` do not pass through the importer; use the appropriate scene/Resource customization API for imported Resource replacement.
- **[MUST]** `_get_name()` returns a stable, unique plugin name. Godot sorts export plugins by this name; when multiple plugins can affect the same artifact, define ownership and intentional order, then validate the final package.

## Customization

- **[MUST]** `_get_customization_configuration_hash()` must cover every relevant option plus a stable customization implementation/schema version that can change customized output.
- **[MUST]** Increment/change that implementation version when the customization algorithm changes so old cached output is invalidated. Do not assume editing the plugin script alone reruns customization.
- **[MUST]** Export customization should be deterministic for the same source + preset + relevant configuration + tool versions; avoid uncontrolled wall clock, RNG/UUID, unordered traversal, and machine absolute paths.
