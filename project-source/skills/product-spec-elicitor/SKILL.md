---
name: product-spec-elicitor
description: "Clarify Product delivery boundaries, order, dependencies and acceptance from current GDD design, and return a focused proposal without writing files. Use for delivery-scope questions. Not for game-design questions, which belong to design-gdd."
---

# Product delivery clarification

## Scope and inputs

Use the GDD prerequisite and source ownership in `methodology/01-product-doc-structure.md`. Clarify which actual GDD requirements the Product delivers. Missing or materially unresolved game design returns to `design-gdd` before dependent delivery choices; do not invent it through Product questions.

Read the caller's requested change, the applicable **Design scope and boundaries** in `methodology/01-product-doc-structure.md`, relevant GDD topics, engineering constraints in Project Rules and architecture decisions, the current Product outline or delivery document and facts about affected Features. Reuse confirmed answers and `document_language`. Actual implementation describes current behavior, not approved design.

Use the [shared questioning method](../project-grill-me/SKILL.md#shared-questioning-method) for missing material decisions. Do not start another interview when supplied sources and authorization already settle the change. This Skill only returns proposals to `product-author`; it does not write GDD, Product or plan files.

## Clarify the relevant difference

| Situation | Focus |
| --- | --- |
| A Product delivery boundary or order needs clarification | Which existing GDD requirements this unit delivers, excludes or depends on; do not redesign the game or fully specify future units. |
| A delivery depends on an unresolved game rule | Identify the owning GDD topic and the delivery decision it blocks, then return that design question to `design-gdd` or its scoped numeric owner `design-balance`. |
| A reported bug exposes ambiguous intent | Separate actual behavior from confirmed expectations. Missing design returns to its owner; an explicit requirement violation returns to the unfinished Feature or engineering route without changing requirements. |
| A cross-system delivery | Use the confirmed GDD rules between those systems to clarify inclusions, exclusions, integration dependencies and delivery acceptance. |
| Presentation details need professional work | Identify the relevant UI/art/audio/localization question and its source owner under methodology 11. Do not duplicate their specifications here. |

Ask about delivery tradeoffs only when they change the current decision. Do not resolve a gameplay value or rule by inventing a delivery default. Reuse valid professional requirements and shared terminology; substantive meaning changes belong with the GDD owner, while meaning-preserving definitions can go to `project-terminology`.

For a dependency on a future Product, settle only what the current delivery needs from it. The future outline remains in `docs/product.md`; clarification does not create its full document or Feature plan.

Deletion, foundational positioning changes and effects on completed behavior must be explicit. Reuse authorization that covers them and ask only about an unresolved material effect. Do not turn a defect report into permission to relax requirements.

## Return a reviewable proposal

Return a compact result in the configured document language, using a table or structured list when useful:

- The current delivery source and proposed change, with precise references to the adopted GDD requirements.
- Any unresolved design, numeric, terminology or professional question that must return to its source owner.
- Confirmed decisions, remaining proposals and blocking questions, kept distinct.
- Effects on the current Product, existing Features/completed behavior and later pre-split entries; omit categories with no impact.
- Required specialist input or validation questions, when applicable.

Do not reproduce unchanged source text, impose a fixed question count or create a second state record. The caller saves the approved change at its owner and handles the planning impact.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
