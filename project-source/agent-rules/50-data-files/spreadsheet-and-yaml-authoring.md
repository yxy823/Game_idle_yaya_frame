# Spreadsheet and YAML Authoring

XLSX and YAML are authoring and tooling formats unless the project explicitly adopts them as runtime dependencies.

## XLSX

- **[MUST]** XLSX is design-time authoring by default, not a Godot runtime dependency.
- **[MUST]** A row, column or cell position is not stable entity identity.
- **[MUST]** Hidden rows and columns, color, font, border and other styles, and merged-cell presentation are not authoritative machine schema unless the schema explicitly says so.
- **[MUST]** Merged cells in a machine table do not imply inheritance or repetition; tooling may read no value from merged cells other than the top-left one.
- **[MUST]** The schema defines which entities are included; the physical used range and trailing blank rows carry no entity meaning.
- **[MUST]** Exclude Office lock and temporary files from authoring discovery.

## Formula authority

- **[MUST]** Do not assume that `openpyxl` calculates formulas; cached values may be stale.
- **[PREFER]** Canonical inputs are literal authoritative values or values derived by the generator. Spreadsheet formulas may serve only as an authoring preview, unless an explicit formula-evaluation engine and version are part of the build contract.
- **[MUST]** If spreadsheet formulas are authoritative, pin the recalculation engine or tool version and the CI and build behavior.
- **[MUST]** External workbook links and volatile formulas (`NOW`, `TODAY`, `RAND` and similar) must not silently drive canonical output. Declare or eliminate those dependencies, and pass the determinism checks.

## YAML

- **[MUST]** YAML is an authoring and tooling format by default. Direct runtime YAML requires an explicit parser dependency and dialect.
- **[MUST]** Do not implement YAML parsing with line splitting or regular expressions.
- **[MUST]** Declare a duplicate-key policy; duplicate mapping keys are errors.
- **[MUST]** Anchors, aliases and merge keys are either explicitly supported and normalized before schema validation, or prohibited.
