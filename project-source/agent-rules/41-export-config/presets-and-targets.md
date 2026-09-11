# Export Presets and Targets

Treat Export Presets as build/distribution APIs.

## Presets

- **[MUST]** `export_presets.cfg` is build/distribution configuration, not runtime `project.godot` configuration.
- **[PREFER]** Use Godot Export UI/supported APIs for structural preset edits. Small deterministic text changes require exact format knowledge and real export validation.
- **[MUST]** A preset name consumed by CLI/CI/build tooling is a build API; rename it only with consumer migration.
- **[MUST]** Validate the build mode actually required. Debug export, Release export, and PCK-only export do not prove the same contract.
- **[MUST]** A relative output path passed to a CLI `--export-*` command resolves from the project root, not the shell working directory. Resolve artifact checks against that project-root path.
- **[PREFER]** A committed preset `export_path` should be project-relative and repository-controlled. An external absolute artifact path is acceptable when explicit CI/build orchestration owns it; do not commit machine- or user-specific paths into the shared preset.

## Target identity

- **[REVIEW]** Published package/bundle/application identifiers are distribution identity. Changing them can create a new installed application identity and requires release/update review.
- **[MUST]** Do not alter target platform, architecture, renderer/template, or package identity as a cleanup/convenience change.
- **[MUST]** Export templates/custom templates must be compatible with the approved Godot executable/version used for validation.
