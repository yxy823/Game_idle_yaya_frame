# Data Lifecycle and Authority

Keep authoring, parsing, validation, canonicalization, and gameplay consumption separated.

## Authority

- **[MUST]** Every data domain declares its authoritative authoring source and one canonical runtime representation.
- **[MUST]** Gameplay consumes validated canonical configuration, not raw parser Dictionary/Array/Variant output.
- **[MUST]** Definition/config data is runtime read-only by default.
- **[MUST]** Raw Dictionary/Array/Variant remains at parsing, migration, extension, or genuinely dynamic boundaries; stable runtime schemas use typed models.
- **[MUST]** Gameplay/runtime does not write design authoring sources such as XLSX/YAML/CSV back as state.

## Errors

- **[MUST]** Distinguish syntax, schema/type, semantic, and reference failures.
- **[MUST]** Production data validation fails closed on Critical/Error; Agent does not downgrade Error to Warning to obtain green status.
- **[MUST]** Diagnostics identify source file and, where available, sheet/row/entity/field/value/constraint/reference target.
