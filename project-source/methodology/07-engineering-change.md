# 07 · Engineering change workflow

> This document covers code and project changes that keep the confirmed game design and delivery intent unchanged: Bug repairs, refactors and maintenance. The `engineering-change-plan` Skill carries it out.

A substantive GDD is required under [GDD prerequisite and authority](01-product-doc-structure.md#gdd-prerequisite-and-authority). A technical repair, refactor or experiment is not a route around this prerequisite. Detailed Product documents are needed only when their delivery scope is relevant.

## Feedback assessment

Before treating a report as engineering work, compare the actual observation with the relevant confirmed contract and the current implementation. Reuse established facts, and ask only for missing information that changes the judgment. Check which of these applies:

- the reported capability already exists;
- its entry point or explanation is hard to find;
- the implementation violates the contract;
- the user wants a different result.

Code shows current behavior; it is not permission to redefine approved intent.

Return a supported classification, its source and evidence, important uncertainty and the next owner.

- An unobserved failure stays unconfirmed; it is not disproved.
- Missing expectations go back to their design or professional owner before a repair is chosen.
- An explanation or navigation problem can end with the requested answer. Feedback assessment does not require a Feature or a rejection or backlog record.
- Saved changes follow their owning document and the current authorization.

`feedback-triage-godot` provides this assessment as a direct entry. Engineering preparation must apply these checks even when no Skill was automatically selected. Once a defect and its ownership are established, use `bug-diagnosis-godot` for focused causal investigation when needed; do not repeat assessment merely because the entry changes.

## Classification boundary

For work that requires an engineering change, choose exactly one mode:

| Mode | Use when | Governing contract |
| --- | --- | --- |
| `bug` | Implementation contradicts an explicit, confirmed GDD, Product delivery, professional or project-tool contract. | Restore the owning contract without changing approved intent. |
| `refactor` | Internal structure should improve without changing accepted behavior. | Preserve behavior. |
| `maintenance` | Dependency, build, tooling, tests, migration, logging, performance or comparable technical work is required. | Preserve behavior and compatibility unless a Product change is separately approved. |

Before classifying a bug, read the relevant authoritative source. Missing, contradictory or materially ambiguous expectations return to their owner:

- `design-gdd` for overall game design;
- `design-balance` for scoped numerical design;
- `product-author` for delivery boundaries;
- the corresponding specialist for professional requirements, under [Specialist work and sources](11-specialist-workflows.md).

A confirmed GDD or professional contract can establish a defect without matching Product text. An unapproved suggestion cannot.

Distinguish game behavior from project tooling. A tooling defect cites the actual tool contract, stays engineering work and is repaired in the project-owned source. Do not invent Product requirements to describe it.

## Bug ownership and routing

| Trigger | Owning work and route |
| --- | --- |
| Defect introduced inside the current unfinished Feature | Keep it in the current Feature and resume the applicable execute Stage; record the failure and rerun affected verification. No duplicate bug Feature merely to move its failure elsewhere. |
| Independent regression of previously completed behavior | Create an approved `bug` Feature through this workflow, retaining original completed history. |
| User wants a different observable behavior | `design-gdd` or the owning numerical/professional designer, even if the user calls it a bug; `product-author` handles changed delivery boundaries. |
| User changes a professional requirement while behavior stays fixed | Its owning specialist updates the approved source and handles planned-work impacts; this is not a defect against the old contract. |
| Project tooling blocker while business work is in progress | Preserve business WIP and its evidence; handle the tool repair as a bounded technical task within this project. |
| Urgent repair | Preparation may be concise, and the user's authorization may cover several preparation steps. Required validation, applicable human acceptance, explicit user review conditions, completion checks and a traceable commit still apply. Urgency is not a waiver. |

Routing a current-Feature defect back to execution does not authorize a new scope; report material scope changes for approval. When switching to a bounded repair, follow [Git changes and commits](../agent-rules/00-core/git-worktree-and-commits.md) to preserve the paused work in the task's checkout and to resume it later from its records and actual changes.

## Workflow

```text
Engineering request
   ↓
confirm the GDD exists; stop if missing
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

If the current request already explicitly approves the concrete repair plan and its execution, keep that authorization when handing off; no second invocation is required. A vague “continue” or urgency alone supplies no missing approval.

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
→ Bug-learning capture (Stage 5.5)
→ Independent review only when requested at this point
→ Completion Gate
→ Commit
```

This chain runs inside the [execute loop](03-execute-loop.md) and adds no Stage of its own.

- **Discovery** collects actual and expected behavior and a repeatable trigger, or the observed conditions of an intermittent failure.
- **Root cause:** establish the causal explanation before choosing the repair. Mark an unknown cause as unknown while investigating.
- **Test Impact Review** records the affected components and the approved regression obligation.
- **Regression RED** must fail for the defect itself. A parser error, setup failure or unrelated baseline failure does not count.
- **Repair and GREEN:** apply the smallest complete fix, observe GREEN for the regression, then run the planned affected set and any required full suite. Reuse a real full run only when its snapshot and actual coverage include the subsets. A hand-entered count never replaces execution evidence.
- **Bug-learning capture (Stage 5.5)** records the `BUG learning` note and assesses the Guardrail under [Bug-learning promotion](#bug-learning-promotion).
- **Finish:** applicable human acceptance, user-requested independent review, the Completion Gate and a local traceable commit finish the repair, as defined in [03 · Execute loop](03-execute-loop.md) and [08 · Test traceability and evidence](08-test-traceability-and-evidence.md). A review repair that changes accepted behavior goes back through verification and applicable human acceptance. Stage 8 then reports brief reusable learning and continues within the remaining user authorization.

### Causal diagnosis

Define the failure by the user's exact observable symptom and its confirmed expectation. Record the relevant version, environment, inputs and actual evidence. A check for "does not crash" cannot establish that an action occurs exactly once or produces the right result. Reproduction may be automated or a repeatable human procedure; lack of an automated failing command does not prevent source inspection or hypothesis formation.

For game behavior, follow the symptom and evidence through the relevant rules and business state, the presentation and their connections. The user need not first classify the failure as logic, presentation or cross-layer.

- Incorrect feedback may come from a wrong business result, a missing or repeated delivery, or the feedback implementation itself. A correct state change alone does not show which remaining part failed.
- Choose domain-specific methods only when they help distinguish the current hypotheses.
- These responsibilities guide one causal investigation. They do not split a symptom into separate Bugs, tasks or agents; the owning task stays as routed above.

Reduce irrelevant inputs, scene elements or steps while preserving the same failure. Change one relevant factor at a time when distinguishing causes, and retain the original scenario for later verification. For intermittent failures, report observed attempts, workload and conditions; do not invent determinism or require a fixed retry count.

Work with plausible causal hypotheses and observations that could distinguish or refute them. Inspect the affected code and current evidence first. Choose the smallest discriminating probe instead of speculative fixes or broad logging. Within their actual execution permissions:

- missing runtime signals may use `diagnostics-instrumentation`;
- measured timing or resource problems may use `diagnostics-performance`;
- sustained accumulation or stability questions may use `diagnostics-soak-test`.

Temporary diagnostics and retained evidence follow [Reports and cleanup](09-records-reports-and-handoff.md#reports-and-cleanup).

Explain the chain from the trigger to the defective state or operation and then to the observed result, citing the evidence. Separate a supported cause from a hypothesis or an unresolved gap. If the authorized investigation is blocked, report what is known, what is missing and the next discriminating check. A log capture alone does not mean the root cause was found. Keep the evidence in the Feature and Progress records and report locations, not in a second Bug ledger.

- An authorized repair follows the Unified Bug workflow above and rechecks the original scenario as well as the focused regression.
- A diagnosis-only request returns the causal conclusion or an explicit investigation gap. It does not implement a repair.
- An already authorized repair returns to its owning task without asking again because diagnosis ended. Missing decisions, scope changes and human acceptance keep their own boundaries.

## Bug Feature contract

Record:

- actual behavior;
- expected outcome and the precise confirmed GDD, Product delivery, professional or project-tool source;
- minimum reproduction or trigger;
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

The engineering template provides the nullable `bug_diagnosis` field.

- For an independent Bug, fill in `actual`, `expected`, `source`, `reproduction` (ordered, non-empty steps) and `root_cause`.
- `root_cause` may be `null` while planning. Every `done` Bug needs a confirmed causal explanation there; the checker rejects a completed Bug without it.
- Refactor and maintenance Features keep `bug_diagnosis` `null` or omit it. Never fill in fictional bug evidence.
- A defect inside the current Feature uses that Feature's notes and linked execution archive and keeps the Feature's original classification.

## Refactor Feature contract

Record the concrete smell, the affected area, the behavior that must stay unchanged, and the tests or verification protecting that behavior. If no target has been selected, `engineering-refactor-select` may rank candidates; after user selection, return here and create an approved Feature before implementation.

## Maintenance Feature contract

Record the technical objective, the reason, the affected technical boundary, the compatibility or invariant that must stay true, and any rollback or migration concern. Typical maintenance includes dependencies, build configuration, development tooling, test infrastructure, storage/schema migration, logging, and performance work.

## Feature write rules

Engineering Features use the normal Feature and test records: stable `ACxx` criteria, non-empty `affected_components` and verification mapped during execution, plus this detail field:

```json
"engineering_change": "bug"
```

Allowed values are `bug`, `refactor`, and `maintenance`. Use the next sequential Feature ID; do not rewrite completed Feature definitions.

Read `docs/test-registry.json` when proposing `affected_components`. After approval, register missing components before writing and validating the Feature:

- Use the merge helper in [feature-plan](../.agents/skills/feature-plan/SKILL.md#test-registry-docstest-registryjson); the Registry rules themselves are in [08 · Registry rules](08-test-traceability-and-evidence.md#registry-rules).
- Reuse current records without resetting tests, and report conflicting IDs.
- A component without a unit suite uses `unit_test_paths: []`. Its `full_suite_on_change` defaults to `false` unless the approved contract requires otherwise.
- Include these Registry changes in the same Feature-plan commit. Test mappings are still finalized during execution.

After the consistent set is written, validate:

```powershell
python -B tools/checks/check-feature-list.py
```

Then stage only this task's Feature-plan paths and create one local commit, unless the user explicitly asked for no commit. The subject format, the `Feature:` and `Work item:` body lines and the forbidden Git operations follow [Git changes and commits](../agent-rules/00-core/git-worktree-and-commits.md#local-commits).

Creating an engineering Feature does not add a `feature-list-revisions.json` entry, because no GDD, Product or professional source was synchronized.

## Bug-learning promotion

Every completed Bug leaves local learning in its Feature notes:

```text
BUG learning
Root cause: <causal implementation defect>
Trigger: <minimum trigger/precondition>
Regression coverage: <F0XX-RTyy logical IDs, or approved manual regression reason/check>
Guardrail: <general principle preventing the same defect class>
```

The local note records facts about this incident. Link `bug_diagnosis` or the execution archive for detailed evidence instead of copying the transcript. Regression IDs are also registered in `docs/test-registry.json`.

This section is the single source for promoting a Guardrail:

```text
Bug Feature
├── regression test → F0XX-RT01
└── BUG learning Guardrail
        ↓ explicit human approval only
   Project or specialized rule / invariant
        ↓
   INV-<DOMAIN>-01 when machine-verifiable
```

A regression test proves that the concrete defect does not return. An invariant test (`INV-<DOMAIN>-NN`, under [08 · Test taxonomy](08-test-traceability-and-evidence.md#test-taxonomy)) proves a generalized cross-Feature rule. The two complement each other and may both exist. Check current rules before recommending a new one.

Propose promotion of only the generalized `Guardrail` when at least one is true:

- it applies across several Features or modules;
- it expresses a project, language or engine invariant;
- it captures an architectural or lifecycle invariant not already documented;
- the defect recurred or needed repeated repair attempts;
- tests cannot fully enforce it.

Promotion follows [incremental rule maintenance](04-project-rules.md#incremental-rule-maintenance): check ownership and current rules, output the self-check before any addition, edit or deletion, and obtain the required explicit decision unless it is already authorized.

- A rejected promotion leaves the local Bug note unchanged.
- Local implementation constraints and their rationale, including brief explanations, go in the Feature design; notes link to it. Do not copy whole rule modules into notes.
- Assess affected current and planned work, and complete the needed `feature-sync` handling before dependent work continues.
- A late rule edit must meet the current verification and acceptance contract. It does not automatically apply only to the next Feature.

## Explicit exclusions

This workflow does not add publishing, release announcements, store submission, deployment approval, distribution or a public-release process.
