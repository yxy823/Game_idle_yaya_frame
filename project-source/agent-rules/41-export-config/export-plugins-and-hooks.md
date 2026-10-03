# Export Plugins and Hooks

An `EditorExportPlugin` is build-pipeline code that can change the final packaged content.

## Scope

- **[MUST]** Treat `EditorExportPlugin` changes as build-pipeline changes, in addition to GDScript and editor-plugin changes.
- **[MUST]** Changes to file inclusion, skipping or remapping, scene or Resource customization, native library packaging or export features require an actual export gate.
- **[MUST]** Do not decide production inclusion with ambiguous substring heuristics such as `path.contains('test')`. Use explicit project-owned contracts for paths and roles.

## Execution contract

- **[MUST]** Call `skip()` only from `_export_file()`, to skip the file currently being handled.
- **[MUST]** `add_file(..., remap = true)` remaps the current file only when it is called from `_export_file()`. Bytes added with `add_file()` do not pass through the importer; use the appropriate scene or Resource customization API to replace an imported Resource.
- **[MUST]** `_get_name()` returns a stable, unique plugin name. Godot sorts export plugins by this name. When several plugins can affect the same artifact, define their ownership and intended order, then validate the final package.

## Customization

- **[MUST]** `_get_customization_configuration_hash()` covers every relevant option, plus a stable version of the customization implementation or schema that can change the customized output.
- **[MUST]** Change that implementation version when the customization algorithm changes, so that previously cached output is invalidated. Do not assume that editing the plugin script alone reruns customization.
- **[MUST]** Make export customization deterministic for the same source, preset, relevant configuration and tool versions. Avoid an uncontrolled wall clock, RNG or UUID values, unordered traversal and absolute machine paths.
