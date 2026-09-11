# Source Assets and Generated Files

Keep source content, import metadata, generated cache, runtime Resources, and export artifacts distinct.

## Authority

- **[MUST]** Source assets are authoritative content; `.godot/imported` is rebuildable generated cache.
- **[MUST]** `<asset>.import` is version-controlled Godot-managed import metadata/configuration, not disposable cache.
- **[MUST]** Load imported Resources through source `res://` path/ResourceLoader contract, not direct `.godot/imported` paths.
- **[MUST]** Raw non-imported FileAccess assets are a separate runtime path and follow export packaging rules.
- **[MUST]** External edits require filesystem refresh/reimport before runtime/editor evidence is trusted.

## Version control

- **[PREFER]** Version-control source assets, relevant `.import` metadata, and project-owned importer/config files; do not commit `.godot/imported` cache.
- **[MUST]** A clean/fresh rebuild should reconstruct imported runtime artifacts from declared source and importer dependencies.
