# Source and Derived Assets

Keep editable source masters, import metadata, the generated cache, runtime Resources and export artifacts distinct, and connect them through a reproducible pipeline. The ownership and authority of `.import` files and `.godot/imported/` follow [Generated and tool-managed files](../00-core/third-party-generated-and-temporary-files.md#generated-and-tool-managed).

## Source masters and runtime assets

- **[MUST]** When they differ, define which file is the editable source master and which is the runtime asset.
- **[MUST]** Runtime assets derived from source art record enough pipeline and provenance information to reproduce the transformation.
- **[MUST]** Do not place runtime-required assets under `.gdignore` simply because source-art masters also exist.
- **[MUST]** Do not assume that source art ignored by Git or kept only locally is cache. The asset pipeline defines authority; Git tracking alone does not.

## Imported assets

- **[MUST]** Source assets are authoritative content, and `.godot/imported` is a rebuildable generated cache.
- **[MUST]** Load imported Resources through their source `res://` path and the ResourceLoader contract, not through direct `.godot/imported` paths.
- **[MUST]** Raw assets that are not imported and are read through FileAccess are a separate runtime path. They follow the [export inclusion rules](../41-export-config/resources-and-filters.md#packaging).
- **[MUST]** After external edits, refresh the filesystem or reimport before trusting runtime or editor evidence.

## Version control

- **[PREFER]** Version-control source assets, the relevant `.import` metadata and project-owned importer and configuration files. Do not commit the `.godot/imported` cache.
- **[MUST]** A clean, fresh rebuild reconstructs the imported runtime artifacts from the declared source and importer dependencies.

## Variants and duplicates

- **[MUST]** Visual similarity alone does not prove that two assets are the same logical asset.
- **[MUST]** Do not duplicate source assets merely to get different filter, repeat or material sampling behavior per use when consumer configuration can provide it.
- **[MUST]** Share assets when their identity, lifecycle and change coupling are actually shared; separate them when they must evolve independently.
- **[MUST]** Generated variants record their source and generation pipeline so that they can be reproduced.
