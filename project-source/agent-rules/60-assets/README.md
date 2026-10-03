# 60 Asset Pipeline Rules

Applies to source images, audio and fonts, `.import` metadata, the Godot import cache, custom importers, paths and UIDs, provenance and licenses, variants and asset validation.

```text
Source Asset
+ <asset>.import configuration
-> Godot Importer
-> .godot/imported generated cache
-> ResourceLoader
-> .tscn, .tres and .gd consumers
-> Export
```

| Document | Read when |
| --- | --- |
| `source-and-derived-assets.md` | Adding source art or other source assets, deciding what is source, generated or runtime content, version-controlling assets, or creating variants and duplicates |
| `import-configuration.md` | Changing `.import` configuration, import types or settings, or reimporting assets |
| `paths-uid-and-moves.md` | Moving, renaming, duplicating or deleting assets |
| `naming-and-organization.md` | Naming files and directories or organizing assets |
| `ignored-and-raw-files.md` | Using `.gdignore` or raw files read through FileAccess |
| `textures-and-images.md` | Importing or changing textures and images |
| `audio-assets.md` | Importing or changing audio |
| `font-assets.md` | Importing or changing fonts |
| `custom-importers.md` | Writing or changing a custom importer |
| `asset-provenance-and-licenses.md` | Adding or modifying third-party assets |
| `validation.md` | Any asset change: determine its applicable validation |
