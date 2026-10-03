# Project Import Defaults

Import defaults are asset-pipeline policy, not a mechanism for repairing one asset.

## Import defaults

- **[REVIEW]** Changing import defaults changes the project's asset-pipeline policy and affects future and reimported assets.
- **[MUST]** Pixel art does not imply universal nearest-filter or no-mipmap defaults. Choose defaults by actual asset roles and allow intentional exceptions.
- **[MUST]** Changing project import defaults does not automatically migrate assets that are already imported. Their `.import` files and per-asset parameters can remain authoritative, so a reimport alone does not prove that the new default was adopted.
- **[MUST]** For existing assets that should adopt the new policy, explicitly migrate their `.import` files, per-asset parameters or preset, then reimport and validate them.
- **[MUST]** Validate the project default itself by freshly importing a representative new asset, and report that evidence separately from the migration of existing assets.
- **[MUST]** Resources and files referenced by import defaults or custom importer configuration are startup dependencies of the project and the editor; keep them available.
