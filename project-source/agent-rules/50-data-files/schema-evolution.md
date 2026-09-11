# Data Schema Evolution

Version data schema deliberately and migrate persisted/external compatibility boundaries explicitly.

## Versioning

- **[MUST]** `schema_version` is separate from content revision, game/build version, and Godot engine version.
- **[MUST]** Balance/content changes alone do not bump schema version.
- **[PREFER]** Repository-controlled data uses one-time bulk migration and keeps HEAD on current schema.
- **[MUST]** Player saves/mods/external data that require compatibility have explicit version support/migration policy.
- **[PREFER]** Persistent migrations are small explicit N->N+1 steps rather than shape guessing.
- **[MUST]** Unsupported future schema versions fail closed.

## Migration

- **[MUST]** Persistent migration runs in memory/temp, validates latest schema/semantics/references, and replaces atomically; failure preserves original.
- **[MUST]** Unit/scale/coordinate-space/reference-target changes are semantic schema migrations.
- **[MUST]** Supported migration code is version-controlled and covered by real old-version fixtures.
- **[MUST]** Optional fields with stable default may be compatible; required-field, rename, type, unit, and reference-target changes normally require migration.
