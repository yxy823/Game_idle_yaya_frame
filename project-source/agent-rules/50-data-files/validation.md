# Data Validation

```text
Source Discovery/Integrity
-> Syntax/Format
-> Schema/Structure
-> Field Type/Value
-> Identity/Reference
-> Graph/Domain Semantics
-> Normalization
-> Canonical Generation
-> Determinism/Staleness
-> Canonical Reload
-> Godot Runtime Integration
-> Target/Export Validation
```

- **[MUST]** Lower-layer PASS never proves a higher layer.
- **[MUST]** Production data is committed to gameplay only after all required validation layers succeed.
- **[MUST]** Unknown production fields fail unless an explicit extension schema allows them.
- **[MUST]** Validate IDs, aliases, required/optional references, cycle policy, cross-record invariants, units, ranges, enum domains, and non-finite numbers.
- **[MUST]** Canonical output is reloaded through production parser/schema, not only validated in pre-serialization in-memory model.
- **[MUST]** Generator changes run repeat determinism and stale-output checks.
- **[MUST]** Runtime integration uses target Godot and a representative typed consumer.
- **[MUST]** Raw runtime files validate actual export packaging.
- **[MUST]** Migration changes run real old-version fixtures through newest full validation stack.
- **[MUST]** Error/Warning severity is centrally owned; Agent does not downgrade an Error to make validation green.
