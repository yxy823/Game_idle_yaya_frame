# Data Validation

```text
Source Discovery and Integrity
-> Syntax and Format
-> Schema and Structure
-> Field Type and Value
-> Identity and Reference
-> Graph and Domain Semantics
-> Normalization
-> Canonical Generation
-> Determinism and Staleness
-> Canonical Reload
-> Godot Runtime Integration
-> Target and Export Validation
```

- **[MUST]** A PASS at a lower layer never proves a higher layer.
- **[MUST]** Production data reaches gameplay only after all required validation layers succeed.
- **[MUST]** Unknown production fields fail unless an explicit extension schema allows them.
- **[MUST]** Validate IDs, aliases, required and optional references, the cycle policy, cross-record invariants, units, ranges, enum domains and non-finite numbers.
- **[MUST]** Reload canonical output through the production parser and schema; validating only the in-memory model before serialization is not enough.
- **[MUST]** Validate runtime integration with the target Godot and a representative typed consumer.
- **[MUST]** For raw runtime files, validate their availability in the actual exported build or PCK and the production loading and consumer behavior.
- **[MUST]** For migration changes, run real fixtures from earlier versions through the complete current validation stack.

Generator determinism and severity handling are defined in `generation-and-derived-data.md` and `data-lifecycle-and-authority.md`.
