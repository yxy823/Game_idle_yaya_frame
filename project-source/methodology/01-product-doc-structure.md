# 01 · Product document structure

## Two-level structure

```text
docs/
├── product.md              ← Scannable Product overview
└── product/
    ├── 01-<core-module>.md ← Detailed module specification
    ├── 02-<other>.md
    └── ...
```

The two levels serve different context needs. `product.md` must remain short enough to scan as a whole, while module documents provide detail on demand. A person or agent should understand the Product shape in about 30 seconds and enter one module in a few minutes.

Generated headings and prose must follow the project's configured `document_language`; the section semantics below must remain intact in every language. See [05-document-language.md](./05-document-language.md).

## Standard `product.md` sections

Write these sections in this order. A document rendered from the canonical template must preserve every template section; when a section does not apply, retain its heading and state that it is not applicable. A project may add specialized sections, but the standard semantics must remain easy to locate.

| Section semantics | Required? | Content |
| --- | --- | --- |
| Title and version summary | Yes | Current version plus a one-sentence description of that version's complete loop. |
| One-line positioning | Yes | A sentence that makes the Product and its complete short experience immediately understandable. |
| Target users | Yes | Primary users, usage context, and expected frequency. An MVP may target maintainer self-testing. |
| Core loop | Yes | A numbered, coherent action sequence for each version such as V0.1 or V0.2. |
| Module list | Yes | Number, filename, module name, and `draft`, `done`, or `obsolete` status. |
| Module dependencies | Yes | An ASCII dependency diagram and intended Product execution order, with cross-cutting modules identified separately. |
| Visual direction | Recommended | Palette, typography, and UI tone used as input to UI sketches. |
| Audio direction | Recommended | Sound-effect and music direction used as input to audio entries. |
| Change history | Yes | Reverse-chronological date, Product change, and reason. |

## Standard `product/NN-name.md` sections

The overview may describe later modules without allocating their Features.
Decompose only the current Product and complete its required Features before
decomposing the next; see [Product-by-Product planning](02-feature-list-schema.md#product-by-product-planning).
Revisit the next module's scope before planning it. Module-document status and
file numbers do not establish implementation completion or override dependencies.

A module document is more detailed than the overview. A rendered template must retain its standard headings and explicitly mark inapplicable sections rather than deleting them. Optional additions such as Version evolution may be included when useful, but unrelated concerns must not be collapsed in a way that hides Product behavior.

| Section semantics | Content |
| --- | --- |
| Module positioning | The module's role and the modules or actors it interacts with. |
| Version evolution (optional) | How the module changes across V0.x releases. |
| Functional flow | Step-by-step user or system behavior, optionally with an ASCII diagram. |
| Data model | Field, type, default value, and meaning. |
| State machine | State values and transition rules, when applicable. |
| UI sketch | ASCII wireframe and key interactions, produced by `product-ui-sketcher`. |
| Audio entries | Trigger, filename, style, and duration, produced by `product-audio-sketcher`. |
| Numeric rules | Formulas, thresholds, and configuration values. |
| Acceptance criteria | Concrete statements of how completed behavior can be verified. |
| Edge cases | Known cases intentionally deferred to later Features. |
| Change history | Reverse-chronological record of changes to this module. |

## Project terminology and CONTEXT (optional)

Clarify vocabulary when competing names or meanings would change a Product
decision. Read existing definitions first. If one word describes different
concepts, distinguish them using familiar names; if several words mean the same
thing, propose one consistent name. Reuse an already clear definition instead
of starting a glossary for every task.

Test the distinction with a concrete scenario. For example, when discussing
inventory, distinguish an item definition, an owned item and a stack only if
their identity or behavior differs. Whether two items with different modifiers
can stack exposes a real decision; listing every possible item attribute does
not. Record any resulting behavior in the flow, data model or AC that owns it.

When implementation exists, compare the relevant code with the stated meaning.
Surface conflicts with both sources: code describes what happens today and
cannot silently redefine approved intent. A new meaning remains a proposal
until the user resolves the material Product choice.

Keep a definition local to a Product module when its positioning or data model
already explains it sufficiently. Use `docs/CONTEXT.md` for confirmed project
vocabulary needed across modules, Features or conversations. Create it only
when there is useful content to retain; an empty project does not receive a
blank glossary. Missing CONTEXT never blocks discussion or development.

CONTEXT is a compact vocabulary reference, not another Product specification:

- Begin with a short description of the domain covered when it helps orient
  the reader, then give each term a name and a one- or two-sentence definition.
- Explain necessary conceptual relationships, aliases or commonly confused
  neighbors only when they prevent a real misunderstanding.
- Link to the owning Product section for detailed rules, flows, values, state
  transitions and AC. Keep implementation state ownership, Godot classes,
  storage formats and technical choices in architecture records or code.
- Keep pending ideas, chat logs, current progress and task-local notes out of
  CONTEXT. Reuse existing definitions; when moving one here, replace authorized
  duplicates with links rather than keeping competing copies. Preserve section
  anchors used by existing Feature sources, leaving a link at the old location.

`project-clarifier` and Product elicitors return proposed wording;
`product-change-standardizer` alone writes approved Product and CONTEXT content.
Pure terminology maintenance preserves meaning and behavior: it may clarify a
name, record an already agreed distinction, or move/link a definition. It does
not require Product initialization, a new Feature, or Feature synchronization,
even when a local Product definition or link is edited. If a definition changes
actual intent or exposes a material unresolved behavior, resolve that decision
and use the normal Product-change and Feature synchronization route.

Read relevant CONTEXT definitions during clarification, planning, implementation
and review when the file exists. Follow `document_language`, preserve stable
IDs, and do not rename code or migrate saved data merely to align terminology.

## Module filename rules

- Use a two-digit prefix and a kebab-case ASCII slug, such as `01-pawn-core.md`, `02-map.md`, or `13-mining.md`.
- Numbers are stable identities, not execution order. Initial allocation may follow known dependencies; planning and execution follow the overview's current dependencies and intended order.
- Once assigned, module numbers must not be reordered. New modules use the next available number, including a new prerequisite of an existing module.
- An obsolete module must be renamed with the `_obsolete-` prefix rather than deleted, preserving traceability.

## Version convention

- Use `V<MAJOR>.<MINOR>`, such as `V0.9`.
- Keep MAJOR at `0` during the MVP phase; increment it for the first formal release.
- Increment MINOR when the user-observable core loop expands.
- Small changes within the same loop remain in the current version rather than creating a new version number.

## When to create a module

- **Create a module** when a new system has its own data model and an independent interaction entry point.
- **Extend an existing module** when new behavior, values, or UI remain within that module's established responsibility.

When the boundary is unclear, use `product-change-standardizer`; it owns the routing decision.

## Anti-examples

- Do not put implementation choices such as a vector type or pathfinding algorithm in Product documents. Those choices belong in Coding Rules, code, or implementation notes.
- Do not describe numeric behavior with subjective terms such as “high damage”; provide a formula or concrete value.
- Do not use subjective acceptance language such as “renders smoothly”; state an observable threshold or outcome.
- Do not put speculative future ideas in active Product requirements. Keep them in a separate `docs/ideas.md` until approved as Product intent.
