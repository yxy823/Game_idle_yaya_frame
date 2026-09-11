# Asset Validation

```text
Source integrity
-> import metadata
-> required importer/tool
-> fresh/reimport
-> expected Godot Resource type
-> UID/path
-> representative consumer
-> target export/platform where relevant
```

- **[MUST]** Validate source presence/integrity and required importer dependency.
- **[MUST]** Validate `.import` configuration and fresh/reimport output with target Godot version.
- **[MUST]** Load expected Resource type from source `res://` path.
- **[MUST]** Validate UID/path/reference stability after move/rename.
- **[MUST]** Validate representative scene/material/audio/font consumers.
- **[MUST]** Validate target export when change affects packaging, codec, platform support, runtime raw-file availability, native libraries, or other export-specific behavior.
- **[MUST]** Clean/fresh import should reconstruct required generated artifacts.
