# Resource Duplication and Runtime State

Explicitly decide aliasing and ownership when duplicating Resource graphs.

## Duplication

- **[MUST]** When using `duplicate(false)`, `duplicate(true)` or `duplicate_deep(mode)`, explicitly decide the alias and copy boundary for the top Resource, containers, internal subresources and external Resources:
  - `duplicate(false)` returns a new top Resource but aliases nested Array, Dictionary, PackedArray and Resource values;
  - `duplicate(true)` recursively copies nested containers and duplicates only local (internal) Resources;
  - `duplicate_deep(mode)` selects `DEEP_DUPLICATE_NONE`, `DEEP_DUPLICATE_INTERNAL` or `DEEP_DUPLICATE_ALL` for subresource copying.
- **[MUST]** Deep duplication is graph-aware. When the source graph references the same Resource more than once, verify that the duplicate preserves the intended shared alias instead of creating separate copies.
- **[MUST]** Do not use a universal deep-duplicate mode as a blanket "make it safe" operation.
- **[MUST]** Where identity matters, test the resulting alias and copy relationships rather than only comparing values.

## Persistent graphs

- **[PREFER]** Keep persistent Resource graphs DAG-like by default. Avoid serialized back-references from a child to its owning parent that create cycles.
- **[PREFER]** For graph domains where cycles or relations are business data, use stable IDs plus a resolver rather than accidental serialized ownership cycles.
- **[MUST]** Model runtime mutable state whose ownership or lifetime differs from the definition data separately, instead of mutating shared definitions.
- **[MUST]** A mutable Resource contract that promises `changed` notification calls `emit_changed()` when observable state changes.
