# Source Art and Runtime Assets

Keep editable masters and runtime-ready assets connected by a reproducible pipeline.

## Source/runtime split

- **[MUST]** Define which file is editable source master and which is runtime asset when they differ.
- **[MUST]** Runtime assets derived from source art record enough pipeline/provenance to reproduce transformation.
- **[MUST]** Do not place runtime-required assets under `.gdignore` simply because source-art masters also exist.
- **[MUST]** Do not assume `.gitignore`/local-only source art is cache; authority is defined by asset pipeline, not Git tracking alone.
