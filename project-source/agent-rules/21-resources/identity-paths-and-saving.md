# Resource Identity, Paths, and Saving

Keep resource identity, business identity, and filesystem location separate.

## Identity

- **[MUST]** Resource UID, `res://` path, `resource_name`, and gameplay Business ID are distinct identity domains.
- **[MUST]** Move/rename Resources with a UID-aware workflow. Do not manually assign/repair UID identity.
- **[MUST]** Do not use `resource_path` as a manually mutated field to 'fix' identity.
- **[MUST]** Unused/unreferenced Resources are deletion candidates only; apply Core deletion rules before removal.
- **[MUST]** Runtime Resources required by the game must not be placed under `.gdignore`.

## Saving/generation

- **[MUST]** Gameplay/exported runtime persistence for saves, settings, and mutable state uses `user://` or an explicitly defined external persistence domain.
- **[MUST]** Gameplay/exported runtime must not rely on modifying repository definition/config `.tres` files under `res://`; keep runtime persistence separate from project definition data.
- **[MUST]** Editor/tool authoring may intentionally write project Resources under `res://` as part of an explicit authoring workflow.
- **[MUST]** Check `ResourceSaver` return/error status. Advanced save flags require deliberate review.
- **[MUST]** Treat `ResourceSaver.save() == OK` as save-operation status only; it does not prove that a new Resource UID was correctly persisted.
- **[MUST]** In Godot 4.7 runtime, automatically generated Resource UIDs are not persisted as they are in Editor mode. A generated Resource that becomes an official repository artifact must be created in an Editor/authoring context or pass subsequent target-editor/import/UID-integrity validation. Do not guess, handwrite, or casually reassign a UID to bypass this boundary.
- **[MUST]** Generated project Resources validate UID/path, custom type, persisted values, dependencies, and invariants after save -> reload.
- **[MUST]** After external text edits to Resource files, use filesystem refresh/fresh process as needed so editor cache does not produce a false-green result.
