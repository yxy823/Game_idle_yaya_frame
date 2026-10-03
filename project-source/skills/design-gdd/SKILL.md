---
name: design-gdd
description: "Develop game ideas and co-create, draft, revise or consolidate GDD design. Use for overall game design from an idea, a conversation or existing material. Not for Product delivery planning (product-author), numeric modeling (design-balance) or independent review."
---

# Game design and GDD authoring

Turn an idea, an ongoing design conversation or existing material into useful game design. Concept exploration, co-creation, drafting, revision and consolidation are parts of this same capability. Match the depth to the requested outcome and project stage; a useful concept draft need not settle every implementation detail.

## Scope and authority

Use `methodology/01-product-doc-structure.md` for GDD authority and its relationship to delivery. This Skill may begin from an idea without an existing GDD, Product or Feature. Own positioning, intended experience, core loops, rules and system relationships, content progression, game-version scope and corresponding design requirements in `docs/gdd/`.

Read the relevant existing design and concrete user decisions before changing them. Follow **Design scope and boundaries** in `methodology/01-product-doc-structure.md`, then the affected topics and necessary dependencies. Check applicable engineering constraints in Project Rules when they affect the proposed design. Reuse clear requirements; ask only about a material unresolved choice. A direct drafting request does not require an interview, and a discussion-only request does not authorize file writes.

Name GDD files under **GDD document names** in methodology 01; that section also covers imported or differently organized GDDs. The entry `docs/gdd/README.md` links the actual topics, including `design-scope-and-boundaries.md` and `open-questions.md`. Filenames stay fixed even when only some topics have content. Write titles and prose in the configured `document_language` (`methodology/05-document-language.md`) without translating the filenames.

Keep proposals, adopted decisions and verification evidence distinguishable. Save each proposal at the owner chosen by **Candidate and unadopted ideas** in methodology 01; this Skill maintains those destinations within its writing authority. Saving a draft does not adopt its proposals or silently replace an adopted rule. Adoption does not establish that the game is balanced, understandable or enjoyable. Mark a useful working assumption and link its open question instead of inventing missing facts.

## Read only the needed design methods

| Current need | Reference |
| --- | --- |
| Find or compare gameplay directions; identify a useful validation question | [Concept exploration](references/concept-ideation.md) |
| Co-create through questions, answers and successive drafts | [GDD dialogue](references/gdd-dialogue.md) |
| Draft a full GDD or judge coverage for its current stage | [Design coverage](references/gdd-fields.md) |
| Organize or revise the entry, topic pages and rule ownership | [Design document structure](references/design-docs.md) |
| Consolidate notes or resolve conflicting design sources | [Material consolidation](references/consolidation.md) |

These references support the current design task; they are not a mandatory sequence. When asking questions, use the [shared questioning method](../project-grill-me/SKILL.md#shared-questioning-method) without starting `project-grill-me`'s separate workflow.

## Maintain the design at its source

Describe each affected mechanism through its purpose, trigger, input, state, result and meaningful boundaries. Use a representative play sequence when it helps connect the player's goal, action, feedback and progress. Under the logic/presentation model in `docs/game-organization.md`, GDD still owns both overall rules and experience goals; distinguish the valid game result from how the player perceives it. Distinguish rule acceptance scenarios from experience hypotheses that need observation or play.

Keep one owning location for each rule. Update the affected text and references when a decision changes, rather than leaving a contradictory rule and appending a correction. Sources can inform different claims: observed implementation is evidence of current behavior, not automatic authority over adopted design. An unresolved conflict retains its sources and impact while independent work continues.

During authorized drafting or scope revision, maintain `docs/gdd/design-scope-and-boundaries.md` and its entry link as useful scope decisions settle, following **Design scope and boundaries** in methodology 01. Local mechanism and presentation limits stay with their topics. Saving an already confirmed game-design boundary uses the current GDD writing authority; it does not require a separate Project Rules task.

Choose supporting capabilities by the actual task:

- Record ordinary specifications and existing values directly. Formula derivation, parameter models, economy or growth curves and tuning use [design-balance](../design-balance/SKILL.md). Pass the relevant goals, draft rules and current authorization; a complete GDD is not a prerequisite for early numeric exploration.
- Delivery boundaries, dependencies and order belong to [product-author](../product-author/SKILL.md).
- Detailed game-presentation, UI, art, audio, asset and localization specifications belong to their fixed owners in `methodology/11-specialist-workflows.md`. That file also governs saving them during initial GDD creation and moving them out of GDD during consolidation. Keep game rules and overall experience goals in GDD, and link relevant non-UI presentations from their GDD topic.
- When a design change affects planned or completed work, apply **Writing and adoption** and **Committing source changes before synchronization** in `methodology/11-specialist-workflows.md`, and use `feature-sync` within the current authorization. A future unplanned idea does not require a Product document or Feature plan.
- During authorized GDD creation, revision or consolidation, use [project-terminology](../project-terminology/SKILL.md) to save the current scope's confirmed terms in `docs/terminology.md` and link them from GDD, following `methodology/14-project-terminology.md`. This terminology maintenance is part of the same writing task; GDD does not keep another glossary. For document wording or organization, use [technical-documentation-writing-godot](../technical-documentation-writing-godot/SKILL.md); it does not decide the design.
- Read and maintain relevant questions in `docs/gdd/open-questions.md` under **Open design questions** in methodology 01. Keep settled decisions at their GDD topics and return resolved questions there. When a pause or blocker needs resumption, Progress/task records under `methodology/09-records-reports-and-handoff.md` link the relevant question and preserve the next action; do not duplicate the question body or create a design-state ledger.

Perform author self-checks for the changed design. Requested design review uses [plan-review-godot](../plan-review-godot/SKILL.md), and independent numeric review uses [review-balance](../review-balance/SKILL.md). A formal independent review requires a separate, non-author instance under `methodology/12-independent-review.md`; this Skill does not certify its own work or add a review gate to ordinary drafting.

Game code, runtime resources and prototype or asset production are outside this Skill's design output. A validation proposal does not start production. When the broader task already authorizes subsequent work, return the design, its sources and remaining uncertainties to the owning workflow. Dependent planning or implementation still needs sufficiently clear current-scope design.

## Finish the requested result

For discussion, return the useful conclusions and remaining material choices, identifying useful confirmed conclusions that remain unsaved. For authorized writing, deliver the actual GDD entry or changed topics, including the scope, open-questions, unadopted-ideas and project terminology files when affected, with important changes, assumptions and relevant unresolved questions. Check current-scope boundaries, rule consistency, proposal ownership, terminology ownership, numeric references and links; consolidation also accounts for retained content and unresolved source conflicts.

A draft may finish with explicit unknowns when it meets the requested purpose. Identify which unknowns block the proposed next use and which can wait. Report calculations, static reasoning, actual execution and human feedback only as far as the evidence supports them. Follow the current task's Git and completion rules.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
