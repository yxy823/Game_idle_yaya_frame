# Data Identity and References

Business identity is stable schema data and is distinct from Godot/resource/runtime identity.

## IDs

- **[MUST]** Business ID is not Resource UID, RID, Object instance ID, filesystem path, row number, cell position, or display name.
- **[MUST]** Canonical IDs satisfy their grammar directly. Do not silently trim/lowercase/repair invalid identifiers into a different ID.
- **[MUST]** Once referenced/persisted, an ID is frozen unless an explicit migration occurs.
- **[MUST]** Do not reuse a published/persisted ID for a different entity.
- **[MUST]** ID rename is a migration across all references and persisted compatibility boundaries.
- **[MUST]** Legacy aliases live at migration/compatibility boundaries; canonical runtime exposes current ID. Do not allow alias cycles/ambiguity/chains.

## References

- **[MUST]** A reference declares target namespace/type and whether it is required/optional.
- **[MUST]** `optional` means the field may be absent or null when its schema permits; it does not make a present non-null ID optional to resolve.
- **[MUST]** Every present non-null reference resolves successfully and satisfies its relation invariants by default. A dangling required or optional reference is an error; do not silently replace it with null/default, fuzzy-match it, or choose the closest entity.
- **[MUST]** An unresolved reference is allowed only when the schema explicitly defines soft/external/late-bound semantics together with its resolver and lifecycle validation policy.
- **[MUST]** Existence is not enough: validate relation invariants such as same tree/category/no-self/level constraints.
- **[MUST]** Resolve static references centrally before gameplay when architecture does not require a dynamic resolver.
- **[MUST]** Graph schemas declare cycle policy and validate cycles before runtime.
- **[MUST]** Collection order is semantic only when schema says so; runtime must not accidentally depend on authoring row order.
- **[MUST]** Persisted enum identity is stable explicit identity; symbolic String IDs are generally preferable when domain benefits from readability/extensibility.
