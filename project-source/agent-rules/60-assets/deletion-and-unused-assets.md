# Asset Deletion and Unused Candidates

Unused detection is candidate discovery, not deletion authorization.

## Deletion

- **[MUST]** Before deleting an asset, check typed Resource references, scenes, scripts, dynamic path registries/registries, remaps, localization, tests, mods/external contracts, and generated/source relationships as applicable.
- **[MUST]** An unused-report result is not permission to delete.
- **[MUST]** Do not perform unrelated asset cleanup during a focused feature/fix task.
- **[MUST]** If deleting source asset, also handle owned metadata/generated cache through supported import workflow; do not manually curate `.godot/imported`.
