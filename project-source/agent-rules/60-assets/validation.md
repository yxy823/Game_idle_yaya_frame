# Asset Validation

```text
Source integrity
-> import metadata
-> required importer or tool
-> fresh import or reimport
-> expected Godot Resource type
-> UID and path
-> representative consumer
-> target export or platform where relevant
```

- **[MUST]** Validate the presence and integrity of the source and the required importer dependency.
- **[MUST]** Validate the `.import` configuration and the output of a fresh import or reimport with the target Godot version.
- **[MUST]** Load the expected Resource type from the source `res://` path.
- **[MUST]** Validate representative scene, material, audio and font consumers.
- **[MUST]** Validate the target export when the change affects packaging, codecs, platform support, runtime availability of raw files, native libraries or other export-specific behavior.

Reference checks after moves and clean rebuilds are defined in `paths-uid-and-moves.md` and `source-and-derived-assets.md`.
