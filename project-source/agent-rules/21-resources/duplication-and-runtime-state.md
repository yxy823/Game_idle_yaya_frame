# Resource Duplication and Runtime State

Explicitly decide aliasing and ownership when duplicating Resource graphs.

## Duplication

- **[MUST]** When using `duplicate(false)`, `duplicate(true)`, or `duplicate_deep(mode)`, explicitly decide the alias/copy boundary for the top Resource, containers, internal subresources, and external Resources. `duplicate(false)` returns a new top Resource but aliases nested Array/Dictionary/PackedArray and Resource values; `duplicate(true)` recursively copies nested containers and only duplicates local/internal Resources; `duplicate_deep(mode)` selects `DEEP_DUPLICATE_NONE`, `DEEP_DUPLICATE_INTERNAL`, or `DEEP_DUPLICATE_ALL` for subresource copying.
- **[MUST]** Deep duplication is graph-aware: when the source graph references the same Resource more than once, verify that the duplicate preserves the intended shared alias relationship rather than creating separate copies.
- **[MUST]** Do not use a universal deep-duplicate mode as a blanket 'make it safe' operation.
- **[MUST]** Where identity matters, test resulting alias/copy relationships rather than only comparing values.

## Persistent graphs

- **[PREFER]** Persistent Resource graphs are DAG-like by default. Avoid serialized child->owning-parent back-references that create cycles.
- **[PREFER]** For graph domains where cycles/relations are business data, use stable IDs plus a resolver rather than accidental serialized ownership cycles.
- **[MUST]** Runtime mutable state with ownership/lifetime separate from definition data should be modeled separately instead of mutating shared definitions.
- **[MUST]** A mutable Resource contract that promises `changed` notification must call `emit_changed()` when observable state changes.
