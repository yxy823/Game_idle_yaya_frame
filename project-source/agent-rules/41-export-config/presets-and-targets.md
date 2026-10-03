# Export Presets and Targets

Treat export presets as build and distribution APIs.

## Presets

- **[MUST]** `export_presets.cfg` is build and distribution configuration, not runtime `project.godot` configuration.
- **[PREFER]** Use the Godot Export UI or supported APIs for structural preset edits. Small deterministic text changes require exact knowledge of the format and real export validation.
- **[MUST]** A preset name consumed by the CLI, CI or build tooling is a build API; rename it only together with a consumer migration.
- **[MUST]** Validate the build mode that is actually required. A debug export, a release export and a PCK-only export do not prove the same contract.
- **[MUST]** A relative output path passed to a CLI `--export-*` command resolves from the project root, not from the shell's working directory. Resolve artifact checks against that project-root path.
- **[PREFER]** Keep a committed preset `export_path` project-relative and under repository control. An external absolute artifact path is acceptable when explicit CI or build orchestration owns it; do not commit machine- or user-specific paths into the shared preset.

## Target identity

- **[REVIEW]** Published package, bundle and application identifiers are distribution identity. Changing them can create a new installed application identity and requires a release and update review.
- **[MUST]** Do not alter the target platform, architecture, renderer, template or package identity as a cleanup or convenience change.
- **[MUST]** Export templates and custom templates are compatible with the approved Godot executable and version used for validation.
