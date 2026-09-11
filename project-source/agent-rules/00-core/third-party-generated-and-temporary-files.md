# Third-Party, Generated, Tool-Managed, Cache, and Temporary Files

Classify both ownership and authority before editing.

## Classification

- **[MUST]** Before editing a non-obvious artifact, determine both ownership (project/vendor/tool/test/unknown) and authority role (source/configuration/generated/cache/temporary).
- **[MUST]** Do not infer ownership solely from extension, `addons/` location, filename, or Git tracking status.
- **[MUST]** Git-tracked status and generated/source/cache status are independent. A committed generated artifact remains generated.
- **[MUST]** Source ownership, Git tracking, Godot import visibility, and production export inclusion are separate dimensions.

## Vendor and third-party

- **[MUST]** Third-party/vendor implementation is an external dependency by default. Do not modify it merely for project lint/style, convenience, warning cleanup, or test green status.
- **[REVIEW]** A necessary vendor fix must consider upstream version/update, adapter/workaround, patch/fork durability, and licensing. Keep local patch distinguishable from upstream.
- **[MUST]** Third-party asset modification is governed by its actual license/provenance and project policy, not by vendor-code rules alone.

## Generated and tool-managed

- **[MUST]** When a generated artifact needs to change, first locate authoritative source, schema/configuration, and generator. Fix the upstream cause and regenerate.
- **[MUST]** Do not hand-patch generated output to avoid the formal pipeline.
- **[MUST]** `<asset>.import` is Godot-managed import metadata with project configuration semantics. Do not treat it as ordinary source or disposable cache.
- **[MUST]** Do not cosmetically edit/repair internal UID/remap/generated fields in `.import`; use supported import workflow for import configuration.
- **[MUST]** `.godot/imported/` is rebuildable cache and is never authoritative. Do not directly edit or copy it into production source.
- **[MUST]** Rebuildable does not mean the Agent may recursively delete the entire `.godot/` directory without a concrete diagnostic purpose and impact review.
- **[MUST]** Do not perform cache surgery. Use supported refresh/reimport/clean-rebuild paths.
- **[MUST]** Do not hide unexpected pipeline artifacts by adding `.gitignore` or `.gdignore` as the default fix. Diagnose whether artifacts should exist.

## Temporary, backup, and scratch

- **[MUST]** Temporary artifacts need a creating owner, bounded purpose, and cleanup/lifetime policy.
- **[MUST]** Only clean temporary artifacts that the task/test/project explicitly owns. Do not delete unknown `tmp*`, `backup*`, `old*`, or similar files by name pattern.
- **[PREFER]** Run destructive editor/import/serialization experiments in a test-owned scratch subtree or temporary Godot project rather than mutating production content and hoping to restore it.
- **[MUST]** Backup/autosave/recovery copies are not automatically source of truth and must not overwrite current work without explicit recovery intent.
- **[MUST]** Generated-file headers/manifests are strong authority/provenance evidence; absence of a marker does not prove hand-authored source.
