# 50 Data File Rules

Applies to design/runtime data such as JSON, CSV, XLSX, YAML, generated canonical
data, schemas, migrations, and data validators.

Canonical lifecycle:

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

Read:

- `csv.md`
- `data-lifecycle-and-authority.md`
- `generation-and-derived-data.md`
- `identity-and-references.md`
- `json.md`
- `normalization-and-determinism.md`
- `runtime-loading-and-packaging.md`
- `schema-and-types.md`
- `schema-evolution.md`
- `spreadsheet-and-yaml-authoring.md`
- `validation.md` (always applies)

Read the concrete documents that match the affected data format or lifecycle; `validation.md` always applies.
