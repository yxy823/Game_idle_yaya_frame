---
name: engineering-change-plan
description: >-
  Prepare bug, refactor or maintenance Features that preserve confirmed GDD design and delivery scope. Triage ownership and evidence, obtain any missing approval, append the engineering plan, then hand off to authorized execution. Changed or ambiguous game design belongs to design-gdd.
---

# Standardize one engineering change

## Authority

Follow `methodology/07-engineering-change.md` for classification, Bug ownership, mode-specific evidence and AC, Feature writes and Bug-learning promotion. Use the relevant artifact schema in `methodology/02-feature-list-schema.md` and the language contract in `methodology/05-document-language.md`. Before durable writes, apply `agent-rules/00-core/git-worktree-and-commits.md`.

Apply the existing-GDD prerequisite in methodology 01 before project engineering work; a technical contract or empty ledger does not bypass it. This Skill prepares engineering work; [feature-execute](../feature-execute/SKILL.md) performs it. Preparation does not imply human acceptance.

## Triage and proposal

Read applicable `docs/project-rules.md`, routed engineering rules and relevant existing Feature designs/architecture decisions. When investigating or changing game behavior, also apply **Design scope and boundaries** in `methodology/01-product-doc-structure.md` and the relevant GDD/professional sources. Proposed engineering-rule changes follow the self-check and authorization in `methodology/04-project-rules.md`; a technical repair does not silently revise engineering constraints or game-design boundaries.

Apply **Feedback assessment** in methodology 07 before treating a report as a change, including when no triage Skill was selected. [feedback-triage-godot](../feedback-triage-godot/SKILL.md) exposes the same checks as a direct entry. When a defect needs causal investigation, use **Causal diagnosis** there through [bug-diagnosis-godot](../bug-diagnosis-godot/SKILL.md), collecting only evidence needed for this preparation. Reuse completed assessment/diagnosis; missing causal evidence may remain explicit in the initial proposal under the Bug contract.

1. Read the actual confirmed GDD, Product delivery scope, professional or technical contract, current Progress and relevant history. Distinguish game behavior from project tooling and select one mode under **Classification boundary** in methodology 07. Route changed or ambiguous GDD intent to [design-gdd](../design-gdd/SKILL.md), scoped numeric design to [design-balance](../design-balance/SKILL.md), delivery scope to [product-author](../product-author/SKILL.md), or changed/ambiguous professional requirements to their specialist under `methodology/11-specialist-workflows.md`; keep defects introduced in unfinished work with that Feature under the canonical ownership table.
2. Collect only the selected mode's necessary evidence from the engineering specification. Keep an unconfirmed root cause unknown. For an unspecified refactor, use [engineering-refactor-select](../engineering-refactor-select/SKILL.md) and return here with the selected candidate.
3. Read the Feature index and relevant details. If this work depends on an unplanned current Product, use [feature-plan](../feature-plan/SKILL.md) for that prerequisite. Independent tooling work uses its documented technical contract and may append an engineering Feature to a valid empty ledger without a detailed business Product, provided the project already has an actual GDD. Read the Test Registry to propose reusable or new affected components.
4. Propose the smallest independently verifiable Feature; split `large` work. Show ID/title/mode, dependencies, affected components, stable criteria, expected files/area and verification obligations. Reuse approval covering the proposal; resolve only missing material decisions.

For `bug`, use the precise confirmed GDD/Product/professional section or documented framework/tool contract as `source`. For `refactor` and `maintenance`, use `infrastructure` unless a single authoritative source owns the preserved contract. Populate a new independent Bug's `bug_diagnosis` under the canonical contract; do not invent a diagnosis for other modes. Keep durable evidence concise and link the execution archive.

For a project-tooling blocker with business work in progress, preserve that WIP and its evidence. Use the task's designated checkout under the Core Git contract for the bounded repair, keeping its changed paths, evidence and logical commit distinct. Resolve a concrete overlapping edit before dependent mutation; use the existing Progress/Feature records to return to the paused work after the repair. Do not introduce a change-attribution workflow or create a worktree merely to obtain a clean directory.

## Write and hand off

After approval, merge missing components before writing the Feature plan using the [Test registry merge procedure](../feature-plan/SKILL.md#test-registry-docstest-registryjson) in `feature-plan`. That procedure owns candidate format, conflict handling and existing-record preservation. Temporary candidates are not committed.

Append the index entry and matching engineering detail using canonical initial planning values; preserve completed history and engineering classification. This operation does not append a revision-log entry because no governing-source synchronization occurred.

Follow the engineering specification's **Feature write rules** for validation and the local plan commit. Inspect the actual diff against approved scope, component registration and preserved history before declaring the plan ready. Include the owning Feature's `Work item` reference in the commit.

Report the created Feature and remaining work. Pass Bug reproduction and regression obligations and the canonical learning requirements into execution; preparation performs no tests and records no acceptance. Execution continues with `feature-execute` only when its concrete scope is authorized; otherwise stop at the missing decision. Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
