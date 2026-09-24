# 07 · Engineering change workflow

> This specification owns code/project changes that preserve already-defined Product intent. The executable Skill is `engineering-change-plan`.

## Classification boundary

Choose exactly one mode:

| Mode | Use when | Product contract |
| --- | --- | --- |
| `bug` | Implementation contradicts an explicit, confirmed Product, professional or project-tool contract. | Restore the owning contract without changing approved intent. |
| `refactor` | Internal structure should improve without changing accepted behavior. | Preserve behavior. |
| `maintenance` | Dependency, build, tooling, tests, migration, logging, performance, or comparable technical work is required. | Preserve behavior/compatibility unless a Product change is separately approved. |

Before classifying a bug, read the relevant authoritative source. Missing, contradictory or materially ambiguous expectations return to their owner: `product-author` for behavior, or the corresponding specialist for design requirements under [Specialist work and sources](11-specialist-workflows.md). A confirmed professional contract can establish a defect without duplicate Product text. An unapproved suggestion cannot. Technical defects use their documented project-tool contract and remain engineering work.

Distinguish game behavior from project tooling. Technical defects cite the actual tool contract and are repaired in the project-owned source. Do not invent Product requirements merely to describe a tooling defect.

## Bug ownership and routing

| Trigger | Owning work and route |
| --- | --- |
| Defect introduced inside the current unfinished Feature | Keep it in the current Feature and resume the applicable execute Stage; record the failure and rerun affected verification. No duplicate bug Feature merely to move its failure elsewhere. |
| Independent regression of previously completed behavior | Create an approved `bug` Feature through this workflow, retaining original completed history. |
| User wants a different observable behavior | `product-author`, even if the user calls it a bug. |
| User changes a professional requirement while behavior stays fixed | Its owning specialist updates the approved source and handles planned-work impacts; this is not a defect against the old contract. |
| Project tooling blocker while business work is in progress | Preserve business WIP and its evidence; handle the tool repair as a bounded technical task within this project. |
| Urgent repair | Preparation may be concise and the existing user authorization may cover multiple preparation steps; required validation, applicable human acceptance, explicit user review conditions, completion checks and a traceable commit still apply. Urgency is not a waiver. |

Routing a current-Feature defect back to execution does not by itself authorize a new scope. Report material scope changes for approval. For a new independent task, the clean-worktree rule still applies; an existing task-owned WIP can be resumed according to its ownership record. Never stash, discard or stage unrelated WIP.

Before any durable write, follow `agent-rules/00-core/git-worktree-and-commits.md`: a new engineering-change task requires a clean worktree, and all later staging must remain limited to that task's Feature-plan changes.

## Workflow

```text
Engineering request
   ↓
classify bug / refactor / maintenance
   ↓
collect only evidence needed to define safe work
   ↓
propose smallest verifiable engineering Feature
   ↓
EXPLICIT HUMAN APPROVAL
   ↓
register needed components; append index + detail; strict ledger validation
   ↓
handoff; stop if execution approval is still missing
   ↓
explicit execution approval (already supplied or newly given)
   ↓
feature-execute
```

This workflow never implements the change itself.

If the current request already explicitly approves the concrete repair plan and execution, retain that authorization when handing off; a redundant invocation is not required. A vague “continue” or urgency alone supplies no missing approval.

## Unified Bug workflow

```text
Discovery
→ Expected behavior and authoritative source
→ Minimal reproduction
→ Root cause
→ Test Impact Review
→ Regression RED
→ Minimal repair
→ GREEN
→ affected tests / required full suite
→ Human Acceptance when required by the approved plan
→ Independent review only when requested at this point
→ Completion Gate
→ Commit
```

This chain uses the existing execute loop; it adds no independent Stage. Triage collects actual/expected behavior and the smallest deterministic trigger. Establish the causal explanation before choosing the repair; mark unknown causes as unknown while investigating. Record the affected components and the approved regression obligation in Test Impact Review. A parser error, setup failure or unrelated baseline failure is not the intended regression RED. Apply the smallest complete fix, observe GREEN for the regression, then execute the planned affected set and necessary full suite. Reuse a real full run only when its snapshot and actual coverage cover the subsets. No hand-entered count can stand in for execution evidence.

Applicable human acceptance, user-requested independent review, the Completion Gate and a local traceable commit finish the repair under `03-execute-loop.md` and `08-testing-strategy.md`. A review repair that changes accepted behavior returns through verification and applicable human acceptance. Stage 8 then reports brief reusable learning and follows the remaining user authorization under the execution loop's handoff contract.

## Bug Feature contract

Record:

- actual behavior;
- expected outcome and precise confirmed Product, professional or project-tool source;
- minimum reproduction/trigger;
- root cause, or an explicit unknown during initial investigation;
- affected semantic components and area when known;
- whether deterministic automated regression coverage is feasible.

