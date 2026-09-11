# Resource Schema, Migration, and Serialization

Treat exported Resource properties and defaults as persisted schema.

## Schema

- **[MUST]** For repository-controlled `.tres`, prefer one-time bulk migration and keep HEAD on the current schema instead of maintaining indefinite legacy branching.
- **[REVIEW]** Player/mod/external persisted Resources may require explicit schema versioning and migrations.
- **[MUST]** Differentiate optional fields with stable defaults from required fields. Missing required data is not silently repaired.
- **[MUST]** Changing an exported default is a behavior/schema change because older serialized Resources may omit that field and inherit the new default.
- **[MUST]** Property rename/remove/type changes and `class_name`/script/base-type changes require Resource migration/validation.
- **[MUST]** Validate domain invariants beyond successful deserialization.

## Construction and migration

- **[MUST]** Do not hide serialized migration inside `_init()` side effects.
- **[MUST]** Persistable custom Resource classes should use a file-level script, not an inner class.
- **[MUST]** A custom Resource that is persisted, created or edited in the Inspector, loaded through `ResourceLoader`, or duplicated/local-to-scene must have a serialization-safe `_init()`: every parameter has a default value, or the class defines no required constructor arguments.
- **[MUST]** Enforce business-required invariants through a factory, validator, explicit initialization, or domain invariant check after construction rather than required `_init()` arguments in these serialization paths.
- **[MUST]** Persistent migration failures preserve the original artifact; migrate in memory/temp, validate, then replace atomically.
