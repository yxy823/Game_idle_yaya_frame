# Custom Importers

Custom importers are first-class, deterministic dependencies of the build and the editor.

## Importers

- **[MUST]** The version and configuration of a custom importer or plugin are part of the dependency set for rebuilding assets.
- **[MUST]** `_get_importer_name()` is the stable, unique importer ID. Do not rename it as incidental refactoring; when an identity change is intentional, migrate the affected import metadata and assets.
- **[MUST]** Increment `_get_format_version()` when the contract of the imported Resource or output changes incompatibly, then verify that existing assets are reimported correctly. Do not hand-edit generated `.import` metadata to simulate the migration.
- **[MUST]** An importer that depends on other imports defines `_get_import_order()` so that its dependencies are imported before it runs.
- **[MUST]** Add every additional generated `res://` Resource path to `gen_files`. When a generated external Resource itself requires import, call `append_import_external_resource()` only during `_import()`, and check its returned `Error`.
- **[MUST]** Return `true` from `_can_import_threaded()` only when the entire importer path, including dependencies, shared state, tools and generated outputs, is thread-safe.
- **[MUST]** Keep importer output deterministic for the same declared source, configuration and tool versions.
- **[MUST]** Validate custom importer changes with representative source roles and downstream Resource consumers, not only with importer unit logic. Fresh and batch imports also validate dependency order, registered and generated outputs, and concurrent behavior when threading is enabled.
- **[MUST]** The production export cannot secretly require an editor-only importer to run at player startup; the exported runtime consumes the built, packaged representation.
