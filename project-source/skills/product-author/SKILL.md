---
name: product-author
description: "Organize Product delivery scope from current GDD sources and coordinate authorized Feature planning or synchronization. Use for `docs/product.md` and the current Product document. Not for game design or GDD writing (design-gdd)."
---

# Product delivery authoring

## Authority and entry

Use `methodology/01-product-doc-structure.md` for the GDD prerequisite, document ownership, Product structure and templates. Product delivery needs actual GDD content covering its scope; an empty directory, purpose notice, Product or code does not substitute for it. If that design is missing or unresolved, return the design work to `design-gdd` within the current authorization before preparing the dependent Product. An unrelated unfinished GDD topic does not block a sufficiently defined delivery.

Within the current authorization, maintain Product as delivery scope and reference GDD as the game-design source. Read the actual GDD entry and follow its relevant topic links without duplicating its rules. `docs/product.md` maps the agreed scope to delivery units, dependencies and intended order; apply **Delivery outcomes and prerequisites** in methodology 01 when judging those boundaries. Only the current unit receives `docs/product/NN-name.md`.

Apply `methodology/05-document-language.md`, the project Git rules, the relevant Project Rules and accepted architecture decisions. A file, a commit or observed code behavior does not approve a proposed design. Preserve explicit decisions and authorization; discussion-only requests return a proposal without writes.

## Select the requested result

Read the applicable **Design scope and boundaries** and **Open design questions** under `methodology/01-product-doc-structure.md`, relevant GDD topics, Product overview, lightweight Feature index and any affected detail/source documents. Use relevant open questions to identify unresolved delivery prerequisites and link them from the affected Product section; do not resolve a game rule by choosing a delivery default. Follow real dependencies; do not load all future design or all Feature details.

| Requested result | Work to perform |
| --- | --- |
| Pre-split the agreed delivery scope | Create or revise only `docs/product.md`: outcomes, boundaries, GDD mappings, dependencies and order. Do not create every Product file or any Feature plan. |
| Detail the current Product | Revisit the latest GDD and completed work, then write only the current delivery document from the canonical template. Resolve dependencies that affect this delivery without detailing future Products. |
| Change game design | Return to `design-gdd`, or `design-balance` for an authorized explicit numeric topic; after the owning design changes, adjust affected delivery scope and existing plans. |
| Change delivery boundaries or order without changing design | Update Product only; preserve GDD intent and evaluate affected existing Features. |
| Formalize already implemented work | Compare the confirmed GDD with actual behavior; reuse suitable implementation under **Adopting existing implementation** in methodology 02. Records do not establish past approval or completion. |
| Maintain meaning-preserving terminology | Use `project-terminology`; no new Product or Feature plan is needed. |
| Repair an implementation that violates explicit requirements | Return to the unfinished Feature or `engineering-change-plan`; do not rewrite design to justify the defect. |
| Change only a professional specification | Use its owner under methodology 11; coordinate a GDD change only if game design changes. |

A Product is a verifiable delivery unit, not necessarily a complete game system or a GDD chapter. The overview may pre-split several units, but future units retain only their outline there. A GDD change does not automatically require future Product files.

## Resolve actual gaps

Reuse clear requirements and settled answers. For a material ambiguity in delivery boundaries, order or integration, use `product-spec-elicitor` with the relevant source sections, requested change, current Product scope and existing decisions. It returns a proposal without writing. An unresolved game rule returns to `design-gdd`; numeric design within settled gameplay belongs to `design-balance`. A clear change needs no additional elicitation.

Distinguish a design change from a delivery choice. New gameplay rules, states, formulas and version design scope belong in GDD; Product identifies which requirements are being delivered, their boundaries and how they connect to existing work. Implementation decisions and rationale use the fixed Feature design, ADR or standalone-decision owner under methodology 10; current structure belongs in architecture and executable behavior in code.

Explain the effect of a foundational change, deletion or invalidation of completed behavior. Obtain only decisions not already covered by the user's concrete authorization. Do not silently remove an adopted requirement or use a speculative default as a confirmed rule.

## Coordinate professional requirements

Presentation, UI, art, audio, resource and localization specifications have fixed owners under `methodology/11-specialist-workflows.md`; a specification first written in GDD still belongs to its professional owner, as that file explains. Link game rules and goals at their GDD source without copying them.

For new interfaces or substantial layout or resource changes, use **Visual prototype before dependent implementation** in `methodology/13-prototypes.md`. Presentation planning uses `design-game-presentation`; prototype a presentation only when a concrete uncertainty needs runtime evidence. Resource handoffs use **Resource requirements and handoff** in `methodology/11-specialist-workflows.md`. Keep real samples, missing inputs and applicable visual/listening acceptance visible. Design documentation does not prove a prototype was operated or accepted.

Pass the configured document language, relevant facts and the current authorization to supporting work, and continue this task with its actual result.

## Write and validate the sources

Use the Product templates and their semantics from `methodology/templates/README.md` only for the requested Product result.

- Reference substantive design at its owning GDD location and preserve its decision status. Do not maintain a second core loop, system inventory, version scope or rule set in Product; return required source changes to the design owner.
- In the overview, preserve stable delivery identities and update boundaries, GDD links and dependencies. Future entries need no placeholder files, detailed AC or test registrations.
- When the current Product is ready, create or revise its delivery document with precise source references, inclusions/exclusions, integration boundaries, delivery acceptance scenarios and material gaps. Observable acceptance can restate the result needed for verification, but rule definitions and values remain at their source.
- Apply **Delivery decision ownership** in methodology 01 to unresolved choices. When detailing a candidate or changing a question's scope, move its body to the prescribed owner and update references in the same edit; do not leave parallel open-question bodies in the overview and detail.
- Preserve existing records and filenames; a collision requires inspecting the actual owner rather than overwriting or allocating a duplicate. Meaning-preserving definitions use `project-terminology`.
- Check source coverage, internal consistency and affected links. Distinguish unreadable material, unadopted proposals, implementation observations and actual user decisions.

Follow `agent-rules/00-core/git-worktree-and-commits.md` for staging only this task's paths or hunks and for validated local commits. Standalone source work uses `docs(product): <中文变更摘要>`; supporting work inside a Feature follows its existing commit boundary. Before initial planning or synchronization, satisfy the committed-source baseline in methodology 02. Report an unmet prerequisite, including a no-commit instruction; do not invent an anchor or absorb unrelated edits.

## Plan, synchronize and continue

Use **Product-by-Product planning** in methodology 02 and the current request to choose the next action:

- A pre-split-only or document-only request ends at that requested result. It does not automatically authorize Feature planning.
- When planning is authorized, detail the current Product first, then use `feature-plan` once to cover its complete necessary scope with multiple Features. Reuse an existing plan rather than regenerate it.
- A substantive source change that affects already planned or completed work uses `feature-sync`. A changed future GDD topic can affect current consumers even when that future Product is unplanned.
- If only future, unplanned scope changes, reflect the owning design result in the relevant overview outline; defer its Product document and Features until its turn.
- Finish the current Product's required Features before detailing and planning the next. Revisit the next scope against the latest GDD and delivery results, continuing only within the current authorization.

Inspect actual planning/synchronization results; invocation is not success. Preserve completed history and use follow-up work for changed completed behavior. A failed synchronization leaves an explicit alignment gap.

Report changed sources and delivery scope, validation results, remaining material decisions, planning results when applicable and the next authorized action. Continue implementation through `feature-execute` when authorized, preserving actual human acceptance boundaries.
