# Scene References, Groups, IDs, and Order

Treat serialized references and Godot-managed IDs as semantic data.

## Resource IDs

- **[MUST]** `ExtResource`/`SubResource` numeric IDs are file-local serialization identifiers. Do not copy/renumber them for aesthetics.
- **[MUST]** Resource UID is stable project identity; do not guess or manually repair it.
- **[MUST]** Preserve Godot 4.6+ scene Node `unique_id`; do not copy the same value to duplicated Nodes or renumber values for readability.
- **[MUST]** A legacy scene saved before Godot 4.6 may legitimately omit Node `unique_id`. Missing values alone are not corruption; do not synthesize, backfill, or renumber them for format uniformity.
- **[MUST]** SubResource dependency order follows actual dependency semantics; do not reorder blindly.
- **[MUST]** Do not reintroduce deprecated/obsolete serialization fields such as old `load_steps` assumptions for Godot 4.7.

## NodePath and rename

- **[MUST]** Node rename/reparent is a cross-reference change. Inspect NodePath properties, animations, `node_paths`, connections, parents/owners, scripts, inherited overrides, and code consumers.
- **[MUST]** A `%UniqueName` is a scene-local reference API under the same owner. Rename/remove it only with consumer migration.
- **[MUST]** Before adding, copying, or enabling `unique_name_in_owner` on a Node, verify that its name is unique across the complete owner scope, not merely among siblings. Do not let subtree duplication silently create a duplicate `%Name`.
- **[MUST]** If a unique-name collision would occur, choose and migrate the affected name deliberately, update every `%Name` consumer, and revalidate reference resolution.

## Groups and order

- **[MUST]** Groups are behavior declarations, not decorative metadata. Do not remove/normalize them without consumer analysis.
- **[MUST]** Do not create project custom groups beginning with `_` where Godot uses underscore-prefixed internal conventions.
- **[MUST]** Do not rely on group iteration order unless the project explicitly imposes deterministic ordering.
- **[MUST]** Inherited/sibling ordering is semantic where Godot behavior depends on it; do not sort for text cleanliness.
