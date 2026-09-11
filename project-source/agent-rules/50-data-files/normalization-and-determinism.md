# Data Normalization and Determinism

Normalization canonicalizes valid equivalent inputs; it does not repair invalid semantics.

## Normalization

- **[MUST]** Missing, null, empty String, zero, and false remain distinct according to schema.
- **[MUST]** Whitespace normalization is field-specific; stable IDs with illegal surrounding whitespace are errors rather than silently trimmed identity.
- **[REVIEW]** Unicode normalization is domain-specific; do not apply blanket NFC/NFKC without semantic review.
- **[MUST]** Percentages/probabilities have one declared authoring scale and canonical scale; do not infer scale from value magnitude.
- **[MUST]** Exact decimal authoring values such as money/precise percentages use decimal/fixed semantics at build boundary before optional runtime conversion.
- **[MUST]** Rounding precision/mode/stage is explicit where it affects canonical values.
- **[MUST]** Spreadsheet display precision is not authoritative numeric precision.

## Canonical output

- **[MUST]** Canonical serialization has stable key order, indentation/format, numeric precision, newline, and encoding rules.
- **[MUST]** Sort map/object/set-like data only when schema declares it unordered; never sort semantic sequences for deterministic appearance.
- **[MUST]** Do not emit generated timestamps, machine absolute paths, uncontrolled RNG/UUID, locale-dependent numbers/dates, or hash-map-order output.
- **[MUST]** Generator randomness has an explicit seed input when randomness is part of generation.
- **[MUST]** Same declared input + schema + generator + options yields same logical output and, where intended, stable bytes.
- **[PREFER]** Use an input fingerprint (source/schema/generator/options) and semantic hash of normalized data when stale-detection value justifies it; do not confuse either with schema version.
