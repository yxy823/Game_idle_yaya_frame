# Asset Naming and Organization

Organize by domain ownership and stable consumer semantics without forcing one universal type-based folder tree.

## Organization

- **[MUST]** Project-owned Godot directories, scripts, scenes, Resources, shaders, runtime data and assets use lowercase English `snake_case` names. Follow vendor/tool contracts for required file and directory names; documentation and non-Godot tooling keep their own naming conventions.
- **[MUST]** Existing project-owned content follows the same naming contract. Treat violations as errors and update affected references when renaming; do not retain old-name aliases or fallback paths for naming compatibility. Follow [Paths, UIDs, and moves](paths-uid-and-moves.md) for identity-preserving migration.
- **[MUST]** Avoid case-only filename distinctions that are fragile across filesystems/platforms.
- **[PREFER]** Organize assets by domain/scene/feature ownership when that keeps related scene/script/assets together; do not create giant extension-only buckets as dogma.
- **[PREFER]** Preserve vendor/package boundaries where they help updates/provenance.
- **[MUST]** Rule-module folder organization does not prescribe asset/project filesystem organization.

## Semantic names

- **[PREFER]** Name files by their domain/object and actual responsibility, such as `production_state.gd`, `producer_definition.gd` or `copper_ore_icon.png`. Use variants or sequence numbers only when they identify meaningful differences.
- **[PREFER]** Keep a scene and its dedicated root script adjacent with the same basename. Shared scripts need not match every consuming scene; global `class_name` identity follows [GDScript naming](../10-gdscript/typing-and-api.md#style-and-naming).
- **[PREFER]** Use role suffixes only when that role exists. `Manager` implies actual coordination or lifecycle management, not automatic Autoload registration; extensions already distinguish scenes, scripts and Resources.

For base directories, genre examples and ambiguous ownership choices, consult `docs/game-organization.md` in the generated project. The guide applies these rules without requiring every example directory or role to exist.
