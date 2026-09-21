---
name: product-author
description: Create, maintain or formalize Product requirements and confirmed project terminology, then plan the current module or synchronize affected Features. Discussion uses project-clarifier; defects against explicit intent use engineering-change-plan.
metadata:
  version: 4.0
  triggers:
    - User requests a new Product, feature, Product improvement, behavior change, requirement correction, or a bug whose expected behavior is not already explicit
    - User authorizes recording or updating confirmed project terminology in docs/terminology.md or Product
  priority: high
---

# Product standardizer

## Non-negotiable rules

1. `docs/product.md` and `docs/product/*.md` are the single source of truth for Product behavior; optional `docs/terminology.md` owns shared vocabulary, not additional behavior.
2. Update Product documents before planning or implementation. Handle effects on existing Features, but initially decompose only the current Product under `methodology/02-feature-list-schema.md` **Product-by-Product planning**; later Products remain unplanned until their turn.
3. This workflow is the only Product and terminology writer. Clarifiers and Product elicitors return proposals for it to persist. Professional Skills maintain their own sources directly under `methodology/11-specialist-workflows.md`; Product keeps behavior and links. Meaning-preserving terminology maintenance follows the separate route below.
4. Product documents describe **what**, not **how**. Keep local implementation details in Feature design/code, current shared structure in architecture and important technical tradeoffs in ADRs. Only project-wide constraints belong in Project Rules.
5. Preserve confirmed Product decisions and existing concrete authorization; unresolved material intent remains a proposal until decided.
6. Apply relevant `docs/project-rules.md` constraints and accepted architecture decisions before defining Product intent. A conflicting request does not silently revise a rule; use `methodology/04-coding-rules-4-layers.md` **Incremental rule maintenance**, including its pre-write self-check and existing authorization.

## Language contract

Apply `methodology/05-document-language.md` before preparing durable Product or
terminology wording. Resolve `document_language` from project configuration and pass
the confirmed value to any elicitor/sketcher; preserve protocol identifiers and
existing history. Language migration follows that contract within explicit scope.

## Existing implementation route

When asked to formalize already implemented behavior, compare the specified
files, relevant history and user decisions with any existing Product. Separate
confirmed intent, observed behavior, experiments/placeholders and unresolved
choices; only confirmed intent becomes Product. Reuse settled answers instead
of repeating a full elicitation. Record the present formalization in Product
change history without inventing earlier approval or copying code structure.

Use the normal Product writing procedure for missing or changed intent within
the authorized scope. When Product already covers the requested behavior, reuse
it and proceed to Steps 6–7 for missing planning and handoff. Apply **Adopting
existing implementation** in `methodology/02-feature-list-schema.md`; diagnose
implementation gaps against the owning Feature, without rewriting Product to
justify defects. Git ownership still follows the existing preflight contract.

## Terminology maintenance route

For an authorized terminology-only request, read
`methodology/01-product-doc-structure.md`, existing `docs/terminology.md` and only
the relevant Product/code sources. Reuse definitions and explicit decisions
already supplied by the user, `project-clarifier` or an elicitor. Do not repeat
the interview or ask for an approval already given. A discussion-only request
returns to `project-clarifier` without writing files.

This route also supports the current Feature's Stage 3 documentation checkpoint. Reuse that Feature's established task ownership and documentation authorization; a supporting call is not a new clean-worktree task. Return to the caller after updating terminology so authorized implementation/verification continues. For substantive Product changes discovered inside a Feature, preserve current ownership and resolve the affected scope before taking the normal Product/planning route.

Determine whether the proposed edit preserves meaning and behavior. Recording
an agreed concept, clarifying a name, or moving/linking an existing definition
can use this route. If it changes intended behavior, rules, values or AC, or
reveals a material unresolved Product choice, resolve that choice and use
Steps 1–7 with the settled answers instead. Code observations alone cannot
approve a new definition or settle a conflict with Product.

For meaning-preserving edits:

1. Resolve the document language and any remaining ambiguity. Show the concrete
   wording for approval only when the current authorization does not cover it.
2. Write the smallest useful definition in its owning Product section or the
   optional `docs/terminology.md`; update relevant links within the authorized scope.
   Keep one definition. Do not create an empty terminology document or force a complete
   Product when none exists. Do not run UI/audio elicitation, generate/sync
   Features or change their history for this edit.
3. Check the wording against confirmed meanings and preserve existing source
   links/section anchors when moving definitions. Follow
   `agent-rules/00-core/git-worktree-and-commits.md`: inspect only the owned
   documentation diff, run cached-diff checks, and make the local documentation
   commit unless the user requested no commit. Standalone terminology work uses
   `docs(terminology): <中文术语摘要>` and needs no new work item. Inside a Feature, let the owning execution workflow include these edits in its validated logical commit rather than making an isolated source commit or declaring the Feature complete.
4. Report the changed definitions and files, then return to the caller or finish the standalone request. Steps 1–7 below are for
   substantive Product changes, not a required continuation of this route.

## Product structure and templates

Use this stable structure:

