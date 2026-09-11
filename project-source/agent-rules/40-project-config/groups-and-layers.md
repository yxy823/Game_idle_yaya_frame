# Groups and Layers

Treat group names and layer indices as stable behavior namespaces.

## Groups

- **[MUST]** Global Group declarations and scene group membership share the same runtime group namespace.
- **[MUST]** Custom group names use stable `snake_case` semantics once consumed.
- **[MUST]** A Global Group declaration does not add Node membership.
- **[MUST]** Do not rely on group iteration order without imposing deterministic ordering yourself.

## Layers

- **[MUST]** Respect Godot layer counts: Physics/Navigation and rendering visibility have different supported layer domains.
- **[MUST]** Distinguish renaming a layer from repurposing/moving its bit. Do not reorder layers for aesthetics.
- **[MUST]** Migrate `collision_layer` and `collision_mask` semantics separately; they are not interchangeable.
- **[MUST]** Do not scatter unexplained magic layer numbers; use project-owned named constants/configuration where code needs stable layer semantics.
- **[MUST]** Physics, navigation, and render/visibility layer namespaces are independent even if they reuse same numeric bit.
- **[MUST]** Clearing a layer display name does not prove that its bit is unused.
