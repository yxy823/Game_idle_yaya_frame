# JSON Rules

Godot's JSON parser is useful but is not a strict standards validator. Preserve exact identity and reject ambiguities that lose information.

## Parsing

- **[MUST]** A successful parse does not mean that the data is valid against the schema or business rules.
- **[MUST]** Production and canonical loaders use `JSON.parse()` and check the returned `Error` before consuming the parsed data.
- **[MUST]** Do not use `result == null` as a general parse-failure test: valid JSON `null` and a failed `JSON.parse_string()` both produce null. Use `parse_string()` only for simple convenience paths where diagnostics are unimportant and the root schema explicitly excludes null.
- **[MUST]** Authoritative and canonical JSON passes a strict, standards-compatible validation of the original source before Godot parses it; `JSON.parse()` alone is not strict validation.
- **[MUST]** That strict pass rejects duplicate object keys before Dictionary conversion. It also rejects non-standard forms such as trailing commas, lax number grammar, illegal control characters in Strings and invalid Unicode, instead of accepting or cleaning them.
- **[MUST]** A project that deliberately accepts Godot's relaxed JSON dialect declares that format and its trust and interoperability boundary explicitly. Do not mix that dialect with canonical interoperable JSON or label it as such.

## Numbers and keys

- **[MUST]** Godot JSON numbers are doubles. Exact integer identity beyond the IEEE-754 range of safe consecutive integers (about ±2^53) must not use a JSON number; encode it as a decimal String or another exact format.
- **[MUST]** Canonical JSON maps have an explicit String-key schema, because JSON serialization turns Dictionary keys into Strings.
- **[MUST]** Do not use non-finite numeric values in canonical gameplay JSON.

## Canonical writing

- **[MUST]** A canonical writer that uses `JSON.stringify()` explicitly defines key ordering, `indent`, the output newline policy and numeric precision, including the `sort_keys` and `full_precision` arguments. Do not rely on writer defaults.
- **[MUST]** Float data that requires exact round-trip decoding uses `full_precision = true`. Data with schema-defined quantization is rounded at the declared stage and written according to that quantization policy.
- **[MUST]** Reject NaN and ±Inf before `JSON.stringify()`. Do not rely on Godot replacing infinity with `1e99999` or NaN with null.

## Trust

- **[MUST]** `JSON.from_native()` and `JSON.to_native()` are an engine-specific encoding contract, not an implicit substitute for a canonical JSON schema shared across systems.
- **[MUST]** When Godot-native conversion is intentional, explicitly define and version the encoded subset of Variant types and the Godot compatibility boundary.
- **[MUST]** Untrusted JSON is data-only by default. Do not enable arbitrary object reconstruction (`to_native(... allow_objects=true)` or an equivalent) for untrusted data.
- **[MUST]** External fields such as `class_name`, script, scene or resource paths, and method or command names do not directly drive arbitrary loading, instantiation or code execution. Resolve validated stable IDs or enums through a project-owned allowlist or registry.
