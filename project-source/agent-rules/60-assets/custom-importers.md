# Custom Importers

Custom importers are first-class deterministic build/editor dependencies.

## Importers

- **[MUST]** A custom importer/plugin version/configuration is part of the asset rebuild dependency set.
- **[MUST]** `_get_importer_name()` is the stable, unique importer ID. Do not rename it as incidental refactoring; migrate affected import metadata and assets when an identity change is intentional.
- **[MUST]** Increment `_get_format_version()` when the imported Resource/output contract changes incompatibly, then verify existing assets are reimported correctly. Do not hand-edit generated `.import` metadata to simulate the migration.
- **[MUST]** A dependency-sensitive importer defines `_get_import_order()` so its dependencies are imported before it runs.
- **[MUST]** Add every additional generated `res://` Resource path to `gen_files`. When a generated external Resource itself requires import, call `append_import_external_resource()` only during `_import()` and check its returned `Error`.
- **[MUST]** Return `true` from `_can_import_threaded()` only when the entire importer path, including dependencies, shared state, tools, and generated outputs, is thread-safe.
- **[MUST]** Importer output should be deterministic for the same declared source/config/tool versions.
- **[MUST]** Custom importer changes validate representative source roles and downstream Resource consumers, not only importer unit logic. Fresh and batch import also validate dependency order, registered/generated outputs, and concurrency behavior when threading is enabled.
- **[MUST]** Production export cannot secretly require an editor-only importer to run at player startup; exported runtime consumes built/package representation.
