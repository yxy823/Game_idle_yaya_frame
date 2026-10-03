# Ignored and Raw Files

`.gdignore`, raw FileAccess reads, Godot import visibility, Git and export are separate concerns.

## Ignored files

- **[MUST]** A directory under `.gdignore` is not imported and is not visible to normal Godot Resource loading. Do not place runtime Resources there.
- **[MUST]** Do not use `.gdignore` to hide tests that the test runner must load.
- **[MUST]** Do not add `.gdignore` merely to reduce clutter without checking runtime and import dependencies.
- **[MUST]** `.gdignore` and `.gitignore` have different semantics and do not substitute for each other.

## Raw runtime files

- **[MUST]** In exported builds, gameplay does not use directory enumeration of imported source extensions as an authoritative registry.
- **[MUST]** Raw runtime assets and data read through FileAccess follow the [export inclusion rules](../41-export-config/resources-and-filters.md#packaging).
