---
name: product-author
description: Maintain an existing project GDD, organize Product delivery scope, and handle related Feature planning or synchronization. Does not initialize a GDD.
---

# GDD maintenance and Product delivery

## Authority and entry

Use `methodology/01-product-doc-structure.md` for the GDD prerequisite, document ownership, Product structure and templates. The project must already contain actual design content under `docs/gdd/`; an empty directory, purpose notice, Product or code does not substitute for it. If it is missing or unreadable, report the missing input and stop. Do not start an idea interview or initialize a GDD.

Within the current authorization, maintain the existing GDD as the game-design source and Product as delivery scope. Read the actual GDD entry and follow its relevant topic links; preserve its organization instead of imposing a new filename or duplicating its rules. `docs/product.md` maps the agreed scope to delivery units, dependencies and intended order. Only the current unit receives `docs/product/NN-name.md`.

Apply `methodology/05-document-language.md`, the project Git contract and applicable Project Rules/accepted architecture decisions. A file, a commit or observed code behavior does not approve a proposed design. Preserve explicit decisions and authorization; discussion-only requests return a proposal without writes.

## Select the requested result

Read the GDD sections relevant to the request, Product overview, lightweight Feature index and any affected detail/source documents. Follow real dependencies; do not load all future design or all Feature details.

| Requested result | Work to perform |
| --- | --- |
| Pre-split the agreed delivery scope | Create or revise only `docs/product.md`: outcomes, boundaries, GDD mappings, dependencies and order. Do not create every Product file or any Feature plan. |
| Detail the current Product | Revisit the latest GDD and completed work, then write only the current delivery document from the canonical template. Resolve dependencies that affect this delivery without detailing future Products. |
| Change existing game design | Update the owning GDD topics and references first; adjust affected delivery scope and existing plans. |
| Change delivery boundaries or order without changing design | Update Product only; preserve GDD intent and evaluate affected existing Features. |
| Formalize already implemented work | Compare the confirmed GDD with actual behavior; reuse suitable implementation under **Adopting existing implementation** in methodology 02. Records do not establish past approval or completion. |
| Maintain meaning-preserving terminology | Use `project-terminology`; no new Product or Feature plan is needed. |
| Repair an implementation that violates explicit requirements | Return to the unfinished Feature or `engineering-change-plan`; do not rewrite design to justify the defect. |
| Change only a professional specification | Use its owner under methodology 11; coordinate a GDD change only if game design changes. |

A Product is a verifiable delivery unit, not necessarily a complete game system or a GDD chapter. The overview may pre-split several units, but future units retain only their outline there. An authorized GDD change may update future design without producing future Product files.

## Resolve actual gaps

Reuse clear requirements and settled answers. For a material ambiguity in the existing GDD or delivery boundary, use `product-spec-elicitor` with the relevant source sections, requested change, current Product scope and existing decisions. It returns a proposal without writing. A clear change needs no additional elicitation.

Distinguish a design change from a delivery choice. New gameplay rules, states, formulas and version design scope belong in GDD; Product identifies which requirements are being delivered, their boundaries and how they connect to existing work. Technical implementation choices belong in Feature design, architecture or code.

Explain the effect of a foundational change, deletion or invalidation of completed behavior. Obtain only decisions not already covered by the user's concrete authorization. Do not silently remove an adopted requirement or use a speculative default as a confirmed rule.

## Coordinate professional requirements

Under `methodology/11-specialist-workflows.md`, the corresponding Skills maintain UI, art, audio, resource and localization specifications. GDD owns game-design intent; specialists supplement it with their detailed requirements. If GDD already owns a detail, link that section instead of copying it into another authoritative body.

For new interfaces or substantial presentation changes, use **Visual prototype before dependent implementation** in methodology 01. Resource handoffs use its **Resource preparation list and handoff**. Keep real samples, missing inputs and applicable visual/listening acceptance visible. Design documentation does not prove a prototype was operated or accepted.

Pass the confirmed language, relevant facts and existing authorization to supporting work. Return its actual result to this task; a Skill handoff does not create another lifecycle or end authorized delivery.

## Write and validate the sources

Use the Product templates and their semantics from `methodology/templates/README.md` only for the requested Product result. GDD maintenance follows its existing entry/topic structure.

- Update substantive design at its owning GDD location, with relevant links and decision status. Do not maintain a second core loop, system inventory, version scope or rule set in Product.
- In the overview, preserve stable delivery identities and update boundaries, GDD links and dependencies. Future entries need no placeholder files, detailed AC or test registrations.
- When the current Product is ready, create or revise its delivery document with precise source references, inclusions/exclusions, integration boundaries, delivery acceptance scenarios and material gaps. Observable acceptance can restate the result needed for verification, but rule definitions and values remain at their source.
- Preserve existing records and filenames; a collision requires inspecting the actual owner rather than overwriting or allocating a duplicate. Meaning-preserving definitions use `project-terminology`.
- Check source coverage, internal consistency and affected links. Distinguish unreadable material, unadopted proposals, implementation observations and actual user decisions.

Follow `agent-rules/00-core/git-worktree-and-commits.md` for explicit path/hunk staging, cached-diff inspection and validated local commits. Standalone source work uses `docs(product): <中文变更摘要>`; supporting work inside a Feature follows its existing commit boundary. Before initial planning or synchronization, satisfy the committed-source baseline in methodology 02. Report an unmet prerequisite, including a no-commit instruction; do not invent an anchor or absorb unrelated edits.

## Plan, synchronize and continue

Use **Product-by-Product planning** in methodology 02 and the current request to choose the next action:

- A pre-split-only or document-only request ends at that requested result. It does not automatically authorize Feature planning.
- When planning is authorized, detail the current Product first, then use `feature-plan` once to cover its complete necessary scope with multiple Features. Reuse an existing plan rather than regenerate it.
- A substantive source change that affects already planned or completed work uses `feature-sync`. A changed future GDD topic can affect current consumers even when that future Product is unplanned.
- If only future, unplanned scope changes, update GDD and the relevant overview outline; defer its Product document and Features until its turn.
- Finish the current Product's required Features before detailing and planning the next. Revisit the next scope against the latest GDD and delivery results, continuing only within existing authorization.

Inspect actual planning/synchronization results; invocation is not success. Preserve completed history and use follow-up work for changed completed behavior. A failed synchronization leaves an explicit alignment gap.

Report changed sources and delivery scope, validation results, remaining material decisions, planning results when applicable and the next authorized action. Continue implementation through `feature-execute` when authorized, preserving actual human acceptance boundaries.
