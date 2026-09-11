# Import Metadata

Treat `.import` as tool-managed configuration with generated identity/remap fields.

## Metadata

- **[MUST]** Do not manually repair generated UID/path/dest/source/importer-version metadata inside `.import`.
- **[MUST]** Change real import configuration through supported Godot import/editor/tooling workflows and validate reimport.
- **[MUST]** When duplicating a logical source asset into a distinct new asset, do not copy the old asset's identity metadata as if it were same Resource.
- **[MUST]** Do not treat a source-file move/rename as content replacement; preserve identity through a UID-aware move workflow where possible.
