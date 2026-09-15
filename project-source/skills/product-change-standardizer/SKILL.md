---
name: product-change-standardizer
description: Owns authorized Product and project terminology writes. Elicits Product intent, plans the current Product and synchronizes impacts on existing Features; later Products remain at document level. Handles meaning-preserving CONTEXT or local terminology edits without creating Features. Discussion alone uses project-clarifier; implementation defects with explicit Product intent use engineering-change-standardizer.
metadata:
  version: 3.0
  triggers:
    - User requests a new Product, feature, Product improvement, behavior change, requirement correction, or a bug whose expected behavior is not already explicit
    - User authorizes recording or updating confirmed project terminology in CONTEXT or Product
    - User says initialize, improve, optimize, add, remove, fix, adjust, or new requirement
    - 用户说「做一个 XXX」「改进」「优化」「增加」「删除」「修复」「调整」或「新需求」
  priority: high
---

# Product change standardizer

## Non-negotiable rules

1. `docs/product.md` and `docs/product/*.md` are the single source of truth for Product behavior; optional `docs/CONTEXT.md` owns shared vocabulary, not additional behavior.
2. Update Product documents before planning or implementation. Handle effects on existing Features, but initially decompose only the current Product under `methodology/02-feature-list-schema.md` **Product-by-Product planning**; later Products remain unplanned until their turn.
3. This workflow is the only Product and CONTEXT writer. Clarifiers, elicitors and sketchers return proposals; this workflow persists them. Meaning-preserving terminology maintenance follows the separate route below, not Product-change planning.
4. Product documents describe **what**, not **how**. Keep technology choices and implementation details in Coding Rules, code, or implementation notes.
5. Never make a Product decision on the user's behalf.

## Language contract

Apply `methodology/05-document-language.md` before preparing durable Product or
CONTEXT wording. Resolve `document_language` from project configuration and pass
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
`methodology/01-product-doc-structure.md`, existing `docs/CONTEXT.md` and only
the relevant Product/code sources. Reuse definitions and explicit decisions
already supplied by the user, `project-clarifier` or an elicitor. Do not repeat
the interview or ask for an approval already given. A discussion-only request
returns to `project-clarifier` without writing files.

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
   optional `docs/CONTEXT.md`; update relevant links within the authorized scope.
   Keep one definition. Do not create an empty CONTEXT or force a complete
   Product when none exists. Do not run UI/audio elicitation, generate/sync
   Features or change their history for this edit.
3. Check the wording against confirmed meanings and preserve existing source
   links/section anchors when moving definitions. Follow
   `agent-rules/00-core/git-worktree-and-commits.md`: inspect only the owned
   documentation diff, run cached-diff checks, and make the local documentation
   commit unless the user requested no commit. For CONTEXT-only work use
   `docs(context): <中文术语摘要>`; no new work item is needed.
4. Report the changed definitions and files, then stop. Steps 1–7 below are for
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
└── ui-mockups/
    └── <exploration>.html
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
- relevant definitions in `docs/CONTEXT.md`, if present
- `docs/feature-list.json`, if present

The overview and lightweight Feature index are sufficient for initial routing.
Expand reading along actual dependencies or unresolved references; do not load
all active modules or Feature details for a local change. The selected planning
workflow loads the additional details it needs.

Choose exactly one route:

Before choosing the route, distinguish Product change from implementation defect:

- If the relevant Product source already states the expected behavior unambiguously and the implementation merely violates it, route to `engineering-change-standardizer` in `bug` mode and stop. Do not rewrite Product documents for an implementation defect.
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

Pass relevant CONTEXT definitions and already confirmed answers to the elicitor.
It asks only remaining questions that materially affect the change and returns
a structured patch. It must not write files or restart a completed interview.
When the supplied facts and decisions already define the change, prepare that
patch directly without invoking another interview.

## Step 4: Complete UI and audio dimensions

Read the existing UI/audio requirements and reuse established decisions.

