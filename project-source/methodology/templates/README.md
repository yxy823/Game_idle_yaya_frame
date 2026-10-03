# Methodology templates

These templates give the structure of files and fixed reply formats that the workflow creates later, such as a Product, a Feature detail or an ADR. They are the single structural source; there are no localized copies.

The project's starting ledgers (`docs/feature-list.json`, `docs/feature-list-revisions.json`, `docs/test-registry.json`, `docs/progress.md` and `docs/project-rules.md`) are not templates. Project creation copies them directly into `docs/`, and the project maintains them from then on.

## Rendering a template

1. Read `document_language` from `docs/methodology-config.json` and resolve it under [document language](../05-document-language.md).
2. Keep machine keys, enum values, IDs, paths, command strings and placeholders exactly as written.
3. Write human-readable headings and prose in `document_language`. Keep every required section and constraint.
4. Do not create a parallel tree of localized templates.

Lines in *italics* are instructions to replace with project content; everything else is structure to keep. Write Markdown prose as natural paragraphs without fixed-width wrapping, and keep the line breaks that lists, tables, code and diagrams need. Do not reflow JSON or other structured templates.

## Templates

| Template | Produces |
| --- | --- |
| `product.md.tmpl` | `docs/product.md`: delivery pre-decomposition, GDD source mapping, boundaries, dependencies and suggested order |
| `product-module.md.tmpl` | One `docs/product/NN-<delivery>.md`: the current Product's delivery scope, source links, integration and acceptance scenarios. Written only when that Product's turn arrives |
| `feature-detail.json.tmpl` | A Product-derived Feature detail. It has no `engineering_change` field |
| `engineering-feature-detail.json.tmpl` | A Bug, refactor or maintenance Feature detail, with the required `engineering_change` field |
| `feature-design.md.tmpl` | Optional outline for `docs/features/F0XX-design.md`. Use only the sections that help; AC and test obligations stay in the Feature JSON |
| `feature-completion-evidence.json.tmpl` | `docs/feature-completion-evidence.json`: the current Feature's test runs and, when required, its human acceptance, each tied to a Git revision and working-tree fingerprint. Reviews are not recorded here |
| `manual-acceptance-checklist.json.tmpl` | The pending manual checks for one Feature, prepared and returned under the [manual acceptance file contract](../contracts/manual-acceptance-files.md) |
| `feature-learning-summary.md.tmpl` | The reply format for Stage 8 learning feedback, including an explicit "nothing learned" outcome. It is not saved as a file |
| `architecture-overview.md.tmpl`, `architecture-subsystem.md.tmpl` | Optional `docs/architecture.md` and subsystem maps: modules, responsibilities, dependencies and relevant runtime flows, kept separate from generated reference facts |
| `architecture-decision-record.md.tmpl` | An optional ADR for one important technical choice. Feature notes and architecture maps link to it instead of copying it |

Field meanings and validation rules live in [the Feature list schema](../02-feature-list-schema.md), engineering Feature rules in [engineering change](../07-engineering-change.md), and test selection in [test traceability and evidence](../08-test-traceability-and-evidence.md). Architecture maps and ADRs follow [the architecture convention](../10-architecture-overview.md); create an ADR only for a real decision.
