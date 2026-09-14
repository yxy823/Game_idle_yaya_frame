---
name: engineering-change-standardizer
description: >-
  The entry point for engineering changes that do not change Product intent: implementation-defect repair, refactoring, and maintenance. It triages Product-vs-implementation responsibility, creates reviewable engineering Features, preserves human control, requires regression coverage for bugs when feasible, and captures reusable bug learnings without silently changing Product or Coding Rules.
---

# Standardize one engineering change

Use this workflow for code or project-engineering changes whose intended user-visible Product behavior is already defined or is deliberately unchanged.

## Language and control contract

1. Read `document_language` from `docs/methodology-config.json`. Resolve missing or invalid configuration through `methodology/05-document-language.md` before writing durable project knowledge.
2. Use the user's current-message language for conversation and approvals. Persist Feature prose and durable notes in `document_language`.
3. This workflow never implements the change. It triages, records one or more engineering Features, then hands off to `execute-next-feature` only with explicit execution authorization. Preserve concrete authorization already supplied in the session; stop if it is missing.
4. Human control is mandatory. Never infer approval to create the Feature, start implementation, accept verification, promote a bug learning to Coding Rules, or continue to the next Feature.
5. Do not add release, publishing, deployment, store, changelog, or distribution work unless it is itself the explicit engineering problem supplied by the user.
6. Before durable writes, follow `agent-rules/00-core/git-worktree-and-commits.md`: independently require a clean worktree for a new project task and keep all later staging limited to task-owned Feature-plan and component-registration changes.

## Scope

Choose exactly one engineering mode:

| Mode | Condition | Product behavior |
| --- | --- | --- |
| `bug` | Implementation contradicts already explicit Product or framework/tool contract | Restore the documented contract without changing Product intent |
| `refactor` | Internal structure should improve while accepted behavior remains unchanged | Preserve behavior |
| `maintenance` | Dependency, build, tooling, test infrastructure, migration, logging, performance, or other technical work | Preserve behavior unless separately approved through Product workflow |

### Product boundary

Before using `bug` mode for Product-facing behavior, read the relevant Product source.
Technical defects instead cite the documented framework/tool contract.

- If Product intent is explicit and implementation differs, continue here as an implementation defect.
- If expected behavior is missing, contradictory, or materially ambiguous, stop and route to `product-change-standardizer`; do not guess the intended behavior.
- If the requested fix would intentionally change observable Product behavior, route to `product-change-standardizer` even if the request was described as a bug.

### Ownership before a new Bug

Read the canonical Bug ownership table and complete repair chain in
`methodology/07-engineering-change.md`; do not maintain a competing workflow.

- A defect introduced inside the current unfinished Feature stays with that
  Feature and returns to the applicable execute Stage. Preserve its classification
  and approvals; do not create a duplicate Feature to hide an unfinished failure.
- An independent regression of completed behavior creates an approved Bug Feature.
- A changed expectation routes to Product change.
- A project-tooling blocker is a bounded repair in the project-owned source,
  following `methodology/07-engineering-change.md`. Preserve business WIP and its
  evidence; use an explicitly approved isolated worktree when needed, and do not
  fold unrelated business paths or evidence into the repair.
- Urgency can shorten preparation, never supply missing approval or waive required
  RED/GREEN, affected/full verification, applicable human acceptance, review/gates or the traceable commit.

## Stage 1: triage and evidence

**Output:** one classified engineering change with enough evidence to plan safely.

Classify ownership as `Framework`, `Tooling`, or `Project-specific` as well as the
engineering mode. For framework/tool defects, cite the actual technical contract;
do not manufacture a Product requirement. Use current `docs/progress.md` for state,
blockers and history links, reading only the relevant execution archive.

For `bug`, collect only information that affects repair:

- actual behavior;
- expected behavior with the exact Product or framework/tool source path and section;
- minimal reproduction or triggering precondition;
- root cause when established; keep it explicitly unknown while still investigating;
- affected area/files when known;
- whether deterministic automated regression coverage is feasible.

