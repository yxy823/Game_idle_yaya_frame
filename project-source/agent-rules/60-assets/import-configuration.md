# Import Configuration

Import metadata, import types and import settings define the Resource API that consumers see. Treat `.import` files as tool-managed configuration that also contains generated identity and remap fields.

## Metadata

- **[MUST]** Change real import configuration through supported Godot import, editor or tooling workflows, and validate the reimport.
- **[MUST]** The generated UID, path, destination, source and importer-version fields in `.import` are not repaired by hand; see [Generated and tool-managed files](../00-core/third-party-generated-and-temporary-files.md#generated-and-tool-managed).
- **[MUST]** Moving, renaming or duplicating a source asset follows [Asset paths, UIDs, and moves](paths-uid-and-moves.md); a move or rename is not a content replacement.

## Import type and settings

- **[MUST]** Changing the importer or import type changes the Resource API that consumers see, and requires validation with representative consumers.
- **[MUST]** Changing the import mode, including Keep File and Skip File, changes export and runtime availability.
- **[MUST]** Do not apply one import preset to all assets merely because they share an extension; classify them by runtime role.
- **[MUST]** Review automatic import decisions such as Detect 3D, which alter mipmap and compression behavior, for textures shared by 2D and 3D paths.
- **[MUST]** When Detect 3D automatically changes mipmap or compression settings and reimports a texture, investigate the resulting `.import` diff and the affected consumers before keeping or reverting it. Do not discard it as unexplained generated noise.

## Reimport and cache

- **[MUST]** Use `reimport_files()` or another targeted reimport when an existing source asset or its `.import` metadata was changed externally.
- **[MUST]** A newly created file, or a file whose type changed, first enters `EditorFileSystem` through `update_file()` or `scan()`. `update_file()` does not import the file; follow it with the required targeted reimport or the scan and import path.
- **[MUST]** Do not start `reimport_files()` or another `scan()` while import or scan work is already in progress. Wait for the relevant filesystem or import completion state or signals before a dependent reload and validation.
- **[MUST]** Changing importer defaults does not migrate assets that are already imported; follow [Project import defaults](../40-project-config/import-defaults.md) for migrating them.
- **[MUST]** Do not directly edit cache hashes, imported textures, generated internal Resources or other `.godot/imported` artifacts.
- **[REVIEW]** Deleting and rebuilding the cache is a diagnostic operation with a scope and an impact; it is not the default first response to an asset that looks stale.
