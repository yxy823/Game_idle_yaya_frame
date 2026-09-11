# Asset Paths, UIDs, and Moves

Move/rename with identity awareness and keep Business IDs separate from asset identity.

## Moves

- **[MUST]** Use UID-aware move/rename workflows for Resources/assets so references can migrate.
- **[MUST]** When externally moving/renaming the same logical asset, move the base file together with its corresponding `.import` or `.uid` sidecar when present; separating them can lose identity/import metadata.
- **[MUST]** When creating a distinct logical duplicate, do not copy the old UID-bearing sidecar. Prefer Godot's UID-aware duplication so the new asset receives new identity through the supported workflow.
- **[MUST]** After an external move/rename, run the required filesystem refresh/import to completion and validate affected UID/path references and dynamic path consumers.
- **[MUST]** Distinguish content update, move/rename of same asset, and logical replacement with a new asset identity.
- **[MUST]** Do not manually set, generate, or repair UID identity for moved or duplicated assets, including as a response to duplicate-UID diagnostics.
- **[MUST]** File/Resource rename does not automatically rename gameplay Business IDs.
- **[MUST]** Dynamic path-based consumers and raw FileAccess paths require explicit migration because UID resolution cannot repair arbitrary Strings.