```text
docs/
├── product.md
├── product/
│   ├── 01-<module>.md
│   ├── 02-<module>.md
│   └── ...
└── ui/
    └── <interface>-design.md  ← owned by design-ui-spec, linked from Product
```

Follow **Module filename rules** in `methodology/01-product-doc-structure.md` for stable module identities and filenames.

Before writing Product documents, read:

- `methodology/templates/README.md` for the rendering contract
- `methodology/templates/product.md.tmpl`
- `methodology/templates/product-module.md.tmpl`
- `methodology/01-product-doc-structure.md`

Preserve every required section and its semantics. Render human-readable headings and guidance in `document_language`; do not copy canonical English headings into a non-English Product or maintain a localized template tree.

## Step 1: Confirm Product intent

Restate the requested change in one or two sentences. Reuse explicit write
authorization and decisions from the user or `project-clarifier`; do not ask
again just to enter this workflow. If the request is discussion only, return
to `project-clarifier`. If the intended write scope remains unclear, clarify
that scope before persisting content.

## Step 2: Load state and choose a route

Read:

- `docs/methodology-config.json`
- `docs/product.md`, if present
- affected `docs/product/*.md` sections and shared/dependency contracts identified from the overview and requested change, if present
- relevant definitions in `docs/terminology.md`, if present
- applicable `docs/project-rules.md` constraints and relevant architecture/ADR records
- `docs/feature-list.json`, if present

The overview and lightweight Feature index are sufficient for initial routing.
Expand reading along actual dependencies or unresolved references; do not load
all active modules or Feature details for a local change. The selected planning
workflow loads the additional details it needs.

Choose exactly one route:

Before choosing the route, distinguish Product change from implementation defect:

- If a confirmed Product or professional source already states the expected outcome unambiguously and the implementation violates it, use the existing current-Feature repair or independent engineering bug route. Do not rewrite requirements for an implementation defect.
- If only a professional requirement changes while Product behavior stays fixed, route directly to its owning specialist and the applicable impact analysis under `methodology/11-specialist-workflows.md`.
- If the expected behavior is missing, contradictory, or the requested fix intentionally changes observable behavior, continue in this Product workflow.

| State | Condition | Route |
| --- | --- | --- |
| A. Initialization | `product.md` is absent or only a template | `product-init-elicitor` |
| B. New module | The change introduces a module with its own responsibility | `product-spec-elicitor`, new-module mode |
| C. Existing module | The change belongs to one existing module | `product-spec-elicitor`, modification mode |
| D. Product correction | The reported bug exposes missing, contradictory, or changed Product intent | `product-spec-elicitor`, bug mode |
| E. Cross-module | The change affects multiple established modules | `product-spec-elicitor`, cross-module mode |

## Step 3: Run the selected elicitor

For initialization, run `product-init-elicitor` with the user's short description. It returns a complete overview and module draft, while UI wireframes and complete audio entries may remain pending.

For states B through E with material gaps, run `product-spec-elicitor` with:

- the change description
- the selected mode
- current content of every affected module
- the resolved `document_language`

Pass relevant terminology definitions and already confirmed answers to the elicitor.
It asks only remaining questions that materially affect the change and returns
a structured patch. It must not write files or restart a completed interview.
When the supplied facts and decisions already define the change, prepare that
patch directly without invoking another interview.

## Step 4: Complete UI and audio dimensions

Read the existing UI/audio requirements and reuse established decisions.

| Need | Action |
| --- | --- |
| Layout or interaction presentation needs specification | `design-ui-spec` maintains its UI document; Product records behavior and a link. Settled copy/value changes need no new sketch. |
| Shared art or sound direction needs a decision | `design-art-direction` / `design-audio-direction` maintains the professional source within scope; no mandatory whole-game specification. |
| Concrete visual/audio assets need specifications | `design-visual-asset-spec` / `design-audio-asset-spec` maintains the existing resource-list entries with actual sample references and unresolved gaps. |
| A runnable Godot or HTML exploration is requested | Pass the professional inputs to the separately authorized scoped experiment/delivery route; design Skills do not implement it. |

For new interfaces or substantial layout/resource changes, apply **Visual
prototype before dependent implementation** in `methodology/01-product-doc-structure.md`.
Include its relevant questions and constraints in the owning professional sources
and pass the needed visual foundation to current-module planning. Keep confirmed
observable size/readability requirements; put trial values and node-level tuning
in implementation notes. Adopt prototype observations only with the applicable
user decision, preserving still-valid requirements and existing authorization.

When resource preparation needs a user handoff, apply **Resource preparation
list and handoff** in the same specification. Coordinate the responsible specialists'
entries and inspected existing assets in the shared project-local list within
the current writing scope; link it from the task instead of copying its rows into
Product or Feature notes. List preparation alone does not expand Product scope.

Pass the resolved `document_language` and confirmed facts to any child workflow.
Professional source ownership follows `methodology/11-specialist-workflows.md`;
implementation and actual human acceptance remain separate.

## Step 5: Write Product documents

This workflow performs Product writes and necessary references:

