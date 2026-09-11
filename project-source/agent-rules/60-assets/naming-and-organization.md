# Asset Naming and Organization

Organize by domain ownership and stable consumer semantics without forcing one universal type-based folder tree.

## Organization

- **[PREFER]** New project-owned asset filenames use lowercase `snake_case` unless an external ecosystem/vendor contract requires another scheme.
- **[MUST]** Avoid case-only filename distinctions that are fragile across filesystems/platforms.
- **[PREFER]** Organize assets by domain/scene/feature ownership when that keeps related scene/script/assets together; do not create giant extension-only buckets as dogma.
- **[PREFER]** Preserve vendor/package boundaries where they help updates/provenance.
- **[MUST]** Rule-module folder organization does not prescribe asset/project filesystem organization.