For `refactor`, record:

- the concrete smell or structural problem;
- files/area affected;
- behavior that must remain unchanged;
- existing tests or verification that protect that behavior.

If the user asked to choose a refactor but did not identify one, run `pick-refactor-smell`. After the user selects a candidate, return here with that selected candidate; do not hand directly to implementation.

For `maintenance`, record:

- the technical objective;
- why it is needed now;
- affected build/runtime/tooling boundary;
- behavior or compatibility that must remain unchanged;
- rollback or migration concern when applicable.

Stop on material ambiguity rather than converting uncertainty into implementation assumptions.

## Stage 2: propose an engineering Feature

Read `docs/feature-list.json` and relevant detail files. If the Feature plan does not exist, route to `generate-feature-list` first.

Read `docs/test-registry.json` before proposing affected components. Reuse existing
records and identify any new component entries or conflicts in the proposal, following
the Test registry contract in `.agents/skills/generate-feature-list/SKILL.md`.

Propose the smallest Feature that can be implemented and verified in one normal work session. Split any `large` change before writing.

Use the current Feature/test schema. Engineering Features are append-only and receive the next sequential Feature ID. Add stable `ACxx` acceptance IDs, non-empty `affected_components`, an initially empty criterion verification mapping, top-level `verification`, and `engineering_change` with exactly one value: `bug`, `refactor`, or `maintenance`. Do not rewrite completed Feature descriptions, criterion IDs/text, or historical test mappings.

### Bug acceptance requirements

A bug Feature must identify the affected semantic components and include criteria covering:

1. the original failure can be reproduced before repair when reasonably feasible;
2. documented expected behavior is restored;
3. a targeted regression test with planned logical ID `F0XX-RTyy` is added or updated when the behavior is deterministically automatable;
4. the relevant automated checks pass after repair;
5. decide acceptance from the requirements in execute Stage 1, then record its mode and corresponding checks. Visual/audio/feel or other human judgment requires manual mode and explicit Stage 5 acceptance; fully automated AC may omit Stage 5.

Carry the canonical chain into the execution handoff: discovery → expectation and
source → minimal reproduction → root cause → Test Impact Review → Regression RED
→ minimal repair → GREEN → affected/required full → Applicable Human Acceptance → Review/Gate
→ Commit. A framework/setup/parser failure does not prove the intended regression
RED. The execution Skill owns actual tests and acceptance, not this preparation Skill.

When an automated regression test is genuinely impractical, state the concrete reason in Feature notes and replace it with a specific repeatable human regression check. Do not use “hard to test” as sufficient justification.

### Refactor acceptance requirements

Include explicit behavior-preservation criteria and the tests/checks that demonstrate no accepted behavior changed.

### Maintenance acceptance requirements

Include the technical success condition, compatibility/invariant that must remain true, and the automated or human evidence required to prove both.

Use `source` as follows:

- `bug`: the precise Product module/section, or framework/tool specification for a technical defect, whose documented behavior is being restored;
- `refactor` or `maintenance`: `infrastructure`, unless one Product section is the clear behavioral contract being preserved.

Store the mode in the detail field `engineering_change`; keep `notes` for localized durable evidence that future work needs. Do not encode workflow state in prose and do not store verbose debugging transcripts.

For a new independent Bug, populate the template's `bug_diagnosis` with actual,
expected, source, ordered reproduction steps and root_cause (`null` only while
investigating). Current completion requires a confirmed root cause when this field
is used. Refactor/maintenance leave it null or omit it. Link detailed run/reproduction
evidence from the single execution archive; do not repeat the same transcript in
Feature notes and Progress. Completion requires a diagnosis and confirmed root cause.

## Stage 3: human approval and write

Show the proposed Feature ID, title, mode, dependencies, affected components, stable acceptance criteria, expected files/area, and regression-test obligation. Reuse explicit approval covering the proposal; wait only for missing decisions or material changes.

