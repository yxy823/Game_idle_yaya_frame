# Godot Resource and Identity References

Keep identity domains distinct. They may map to each other, but they are not interchangeable.

## Identity domains

- **[MUST]** Use a stable Business ID for persistent gameplay and domain identity in saves, data references, commands, telemetry, replays and migrations.
- **[MUST]** A Resource UID (`uid://`) is Godot Resource identity; it is not a gameplay Business ID.
- **[MUST]** `res://` and `user://` paths are locations, not logical identity, unless a schema explicitly defines path semantics.
- **[MUST]** NodePath and `%UniqueName` express SceneTree structural relationships, not persistent gameplay identity.
- **[MUST]** The serialized scene Node `unique_id` of Godot 4.6 and later is scene and editor serialization identity. Do not use it as a Business ID, a runtime lookup API, a save ID or a network ID.
- **[MUST]** RIDs and Object instance IDs are runtime identities for the current session only. Do not persist them or send them over the network as long-lived entity identity.
- **[MUST]** RIDs and Object instance IDs are separate runtime identity domains and are not interchangeable.

## Resource references

- **[PREFER]** For known editor-authored static dependencies, use typed Resource or PackedScene references instead of a bare String path plus `load()`.
- **[MUST]** In Godot 4.7, do not assume that an `@export_file` String contains a `res://` path. Use explicit path semantics when raw path identity is required.
- **[MUST]** Use the Godot ResourceUID and ResourceLoader APIs for UID and path mapping. Do not convert by string replacement, concatenation or guessing.
- **[MUST]** Do not invent, copy, renumber or hand-repair Resource UIDs or scene Node `unique_id` values, including for cosmetic consistency.
- **[MUST]** Successful UID resolution proves identity resolution only; it does not replace Resource type, schema or consumer validation.
- **[MUST]** Moving or renaming a Resource or file does not automatically rename a Business ID. Business-ID migration and filesystem or resource migration are separate events.

## Scene references

- **[MUST]** Renaming or reparenting a Node is a reference migration for serialized NodePaths, animation tracks, connections, script references, inherited overrides and other consumers.
- **[PREFER]** Within a scene, use a direct typed Node reference or `%UniqueName` for stable access to key children when appropriate. Do not use a recursive `find_child()` merely to hide a structural dependency.
- **[MUST]** A `%UniqueName` is scoped to its scene and owner contract; it is not a global service or a Business-ID namespace.
- **[MUST]** Once a scene unique name is consumed, renaming or removing it is a change to the scene-local reference API.
- **[PREFER]** For known Node dependencies assigned in the Inspector, use typed exported Node references rather than NodePath Strings when path semantics are not required.

## Schema and API clarity

- **[MUST]** Do not use one vague `id: String` to carry Business IDs, Resource UIDs, paths and NodePaths. Choose field names, API names and types that identify the identity domain.
- **[MUST]** Do not mechanically migrate every `res://` String to `uid://`, or every UID back to a readable path. Choose according to whether the value means resource identity or location.
- **[MUST]** Validate each identity domain with its own rules. A generic "ID exists" check cannot substitute for business-reference, resource, scene or runtime validation.
