---
name: engineering-change-plan
description: >-
  Prepare bug, refactor or maintenance Features that preserve explicit Product intent. Triage ownership and evidence, obtain any missing approval, append the engineering plan, then hand off to authorized execution. Changed or ambiguous Product behavior belongs to product-author.
---

# Standardize one engineering change

## Authority

Follow `methodology/07-engineering-change.md` for classification, Bug ownership, mode-specific evidence and AC, Feature writes and Bug-learning promotion. Use the relevant artifact schema in `methodology/02-feature-list-schema.md` and the language contract in `methodology/05-document-language.md`. Before durable writes, apply `agent-rules/00-core/git-worktree-and-commits.md`.

This Skill prepares engineering work; `feature-execute` performs it. Preserve concrete authorization under **Authorization and continuation** in `methodology/03-execute-loop.md`. Preparation does not imply human acceptance.

## Triage and proposal

Read applicable `docs/project-rules.md`, routed engineering rules and relevant existing Feature designs/architecture decisions. Proposed rule changes follow the self-check and authorization in `methodology/04-coding-rules-4-layers.md`; a technical repair does not silently revise project constraints.

1. Read the actual confirmed Product, professional or technical contract, current Progress and relevant history. Classify ownership as `Framework`, `Tooling` or `Project-specific`, and select one canonical mode. Route changed/ambiguous Product intent to `product-author`, or changed/ambiguous professional requirements to their specialist under `methodology/11-specialist-workflows.md`; keep defects introduced in unfinished work with that Feature under the canonical ownership table.
2. Collect only the selected mode's necessary evidence from the engineering specification. Keep an unconfirmed root cause unknown. For an unspecified refactor, use `engineering-refactor-select` and return here with the selected candidate.
3. Read the Feature index and relevant details. If this work depends on an unplanned current Product, use `feature-plan` for that prerequisite. Independent tooling work uses its documented technical contract and may append an engineering Feature to a valid empty ledger without a business Product. Read the Test Registry to propose reusable or new affected components.
4. Propose the smallest independently verifiable Feature; split `large` work. Show ID/title/mode, dependencies, affected components, stable criteria, expected files/area and verification obligations. Reuse approval covering the proposal; resolve only missing material decisions.

For `bug`, use the precise confirmed Product/professional section or documented framework/tool contract as `source`. For `refactor` and `maintenance`, use `infrastructure` unless a single authoritative source owns the preserved contract. Populate a new independent Bug's `bug_diagnosis` under the canonical contract; do not invent a diagnosis for other modes. Keep durable evidence concise and link the execution archive.

For a project-tooling blocker with business work in progress, preserve that WIP and its evidence. Use the same project directory for the bounded repair, keeping its changed paths, evidence and logical commit distinct. Resolve a concrete overlapping edit before dependent mutation; use the existing Progress/Feature records to return to the paused work after the repair. Do not introduce a worktree or change-attribution workflow.

## Write and hand off

After approval, merge missing components before writing the Feature plan using the **Test registry** procedure in `.agents/skills/feature-plan/SKILL.md`. That procedure owns candidate format, conflict handling and existing-record preservation. Temporary candidates are not committed.

Append the index entry and matching engineering detail using canonical initial planning values; preserve completed history and engineering classification. This operation does not append a revision-log entry because no governing-source synchronization occurred.

Follow the engineering specification's **Feature write rules** for validation and the local plan commit. Inspect the actual diff against approved scope, component registration and preserved history before declaring the plan ready. Include the owning Feature's `Work item` reference in the commit.

Report the created Feature and remaining work. Return to the caller; continue with `feature-execute` when its concrete scope is authorized, or stop at the missing decision. Pass Bug reproduction/regression obligations and canonical learning requirements into that execution, without performing tests or recording acceptance as part of preparation.
