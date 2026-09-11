# Data Schema and Types

Parser types are not business schema types.

## Fields

- **[MUST]** Each stable data domain has a schema owner defining field names, required/optional/nullability, semantic types, units, ranges, enums/domains, references, and defaults.
- **[MUST]** Missing required fields are errors. Do not use `.get(key, default)` as silent repair of required data.
- **[MUST]** Defaults apply only to schema-defined optional fields with stable semantics.
- **[MUST]** Integer fields accept mathematically integral values; do not round/tolerance-repair arbitrary floats into integers.
- **[MUST]** Reject non-finite NaN/±Inf in canonical gameplay numeric data.
- **[MUST]** Do not clamp invalid source values into ranges unless clamping is explicitly the authoring contract.

## Semantic types

- **[MUST]** Distinguish free text, stable ID, reference, enum, path, localized key, duration, timestamp, calendar date, and other String-like semantics.
- **[MUST]** Optional and nullable are distinct when missing and null have different meaning.
- **[MUST]** List and Set are distinct; Set-like duplicate elements are errors unless schema explicitly allows deduplication.
- **[MUST]** Map declares key and value semantic types. Canonical JSON map keys are explicit Strings unless represented structurally.
- **[MUST]** Use explicit discriminator fields for tagged unions; do not guess variants from object shape.
- **[MUST]** Units, scale, coordinate space, precision, rounding mode, and rounding stage are schema semantics when applicable.

## Structure choices

- **[PREFER]** CSV/XLSX are suited to scalar 2D/balance data; use child/relation tables for one-to-many; use JSON/Resource/another structured format for deep nested objects/maps/unions.
- **[MUST]** Do not encode undocumented nested mini-languages in Strings. A complex compound String is either structured data or a formal DSL with grammar/parser/AST/validation/version/tests.
- **[MUST]** Do not place JSON text inside a JSON String when the domain is actual nested JSON structure.
- **[MUST]** Do not infer behavior by parsing display/localized/free text.
