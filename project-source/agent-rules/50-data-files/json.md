# JSON Rules

Godot's JSON parser is useful but not a strict standards validator; preserve exact identity and reject information-losing ambiguities.

## Parsing

- **[MUST]** Parse success does not mean schema/business validity.
- **[MUST]** Production/canonical loaders use `JSON.parse()` and check the returned `Error` before consuming parsed data.
- **[MUST]** Do not use `result == null` as a general parse-failure test: valid JSON `null` and a failed `JSON.parse_string()` both produce null. Use `parse_string()` only for simple convenience paths where diagnostics are unimportant and the root schema explicitly excludes null.
- **[MUST]** Authoritative/canonical JSON passes a strict standards-compatible validation over the original source before Godot parsing; `JSON.parse()` alone is not strict validation.
- **[MUST]** That strict pass rejects duplicate object keys before Dictionary conversion and rejects non-standard forms such as trailing commas, lax number grammar, illegal String controls, or invalid Unicode instead of accepting or cleaning them.
- **[MUST]** A project that deliberately accepts Godot's relaxed JSON dialect declares that format and trust/interoperability boundary explicitly; do not mix it with or label it canonical interoperable JSON.

## Numbers and keys

- **[MUST]** Godot JSON numbers are double-based. Exact integral identity beyond IEEE-754 safe consecutive integer range (about ±2^53) must not use JSON number; encode as decimal String or another exact format.
- **[MUST]** Canonical JSON Map keys have explicit String-key schema because JSON serialization stringifies Dictionary keys.
- **[MUST]** Do not use non-finite numeric values in canonical gameplay JSON.

## Canonical writing

- **[MUST]** A canonical writer using `JSON.stringify()` explicitly defines key ordering, `indent`, output newline policy, and numeric precision, including the `sort_keys` and `full_precision` arguments; do not rely on writer defaults.
- **[MUST]** Float data requiring exact round-trip decoding uses `full_precision = true`. Data with schema-defined quantization is rounded at the declared stage and emitted according to that quantization policy.
- **[MUST]** Reject NaN/±Inf before `JSON.stringify()`; do not rely on Godot replacing infinity with `1e99999` or NaN with null.

## Trust

- **[MUST]** `JSON.from_native()`/`JSON.to_native()` is an engine-specific encoding contract, not an implicit substitute for a cross-system canonical JSON schema.
- **[MUST]** When Godot-native conversion is intentional, define and version the encoded Variant/type subset and Godot compatibility boundary explicitly.
- **[MUST]** Untrusted JSON is data-only by default. Do not enable arbitrary object reconstruction (`to_native(... allow_objects=true)` or equivalent) for untrusted data.
- **[MUST]** External fields such as `class_name`, script/scene/resource paths, method/command names do not directly drive arbitrary loading/instantiation/code execution. Resolve validated stable IDs/enums through a project-owned allowlist/registry.
