---
name: design-balance
description: "Derive or adjust game formulas, parameter models and pacing curves from explicit goals, draft rules or data, and maintain them in authorized GDD balance files. Use for formula or parameter derivation, economy and progression models, numeric diagnosis or tuning. Not for recording an ordinary dimension or existing value, independent balance review (review-balance) or runtime implementation."
---

# Numeric game design

Build an explainable, reproducible numeric proposal for the intended player experience.

## Inputs and authority

An explicit experience target and enough draft rules to state a useful model are valid inputs. Early numeric design does not require a complete GDD, Product or Feature; see **GDD prerequisite and authority** in `methodology/01-product-doc-structure.md`. If a GDD exists, follow its entry to the relevant rules, numeric source and dependencies rather than modeling from an overview alone.

Extract the actual goal, constraints, variables and available evidence. Identify which sources describe adopted rules, candidate rules, observed implementation or measured results. Preserve their scope and assumptions. Ask only when a missing decision would materially change the goal or model; otherwise state a bounded assumption and continue. When clarification is needed, use the [shared questioning method](../project-grill-me/SKILL.md#shared-questioning-method) within this Skill's scope. A model conditional on a draft rule remains conditional.

Within the user's concrete authorization, maintain models in the fixed balance file for the system's scope and key, under **GDD document names** in `methodology/01-product-doc-structure.md`. Model length or complexity does not select the location. That section also covers GDDs organized differently. Authorized consolidation moves an embedded model into the matching balance file and leaves a reference. Report any needed migration that exceeds the writing scope. Write titles and prose in `document_language` (`methodology/05-document-language.md`). Discussion-only requests deliver the model in the conversation.

New derivations and tuning values start as candidates. Mark adoption only when the user decides it. Keep validation evidence separate: calculated, simulated and observed results prove different things. Place alternative values and parked ideas under **Candidate and unadopted ideas** in methodology 01; a parked future mechanic returns to `design-gdd`, not a speculative balance file. Never silently replace an adopted value. Saving a candidate model does not adopt it, and an adopted value may still have no experience evidence.

## Derive and check the model

Use [Numeric modeling and calculation checks](references/numeric-modeling.md) for the applicable relationships, time/resource accounting, scenarios and pitfalls. Work only on adopted mechanisms or alternatives the user has asked to explore. Do not infer offline rewards, prestige, exponential growth or endless progression from a genre label.

Translate the experience goal into the quantity being modeled, preserving subjective questions that still need human observation. Define variables, units, formulas, bounds, rounding and update conditions. Use the simplest model that answers the question; split phases when a constant-rate approximation would hide a material change.

Show meaningful inputs and intermediate relationships so the main result can be recalculated. Check typical scenarios and the boundaries relevant to the proposed change, including plausible player choices and sensitive assumptions. Use available calculation tools when useful and state exactly what ran. A proposed simulation is not a simulation result.

For diagnosis, distinguish the observed symptom, supported conclusion and cause hypothesis. For tuning, compare the original value and candidate replacement, expected effect, tradeoff and remaining uncertainty. Prefer a small set of consequential changes when it can answer the goal; do not silently redesign the game to make a target reachable.

## Write back and coordinate consequences

Keep formulas, values, decision state and calculation assumptions together at their owning GDD location. Read and maintain affected numeric questions under **Open design questions** in `methodology/01-product-doc-structure.md`, preserving uncertainties that still need adoption or play evidence. Update the authorized numeric passage and relevant links directly; no separate overall-design approval is needed merely because the owning document is GDD.

- A new mechanic or changed experience goal belongs to [design-gdd](../design-gdd/SKILL.md). Explain the conflict or proposed tradeoff and carry the current authorization into that work; do not treat a tuning request as permission to adopt a different game.
- When the changed numeric source affects planned or completed work, use **Writing and adoption** and **Committing source changes before synchronization** in `methodology/11-specialist-workflows.md`. Coordinate affected Product scope with `product-author` and planned consumers with `feature-sync` within the task's authorization. Do not create Product/Feature documents merely to finish a standalone model.
- For a useful persistent domain definition, use `project-terminology`; for documentation wording, use `technical-documentation-writing-godot`. For a real pause or blocker, use the Progress or task records under `methodology/09-records-reports-and-handoff.md`. These are conditional support, not a required chain of Skills.
- Independent numeric review uses [review-balance](../review-balance/SKILL.md). Author calculation checks are not a formal independent review; a requested formal review needs a separate, non-author instance under `methodology/12-independent-review.md`.

Numeric design authorization does not automatically authorize editing runtime code, data or resources. An already authorized implementation continues through its owning workflow using sufficiently clear adopted design, with its normal verification and human acceptance obligations. Designing a validation scenario does not automatically build a prototype.

## Deliver the result

Provide the target and source basis, model and candidate values, reproducible calculation scenarios, important sensitivity or limits, and the evidence needed to assess the intended effect. State what was adopted and what was actually checked without implying that the game is now balanced or enjoyable.

For authorized writing, link the updated numeric source and explain relevant downstream effects, completed synchronization and any remaining gap. For proposals only, identify affected source locations without claiming they were updated. Follow the task's Git and completion rules.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
