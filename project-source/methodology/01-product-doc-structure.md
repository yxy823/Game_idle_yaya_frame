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

Before writing or revising Product intent, check applicable hard constraints in `docs/project-rules.md` and relevant accepted architecture decisions. A Product request does not silently amend a project rule. Resolve conflicts through [project rule maintenance](04-coding-rules-4-layers.md#incremental-rule-maintenance); keep behavior in Product and rule-change rationale in its owning record.

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
| Visual direction | Recommended | Product experience goals and links to the applicable Art Bible/UI specifications; undecided style remains a proposal. |
| Audio direction | Recommended | Product feedback goals and links to the Sound Bible/resource specifications. |
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
| UI sketch | Player actions and behavior, with links to the interface specification maintained by `design-ui-spec` and relevant prototype conclusions. |
| Audio entries | Behavioral triggers and feedback intent, with links to specifications maintained by `design-audio-asset-spec`; avoid copying resource rows. |
| Numeric rules | Formulas, thresholds, and configuration values. |
| Acceptance criteria | Concrete statements of how completed behavior can be verified. |
| Edge cases | Known cases intentionally deferred to later Features. |
| Change history | Reverse-chronological record of changes to this module. |

## Visual prototype before dependent implementation

Professional documents are maintained directly by their owning Skills under
[Specialist work and sources](11-specialist-workflows.md). Product keeps behavioral
intent and useful references, not duplicate UI, art or audio specifications.

For a new interface or a substantial layout/resource change, establish its visual
foundation before implementing logic that depends on that interface. Reuse an
already validated layout when it covers the current scope; copy/value changes,
non-visual logic and unaffected modules do not require another prototype.
Work on the current interface/module, including its surrounding screen context,
rather than waiting for all game art or all future screens to be ready.

The sequence is: interface purpose and main states → representative resources
and initial specifications → independent Godot visual prototype → layout/scale
validation and adjustment → dependent production logic → visual refinement.
Resource specifications and layout may iterate together.

The Agent identifies this need during planning and resource preflight, or the
user may request a prototype directly. This is task reasoning, not a background
trigger. Discussion-only work proposes the next step without writing or building;
existing implementation authorization covers in-scope preparation and execution,
but never supplies the user's actual visual acceptance.

### Scope and resources

Before building, identify the questions to settle, the target viewport/window
and relevant scaling conditions, core elements/states, available resources and
remaining gaps. The relevant specialist Skills specify these inputs; a written sketch
or HTML exploration does not verify the Godot result.
When resources need a preparation handoff, use the
[resource preparation list](#resource-preparation-list-and-handoff) below.

Use representative real images, fonts, video, music and sound effects where the
interface calls for them. Select samples that expose actual aspect ratios,
detail, text lengths and content density; do not require every media type or the
complete asset library. Distinguish source pixel dimensions, on-screen size and
visible subject size after transparent padding. For audio, identify duration,
looping and feedback timing relevant to the experience. Follow existing asset
provenance and import rules. A missing sample leaves that check unverified;
identify the gap and seek a suitable sample or an explicitly accepted substitute,
rather than claiming that text, silence or a placeholder filename proves it.

Create a clearly named, independently runnable `.tscn` in the project's existing
scene organization, separate from production functionality. Include the actual
content regions, representative items, buttons and text in their surrounding
layout. Use local sample state and only interactions needed for evaluation,
such as hover/pressed/selected/disabled feedback, opening a panel, scrolling or
preview playback. Do not connect production business/game rules, persistence
or live data flows. If project Autoloads would run those flows, isolate the
prototype entry from their side effects. A small local script is sufficient
when native controls cannot express the required feedback.

Final backgrounds, decoration and palette are optional at this point; readable
contrast and distinguishable interaction states are necessary for evaluation.
Avoid a fixed number of design variants: compare alternatives only when a real
layout decision needs them.

### Validation and adoption

Run the scene in the target project's confirmed Godot environment. Check spatial
relationships, resource scale/cropping, text readability, button usability and
relevant empty/dense/long-text states at the agreed display conditions. Exercise
interactions and listen to relevant samples. Static checks and screenshots are
supporting evidence, not substitutes for actual operation and human judgment.
Missing execution or human feedback remains explicitly unverified.

Keep the entry scene, questions, observations, a link to any resource preparation
list and file disposition in current Feature notes, or Progress for a standalone
experiment. Keep resource details in that list when present. Confirmed
behavior changes belong in Product via `product-author`; professional
layout, size, readability or sound requirements belong in their owning specialist
source. Adoption uses the applicable authorization and source-impact route.
Node properties and tuning values remain in the scene, resources or implementation
notes. Do not maintain a second specification or prototype status ledger.

During planned delivery, use an ordinary Feature for an independently reviewable
visual foundation and make dependent implementation wait for its applicable
manual acceptance. A narrow check may stay inside the current Feature, with
the visual decision settled before dependent logic. An explicitly requested
standalone exploration follows the scoped-experiment route in
[task routing](00-overview.md#canonical-task-routing). Prototype acceptance covers
only its visual/interaction scope, never the later business behavior.

After validation, reuse suitable layout nodes, themes and resources deliberately;
remove sample-state wiring when adopting them into production. Retain a separate
prototype only while it answers an ongoing question; otherwise archive or remove
it within the authorized scope. Record unresolved limits and keep the accepted
decisions, without maintaining competing production and prototype interfaces.

## Resource preparation list and handoff

Create or update a project-local Markdown list when the user requests one or
the authorized task needs the user to prepare/reuse resources before a prototype
or implementation. Prefer an existing list covering the same scope; otherwise
use `docs/resource-requirements/<scope>.md`, such as
`inventory-visual-prototype.md`. Do not create empty lists in blank projects or
one list per Feature by default. Several Features may reference the same list.
The responsible specialist maintains its entries; the current task coordinates
shared uses without a separate registry or a Product-writing intermediary.

Read the current task, confirmed Product and professional requirements, relevant
existing assets and any supplied source locations. `design-visual-asset-spec` and
`design-audio-asset-spec` maintain their domain entries in the same list. Include only
the minimum files needed for this scope, merging repeated uses of one resource.
Do not add future decoration or separate files for states that existing themes
or procedural presentation can already express. Record unknown inputs rather
than inventing resources, styles, dimensions or other technical requirements.

The document follows `document_language` and contains a brief scope/source overview,
a resource file table and unresolved questions. Keep these nine core fields in
the table; longer specifications may live in details keyed by resource ID:

| Field | Meaning |
| --- | --- |
| Resource ID | Unique within the list, e.g. `RES-001`; preserve IDs when revising it, and include the list path for cross-list references. No global counter. |
| Resource filename | Semantic name with full extension when the format is known. Preserve reusable filenames; mark suggested names as proposals. If format is unresolved, mark the extension pending or show labeled alternatives. |
| Resource type | The actual needed kind: image, icon, character/UI art, texture, animation, audio, video, font, model or another task-specific resource. |
| Purpose | The task use and any shared uses that avoid duplicate preparation. |
| Pixel dimensions | Width × height where applicable; distinguish required dimensions from measurements of an existing file. |
| Style | Confirmed visual/audio direction, or pending; do not invent a final palette. |
| File format | Confirmed requirement or observed existing format, consistent with the filename; unresolved choices remain pending. |
| Preparation status | Plain factual wording such as pending decision, to prepare, supplied/uninspected or inspected for reuse; never a substitute for Feature completion or human acceptance. |
| Notes | Only applicable constraints, e.g. transparency, aspect ratio, animation frames/duration, audio sample rate/looping or model requirements. |

For each entry, include **source/actual location**, **project target path** and
**expected display size or relative scale** in Notes or its ID-linked details.
Identify missing sources and proposed target paths explicitly; reuse the project's
organization. Runtime assets stay outside ignored documentation folders. Link
existing provenance records where relevant rather than duplicating them.

Use distinct labels for **pending confirmation** (applicable but unknown),
**not applicable**, **proposed value** and **measured value**. A non-final sample
can be sufficient for the current prototype; state what it represents and what
remains to be replaced. Do not turn every optional technical parameter into a
blocking question. Missing information does not prevent drafting the useful list.

Product owns behavioral intent; professional sources own their confirmed design
requirements; the list owns local specifications, preparation details and file
mapping; scenes/resources own implementation settings. Link the applicable list
entries from Feature AC/design, with notes or Progress providing navigation.
Do not hide binding requirements solely in process-only notes or copy entire rows.
A resource analysis alone does not change intent or create Features. Material
changes follow the owning source's route in `11-specialist-workflows.md`.

Hand off the list with the missing files/specifications and their destination
paths so the user can create, reuse or supply them. Pause only work that needs
unavailable resources, subject to the current task's continuation boundaries.
If resources already suffice, continue authorized work without a ceremonial wait.
When files arrive, inspect their actual content and applicable format, dimensions
or duration; filenames and user-reported copying alone do not establish fit.
Update the same list and retain unresolved gaps. Copy/import only within the
authorized scope, preserving source files and unrelated project content, then
continue the prototype and its actual operation/listening checks. List completion,
file presence, successful import and visual/audio acceptance are separate facts.

## Project terminology (optional)

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
already explains it sufficiently. Use `docs/terminology.md` for confirmed project
vocabulary needed across modules, Features or conversations. Create it only
when there is useful content to retain; an empty project does not receive a
blank glossary. Missing terminology never blocks discussion or development.

`docs/terminology.md` owns confirmed domain vocabulary and a shared language across requirements, design, code and discussion. It is not a general project-context document. Do not create a second `UBIQUITOUS_LANGUAGE.md` or parallel glossary. Retain definitions that will be reused beyond this discussion and prevent a real ambiguity; stable means currently agreed, not immutable.

Use a compact structure, expanding only where a distinction needs explanation:

- Begin with a short description of the domain covered when it helps orient
  the reader, then give each term a canonical name and definition, normally one or two sentences. Include domain actions as well as nouns when their meanings matter. Necessary distinctions may take more space; there is no word or term quota.
- Explain necessary conceptual relationships, aliases or commonly confused
  neighbors only when they prevent a real misunderstanding.
- Link to the owning Product section for detailed rules, flows, values, state
  transitions and AC. Keep implementation state ownership, Godot classes,
  storage formats and technical choices in architecture records or code.
- Keep pending ideas, chat logs, current progress and task-local notes out of
  terminology. Reuse existing definitions; when moving one here, replace authorized
  duplicates with links rather than keeping competing copies. Preserve section
  anchors used by existing Feature sources, leaving a link at the old location.

`project-clarifier` and Product elicitors return proposed wording;
`product-author` alone writes approved Product and terminology content.
Pure terminology maintenance preserves meaning and behavior: it may clarify a
name, record an already agreed distinction, or move/link a definition. It does
not require Product initialization, a new Feature, or Feature synchronization,
even when a local Product definition or link is edited. If a definition changes
actual intent or exposes a material unresolved behavior, resolve that decision
and use the normal Product-change and Feature synchronization route.

Read relevant terminology definitions during clarification, planning, implementation
and review when the file exists. Follow `document_language`, preserve stable
IDs, and do not rename code or migrate saved data merely to align terminology.

### Incremental terminology maintenance

Check new terms, renames, retirements and clarified meanings during Product work and at the Stage 3 documentation checkpoint before final verification. If there is no useful change, do not write or produce an empty report. Reuse existing documentation authorization for settled, meaning-preserving changes; discovering a new material Product choice does not approve it.

Add confirmed definitions, merge duplicates and repair references. For a rename, retain an old name only while it helps readers find the canonical term. For retirement, retain a replacement link when historical references need it; otherwise remove obsolete wording within scope. Resolve semantic changes in the owning Product/design workflow first and synchronize affected work. Keep the current definitions here and the change rationale in Product history, Feature design, ADR or Git as appropriate, not a growing glossary change log. A known code identifier may be recorded as an alias without authorizing code or save-data migration.

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

When the boundary is unclear, use `product-author`; it owns the routing decision.

## Anti-examples

- Do not put implementation choices such as a vector type or pathfinding algorithm in Product documents. Those choices belong in Project Rules, code, or implementation notes.
- Do not describe numeric behavior with subjective terms such as “high damage”; provide a formula or concrete value.
- Do not use subjective acceptance language such as “renders smoothly”; state an observable threshold or outcome.
- Do not put speculative future ideas in active Product requirements. Keep them in a separate `docs/unadopted-ideas.md` until approved as Product intent.
