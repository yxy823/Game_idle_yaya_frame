# Godot Resource and Identity References

Keep identity domains distinct. They may map to each other, but they are not interchangeable.

## Identity domains

- **[MUST]** Use a stable Business ID for persistent gameplay/domain identity in saves, data references, commands, telemetry, replay, and migrations.
- **[MUST]** Resource UID / `uid://` is Godot Resource identity; it is not a gameplay Business ID.
- **[MUST]** `res://`/`user://` paths are locations/addresses unless a schema explicitly defines path semantics; they are not automatically logical identity.
- **[MUST]** NodePath and `%UniqueName` express SceneTree structural relationships, not persistent gameplay identity.
- **[MUST]** Godot 4.6+ serialized scene Node `unique_id` is scene/editor serialization identity. Do not use it as Business ID, runtime lookup API, save ID, or network ID.
- **[MUST]** RID and Object instance IDs are current-session runtime identities only. Do not persist or network them as long-lived entity identity.
- **[MUST]** RID and Object instance ID are separate runtime identity domains and are not interchangeable.

## Resource references

- **[PREFER]** For known editor-authored static dependencies, use typed Resource/PackedScene references instead of a bare String path plus `load()`.
- **[MUST]** In Godot 4.7 do not assume an `@export_file` String necessarily contains a `res://` path. Use explicit path semantics when raw path identity is required.
- **[MUST]** Use Godot ResourceUID/ResourceLoader APIs for UID/path mapping. Do not convert by string replacement, concatenation, or guessing.
- **[MUST]** Do not invent, copy, renumber, or hand-repair Resource UIDs or scene Node `unique_id` values for cosmetic consistency.
- **[MUST]** UID resolution success proves identity resolution only; it does not replace Resource type, schema, or consumer validation.
- **[MUST]** Resource/file move or rename does not automatically rename a Business ID. Business-ID migration and filesystem/resource migration are separate events.

## Scene references

- **[MUST]** Node rename/reparent is a reference migration for serialized NodePaths, animation tracks, connections, script references, inherited overrides, and other consumers.
- **[PREFER]** Within a scene, use a direct typed Node reference or `%UniqueName` for stable key-child access when appropriate; do not use recursive `find_child()` merely to hide a structural dependency.
- **[MUST]** `%UniqueName` is scoped to its scene/owner contract and is not a global service or Business-ID namespace.
- **[MUST]** Once consumed, renaming/removing a scene unique name is a scene-local reference API change.
- **[PREFER]** For inspector-authored known Node dependencies, use typed exported Node references rather than NodePath Strings when path semantics are not required.

## Schema/API clarity

- **[MUST]** Do not use one semantically vague `id: String` to carry Business IDs, resource UIDs, paths, and NodePaths. Field/API names and types should identify the identity domain.
- **[MUST]** Do not mechanically migrate every `res://` String to `uid://`, or every UID back to a readable path. Choose based on resource identity versus location semantics.
- **[MUST]** Validate each identity domain with its own rules; a generic 'ID exists' check cannot substitute for business-reference, resource, scene, or runtime validation.
