# Data Lifecycle and Authority

Keep authoring, parsing, validation, canonicalization and gameplay consumption separate.

## Canonical lifecycle

```text
Authoring Source
-> Parse
-> Structural Schema Validation
-> Semantic Validation
-> Reference Resolution
-> Normalization
-> Canonical Runtime Configuration
-> Freeze
-> Gameplay Read-only Consumption
```

External data does not go directly from parser output into gameplay.

## Authority

- **[MUST]** Every data domain declares its authoritative authoring source and one canonical runtime representation.
- **[MUST]** Gameplay consumes validated canonical configuration, not raw Dictionary, Array or Variant output from a parser.
- **[MUST]** Definition and configuration data is read-only at runtime by default.
- **[MUST]** Raw Dictionary, Array and Variant values stay at parsing, migration, extension or genuinely dynamic boundaries; stable runtime schemas use typed models.
- **[MUST]** Gameplay and runtime code do not write state back into design authoring sources such as XLSX, YAML or CSV files.

## Errors

- **[MUST]** Distinguish syntax, schema or type, semantic and reference failures.
- **[MUST]** Production data validation fails closed on Critical and Error results. The Agent does not downgrade an Error to a Warning to obtain a green status.
- **[MUST]** Diagnostics identify the source file and, where available, the sheet, row, entity, field, value, constraint and reference target.

## Runtime loading and packaging

Editor visibility does not prove that raw runtime data is inside the exported package.

- **[MUST]** Raw `res://` JSON, CSV or TXT files loaded through FileAccess follow the [export inclusion rules](../41-export-config/resources-and-filters.md#packaging).
- **[PREFER]** When appropriate, convert canonical data to a `.tres`, custom Resource or binary format and load it through ResourceLoader instead of maintaining a raw-file runtime path.
- **[MUST]** Raw data embedded in the project and external `user://` or mod data are separate trust and packaging domains.

## Trust boundary

- **[MUST]** Trusted data authored by the project and untrusted player, mod, network or other external data have separate trust policies.
- **[MUST]** Untrusted data has explicit size, depth, shape and schema constraints where denial of service or pathological input is plausible.
