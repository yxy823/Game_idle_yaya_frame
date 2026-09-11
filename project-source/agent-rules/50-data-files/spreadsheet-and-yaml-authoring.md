# Spreadsheet and YAML Authoring

XLSX/YAML are authoring/tooling formats unless the project explicitly adopts them as runtime dependencies.

## XLSX

- **[MUST]** XLSX is design-time authoring by default, not a Godot runtime dependency.
- **[MUST]** Row/column/cell position is not stable entity identity.
- **[MUST]** Hidden row/column, color/font/border/style, and merged-cell presentation are not authoritative machine schema unless schema explicitly says so.
- **[MUST]** Machine-table merged cells do not imply inheritance/repetition; merged cells other than top-left may have no value in tooling.
- **[MUST]** Entity inclusion is schema-defined; physical used range and trailing blank rows are not entity semantics.
- **[MUST]** Exclude Office lock/temp files from authoring discovery.

## Formula authority

- **[MUST]** Do not assume `openpyxl` calculates formulas; cached values may be stale.
- **[PREFER]** Canonical inputs are literal authoritative values or generator-derived values; spreadsheet formulas may be authoring preview unless an explicit formula-evaluation engine/version is part of build contract.
- **[MUST]** If spreadsheet formulas are authoritative, pin recalculation engine/tool version and CI/build behavior.
- **[MUST]** External workbook links and volatile formulas (`NOW`, `TODAY`, `RAND`, etc.) must not silently drive canonical output; declare/eliminate dependencies and pass determinism checks.

## YAML

- **[MUST]** YAML is authoring/tooling by default. Direct runtime YAML requires explicit parser dependency and dialect.
- **[MUST]** Do not implement YAML with line splitting/regex.
- **[MUST]** Declare duplicate-key policy; duplicate mapping keys are errors.
- **[MUST]** Anchors/aliases/merge keys are either explicitly supported and normalized before schema validation or prohibited.
