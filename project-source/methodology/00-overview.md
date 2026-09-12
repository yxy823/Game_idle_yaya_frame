# 00 · Methodology overview

> This is the canonical mental model for the workflow. Skills guide the work; project checks are invoked explicitly.

## Mental model: specification and execution

```text
methodology/                         canonical workflow specification
     │
     ├──────────────→ Skills         agent-executable workflows
     │                    │
     │                    ▼
     │               project docs/  durable Product, Feature, Rules, Progress
     │                    ▲
     └──────────────→ Commands       explicit validation when the task needs it
```

The project knowledge layer is:

```text
<repo>/
├── agent-rules/                     repository-specific concrete implementation rules
└── docs/
    ├── product.md + product/*.md    Product intent: What
    ├── feature-list.json            lightweight Feature index: Todo/status
    ├── features/F0XX.json           Feature detail and durable local notes
    ├── feature-list-revisions.json  Product/Coding-Rules synchronization history
    ├── test-catalog.json            component/test traceability and safety-net index
    ├── gate-evidence.json           current-snapshot Feature completion evidence
    ├── coding_rules.md              collaboration and stack-independent architecture
    ├── progress.md                  current state, blockers, decisions, next action and history index
    ├── progress/                    one historical body per Feature or approved batch
    ├── architecture.md             optional human-owned module/dependency overview
    ├── architecture/               optional subsystem maps and important technical ADRs
    └── methodology-config.json      language, environment, and verification commands
```

## Skill groups

| Group | Skills | Responsibility |
| --- | --- | --- |
| Product | `product-init-elicitor`, `product-change-standardizer`, `product-spec-elicitor`, `product-ui-sketcher`, `product-audio-sketcher` | Define or change Product intent. |
| Planning | `generate-feature-list`, `sync-feature-list` | Maintain stable Feature IDs, dependency-driven execution and traced incremental source changes. |
| Engineering | `engineering-change-standardizer`, `pick-refactor-smell` | Create controlled engineering work when Product intent stays fixed: bugs, refactors, maintenance. |
| Delivery | `execute-next-feature` | Implement exactly one approved Feature through verification, applicable human acceptance, independent review, completion, and handoff. |
| Guidance | `yaya-next-step-advisor` | Read current state and produce an appropriately scoped prompt for an existing workflow; never execute or grant approval. |

## Canonical task routing

This table owns task routing. Guidance Skills read it and the destination
workflow; they do not maintain an independent lifecycle or approval table.

| Task type | Entry | Boundary |
| --- | --- | --- |
| Explicitly requested prototype / technical spike | Scoped experiment in the target project | Answer one hypothesis within the authorized change/run scope and budget. An experiment inside a Feature keeps its workflow; independent exploration need not create a full Product/Feature chain. |
| New Feature / Product change | `product-change-standardizer` | Define or change Product authority, then incrementally synchronize the plan. |
| Initial decomposition | `generate-feature-list` | Create the first plan from approved Product and Coding Rules. |
| Source synchronization | `sync-feature-list` | Trace additions, revisions, splits, merges and dependency/test retirement migrations. |
| Continue current Feature | `execute-next-feature` | Resume the actual Stage and existing authorization; “continue” alone does not grant missing approval or acceptance. |
| Execute eligible planned Feature | `execute-next-feature` | Select by the dependency DAG, present Stage 1 and preserve its approval boundary. |
| Bug in current unfinished Feature | Current Feature repair route | Reproduce and repair within its scope; keep failure evidence and relevant regression coverage. |
| Independent Bug in completed behavior | `engineering-change-standardizer` in bug mode | Restore explicit expected behavior; changed intent instead follows Product change. |
| Refactor | `engineering-change-standardizer` in refactor mode | Preserve behavior; use `pick-refactor-smell` first only when selecting a smell is requested. |
| Maintenance | `engineering-change-standardizer` in maintenance mode | Define technical success, compatibility, migration and validation. |
| Project tooling issue | `engineering-change-standardizer` | Describe the actual technical problem and repair the project-owned tool within the authorized scope. |
| Audit | Read-only inspection | Report evidence, uncertainty and findings; a request for audit does not authorize implementation. |
| Human Acceptance follow-up | Current Feature Stage 5/6 route | Bind the user's explicit acceptance to the actual reviewed scope and snapshot; do not infer acceptance. |
| Status query | Read-only state explanation | Report current facts and next legal action; do not start work or call readiness checks merely to answer. |

Complexity changes prompt detail, not authorization. Simple known work gets a
short actionable prompt; uncertain, cross-module or migration work gets an
investigation/planning prompt. Current user authorization takes precedence over
generic workflow wording, but implementation approval never implies human
acceptance.

Prototype observations and tentative parameters are not approved Product intent
or Feature acceptance. Keep the question, observed result, decision and experiment
file disposition in current Feature notes, or current Progress when no Feature
exists. Adopting an outcome into formal development returns to the Product or
engineering entry above; exceeding the experiment budget requires user direction.

## Project environment and workflow

