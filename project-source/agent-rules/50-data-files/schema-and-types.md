# Data Schema and Types

Parser types are not business schema types.

## Fields

- **[MUST]** Each stable data domain has a schema owner that defines field names, whether each field is required, optional or nullable, semantic types, units, ranges, enums and domains, references and defaults.
- **[MUST]** Missing required fields are errors. Do not use `.get(key, default)` to silently repair required data.
- **[MUST]** Defaults apply only to schema-defined optional fields with stable semantics.
- **[MUST]** Integer fields accept mathematically integral values. Do not round arbitrary floats into integers or repair them with a tolerance.
- **[MUST]** Reject non-finite values (NaN and ±Inf) in canonical gameplay numeric data.
- **[MUST]** Do not clamp invalid source values into ranges unless clamping is explicitly the authoring contract.

## Semantic types

- **[MUST]** Distinguish free text, stable IDs, references, enums, paths, localization keys, durations, timestamps, calendar dates and other String-like semantics.
- **[MUST]** Optional and nullable are distinct when missing and null have different meanings.
- **[MUST]** Lists and Sets are distinct. Duplicate elements in a Set-like field are errors unless the schema explicitly allows deduplication.
- **[MUST]** A Map declares the semantic types of its keys and values. Canonical JSON map keys are explicit Strings unless the map is represented structurally.
- **[MUST]** Use explicit discriminator fields for tagged unions; do not guess variants from the shape of an object.
- **[MUST]** Units, scale, coordinate space, precision, rounding mode and rounding stage are schema semantics when they apply.

## Structure choices

- **[PREFER]** CSV and XLSX suit scalar two-dimensional and balance data. Use child or relation tables for one-to-many data, and JSON, Resources or another structured format for deeply nested objects, maps or unions.
- **[MUST]** Do not encode undocumented nested mini-languages in Strings. A complex compound String is either structured data or a formal DSL with a grammar, parser, AST, validation, version and tests.
- **[MUST]** Do not place JSON text inside a JSON String when the domain is an actual nested JSON structure.
- **[MUST]** Do not infer behavior by parsing display, localized or free text.