1. **Initialization:** render the canonical overview and module templates into `document_language`.
2. **New module:** create `docs/product/NN-<slug>.md` with the next available module number.
3. **Existing module:** edit only the affected sections; preserve unrelated content.
4. **Overview:** update the module inventory and dependencies when they change.
5. **Change history:** append a dated change and reason to every affected Product file, in `document_language`.
6. **Resources:** link the owning professional specifications/resource-list entries and pass concrete requirements, real samples and remaining gaps to the current or affected plan. Do not duplicate the entries or invent missing-file obligations from naming examples. Later Products retain linked specifications without premature Feature decomposition.

If the elicitor returns terminology changes, review them with the affected
Product behavior and persist confirmed wording in the owning Product section
or `docs/terminology.md`, following the **Project terminology** guidance
in `methodology/01-product-doc-structure.md`. Keep one owning definition and
links from relevant modules. Do not treat code observations or unconfirmed
terms as approved intent. Terminology accompanies Product changes; it never replaces
the Product behavior that Feature planning needs.

After the approved Product write, follow
`agent-rules/00-core/git-worktree-and-commits.md`: review the complete authorized,
task-owned documentation change, including associated terminology, new or updated
resource preparation lists and required links. Stage only explicit owned paths
or inspected hunks, run the cached-diff checks and validate the complete logical
change, including its references, before committing.

For standalone Product work, create the local source commit unless the user
explicitly requested no commit. Use `docs(product): <中文行为摘要>` and omit
`Work item` when no Feature owns the change. Supporting documentation inside an
existing Feature stays in its owning execution workflow's validated logical
commit; calling this Skill does not start a new clean-worktree task or require
an isolated source commit. Substantive Product changes still require the approved
impact handling and committed source baseline needed by synchronization.
Check `git status --short` before downstream planning or execution and account
for all task-produced documents; preserve unrelated changes and report any unmet
Git or source-baseline prerequisite, including under a no-commit instruction.

Before writing destructive or foundational changes, show their concrete impact
and verify that it is explicitly approved. This includes deleting or obsoleting
a module, changing the target audience or core loop, or invalidating completed
Product behavior. Reuse that approval when already given; ask only about an
unapproved effect or material change.

## Step 6: Synchronize Features

- Read the Product execution order and existing Feature sources/statuses using the **Product-by-Product planning** rule. A new module or a large change does not authorize regenerating the project plan.
- For the current Product without a plan, use `feature-plan` to decompose only its approved scope. The first Product may start from an empty ledger; later Products wait until the current Product's required Features are complete and append to the same ledger.
- For changes affecting already planned or completed behavior, use `feature-sync` to handle the actual Feature, dependency and test impacts. Do not use synchronization to pre-plan later Products.
- For a later Product with no Feature plan and no impact on existing work, finish the Product-document update and report that its Feature decomposition is deferred. Do not call a planning Skill merely because this document changed.

When a planning workflow is needed, wait for it to finish and inspect its result.
Never report synchronization as successful merely because it was invoked, or
describe a deliberately unplanned Product as fully covered. Preserve completed
Feature history; changed completed behavior creates explicit follow-up work.

## Step 7: Report and hand off

Report:

- Product files created or changed and the intent of each change
- associated documents and required links, including any resource preparation list path, remaining preparation/confirmation needs and project target paths
- the confirmed `document_language`
- Feature planning/synchronization result, including which later Products remain unplanned
- affected Feature states
- every placeholder resource

Report unresolved Product decisions, if any. Return the completed documents and
plan to the calling workflow; when concrete execution authorization is already
present, continue through `feature-execute`. Otherwise stop at the requested
documentation/planning result or ask for the missing decision. This Skill owns
Product writing, while the execution Skill owns implementation and its Gates.

## Boundaries

1. Strip implementation choices from Product intent. Translate a request such as using a particular animation component into its observable transition behavior.
2. Complete Product and applicable Feature planning/synchronization before handing implementation to `feature-execute`; preserve any already authorized end-to-end scope.
3. Resolve ambiguous Product decisions through the appropriate elicitor.
4. Always assess substantive changes against existing Features. Current Product decomposition and actual impacts on planned work need the appropriate planning route; a later, unplanned Product remains at document level. Meaning-preserving terminology maintenance also omits planning.
5. Never silently edit a completed Feature. Create follow-up work or use the synchronization workflow's explicit lifecycle rules.
6. Require confirmation before deleting modules, invalidating completed behavior, or changing foundational positioning.
7. Do not let a conversation-language change rewrite or gradually mix durable Product language.

## Failure handling

- If the user rejects an elicitor draft, do not persist it; return to the elicitor for focused clarification.
- If Feature synchronization fails, report the failure and do not leave Product and Feature state presented as aligned. Offer a reviewable repair or Git rollback; never perform a destructive rollback automatically.
- If a destination module filename already exists, stop and ask whether to merge, choose a new module boundary, or use the next valid number. Never overwrite silently.
- If a child workflow returns durable prose in the wrong language, re-render it in `document_language` before writing. Preserve approved meaning and reuse existing authorization; ask only if the correction introduces a material meaning choice.

For substantive Product changes, preserve this order within the authorized scope:

**Product documents first → applicable current-Product planning or existing-Feature synchronization → implementation last.** Later, unplanned Products stop at the document update until their turn.