After approval:

Before writing the Feature plan, merge any approved new components with the existing
`.agents/skills/generate-feature-list/scripts/merge_test_registry.py` command and
candidate format from that contract. Preserve existing components/tests and reject
conflicting existing IDs. New components use `unit_test_paths: []` when no suite
exists and `full_suite_on_change: false` unless the approved contract requires it;
do not create a future suite just to register a component. Temporary candidates are
not committed. Execution-time test mappings remain owned by `execute-next-feature`.

1. append the Feature to `docs/feature-list.json`;
2. create the matching `docs/features/F0XX.json` with `affected_components`, stable `ACxx` criteria, and empty execution-time verification mappings;
3. update `meta.total_features`;
4. validate all affected JSON and Feature invariants with `python -B tools/checks/check-feature-list.py`;
5. do not modify `docs/feature-list-revisions.json`, because no Product/Coding-Rules source synchronization occurred;
6. inspect `git status --short`, stage only the task-owned Feature-plan and component-registration paths or inspected hunks, and run `git diff --cached --check`, `git diff --cached --stat`, and the complete `git diff --cached` review;
7. unless the user explicitly requested no commit, create one local commit without asking again, using `<type>(<scope>): <中文行为摘要>` and a body containing `Work item: docs/features/F0XX.json` plus the meaningful reason/validation summary;
8. run `git status --short` after commit and stop on any unexpected or omitted change. Never push, amend, rebase, reset, change remotes, or use `--no-verify`.

Report the created Feature. Start `execute-next-feature` only when the concrete
execution scope already has explicit user approval; otherwise stop for that decision.
Do not reinterpret “continue” as approval of a plan the user has not seen.

## Bug-learning capture contract

Bug repair should leave durable knowledge, but only at the narrowest useful scope.

### Always capture locally

At bug completion, `execute-next-feature` appends a concise `BUG learning` block to the repair Feature's `notes` containing:

- `Root cause`: the causal implementation defect, not the symptom;
- `Trigger`: the minimum precondition that exposed it;
- `Regression coverage`: logical `F0XX-RTyy` IDs, or the approved reason automation is impractical plus the human regression check;
- `Guardrail`: one short implementation principle that would prevent the same defect class.

Do not store dead-end debugging steps, temporary guesses, stack traces already
available elsewhere, or incidental machine-specific failures. Link to the detailed
diagnosis/archive instead of duplicating it. Check whether existing rules already
cover the learning before proposing promotion; no automatic rule is created per bug.

### Promote only reusable knowledge

After the local note is prepared, propose promotion to the most relevant `docs/coding_rules.md` or repository-specific imported rule source (for example `agent-rules/`) only when at least one condition is true:

- the same defect class can affect multiple Features or modules;
- the learning expresses a framework/language/engine semantic that future implementation must consistently respect;
- it defines an architectural or lifecycle invariant not already documented;
- the defect recurred or required multiple repair attempts;
- automated tests cannot fully enforce the guardrail.

A promoted rule must be prescriptive and general. Do not copy the incident narrative into Coding Rules.

Promotion always requires explicit user approval. A rejected promotion leaves the local Feature note intact. A Coding Rules change applies to subsequent Features under the rule-snapshot contract; it does not retroactively redefine the completed bug Feature.

## Relationship to other workflows

- `product-change-standardizer`: owns new/changed/ambiguous Product intent.
- `generate-feature-list`: creates the initial Product-derived plan.
- `sync-feature-list`: synchronizes committed Product or Coding Rules source changes.
- `pick-refactor-smell`: selects a recorded refactor candidate, then returns the selection here.
- `execute-next-feature`: performs Test Impact Review, persists the approved test plan/registry entries, executes TDD/verification, applicable human acceptance, independent review, completion, and handoff.

The routing invariant is:

**Product intent changes → Product workflow. Product intent stays fixed → engineering workflow.**
