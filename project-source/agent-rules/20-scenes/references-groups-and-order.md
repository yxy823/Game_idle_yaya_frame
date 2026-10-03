# Scene References, Groups, IDs, and Order

Treat serialized references and Godot-managed IDs as semantic data. The identity rules for Resource UIDs, NodePaths and `%UniqueName` are defined in [Godot resource and identity references](../00-core/godot-resource-references.md); this document adds what applies inside `.tscn` files.

## Resource IDs

- **[MUST]** `ExtResource` and `SubResource` numeric IDs are file-local serialization identifiers. Do not copy or renumber them for aesthetics.
- **[MUST]** Preserve the scene Node `unique_id` values of Godot 4.6 and later. Do not copy one value to duplicated Nodes or renumber values for readability.
- **[MUST]** A legacy scene saved before Godot 4.6 may legitimately omit Node `unique_id`. Missing values alone are not corruption; do not synthesize, backfill or renumber them for format uniformity.
- **[MUST]** SubResource order follows the actual dependencies; do not reorder it blindly.
- **[MUST]** Do not reintroduce deprecated serialization fields, such as `load_steps` assumptions from earlier versions, into Godot 4.7 scenes.

## NodePath and rename

- **[MUST]** Renaming or reparenting a Node is a [scene reference migration](../00-core/godot-resource-references.md#scene-references). In a `.tscn`, inspect and validate NodePath properties, animations, `node_paths`, connections, parents and owners, scripts, inherited overrides and code consumers.
- **[MUST]** Before adding, copying or enabling `unique_name_in_owner` on a Node, verify that its name is unique across the complete owner scope, not merely among siblings. Do not let subtree duplication silently create a duplicate `%Name`.
- **[MUST]** If a unique-name collision would occur, choose and migrate the affected name deliberately, update every `%Name` consumer and revalidate reference resolution.

## Groups and order

- **[MUST]** Groups are behavior declarations, not decorative metadata. Do not remove or normalize them without analyzing their consumers.
- **[MUST]** Do not create custom project groups whose names begin with `_`, because Godot uses underscore-prefixed names for internal conventions.
- **[MUST]** Group naming and iteration order follow [Groups and layers](../40-project-config/groups-and-layers.md#groups).
- **[MUST]** Sibling and index order may be semantic for drawing, layout, processing and serialized behavior, including in inherited and instanced scenes. Do not alphabetize, reorder or sort Nodes for aesthetics or text cleanliness.
