# Asset Naming and Organization

Organize assets by domain ownership and stable consumer semantics, without forcing one universal folder tree by file type.

## Organization

- **[MUST]** Project-owned Godot directories, scripts, scenes, Resources, shaders, runtime data and assets use lowercase English `snake_case` names. Follow vendor and tool contracts for required file and directory names; documentation and non-Godot tooling keep their own naming conventions.
- **[MUST]** Existing project-owned content follows the same naming contract. Rename a violating file or directory only when the current task touches that object, and then update the affected references through the identity-preserving migration in [Paths, UIDs, and moves](paths-uid-and-moves.md). Do not keep the previous name as an alias or fallback path. Report other violations as Incidental Issues under [Task scope](../00-core/change-scope-and-ownership.md#task-scope).
- **[MUST]** Avoid filenames that differ only in case; they are fragile across filesystems and platforms.
- **[PREFER]** Organize assets by the domain, scene or feature that owns them when that keeps related scenes, scripts and assets together. Do not create giant buckets by extension as dogma.
- **[PREFER]** Preserve vendor and package boundaries where they help with updates and provenance.

## Semantic names

- **[PREFER]** Name files by their domain object and actual responsibility, such as `production_state.gd`, `producer_definition.gd` or `copper_ore_icon.png`. Use variants or sequence numbers only when they identify meaningful differences.
- **[PREFER]** Keep a scene and its dedicated root script adjacent with the same basename. Shared scripts need not match every consuming scene; global `class_name` identity follows [GDScript naming](../10-gdscript/typing-and-api.md#style-and-naming).
- **[PREFER]** Use role suffixes only when that role exists. `Manager` implies actual coordination or lifecycle management, not automatic Autoload registration; extensions already distinguish scenes, scripts and Resources.

For base directories, genre examples and ambiguous ownership choices, consult `docs/game-organization.md` in the generated project. The guide applies these rules without requiring every example directory or role to exist.
