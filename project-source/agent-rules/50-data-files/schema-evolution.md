# Data Schema Evolution

Version data schemas deliberately, and migrate persisted and external compatibility boundaries explicitly.

## Versioning

- **[MUST]** `schema_version` is separate from the content revision, the game or build version and the Godot engine version.
- **[MUST]** Balance or content changes alone do not bump the schema version.
- **[MUST]** Migrate repository-controlled data in one bulk migration and keep HEAD on the current schema. Do not maintain indefinite branches for legacy formats.
- **[MUST]** Player saves, mods and other external data that require compatibility have an explicit version-support and migration policy.
- **[PREFER]** Write persistent migrations as small explicit steps from version N to N+1 rather than guessing from the data's shape.
- **[MUST]** Unsupported future schema versions fail closed.

## Migration

- **[MUST]** A persistent migration runs in memory or in a temporary file, validates the latest schema, semantics and references, and replaces the data atomically. A failure preserves the original.
- **[MUST]** Changes of unit, scale, coordinate space or reference target are semantic schema migrations.
- **[MUST]** Supported migration code is version-controlled and covered by real fixtures in earlier versions.
- **[MUST]** Adding an optional field with a stable default may be compatible. Changes to required fields, renames, types, units and reference targets normally require migration.
