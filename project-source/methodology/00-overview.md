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
├── agent-rules/                         repository-specific concrete implementation rules
└── docs/
    ├── product.md + product/*.md        Product intent: What
    ├── CONTEXT.md                       optional shared project vocabulary
    ├── feature-list.json                lightweight Feature index: Todo/status
    ├── features/F0XX.json               Feature detail and durable local notes
    ├── knowledge/                      development experience, with topic indexes and separate entries
    ├── feature-list-revisions.json      Product/Coding-Rules synchronization history
    ├── test-registry.json               component/test traceability and safety-net index
    ├── feature-completion-evidence.json current-snapshot Feature completion evidence
    ├── coding_rules.md                  collaboration and stack-independent architecture
    ├── progress.md                      current state, blockers, decisions, next action and history index
    ├── progress/                        one historical body per Feature or approved batch
    ├── architecture.md                  optional human-owned module/dependency overview
    ├── architecture/                    optional subsystem maps and important technical ADRs
    └── methodology-config.json          language, environment, and verification commands
```

## Skill groups

| Group | Skills | Responsibility |
| --- | --- | --- |
| Clarification | `project-clarifier` | Focused discussion; hand approved terminology to the existing writer only when documentation is requested. |
| Product | `product-init-elicitor`, `product-change-standardizer`, `product-spec-elicitor`, `product-ui-sketcher`, `product-audio-sketcher` | Define or change Product intent. |
| Planning | `generate-feature-list`, `sync-feature-list` | Decompose one Product at a time; preserve stable Feature IDs and trace actual source changes to existing work. |
| Engineering | `engineering-change-standardizer`, `pick-refactor-smell` | Create controlled engineering work when Product intent stays fixed: bugs, refactors, maintenance. |
| Delivery | `execute-next-feature` | Implement exactly one approved Feature through verification, applicable human acceptance, user-requested independent review, completion, and handoff. |
| Guidance | `yaya-next-step-advisor` | Explain current state; provide a scoped continuation prompt when needed, without executing or granting approval. |

## Canonical task routing

This table owns task routing. Guidance Skills read it and the destination
workflow; they do not maintain an independent lifecycle or approval table.

| Task type | Entry | Boundary |
| --- | --- | --- |
| Discuss an idea, design choice or ambiguous term | `project-clarifier` | Ask only useful questions; conversation alone writes nothing and needs no Product or ready environment. |
| Record or maintain settled project vocabulary | `project-clarifier` → `product-change-standardizer` | Write only within existing authorization. Meaning-preserving definitions/links do not initialize Product or synchronize Features; substantive behavior changes use the Product route. |
| Explicitly requested prototype / technical spike | Scoped experiment in the target project | Answer one hypothesis within the authorized change/run scope and budget. An experiment inside a Feature keeps its workflow; independent exploration need not create a full Product/Feature chain. |
| Establish layout, resource scale and interaction readability before dependent logic | Current Product planning and delivery, or an explicitly requested scoped experiment | Apply [Visual prototype before dependent implementation](01-product-doc-structure.md#visual-prototype-before-dependent-implementation); sketchers supply requirements, while the runnable Godot scene and applicable human acceptance belong to execution. |
| New Feature / Product change | `product-change-standardizer` | Update Product, handle existing-work impacts, and defer later Products' initial decomposition. |
| Existing implementation without adequate Product/Feature records | `product-change-standardizer` → existing planning/delivery routes | Confirm intent and adopt the current module under [Adopting existing implementation](02-feature-list-schema.md#adopting-existing-implementation); reuse working behavior, preserve real history and finish only authorized gaps and verification. |
| Decompose the current Product | `generate-feature-list` | Append only this Product's plan; finish its required Features before initially decomposing the next Product. |
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

Product execution order governs the planning horizon: one Product's Features
are decomposed and completed before the next Product is decomposed. Revisit
later requirements using actual experience instead of allocating all future
tasks up front. Use [Product-by-Product planning](02-feature-list-schema.md#product-by-product-planning)
with the existing Product documents and Feature sources/statuses; no extra
Product queue or planning-state file is needed.

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

## Reuse project knowledge

Before choosing an approach for planning, investigation, development or review,
consult `docs/knowledge/README.md`, then the relevant topic indexes and experience
entries. Use project evidence before repeating external research;
verify its conditions against the current task and target version. This is
scoped reading, not a requirement to load the whole directory or to accept
historical notes as rules. Reuse prior reading when continuing unchanged work.

Capture useful task learning in that directory during authorized documentation,
with one entry per reusable approach or lesson and links to its original
task evidence. Follow the directory README and [knowledge ownership](09-artifact-lifecycle.md#project-knowledge).
No matching entry, no new learning, and a read-only task are normal outcomes.
Feature documentation is finalized before the Stage 7 commit; Stage 8 reports it.

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
   ├─ Discuss or clarify the current idea
   │      ↓
   │  project-clarifier → conversation result
   │      └─ Authorized terminology documentation
   │            → product-change-standardizer terminology route → STOP
   │
   ├─ Formalize new, changed, missing, or ambiguous Product intent
   │      ↓
   │  product-change-standardizer
   │      ↓
   │  Product docs → decompose current Product / sync existing-work impacts
   │                 later Products remain at document level until their turn
   │
   └─ Product intent is already explicit and should stay fixed
          ↓
      engineering-change-standardizer
          ├─ bug
          ├─ refactor
          └─ maintenance
          ↓
      approved engineering Feature

Product and engineering paths
   ↓
execute-next-feature
   ↓
implementation → automated verification → human acceptance when required by the approved plan
   ↓
optional independent review when requested at this point; otherwise proceed
   ↓
Feature completion gate → done
   ↓
handoff → continue within existing authorization, otherwise STOP
```

A reported bug must be classified before any Product edit:

- documented expected behavior exists and implementation violates it → `engineering-change-standardizer` in `bug` mode;
- expected behavior is missing, contradictory, or intentionally changing → `product-change-standardizer`.

## Delivery control points

Apply [Authorization and continuation](03-execute-loop.md#authorization-and-continuation)
at these control points; reuse decisions that already cover the concrete action:

1. A proposed Product or engineering change must be approved before durable planning writes that require approval.
2. `execute-next-feature` Stage 1 requires explicit approval before implementation begins.
3. Stage 1 decides acceptance from the requirement. Visual/audio/game-feel or other human judgment requires manual mode and Stage 5; fully automated AC may use automated mode and omit Stage 5. Empty checks do not make this decision.
4. Bug Guardrail promotion into Coding Rules requires explicit approval.
5. Stage 8 reports completion and continues only within the user's remaining authorization. Stop at the requested scope boundary or a missing decision.

## Stage 0–8 delivery loop

```text
Clean worktree gate (new task) / verify task ownership (resumed task)
   ↓
Stage 0   Require ready environment; select Feature; consult relevant knowledge; load Context / Rules Snapshot
   ↓
Stage 1   Test Impact Review + resource preflight → explicit human approval
   ↓
Stage 2   Mark in_progress; persist approved verification plan/registry entries
   ↓
Stage 3   Existing Safety Net baseline → TDD RED/GREEN → focused implementation
   ↓
Stage 4   Required Test Set + static/full checks → test evidence + human checklist
   ↓
Stage 5   Explicit human acceptance only for approved manual mode
   ↓
Stage 5.5 Bug only: capture Root cause / Trigger / Regression / Guardrail
   ↓
Stage 6   Optional user-requested review; may instead review several completed Features together
   ↓
Stage 7   Run completion checks; mark done; finalize useful knowledge; stage task-owned changes; commit; verify status
   ↓
Stage 8   Report results; continue authorized next work or stop at the scope/decision boundary
```

## Explicit project checks

No automatic tool events are registered. The Agent reads Git status and follows
the current task's Skill. Editing a file or ending a reply does not trigger a
second workflow.

`tools/checks/check-feature-list.py` validates the ledger, Registry and
dependencies; `--eligible` lists pending work whose prerequisites are satisfied.

`tools/testing/run-gdunit-tests.py --feature F0XX` reads the current Feature/Registry and selects tests directly.
`.agents/skills/execute-next-feature/scripts/record-feature-completion.py` records actual results and human
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