| Need | Action |
| --- | --- |
| Layout or interaction needs clarification, or a sketch is requested | Use `product-ui-sketcher` for an ASCII wireframe and intent; a simple copy/value change with settled interaction needs no new sketch |
| HTML/Tailwind exploration is requested or has an agreed purpose | Use the sketcher's optional exploration; do not add a routine question about HTML to every UI edit |
| Sound requirements need design or clarification | Use `product-audio-sketcher` with known trigger, style and duration; reuse complete entries and its stable placeholder naming |

Pass the resolved `document_language` and confirmed facts to any child workflow.
These are Product requirements; implementation and actual human acceptance remain separate.

## Step 5: Write Product documents

This workflow performs all writes:

1. **Initialization:** render the canonical overview and module templates into `document_language`.
2. **New module:** create `docs/product/NN-<slug>.md` with the next available module number.
3. **Existing module:** edit only the affected sections; preserve unrelated content.
4. **Overview:** update the module inventory and dependencies when they change.
5. **Change history:** append a dated change and reason to every affected Product file, in `document_language`.
6. **Placeholders:** pass relevant `_placeholder_` asset paths to the current or affected existing Feature plan. Later, unplanned Products retain their placeholder requirements in Product until decomposition.

If the elicitor returns terminology changes, review them with the affected
Product behavior and persist confirmed wording in the owning Product section
or `docs/CONTEXT.md`, following the **Project terminology and CONTEXT** guidance
in `methodology/01-product-doc-structure.md`. Keep one owning definition and
links from relevant modules. Do not treat code observations or unconfirmed
terms as approved intent. CONTEXT accompanies Product changes; it never replaces
the Product behavior that Feature planning needs.

After the approved Product write, follow
`agent-rules/00-core/git-worktree-and-commits.md`: inspect and stage only the
explicit Product and associated CONTEXT paths, run the cached-diff checks, and
create the local Product source commit unless the user explicitly requested no commit. Use
`docs(product): <中文行为摘要>`, omit `Work item` because the downstream Feature
record does not exist yet, and confirm `git status --short` before Feature
synchronization.

Before writing destructive or foundational changes, show their concrete impact
and verify that it is explicitly approved. This includes deleting or obsoleting
a module, changing the target audience or core loop, or invalidating completed
Product behavior. Reuse that approval when already given; ask only about an
unapproved effect or material change.

## Step 6: Synchronize Features

- Read the Product execution order and existing Feature sources/statuses using the **Product-by-Product planning** rule. A new module or a large change does not authorize regenerating the project plan.
- For the current Product without a plan, use `generate-feature-list` to decompose only its approved scope. The first Product may start from an empty ledger; later Products wait until the current Product's required Features are complete and append to the same ledger.
- For changes affecting already planned or completed behavior, use `sync-feature-list` to handle the actual Feature, dependency and test impacts. Do not use synchronization to pre-plan later Products.
- For a later Product with no Feature plan and no impact on existing work, finish the Product-document update and report that its Feature decomposition is deferred. Do not call a planning Skill merely because this document changed.

When a planning workflow is needed, wait for it to finish and inspect its result.
Never report synchronization as successful merely because it was invoked, or
describe a deliberately unplanned Product as fully covered. Preserve completed
Feature history; changed completed behavior creates explicit follow-up work.

## Step 7: Report and hand off

Report:

- Product files created or changed and the intent of each change
- the confirmed `document_language`
- Feature planning/synchronization result, including which later Products remain unplanned
- affected Feature states
- every placeholder resource

Report unresolved Product decisions, if any. Return the completed documents and
plan to the calling workflow; when concrete execution authorization is already
present, continue through `execute-next-feature`. Otherwise stop at the requested
documentation/planning result or ask for the missing decision. This Skill owns
Product writing, while the execution Skill owns implementation and its Gates.

## Boundaries

1. Strip implementation choices from Product intent. Translate a request such as using a particular animation component into its observable transition behavior.
2. Complete Product and applicable Feature planning/synchronization before handing implementation to `execute-next-feature`; preserve any already authorized end-to-end scope.
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
