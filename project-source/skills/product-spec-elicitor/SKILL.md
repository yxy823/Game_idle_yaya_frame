---
name: product-spec-elicitor
description: Clarify a material change or gap in an existing GDD or Product delivery scope, returning a focused proposal without writing files. Does not initialize game design.
---

# Existing design and delivery clarification

## Scope and inputs

Use the GDD prerequisite and source ownership in `methodology/01-product-doc-structure.md`. Without an actual project GDD, report the missing input and stop; this Skill has no from-scratch idea or initialization route.

Read the caller's requested change, relevant GDD topics, applicable Project Rules/architecture decisions, current Product outline or delivery document and affected existing Feature facts. Reuse confirmed answers and `document_language`. Actual implementation describes current behavior, not approved design.

Use the [shared questioning method](../project-clarifier/SKILL.md#shared-questioning-method) for missing material decisions. Do not start another interview when supplied sources and authorization already settle the change. This Skill only returns proposals to `product-author`; it does not write GDD, Product or plan files.

## Clarify the relevant difference

| Situation | Focus |
| --- | --- |
| A new or revised game behavior within the existing GDD | Changed trigger, input, state, outcome, constraints and important exceptions; identify the owning GDD topic and real cross-system dependencies. |
| A Product delivery boundary or order needs clarification | Which existing GDD requirements this unit delivers, excludes or depends on; do not redesign the game or fully specify future units. |
| A reported bug exposes ambiguous intent | Separate actual behavior from confirmed expectations. An explicit requirement violation returns to the unfinished Feature or engineering route without changing requirements. |
| A cross-system change | Identify affected GDD topics, existing consumers and delivery boundaries; clarify only unresolved inclusions, exclusions and consequences. |
| Presentation details need professional work | Identify the relevant UI/art/audio/localization question and its source owner under methodology 11. Do not duplicate their specifications here. |

Ask about a value or edge case only when it changes the current decision. Mark a proposed default as a proposal, never an adopted requirement. Reuse valid professional requirements and shared terminology; substantive meaning changes belong with the GDD rule, while meaning-preserving definitions can go to `project-terminology`.

For a dependency on a future Product, settle only the contract needed by the current delivery. The future outline remains in `docs/product.md`; clarification does not create its full document or Feature plan.

Deletion, foundational positioning changes and effects on completed behavior must be explicit. Reuse authorization that covers them and ask only about an unresolved material effect. Do not turn a defect report into permission to relax requirements.

## Return a reviewable proposal

Return a compact result in the configured document language, using a table or structured list when useful:

- The current source and proposed change, with an actual file/section or a proposed topic location within the existing GDD.
- Whether the change belongs to GDD, Product delivery scope, shared terminology or a professional specification.
- Confirmed decisions, remaining proposals and blocking questions, kept distinct.
- Effects on the current Product, existing Features/completed behavior and later pre-split entries; omit categories with no impact.
- Required specialist input or validation questions, when applicable.

Do not reproduce unchanged source text, impose a fixed question count or create a second state record. The caller persists the approved change at its owner, handles planning impact and continues the authorized task.
