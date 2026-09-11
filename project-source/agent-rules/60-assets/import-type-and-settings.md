# Import Type and Settings

Import type/settings define the Resource API seen by consumers.

## Import semantics

- **[MUST]** Changing importer/import type is a consumer Resource-API change and requires representative consumer validation.
- **[MUST]** Keep/Skip File/import-mode changes are export/runtime availability changes.
- **[MUST]** Do not apply one import preset to all assets merely because they share an extension; classify by runtime role.
- **[MUST]** Detect-3D/automatic import decisions that alter mipmap/compression behavior require review for shared textures used by 2D/3D paths.
- **[MUST]** When Detect 3D automatically changes mipmap/compression settings and reimports a texture, investigate the resulting `.import` diff and affected consumers before keeping or reverting it; do not discard it as unexplained generated noise.
