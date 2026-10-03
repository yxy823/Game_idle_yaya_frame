# 20 Scene (`.tscn`) Rules

A `.tscn` file is serialized Godot scene state, not ordinary free-form text.

| Document | Read when |
| --- | --- |
| `structure-and-ownership.md` | Editing serialized scene state, the node hierarchy or ownership |
| `instancing-inheritance-and-overrides.md` | Changing scene instances, inherited scenes or instance-local overrides |
| `references-groups-and-order.md` | Changing ExtResource or SubResource IDs, Node `unique_id` values, NodePaths, unique names, groups, node names or sibling order |
| `ui-and-scripts.md` | Changing UI layout or focus, script binding or signal connections |
| `validation.md` | Any scene change: determine its applicable validation |

No project rule splits scenes by line count, node count or tree depth alone.
