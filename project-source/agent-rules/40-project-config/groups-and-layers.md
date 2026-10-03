# Groups and Layers

Treat group names and layer indices as stable behavior namespaces.

## Groups

- **[MUST]** Global Group declarations and scene group membership share the same runtime group namespace.
- **[MUST]** Custom group names use stable `snake_case` once they are consumed.
- **[MUST]** A Global Group declaration does not add any Node to the group.
- **[MUST]** Do not rely on group iteration order unless you impose a deterministic order yourself.

## Layers

- **[MUST]** Respect the layer counts that Godot supports: physics and navigation layers and rendering visibility layers have different supported domains.
- **[MUST]** Distinguish renaming a layer from repurposing or moving its bit. Do not reorder layers for aesthetics.
- **[MUST]** Migrate `collision_layer` and `collision_mask` semantics separately; they are not interchangeable.
- **[MUST]** Do not scatter unexplained magic layer numbers. Use project-owned named constants or configuration where code needs stable layer semantics.
- **[MUST]** Physics, navigation and render visibility layer namespaces are independent, even when they reuse the same numeric bit.
- **[MUST]** Clearing a layer's display name does not prove that its bit is unused.
