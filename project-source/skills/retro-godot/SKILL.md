---
name: retro-godot
description: Retrospect on actual Godot development work and verification records to assess useful workflow, rule, tool or knowledge improvements. Returns evidence-based recommendations and their owners; not routine completion, code review or automatic rule maintenance.
---

# Godot development retrospective

Use actual task experience to decide whether the project's way of working needs a focused improvement or deserves reusable knowledge. Support one project user working with an Agent in the task's target checkout. Do not extend the project into multi-user coordination or change-attribution systems.

This is an optional retrospective for a concrete question or observed recurring difficulty, not a mandatory end-of-task exercise. Apply the existing GDD prerequisite in `methodology/01-product-doc-structure.md` and current project authority; it neither starts a Feature nor replaces its validation or completion work.

Use [loop-me-godot](../loop-me-godot/SKILL.md) when the user wants to design future handling of identified recurring or anticipated work; that design needs no history of failure.

## Establish what happened

Identify the task, relevant version or time span, intended outcome and concern from available conversation and records. Read only evidence that bears on that concern: applicable Feature/design notes, relevant diffs, actual verification output, user feedback and the affected workflow, rule, tool or knowledge source. Reuse valid context; do not scan every task, rule or knowledge topic.

Separate the requirement and chosen method from the observed result. Check whether evidence belongs to the relevant revision and whether it demonstrates static correctness, a tool run, real engine behavior or actual human acceptance. Missing, interrupted or older verification remains a limitation, not a pass or proof of a process defect. If no task evidence is available, explain the minimum information needed for this retrospective rather than inventing a history or cause.

## Judge the smallest useful improvement

Consider both observed difficulties and successful approaches worth retaining. Distinguish a local mistake, a tool/environment limitation, a real rule conflict, repeated process friction and a useful contextual technique; do not promote one incident into a universal restriction.

- Check existing coverage before proposing a new rule, helper or knowledge entry. A clearer reference, merged duplicate, removal of an obsolete constraint or local correction may be enough.
- Assess the concrete benefit, recurring cost and conditions of each proposal against the single-user project. Ordinary Agent judgment and existing commands remain valid solutions.
- Do not treat the absence of Hooks, CI, scripts, scoring, receipts or extra approval stages as a problem. Do not default to adding them or automate supervision of Agent actions.
- Link the conclusion to real evidence. Mark a plausible cause as a hypothesis and identify the observation that would distinguish it; do not claim a remedy has been validated merely because it sounds reasonable.

No improvement may be warranted. Return that conclusion with its evidence and limits instead of manufacturing a lesson, rule or follow-up task.

## Place recommendations at their actual owner

For each useful recommendation, explain the observed problem or benefit, supporting record, proposed change, why it belongs at that location and any missing decision or validation. Use the following boundaries only when the proposal touches that subject; they are not a reading checklist.

| Subject | Owning material or workflow |
| --- | --- |
| Task-specific incident, design choice or pending work | Existing Feature notes/design and the current records under `methodology/09-artifact-lifecycle.md`; preserve historical facts. |
| Reusable contextual technique or failure lesson | `docs/knowledge/README.md` and its relevant topic; check for an existing entry. Knowledge explains evidence and conditions, not new mandatory behavior. |
| Stable project constraint or concrete engineering rule | `methodology/04-coding-rules-4-layers.md` determines `docs/project-rules.md` versus the applicable `agent-rules/` module and owns the pre-write self-check and authorization. |
| Workflow, Skill guidance, command or configuration | The actual project-owned source and its callers. Follow `methodology/07-engineering-change.md` for an authorized project-tool change. Task routing belongs in **Canonical task routing** in `methodology/00-overview.md`; `AGENTS.md` routes affected engineering domains to Core and specialized rule entries. A framework-source recommendation returns to the framework maintenance task without writing across repositories or fetching framework materials. |
| Current technical structure or an important cross-Feature decision | `methodology/10-architecture-overview.md`; do not require an ADR for an ordinary local choice. |
| Changed game-design intent, delivery scope or existing Feature plan | [product-author](../product-author/SKILL.md) and, where existing plans are affected, [feature-sync](../feature-sync/SKILL.md). Do not relax requirements to explain a failed implementation. |

Keep the result in the conversation. This Skill does not automatically edit rules, code, tools, knowledge, state or approval records, create reports, or turn recommendations into a backlog. Review findings cannot rewrite a past decision, advance Stage, supply missing acceptance or establish implementation success.

Return the recommendations and evidence to the coordinating task. Concrete follow-up already authorized continues through its existing owner and applicable checks without a new confirmation merely because this Skill returned. A retrospective-only request ends with the analysis; a genuinely new restriction, unresolved choice or wider scope retains its existing decision boundary.

Inspired by Matt Pocock's `retro` approach to improving agent work from actual experience; rewritten for this Godot project's workflow, evidence and authorization boundaries.
