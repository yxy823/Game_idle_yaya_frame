# Ignored and Raw Files

`.gdignore`, raw FileAccess, Godot import visibility, Git, and export are separate concerns.

## Ignored files

- **[MUST]** A directory under `.gdignore` is not imported/visible to normal Godot Resource loading. Do not place runtime Resources there.
- **[MUST]** Do not use `.gdignore` to hide tests that the test runner must load.
- **[MUST]** Do not add `.gdignore` merely to suppress clutter without checking runtime/import dependencies.
- **[MUST]** `.gdignore` and `.gitignore` have different semantics and are not substitutes.

## Raw runtime files

- **[MUST]** Gameplay must not rely on directory enumeration of imported source extensions as authoritative catalog in exported builds.
- **[MUST]** Raw FileAccess runtime assets/data follow `41-export-config` packaging rules.
