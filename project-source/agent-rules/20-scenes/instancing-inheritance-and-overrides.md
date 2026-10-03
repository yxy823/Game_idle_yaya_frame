# Scene Instancing, Inheritance, and Overrides

Preserve PackedScene identity and the distinction between shared source state and local overrides.

## PackedScene instances

- **[MUST]** Preserve PackedScene instance identity unless the task intentionally localizes or unpacks the structure.
- **[MUST]** Distinguish runtime instantiation from editor authoring. Runtime code normally uses `PackedScene.instantiate()`. An editor or Agent tool that creates a persistent instance in the currently edited scene instantiates it with the Godot 4.7 instance edit state, such as `PackedScene.GEN_EDIT_STATE_INSTANCE` in an editor build.
- **[MUST]** When persisting that editor-authored instance, set the instance root's owner as the edited scene requires. Do not recursively replace the owners of its descendants with the current scene root; preserve the descendant ownership and the instance boundary encoded by the source PackedScene.
- **[MUST]** Decide deliberately whether a change belongs in the source scene or in an instance-local override.
- **[REVIEW]** `Editable Children` changes the instance boundary and requires a real reason. Do not enable it as a convenience for patching deep children.
- **[MUST]** After a structural change to `Editable Children` or an inherited-scene override, save the scene and validate the instance identity, ownership and overrides again after a fresh reload. The current editor's in-memory tree is not sufficient evidence.

## Inherited scenes

- **[MUST]** An inherited scene remains a base plus overrides. Shared behavior belongs in the base; derived-only behavior belongs in minimal overrides.
- **[MUST]** Do not flatten an inherited scene or copy the full base state into the derived scene to simplify editing.
- **[MUST]** When the base structure or names change, validate all derived scenes and their overrides.

Sibling order in instanced and inherited scenes follows [Groups and order](references-groups-and-order.md#groups-and-order).
