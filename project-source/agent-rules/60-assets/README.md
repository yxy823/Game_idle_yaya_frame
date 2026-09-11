# 60 Asset Pipeline Rules

Applies to source images/audio/fonts, `.import` metadata, Godot imported cache,
custom importers, paths/UIDs, provenance/licenses, variants, and asset validation.

Core model:

```text
Source Asset
+ <asset>.import configuration
-> Godot Importer
-> .godot/imported generated cache
-> ResourceLoader
-> .tscn/.tres/.gd consumers
-> Export
```

Read:

- `asset-provenance-and-licenses.md`
- `audio-assets.md`
- `custom-importers.md`
- `deletion-and-unused-assets.md`
- `font-assets.md`
- `ignored-and-raw-files.md`
- `import-metadata.md`
- `import-type-and-settings.md`
- `naming-and-organization.md`
- `paths-uid-and-moves.md`
- `reimport-and-cache.md`
- `source-art-and-runtime-assets.md`
- `source-assets-and-generated-files.md`
- `textures-and-images.md`
- `validation.md` (always applies)
- `variants-and-duplication.md`

Read the concrete documents that match the affected asset type or pipeline stage; `validation.md` always applies.
