# Reimport and Cache

Use supported reimport/refresh paths; do not edit cache internals.

## Reimport

- **[MUST]** Use `reimport_files()`/targeted reimport when an existing source asset or its `.import` metadata was changed externally.
- **[MUST]** A newly created file or changed file type must first enter `EditorFileSystem` through `update_file()` or `scan()`. `update_file()` does not import the file; follow it with the required targeted reimport or scan/import path.
- **[MUST]** Do not start `reimport_files()` or another `scan()` while import/scan work is already in progress. Wait for the relevant filesystem/import completion state or signals before dependent reload and validation.
- **[MUST]** Importer/default changes explicitly reimport affected source set; changing defaults alone does not migrate existing imported artifacts.
- **[MUST]** Do not directly edit cache hashes, imported textures, generated internal Resources, or other `.godot/imported` artifacts.
- **[REVIEW]** Deleting/rebuilding cache is a diagnostic operation with scope/impact, not a default first response to any stale-looking asset.
