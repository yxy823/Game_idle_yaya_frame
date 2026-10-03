# Third-Party, Generated, Tool-Managed, Cache, and Temporary Files

Classify both ownership and authority before editing.

## Classification

- **[MUST]** Before editing a non-obvious artifact, determine both its ownership (project, vendor, tool, test or unknown) and its authority role (source, configuration, generated, cache or temporary).
- **[MUST]** Do not infer ownership solely from the extension, an `addons/` location, the filename or the Git tracking status.
- **[MUST]** Git tracking and generated, source or cache status are independent. A committed generated artifact remains generated.
- **[MUST]** Source ownership, Git tracking, Godot import visibility and inclusion in the production export are separate dimensions.

## Vendor and third-party

- **[MUST]** Third-party and vendor implementation is an external dependency by default. Do not modify it merely for project lint or style, convenience, warning cleanup or a green test status.
- **[REVIEW]** A necessary vendor fix must consider the upstream version and updates, an adapter or workaround, how long a patch or fork can be maintained, and licensing. Keep the local patch distinguishable from upstream.
- **[MUST]** Modification of a third-party asset is governed by its actual license, its provenance and project policy, not by the vendor-code rules alone.

## Generated and tool-managed

- **[MUST]** When a generated artifact needs to change, first locate its authoritative source, its schema or configuration and its generator. Fix the upstream cause and regenerate.
- **[MUST]** Do not hand-patch generated output to avoid the formal pipeline.
- **[MUST]** `<asset>.import` is Godot-managed import metadata with project configuration semantics. Do not treat it as ordinary source or as disposable cache.
- **[MUST]** Do not cosmetically edit or repair the internal UID, remap or other generated fields in `.import`; change import configuration through the supported import workflow.
- **[MUST]** `.godot/imported/` is rebuildable cache and is never authoritative. Do not edit it directly or copy it into production source.
- **[MUST]** Rebuildable does not mean that the Agent may recursively delete the entire `.godot/` directory without a concrete diagnostic purpose and an impact review.
- **[MUST]** Do not perform cache surgery. Use the supported refresh, reimport or clean-rebuild paths.
- **[MUST]** Do not hide unexpected pipeline artifacts by adding `.gitignore` or `.gdignore` as the default fix. Diagnose whether the artifacts should exist.

## Temporary, backup, and scratch

- **[MUST]** A temporary artifact needs a creating owner, a bounded purpose and a cleanup or lifetime policy.
- **[MUST]** Clean only temporary artifacts that the task, test or project explicitly owns. Do not delete unknown `tmp*`, `backup*`, `old*` or similar files by name pattern.
- **[PREFER]** Run destructive editor, import or serialization experiments in a test-owned scratch subtree or a temporary Godot project rather than mutating production content and hoping to restore it.
- **[MUST]** Backup, autosave and recovery copies are not automatically the source of truth. They must not overwrite current work without explicit recovery intent.
- **[MUST]** Generated-file headers and manifests are strong evidence of authority and provenance; the absence of a marker does not prove that a file is hand-authored source.
