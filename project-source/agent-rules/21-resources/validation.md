# Resource Validation

- **[MUST]** Parse/load with target Godot 4.7.
- **[MUST]** Validate Resource UID/path and expected Resource/custom type.
- **[MUST]** Validate exported values, required fields, invariants, and dependency compatibility.
- **[MUST]** For duplication/local-to-scene changes, validate identity/alias relationships, not only value equality.
- **[MUST]** For generated/saved Resources, run save -> reload through production loader and revalidate values/dependencies/invariants.
- **[MUST]** For class/property/default/schema changes, validate all affected repository Resources and representative consumers.
- **[MUST]** When editor cache may hide external changes, include refresh or a fresh target Godot process.
