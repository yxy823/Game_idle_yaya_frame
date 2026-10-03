# Data Identity and References

Business identity is stable schema data and is distinct from Godot, resource and runtime identity.

## IDs

- **[MUST]** A Business ID is not a Resource UID, RID, Object instance ID, filesystem path, row number, cell position or display name.
- **[MUST]** Canonical IDs satisfy their grammar directly. Do not silently trim, lowercase or repair invalid identifiers into a different ID.
- **[MUST]** Once an ID is referenced or persisted, it is frozen unless an explicit migration occurs.
- **[MUST]** Do not reuse a published or persisted ID for a different entity.
- **[MUST]** Renaming an ID is a migration across all references and persisted compatibility boundaries.
- **[MUST]** Legacy aliases live at migration and compatibility boundaries; the canonical runtime exposes the current ID. Do not allow alias cycles, ambiguity or chains.

## References

- **[MUST]** A reference declares its target namespace or type, and whether it is required or optional.
- **[MUST]** `optional` means that the field may be absent or null when its schema permits; it does not make a present non-null ID optional to resolve.
- **[MUST]** By default, every present non-null reference resolves successfully and satisfies its relation invariants. A dangling required or optional reference is an error. Do not silently replace it with null or a default, fuzzy-match it or choose the closest entity.
- **[MUST]** An unresolved reference is allowed only when the schema explicitly defines soft, external or late-bound semantics, together with its resolver and lifecycle validation policy.
- **[MUST]** Existence is not enough: validate relation invariants such as the same tree or category, no self-reference and level constraints.
- **[MUST]** Resolve static references centrally before gameplay, unless the architecture requires a dynamic resolver.
- **[MUST]** Graph schemas declare a cycle policy and validate cycles before runtime.
- **[MUST]** Collection order is semantic only when the schema says so; runtime code must not accidentally depend on the row order of the authoring source.
- **[MUST]** Persisted enum identity is a stable explicit identity. Symbolic String IDs are generally preferable when the domain benefits from readability or extensibility.
