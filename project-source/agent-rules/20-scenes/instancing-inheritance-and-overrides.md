# Scene Instancing, Inheritance, and Overrides

Preserve PackedScene identity and the distinction between shared source state and local overrides.

## PackedScene instances

- **[MUST]** Preserve PackedScene instance identity unless the task intentionally localizes/unpacks structure.
- **[MUST]** Distinguish runtime instantiation from editor authoring. Runtime code normally uses `PackedScene.instantiate()`; an editor/Agent tool that creates a persistent instance in the currently edited scene must instantiate it with the Godot 4.7 instance edit state, such as `PackedScene.GEN_EDIT_STATE_INSTANCE` in an editor build.
- **[MUST]** When persisting that editor-authored instance, set the instance root's owner as required by the edited scene, but do not recursively replace the owners of its descendants with the current scene root. Preserve the descendant ownership and instance boundary encoded by the source PackedScene.
- **[MUST]** Decide deliberately whether a change belongs in the source scene or as an instance-local override.
- **[REVIEW]** `Editable Children` changes the instance boundary and requires a real reason; do not enable it as a convenience to patch deep children.
- **[MUST]** After a structural `Editable Children` or inherited-scene override change, save the scene and validate the instance identity, ownership, and overrides again after a fresh reload; the current editor's in-memory tree is not sufficient evidence.

## Inherited scenes

- **[MUST]** An inherited scene remains base plus override. Shared behavior belongs in the base; derived-only behavior belongs in minimal overrides.
- **[MUST]** Do not flatten an inherited scene or copy the full base state into the derived scene to simplify editing.
- **[MUST]** When base structure/names change, validate all derived/inherited scenes and their overrides.

## Order

- **[MUST]** Sibling/index order may be semantic for draw/layout/process/serialized behavior. Do not alphabetize/reorder Nodes for aesthetics.
