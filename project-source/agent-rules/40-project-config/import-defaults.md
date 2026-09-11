# Project Import Defaults

Import defaults are asset-pipeline policy, not a one-asset repair mechanism.

## Import defaults

- **[REVIEW]** Changing import defaults is a project asset-pipeline policy change affecting future/reimported assets.
- **[MUST]** Pixel art does not imply universal nearest/no-mipmap defaults. Choose defaults by actual asset roles and allow intentional exceptions.
- **[MUST]** Changing project import defaults does not automatically migrate already imported assets. Existing `.import`/per-asset parameters can remain authoritative, so reimport alone does not prove that the new default was adopted.
- **[MUST]** For existing assets intended to adopt the new policy, explicitly migrate their `.import`/per-asset parameters or preset, then reimport and validate them.
- **[MUST]** Fresh-import a representative new asset to validate the project default itself, and report that evidence separately from existing-asset migration.
- **[MUST]** Any Resources/files referenced by import defaults/custom importer configuration are project/editor startup dependencies and must remain available.