Acceptance criteria cover:

1. pre-fix reproduction when reasonably feasible;
2. restoration of documented behavior;
3. targeted regression test with a stable `F0XX-RTyy` logical ID when deterministically automatable;
4. relevant automated checks after repair;
5. explicit human acceptance in execute Stage 5 when the approved mode is manual; otherwise automated AC/regression verification is sufficient for this step.

If automated regression is genuinely impractical, record the concrete reason and a repeatable human regression check. “Hard to test” is insufficient.

The engineering template provides nullable `bug_diagnosis`. For a new independent Bug, populate it with `actual`, `expected`, `source`, `reproduction` (ordered, non-empty steps), and `root_cause`. Root cause may be `null` while planning; it must be a confirmed causal explanation before completion. Refactor/maintenance keep it `null` or omit it, never fill fictional bug evidence. Older Bugs without this field remain readable; their existing notes are historical evidence, not automatically migrated. Current-Feature defects can use that Feature's notes and linked execution archive without changing its original Product/engineering classification.

## Refactor Feature contract

Record the concrete smell, affected area, behavior that must remain unchanged, and tests/verification protecting that behavior. If no target has been selected, `engineering-refactor-select` may rank candidates; after user selection, return here and create an approved Feature before implementation.

## Maintenance Feature contract

Record technical objective, reason, affected technical boundary, compatibility/invariant that must remain true, and rollback/migration concern where applicable. Typical maintenance includes dependencies, build configuration, development tooling, test infrastructure, storage/schema migration, logging, and performance work.

## Feature write rules

Engineering Features use the normal Feature/test ledger: stable `ACxx` criteria, non-empty `affected_components`, execution-time verification mapping, plus detail field:

```json
"engineering_change": "bug"
```

Allowed values are `bug`, `refactor`, and `maintenance`. Use the next sequential Feature ID; do not rewrite completed Feature definitions.

Read the existing Test Registry when proposing `affected_components`. After approval, register missing components before writing/validating the Feature, using the existing merge helper and Test registry contract in `.agents/skills/feature-plan/SKILL.md`. Reuse existing records without resetting tests; report conflicting IDs. A component without an existing unit suite uses `unit_test_paths: []`, and its full-suite flag defaults to false unless the approved contract requires otherwise. Include these task-owned Registry changes in the same Feature-plan commit; test mappings are still finalized during execution. After the consistent set is written, validate:

```powershell
python -B tools/checks/check-feature-list.py
```

Then inspect and stage only the new/updated Feature-plan paths, run the required cached-diff checks, and create one local commit unless the user explicitly requested no commit. Use `<type>(<scope>): <中文行为摘要>` and include `Work item: docs/features/F0XX.json` in the body. Run `git status --short` afterward. Never push or rewrite history.

Creation of an engineering Feature alone does not create a `feature-list-revisions.json` entry because no governing-source synchronization occurred.

## Bug-learning promotion

Every completed Bug leaves local learning in its Feature notes:

```text
BUG learning
Root cause: <causal implementation defect>
Trigger: <minimum trigger/precondition>
Regression coverage: <F0XX-RTyy logical IDs, or approved manual regression reason/check>
Guardrail: <general principle preventing the same defect class>
```

The local record is factual incident knowledge. Link to `bug_diagnosis` or the execution archive for detailed evidence instead of copying the incident transcript. Regression IDs are also registered in `docs/test-registry.json`. Project Rules are prescriptive global knowledge. If an approved Guardrail becomes machine-verifiable across Features, it may also become an `INV-<DOMAIN>-NN` invariant under `08-testing-strategy.md`. Check existing rules before recommending a new rule.

Propose promotion of only the generalized `Guardrail` when at least one is true:

- it applies across multiple Features/modules;
- it expresses a project/language/engine invariant;
- it captures an architectural or lifecycle invariant not already documented;
- the defect recurred or needed repeated repair attempts;
- tests cannot fully enforce it.

Promotion follows [incremental rule maintenance](04-coding-rules-4-layers.md#incremental-rule-maintenance): check ownership and existing rules, output the self-check before any add/edit/delete, and obtain the required explicit decision unless already authorized. A rejected promotion leaves the local Bug note untouched. Preserve detailed local constraints and rationale in the optional Feature design when needed; do not copy whole rule modules into notes. Assess affected current and planned work, and complete needed `feature-sync` handling before dependent continuation. Late governing edits must satisfy the current verification and acceptance contract; they do not automatically apply only to the next Feature.

## Explicit exclusions

This workflow does not add publishing, release announcement, store submission, deployment approval, distribution, or public-release process by default.
