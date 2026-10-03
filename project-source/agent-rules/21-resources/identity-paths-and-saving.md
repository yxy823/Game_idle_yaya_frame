# Resource Identity, Paths, and Saving

Keep resource identity, business identity and filesystem location separate.

## Identity

- **[MUST]** The Resource UID, the `res://` path, `resource_name` and the gameplay Business ID are distinct identity domains.
- **[MUST]** Move or rename Resources with a UID-aware workflow, as described in [Asset paths, UIDs, and moves](../60-assets/paths-uid-and-moves.md). UID handling follows [Resource references](../00-core/godot-resource-references.md#resource-references).
- **[MUST]** Do not mutate `resource_path` manually to "fix" identity.
- **[MUST]** Unused or unreferenced Resources are deletion candidates only; apply the [Core deletion rules](../00-core/change-scope-and-ownership.md#deletion-and-derived-outputs) before removal.
- **[MUST]** Do not place Resources that the game requires at runtime under `.gdignore`.

## Saving and generation

- **[MUST]** Gameplay and exported runtime persistence for saves, settings and mutable state uses `user://` or an explicitly defined external persistence domain.
- **[MUST]** Gameplay and exported runtime code must not rely on modifying repository definition or configuration `.tres` files under `res://`. Keep runtime persistence separate from project definition data.
- **[MUST]** Editor and tool authoring may intentionally write project Resources under `res://` as part of an explicit authoring workflow.
- **[MUST]** Check the return status of `ResourceSaver`. Advanced save flags require deliberate review.
- **[MUST]** Treat `ResourceSaver.save() == OK` as the status of the save operation only; it does not prove that a new Resource UID was correctly persisted.
- **[MUST]** In the Godot 4.7 runtime, automatically generated Resource UIDs are not persisted as they are in Editor mode. A generated Resource that becomes an official repository artifact is created in an Editor or authoring context, or passes later validation of target-editor import and UID integrity. Do not guess, handwrite or reassign a UID to bypass this boundary.
- **[MUST]** After saving generated project Resources, reload them through the production loader and validate the UID and path, the custom type, persisted values, dependencies and invariants.
- **[MUST]** After external text edits to Resource files, refresh the filesystem or use a fresh process as needed, so that the editor cache does not produce a false green result.
