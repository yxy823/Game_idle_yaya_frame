# Asset Paths, UIDs, and Moves

Move, rename, duplicate and delete assets with awareness of their identity, and keep Business IDs separate from asset identity.

## Moves

- **[MUST]** Use UID-aware move and rename workflows for Resources and assets so that references can migrate.
- **[MUST]** When moving or renaming the same logical asset outside the editor, move the base file together with its `.import` or `.uid` sidecar when one exists; separating them can lose identity or import metadata.
- **[MUST]** When creating a distinct logical duplicate, do not copy the UID-bearing sidecar of the original. Prefer Godot's UID-aware duplication, so that the new asset receives a new identity through the supported workflow.
- **[MUST]** After an external move or rename, run the required filesystem refresh and import to completion, and validate the affected UID and path references and dynamic path consumers.
- **[MUST]** Distinguish a content update, a move or rename of the same asset, and a logical replacement with a new asset identity.
- **[MUST]** Do not manually set, generate or repair UID identity for moved or duplicated assets, including in response to duplicate-UID diagnostics.
- **[MUST]** Renaming a file or Resource does not automatically rename gameplay Business IDs.
- **[MUST]** Path-based dynamic consumers and raw FileAccess paths require explicit migration, because UID resolution cannot repair arbitrary Strings.

## Deletion

A report of unused assets only finds candidates; deletion permission and scope follow [Deletion and derived outputs](../00-core/change-scope-and-ownership.md#deletion-and-derived-outputs) and [Task scope](../00-core/change-scope-and-ownership.md#task-scope).

- **[MUST]** Before deleting an asset, check typed Resource references, scenes, scripts, dynamic path registries, remaps, localization, tests, mods and external contracts, and generated or source relationships, as applicable.
- **[MUST]** When deleting a source asset, also handle its metadata and generated cache through the supported import workflow; do not manually curate `.godot/imported`.
