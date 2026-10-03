# Resource Schema, Migration, and Serialization

Treat exported Resource properties and their defaults as a persisted schema.

## Schema

- **[MUST]** Migrate repository-controlled `.tres` files in one bulk migration and keep HEAD on the current schema. Do not maintain indefinite branches for legacy formats.
- **[REVIEW]** Player, mod and other external persisted Resources may require explicit schema versioning and migrations.
- **[MUST]** Differentiate optional fields with stable defaults from required fields. Missing required data is not silently repaired.
- **[MUST]** Changing an exported default is a behavior and schema change, because previously serialized Resources may omit that field and inherit the new default.
- **[MUST]** Renaming, removing or retyping a property, and changing the `class_name`, script or base type, require Resource migration and validation.
- **[MUST]** Validate domain invariants beyond successful deserialization.

## Construction and migration

- **[MUST]** Do not hide serialized migration inside `_init()` side effects.
- **[MUST]** Define persistable custom Resource classes in a file-level script, not in an inner class.
- **[MUST]** A custom Resource that is persisted, created or edited in the Inspector, loaded through `ResourceLoader`, duplicated or made local to a scene has a serialization-safe `_init()`: every parameter has a default value, or the class defines no required constructor arguments.
- **[MUST]** In these serialization paths, enforce business-required invariants through a factory, a validator, explicit initialization or a domain invariant check after construction, rather than through required `_init()` arguments.
- **[MUST]** A failed persistent migration preserves the original artifact. Migrate in memory or in a temporary file, validate, then replace atomically.
