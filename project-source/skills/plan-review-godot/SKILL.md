---
name: plan-review-godot
description: Review an existing Godot GDD, Product or Feature proposal for consequential gaps, conflicts and implementation feasibility. Returns findings; does not replace ordinary clarification, author the plan or add a required review gate.
---

# Godot plan review

Review the supplied proposal against its intended outcome and current project constraints. Apply the project's existing GDD prerequisite under `methodology/01-product-doc-structure.md`; a review does not initialize missing game design. This is a focused review method, not a step required for every task. A formal independent review also follows `methodology/12-independent-review.md`; loading this Skill alone establishes no independence.

## Establish the current question

Identify the proposal, the decision it should support and the requested review scope from the conversation and current files. Reuse confirmed decisions. Distinguish approved requirements, observed implementation, proposed changes and assumptions; an old review or passing test does not establish the current proposal's correctness.

Read only sources that can affect this judgment: relevant GDD topics and Product boundaries, selected Feature details/designs and their dependencies, applicable project rules, accepted architecture decisions, professional requirements and matching project knowledge. Follow actual references rather than a fixed document list. Use the engineering routes in project `AGENTS.md` for affected Godot domains. Missing optional documents are not defects by themselves.

## Examine consequential weaknesses

Select the relevant concerns below and explain their concrete effect. Do not force an issue under every heading or invent a design for unrelated future scope.

| Concern | What to establish |
| --- | --- |
| Goal and boundary | The proposed outcome serves the confirmed GDD intent and current Product delivery; inclusions, exclusions and effects on existing behavior are consistent. |
| Assumptions and choices | Material assumptions have evidence or remain visibly undecided. Compare feasible alternatives where the choice changes scope, user-visible behavior or costly implementation. |
| Decomposition and dependencies | Features deliver coherent, independently verifiable outcomes; coverage has no consequential omission or overlap. Dependencies reflect actual contracts and available inputs, without detailing future Products prematurely. |
| Verification | Important outcomes have observable acceptance criteria and a feasible way to check them. Distinguish static checks, automated/runtime evidence and human perception or acceptance; planned checks are not results. |
| Godot implementation constraints | Relevant scene/resource ownership, state boundaries, signals, lifecycle, imports, persistence, UI or engine APIs fit the project and target version. Inspect only affected domains and verify uncertain version-sensitive claims before relying on them. |

Use a concrete example or counterexample to test a disputed claim. Prefer a local correction, reuse or removal when sufficient. Separate a blocking contradiction from a useful improvement and an evidence gap; uncertainty alone does not prove a defect. Ask only about a missing fact or choice that changes the current judgment. Return qualified findings when possible instead of pursuing an exhaustive interview.

## Return the conclusion to its owner

Lead with whether the proposal supports the requested next step, the most consequential issue and the limits of the review. For each actionable finding give its source or concrete scenario, impact, suggested correction and owning workflow. State the actual scope examined and important unresolved evidence. A sound proposal may receive no change recommendation; no score, new approval status or report file is required.

| Result needing follow-up | Existing owner |
| --- | --- |
| GDD design or Product delivery document change | [product-author](../product-author/SKILL.md); material design or delivery uncertainty uses [product-spec-elicitor](../product-spec-elicitor/SKILL.md) within that work. |
| Initial decomposition of the current Product | [feature-plan](../feature-plan/SKILL.md), preserving its existing proposal and writing contract. |
| Changes affecting an existing Feature plan | [feature-sync](../feature-sync/SKILL.md), with its actual source, baseline and plan-evolution contracts; findings do not establish a historical source change. |
| Current Feature's detailed implementation design | [feature-execute](../feature-execute/SKILL.md), under the optional design contract in `methodology/02-feature-list-schema.md`. |
| Professional specification change | Its owning specialist under `methodology/11-specialist-workflows.md`; keep GDD intent and detailed professional requirements at their existing sources. |
| Ordinary unresolved project question | [project-clarifier](../project-clarifier/SKILL.md); do not impose a plan review on normal clarification. |

This Skill returns analysis; it does not edit authoritative sources, code, rules, plan records or task state. Its conclusion neither changes approved/frozen decisions nor advances a Stage or substitutes for human acceptance. Return findings to the coordinating task. If its concrete authorization already covers the follow-up, continue there through the existing owner without asking again merely because this review ended; a review-only request ends with the findings.