This project uses Godot 4.7 / GDScript / gdunit4 on Windows 11.
The machine configuration starts incomplete. A first-use request lets the Agent
configure actual executable paths and commands directly in docs/methodology-config.json,
then run `tools/checks/check-project-environment.py --require-ready`.
Git initialization is a separate explicit action.

### Workflow entry

```text
User request
   │
   ├─ Observable Product intent is new, changed, missing, or ambiguous
   │      ↓
   │  product-change-standardizer
   │      ↓
   │  Product docs → generate/sync Feature plan
   │
   └─ Product intent is already explicit and should stay fixed
          ↓
      engineering-change-standardizer
          ├─ bug
          ├─ refactor
          └─ maintenance
          ↓
      approved engineering Feature

Both paths
   ↓
execute-next-feature
   ↓
implementation → automated verification → human acceptance when required by the approved plan
   ↓
independent requirements and code-quality review → must_fix: 0
   ↓
Feature completion gate → done
   ↓
handoff and STOP for the user's next decision
```

A reported bug must be classified before any Product edit:

- documented expected behavior exists and implementation violates it → `engineering-change-standardizer` in `bug` mode;
- expected behavior is missing, contradictory, or intentionally changing → `product-change-standardizer`.

## Delivery control points

Human control is mandatory and is deliberately not optimized away:

1. A proposed Product or engineering change must be approved before durable planning writes that require approval.
2. `execute-next-feature` Stage 1 requires explicit approval before implementation begins.
3. Stage 1 decides acceptance from the requirement. Visual/audio/game-feel or other human judgment requires manual mode and Stage 5; fully automated AC may use automated mode and omit Stage 5. Empty checks do not make this decision.
4. Bug Guardrail promotion into Coding Rules requires explicit approval.
5. Stage 8 stops. The user decides whether to synchronize changed rules, execute the next Feature, review more broadly, or pause.

## Stage 0–8 delivery loop

```text
Clean worktree gate (new task) / verify task ownership (resumed task)
   ↓
Stage 0   Require ready environment; select Feature; load Context / Rules Snapshot
   ↓
Stage 1   Test Impact Review + resource preflight → explicit human approval
   ↓
Stage 2   Mark in_progress; persist approved verification plan/catalog entries
   ↓
Stage 3   Existing Safety Net baseline → TDD RED/GREEN → focused implementation
   ↓
Stage 4   Required Test Set + static/full checks → test evidence + human checklist
   ↓
Stage 5   Explicit human acceptance only for approved manual mode
   ↓
Stage 5.5 Bug only: capture Root cause / Trigger / Regression / Guardrail
   ↓
Stage 6   Independent requirements/quality review; repair and reverify as needed; must_fix: 0
   ↓
Stage 7   Run explicit completion checks; mark done; stage task-owned changes; local commit; verify status
   ↓
Stage 8   Report next eligible work and STOP
```

## Explicit project checks

No automatic tool events are registered. The Agent reads Git status and follows
the current task's Skill. Editing a file or ending a reply does not trigger a
second workflow.

`tools/checks/check-feature-list.py` validates the ledger, Catalog and
dependencies; `--eligible` lists pending work whose prerequisites are satisfied.

`tools/testing/run-gdunit-tests.py --feature F0XX` reads the current Feature/Catalog and selects tests directly.
`.agents/skills/execute-next-feature/scripts/write-gate-evidence.py` records actual results and human
decisions. Its `validate --feature F0XX` command checks completion evidence
before the Agent records completion. Test, static and acceptance requirements
remain those of the execution Skill.

Report actual verification scope and review findings in ordinary language. Result
references and explicit decisions are stored by the Skill helper, not parsed from
conversation summaries.

## Scope boundary for this personal-project workflow

This methodology covers Product definition, engineering changes, Feature planning, implementation, automated testing, human acceptance, defect learning, refactoring review, maintenance, and local Git-safe handoff.

Release management, store submission, public version announcements, deployment approval, publishing workflow, and distribution governance are outside the default methodology unless the user explicitly defines one of them as project work.

## Further reading

| Topic | File |
| --- | --- |
| Product document structure | [01-product-doc-structure.md](./01-product-doc-structure.md) |
| Feature ledger schema and invariants | [02-feature-list-schema.md](./02-feature-list-schema.md) |
| Stage 0–8 execution loop | [03-execute-loop.md](./03-execute-loop.md) |
| Coding Rules architecture and bug-guardrail promotion | [04-coding-rules-4-layers.md](./04-coding-rules-4-layers.md) |
| Document language and verification configuration | [05-document-language.md](./05-document-language.md) |
| Document-language smoke scenarios | [06-document-language-smoke-scenarios.md](./06-document-language-smoke-scenarios.md) |
| Engineering change classification and creation | [07-engineering-change.md](./07-engineering-change.md) |
| Test traceability, TDD, regression/invariant selection | [08-testing-strategy.md](./08-testing-strategy.md) |
| Reports, explicit cleanup and Progress history | [09-artifact-lifecycle.md](./09-artifact-lifecycle.md) |
| Optional architecture overview and ADRs | [10-architecture-overview.md](./10-architecture-overview.md) |
