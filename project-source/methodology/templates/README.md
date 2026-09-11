# Methodology templates

These templates define the durable files rendered by the workflow. Templates are canonical structure, not localized copies.

Before rendering any template:

1. Read `docs/methodology-config.json` and resolve `document_language` according to `../05-document-language.md`.
2. Preserve machine keys, enum values, IDs, paths, command strings, and placeholders exactly.
3. Render human-readable headings/prose in `document_language` while preserving every required section and semantic constraint.
4. Do not create parallel localized template trees.

## Templates

| Template | Purpose |
| --- | --- |
| `product.md.tmpl` | Product overview and module inventory. |
| `product-module.md.tmpl` | One Product module specification. |
| `feature-list.json.tmpl` | Lightweight Feature index. |
| `feature-detail.json.tmpl` | Product-derived Feature detail. It intentionally omits `engineering_change`. |
| `engineering-feature-detail.json.tmpl` | Bug/refactor/maintenance Feature detail with required `engineering_change`. |
| `feature-list-revisions.json.tmpl` | Versioned Product/Coding-Rules migration log, preserving historical entries and typed evolution relationships. |
| `test-catalog.json.tmpl` | Empty machine-readable component/test traceability catalog used by Test Impact Review. |
| `gate-evidence.json.tmpl` | Current-Feature test, human-acceptance, review, Git revision, and working-tree evidence used by the explicit completion check. |
| `progress.md.tmpl` | Current state, blockers, pending decisions, next legal action and a history index; history bodies live separately. |
| `coding_rules.md.tmpl` | Stack-independent collaboration and architecture rules, with pointers to the root router and routed project rules. |
| `run-manifest.json.tmpl` | Actual-run evidence shape; placeholders are not executed results. |
| `stage8-learning.md.tmpl` | Concise feedback inside existing Stage 8, including an explicit no-learning outcome. |
| `architecture-overview.md.tmpl`, `architecture-subsystem.md.tmpl` | Optional human-owned module/responsibility/dependency maps, separate from generated reference facts. |

The authoritative Feature/test field semantics and invariants live in `../02-feature-list-schema.md`; engineering mode semantics live in `../07-engineering-change.md`; test selection and TDD semantics live in `../08-testing-strategy.md`.

Lint metric semantics, the controlled vendor patch and executable contract
checks are documented in `../gdscript-lint.md`.

`full_test_cmd` may be rendered as JSON `null` when the project has no distinct full-suite command. Do not render the string `"null"`.

Project configuration is stored in `docs/methodology-config.json`.
Use the templates above when a task needs Product, Feature, test or history records.
