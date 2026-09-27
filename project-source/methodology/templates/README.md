# Methodology templates

These templates define the durable files rendered by the workflow. Templates are canonical structure, not localized copies.

Before rendering any template:

1. Read `docs/methodology-config.json` and resolve `document_language` according to `../05-document-language.md`.
2. Preserve machine keys, enum values, IDs, paths, command strings, and placeholders exactly.
3. Render human-readable headings/prose in `document_language` while preserving every required section and semantic constraint.
4. Do not create parallel localized template trees.

Markdown prose uses natural paragraphs without fixed-width hard wrapping. Keep blank lines between paragraphs and preserve semantic line breaks in lists, tables, code, diagrams and other structured content. Do not reflow JSON or other structured templates as prose.

## Templates

| Template | Purpose |
| --- | --- |
| `product.md.tmpl` | Delivery pre-decomposition, GDD source mapping, boundaries, dependencies and suggested order. |
| `product-module.md.tmpl` | Current Product delivery scope, source links, integration and acceptance scenarios; written only when its turn arrives. |
| `feature-list.json.tmpl` | Lightweight Feature index. |
| `feature-detail.json.tmpl` | Product-derived Feature detail. It intentionally omits `engineering_change`. |
| `feature-design.md.tmpl` | Optional outline for a detailed `docs/features/F0XX-design.md`; select useful sections, keep AC/test obligations in JSON and link current architecture/ADRs. |
| `engineering-feature-detail.json.tmpl` | Bug/refactor/maintenance Feature detail with required `engineering_change`. |
| `feature-list-revisions.json.tmpl` | Versioned governing-source migration log for GDD, Product, professional sources and Project Rules, preserving historical entries and typed evolution relationships. |
| `test-registry.json.tmpl` | Empty machine-readable component/test traceability registry used by Test Impact Review. |
| `feature-completion-evidence.json.tmpl` | Current-Feature test and applicable human-acceptance evidence, with Git revision and working-tree fingerprint; no review counts. |
| `manual-acceptance-checklist.json.tmpl` | Pending manual checks expanded from one Feature; preparation and returned results follow [the file contract](../manual-acceptance-files.md). |
| `progress.md.tmpl` | Current state, blockers, pending decisions, next legal action and a history index; history bodies live separately. |
| `project-rules.md.tmpl` | Project-wide constraints, collaboration and design defaults, with rule strengths, incremental maintenance and links to specialized rules. Copied directly to `docs/project-rules.md`; no game-specific constraints are invented. |
| `feature-learning-summary.md.tmpl` | Concise feedback inside existing Stage 8, including an explicit no-learning outcome. |
| `architecture-overview.md.tmpl`, `architecture-subsystem.md.tmpl` | Optional human-owned module/responsibility/dependency maps and relevant subsystem runtime flows, separate from generated reference facts. |
| `architecture-decision-record.md.tmpl` | Optional rationale for one important technical choice; Feature notes and architecture maps link it without copying its body. |

The authoritative Feature/test field semantics and invariants live in `../02-feature-list-schema.md`; engineering mode semantics live in `../07-engineering-change.md`; test selection and TDD semantics live in `../08-testing-strategy.md`. Project development requires an existing GDD under `../01-product-doc-structure.md#gdd-prerequisite-and-authority`; no template here initializes one.

Architecture maps and ADRs follow [the architecture convention](../10-architecture-overview.md). Create an ADR only when a real decision warrants it, not when copying a project.

Lint metric semantics, the controlled vendor patch and executable contract checks are documented in `../gdscript-lint.md`.


Project configuration is stored in `docs/methodology-config.json`. Use the templates above when a task needs Product, Feature, test or history records.
