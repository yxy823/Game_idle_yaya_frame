# Data Normalization and Determinism

Normalization canonicalizes valid equivalent inputs; it does not repair invalid semantics.

## Normalization

- **[MUST]** Missing, null, an empty String, zero and false remain distinct according to the schema.
- **[MUST]** Whitespace normalization is specific to each field. Stable IDs with illegal surrounding whitespace are errors rather than silently trimmed identities.
- **[REVIEW]** Unicode normalization is domain-specific; do not apply blanket NFC or NFKC without a semantic review.
- **[MUST]** Percentages and probabilities have one declared authoring scale and one canonical scale; do not infer the scale from the magnitude of a value.
- **[MUST]** Exact decimal authoring values, such as money or precise percentages, use decimal or fixed-point semantics at the build boundary before any optional runtime conversion.
- **[MUST]** Make the rounding precision, mode and stage explicit where they affect canonical values.
- **[MUST]** The display precision of a spreadsheet is not the authoritative numeric precision.

## Canonical output

- **[MUST]** Canonical serialization has stable rules for key order, indentation and format, numeric precision, newlines and encoding.
- **[MUST]** Sort map, object or set-like data only when the schema declares it unordered. Never sort semantic sequences for a deterministic appearance.
- **[MUST]** Do not emit generated timestamps, absolute machine paths, uncontrolled RNG or UUID values, locale-dependent numbers or dates, or output in hash-map order.
- **[MUST]** When randomness is part of generation, the generator takes an explicit seed as input.
- **[MUST]** The same declared input, schema, generator and options yield the same logical output and, where intended, stable bytes.
- **[PREFER]** Use an input fingerprint (of source, schema, generator and options) and a semantic hash of the normalized data when the value of detecting stale output justifies them. Do not confuse either with a schema version.
