# 00 · Methodology overview

> This is the canonical mental model for the workflow. Skills guide the work; project checks are invoked explicitly.

The project has one user coordinating Agent work. Pause, switch and resume tasks through existing records and real Git differences in the task's target checkout. Worktree use follows the Core Git contract and actual task authorization rather than being default setup. Multi-user attribution is outside scope; focused research and independent review remain available under their contracts.

## Mental model: specification and execution

```text
methodology/                         canonical workflow specification
     │
     ├──────────────→ Skills         agent-executable workflows
     │                    │
     │                    ▼
     │               project docs/  durable GDD, Product, Feature, Rules, Progress
     │                    ▲
     └──────────────→ Commands       explicit validation when the task needs it
```

The project knowledge layer is:

```text
<repo>/
├── agent-rules/                         repository-specific concrete implementation rules
└── docs/
    ├── gdd/                            game-design authority, created and maintained as needed
    ├── product.md + product/*.md        delivery pre-decomposition and current Product scope
    ├── unadopted-ideas.md               ideas not adopted as requirements or delivery commitments
    ├── terminology.md                  optional domain terms and shared definitions
    ├── art/, audio/, ui/, localization/ optional professional specifications, owned by specialist Skills
    ├── resource-requirements/           shared resource specifications and preparation details
    ├── feature-list.json                lightweight Feature index: Todo/status
    ├── features/F0XX.json               Feature detail and durable local notes
    ├── features/F0XX-design.md          optional detailed design of one Feature
    ├── knowledge/                      development experience, with topic indexes and separate entries
    ├── research/                       optional cited external research; not project requirements
    ├── feature-list-revisions.json      governing-source synchronization history
    ├── test-registry.json               component/test traceability and safety-net index
    ├── feature-completion-evidence.json current-snapshot Feature completion evidence
    ├── project-rules.md                 project constraints, collaboration and design principles
    ├── progress.md                      current state, blockers, decisions, next action and history index
    ├── progress/                        one historical body per Feature or approved batch
    ├── architecture.md                  optional human-owned module/dependency overview
    ├── architecture/                    optional subsystem maps and important technical ADRs
    └── methodology-config.json          language, environment, and verification commands
```

New projects include short purpose/pending-state notices in fixed documents and directory navigation for future multi-file content. These are not a GDD, a delivery plan, confirmed professional decisions, tasks or historical results. Their owning contracts below govern when useful content is added; document presence alone does not determine the workflow state.

## Skill groups

| Group | Skills | Responsibility |
| --- | --- | --- |
| Clarification | `project-grill-me` | Resolve material uncertainty and return settled answers to the current task. |
| Linked uncertainty | `wayfinder-godot` | Resolve mutually dependent unknowns using only the discussion, research or experiment the current gap needs. |
| Feedback and diagnosis | `feedback-triage-godot`, `bug-diagnosis-godot` | Classify feedback against current evidence, or investigate the cause of a concrete abnormal behavior; return to the owning authorized task. |
| Project environment | `project-environment-godot` | Configure or recover project tools and complete a needed first resource scan under the existing environment contract. |
| Scoped verification | `project-verification-godot` | Run requested parsing, lint, existing tests or scoped scene checks and report actual results. |
| Human acceptance | `manual-acceptance-godot` | Prepare a Feature's pending checklist or record actual user results under the existing acceptance contract. |
| Verification evidence | `verification-evidence-godot` | Inspect, import or recover existing evidence and route necessary reruns or human follow-up. |
| Prototyping | `prototype-godot` | Build and inspect a bounded Godot UI or logic prototype within an existing Feature or authorized experiment. |
| Worktree preparation | `worktree-create-godot` | Prepare or reuse the intended checkout and the local conditions required for its authorized task. |
| Worktree integration | `worktree-integrate-godot` | Bring selected results into the intended target, including resuming authorized conflicts, and verify the combined result. |
| Plan inspection | `plan-review-godot` | Inspect an existing GDD, Product or Feature proposal and return findings to its owner; no mandatory planning gate. |
| Development retrospective | `retro-godot` | Use actual task evidence to suggest focused improvements to project workflows, rules or tools. |
| Recurring work design | `loop-me-godot` | Design reusable handling for a user-identified recurring or anticipated activity; compare existing entries, Skills, documentation and tools. |
| Terminology | `project-terminology` | Maintain meaning-preserving definitions and links without starting Product planning. |
| Game design | `design-gdd` | Develop ideas into GDD and deepen, revise or consolidate game design. |
| Numerical design | `design-balance` | Derive or adjust models, formulas and parameters; maintain their scoped GDD body within authorization. |
| Product delivery | `product-author`, `product-spec-elicitor` | Clarify, derive and maintain delivery scope from sufficiently clear GDD design. |
| Professional design | `design-ui-spec`, `design-audio-asset-spec`, `design-art-direction`, `design-audio-direction`, `design-visual-asset-spec`, `design-localization-spec` | Maintain the applicable UI, art, sound, resource and localization specifications directly. |
| Integration and measurement | `content-asset-integration`, `content-localization`, `diagnostics-instrumentation`, `diagnostics-performance`, `diagnostics-soak-test` | Supply independently callable methods within the owning authorized task. |
| Independent review | `review-code`, `review-ux`, `review-art`, `review-audio`, `review-assets`, `review-localization`, `review-balance` | Separate methods, selected by requested scope and executed by a fresh reviewer instance. |
| Planning | `feature-plan`, `feature-sync` | Decompose one Product at a time; preserve stable Feature IDs and trace actual source changes to existing work. |
| Engineering | `engineering-change-plan`, `engineering-refactor-select` | Create controlled engineering work when Product intent stays fixed: bugs, refactors, maintenance. |
| Delivery | `feature-execute` | Implement exactly one approved Feature through verification, applicable human acceptance, user-requested independent review, completion, and handoff. |
| Implementation guidance | `implementation-guidance-godot` | Prepare constraints, design, necessary implementation dependencies and verification reasoning for an existing Feature; reuse its optional design document. |
| Guidance | `project-next-step-advisor` | Explain current state; provide a scoped continuation prompt when needed, without executing or granting approval. |
| Task handoff | `task-handoff-godot` | Preserve a requested stop point and prepare continuation context using existing records; do not create or message another conversation. |

## Canonical task routing

This table owns task routing. Guidance Skills read it and the destination workflow; they do not maintain an independent lifecycle or approval table. Apply [GDD creation and the development prerequisite](01-product-doc-structure.md#gdd-prerequisite-and-authority): initial GDD design and its supporting clarification, numerical modeling and draft review may start from known goals and available material. Delivery planning, implementation, engineering repairs and runnable experiments require substantive current-scope design. If that input is missing, explain the design route without starting an unrequested interview or inventing requirements.

| Task type | Entry | Boundary |
| --- | --- | --- |
| Develop a game idea, write or deepen a GDD, or consolidate design materials | `design-gdd` | Begin with available goals and sources, distinguish assumptions and adopted decisions, and write only within authorization. No complete GDD, Product, Feature or ready engine is required for this design work. |
| Design or adjust numerical models, formulas and parameters | `design-balance` | Use known experience goals and rules, including an early GDD draft. Directly maintain the authorized numerical topic; gameplay changes return to overall design, runtime changes to implementation. Formal balance review uses `review-balance`. |
| Clarify a game-design choice, delivery boundary or ambiguous term | `project-grill-me`, or `product-spec-elicitor` for delivery questions | Ask only useful questions; discussion alone writes nothing. Initial GDD design may reuse the shared method without starting another interview. |
| Resolve several material unknowns whose answers affect one another | `wayfinder-godot` | Follow actual decision dependencies and choose only needed methods. Preserve discussion-only limits or existing implementation authority; no compulsory interview, prototype, worktree or new record type. |
| Assess feedback or an external report before choosing work | `feedback-triage-godot` | Check current facts, distinguish defects, changed intent, existing coverage and evidence gaps, then identify the owner. Classification does not authorize a repair or create a Feature. |
| Investigate the cause of a concrete abnormal behavior | `bug-diagnosis-godot` | Test relevant hypotheses within the authorized evidence/run scope. Keep unknown causes explicit; an investigation-only request does not permit implementation changes. |
| Examine a GDD draft/document or a Product/Feature proposal | `plan-review-godot` | Read only the requested topics or whole-document scope; GDD review does not require a Product or Feature. Return findings to the source owner. Formal independent review follows methodology 12; neither kind advances a Stage or creates a mandatory review gate. |
| Reflect on actual task experience, including observed recurring friction | `retro-godot` | Return evidence-based improvement suggestions and their proper owners. No automatic rule edits, reports, checks or new work items; subsequent implementation follows existing authorization. |
| Design how to handle a recurring or anticipated project activity identified by the user | `loop-me-godot` | Compare existing capabilities and propose a useful entry, inputs, decisions, outputs and ownership of details. No prior failure is required; this callable design method adds no Stage or automatic implementation, and existing implementation authority returns to its owner. |
| Investigate external facts or compare approaches | Coordinating agent, optionally delegating to `researcher` under [External research](#external-research) | Choose search depth and retention by the actual question; no mandatory research Stage, new Feature or automatic adoption. |
| Record or maintain settled project vocabulary | `project-terminology` | Write only within existing authorization. Meaning-preserving definitions/links do not create Product plans or synchronize Features; substantive behavior changes use the GDD design route. |
| Maintain project-wide or specialized rules | Current authorized task, using [incremental rule maintenance](04-coding-rules-4-layers.md#incremental-rule-maintenance) | Report every proposed rule change before writing; reuse specific authority, obtain missing substantive decisions and handle actual downstream impacts. No artificial Feature is required for standalone rule documentation. |
| Explain a Feature design or important technical decision | Current planning/design task under [Feature design](02-feature-list-schema.md#feature-design-and-implementation-notes-optional) and [architecture/ADR](10-architecture-overview.md) | Create detailed Markdown only when useful or requested; an ADR needs a real qualifying choice. Preserve Product and project-rule authority. |
| Choose visual or sound direction | `design-art-direction` / `design-audio-direction` | Own the confirmed shared specification under [specialist work](11-specialist-workflows.md); do not require an entire game's design or produce assets. |
| Specify an interface or individual assets | `design-ui-spec`, `design-visual-asset-spec`, `design-audio-asset-spec` | Refine and reference GDD requirements in professional sources; Product owns delivery scope and source mapping. |
| Prepare visual art, music or sound effects | Production capability reserved in [specialist work](11-specialist-workflows.md#design-production-integration-and-review) | Record specifications and available resources; no production Skill is implemented yet. |
| Define language coverage and locale conventions | `design-localization-spec` | Own the approved localization source within GDD design; domain meanings stay with GDD/terminology. Specification work may stand alone. |
| Integrate supplied assets or implement approved localization | `content-asset-integration` / `content-localization` | Runtime changes consume approved specifications and return to the owning authorized Feature/experiment. |
| Add diagnostic signals, measure performance or run a soak scenario | `diagnostics-instrumentation` / `diagnostics-performance` / `diagnostics-soak-test` | Separate instrumentation, measurement, diagnosis and authorized repair; report actual evidence and limits. |
| Explicitly requested prototype / technical spike | `prototype-godot` in the target project | Answer one hypothesis with actual Godot UI or logic under the authorized change/run scope and budget; apply [Scoped logic prototypes](01-product-doc-structure.md#scoped-logic-prototypes) when testing logic. An experiment inside a Feature keeps its workflow; independent exploration need not create a full Product/Feature chain. |
| Prepare or reuse a separate checkout for an authorized task | `worktree-create-godot` | Establish the intended base, target directory and necessary local preparation under the Core Git contract. Existing changes remain protected; separate checkout paths do not establish runtime-data isolation. |
| Bring an adopted worktree result into a target, or resume its interrupted/conflicted integration | `worktree-integrate-godot` | Identify source, target and selected scope; validate the combined result under current acceptance and commit conditions. Conflict handling is its conditional reference, not a separate entry. Integration does not select a winner or authorize cleanup. |
| Establish layout, resource scale and interaction readability before dependent logic | `prototype-godot` within current Product planning/delivery or an authorized experiment | Apply [Visual prototype before dependent implementation](01-product-doc-structure.md#visual-prototype-before-dependent-implementation); sketchers supply requirements, while the runnable Godot scene and applicable human acceptance belong to execution. |
| Analyze and hand off the minimum resource files for a task | Current task coordinates `design-visual-asset-spec` / `design-audio-asset-spec` as needed | Apply [Resource preparation list and handoff](01-product-doc-structure.md#resource-preparation-list-and-handoff); requirements, production and integration have separate scopes. |
| Pre-decompose delivery scope from an existing GDD | `product-author` | Write or revise only the requested `product.md` horizon, boundaries, source mapping, dependencies and suggested order. |
| Revise game design | `design-gdd`, or `design-balance` for scoped numerical design | Update the owning GDD topic, coordinate affected sources and existing work within authorization; a design edit does not automatically create a Product or Feature. |
| Revise current Product delivery scope | `product-author` | Update the owning Product, handle existing-work impacts, and keep future Products at pre-decomposition level. |
| Existing implementation without adequate Product/Feature records | `product-author` → existing planning/delivery routes | Use confirmed existing GDD design to define the current delivery under [Adopting existing implementation](02-feature-list-schema.md#adopting-existing-implementation); reuse working behavior, preserve real history and finish only authorized gaps and verification. |
| Detail the next Product after current delivery completes | `product-author` → `feature-plan` when authorized | Revisit current GDD and the candidate, write this Product's delivery document, then plan its complete necessary scope. |
| Decompose the current Product | `feature-plan` | Append only this Product's plan; finish its required Features before initially decomposing the next Product. |
| Source synchronization | `feature-sync` | Trace additions, revisions, splits, merges and dependency/test retirement migrations. |
| Continue current Feature | `feature-execute` | Resume the actual Stage and existing authorization; “continue” alone does not grant missing approval or acceptance. |
| Execute eligible planned Feature | `feature-execute` | Select by the dependency DAG, present Stage 1 and preserve its approval boundary. |
| Prepare implementation guidance for an existing Feature | `implementation-guidance-godot`, normally used by the main agent | Only explicit user delegation or still-valid task authorization selects `implementation-advisor`; complexity alone does not. Follow the Skill's model, question relay, limited design-writing and stop-on-failure contract, then return to the owning Feature. |
| Bug in current unfinished Feature | Current Feature repair route | Reproduce and repair within its scope; keep failure evidence and relevant regression coverage. |
| Independent Bug in completed behavior | `engineering-change-plan` in bug mode | Restore a confirmed Product, professional or tool contract; changed requirements return to their owner. |
| Refactor | `engineering-change-plan` in refactor mode | Preserve behavior; use `engineering-refactor-select` first only when selecting a smell is requested. |
| Maintenance | `engineering-change-plan` in maintenance mode | Define technical success, compatibility, migration and validation. |
| Project tooling issue | `engineering-change-plan` | Describe the actual technical problem and repair the project-owned tool within the authorized scope. |
| Audit | Applicable review Skill in a fresh `independent-reviewer` instance | Follow [independent review](12-independent-review.md): reviewed artifacts stay read-only, permitted validation uses isolation; no repair or human acceptance is implied. |
| Configure, update or recover project tools, or complete a needed first resource scan | `project-environment-godot` | Use the existing configuration and Bootstrap contract in [document language and environment](05-document-language.md). Preparation does not prove game behavior or require a new Feature. |
| Run requested parsing, lint, existing tests or a scoped scene check | `project-verification-godot` | Preserve the requested check kinds and each method's required scope. With or without a Feature, report actual results without adding repair, human acceptance or whole-delivery completion. |
| Prepare pending human checks or record actual user acceptance | `manual-acceptance-godot` | Follow [manual acceptance](manual-acceptance-files.md) for the actual Feature, scope and snapshot. Preparing checks is not acceptance; recording results does not advance a Stage or supply separate commit permission. |
| Inspect, import or recover existing verification evidence | `verification-evidence-godot` | Apply the existing [evidence and freshness contract](08-testing-strategy.md#artifact-backed-completion-and-semantic-freshness). Distinguish reference repair, missing originals, stale results and interrupted runs; route only necessary execution or human follow-up. |
| Status query | Read-only state explanation | Report current facts and next legal action; do not start work or call readiness checks merely to answer. |
| Save a requested pause or prepare another conversation to continue the same task | `task-handoff-godot` | Use existing Progress/Feature or task records and current Git facts. Preserve an explicit pause; supply copyable continuation text when requested, without a new Feature, handoff ledger, conversation or message. |

Product execution order governs both detailed writing and Feature planning: first pre-decompose the agreed delivery horizon in `product.md`, then write only the current Product document and decompose its complete necessary scope into multiple Features. Complete those Features before detailing the next Product. Revisit later candidates and GDD dependencies using actual experience. Use [Product-by-Product planning](02-feature-list-schema.md#product-by-product-planning) with existing documents and Feature sources/statuses; no extra Product queue or planning-state file is needed.

Choose investigation, planning or execution from the available evidence and current user authorization. Feedback triage, diagnosis, environment preparation, scoped verification, manual acceptance and evidence handling are callable methods, not additional mandatory Stages. Use them where the current task needs the capability, including a direct bounded request; their return does not end already authorized work through its existing owner or expand a limited check into full delivery. Drafted task prompts follow [Continuation prompts](09-artifact-lifecycle.md#continuation-prompts), regardless of task size; the format does not create new steps or authority. Current user authorization takes precedence over generic workflow wording, but implementation approval never implies human acceptance.

Wayfinding, worktree preparation and integration are also independent capabilities, not a fixed sequence. Ordinary questions can use clarification directly; clear work continues its owner. Retained exploration findings use the existing [artifact ownership](09-artifact-lifecycle.md) and [ADR threshold](10-architecture-overview.md#architecture-decision-records), while Git mutations remain governed by `agent-rules/00-core/git-worktree-and-commits.md`.

Prototype observations and tentative parameters are not approved GDD design or Feature acceptance. Keep the question, observed result, decision and experiment file disposition in current Feature notes, or current Progress when no Feature exists. Adopting game-design changes updates the existing GDD and affected delivery scope; technical outcomes return to the engineering entry above. Exceeding the experiment budget requires user direction.

## Reuse project knowledge

Before choosing an approach for planning, investigation, development or review, or repeating external research, follow [project knowledge lookup](../docs/knowledge/README.md#find-relevant-knowledge-first).

Capture useful task learning during authorized documentation under [knowledge maintenance](../docs/knowledge/README.md#maintain-during-authorized-work) and [knowledge ownership](09-artifact-lifecycle.md#project-knowledge). Feature documentation is finalized before the Stage 7 commit; Stage 8 reports it.

## External research

The coordinating agent judges whether existing evidence is sufficient, a direct lookup would help, or a bounded investigation merits delegation to `researcher`. This choice can arise during discussion, planning, implementation or diagnosis; no Stage, topic or Feature automatically requires research. Reuse relevant knowledge and previous research while checking applicability, rather than repeating searches.

For delegated research, use `.codex/agents/researcher.toml` when supported and actually selected by the client. Pass the question, concrete target versions where relevant, project constraints, useful existing evidence, and whether/where to save a report. Keep independent work moving; decisions depending on the findings wait for them. The role owns research methods and report content. Direct lookups use its applicable source/version guidance without requiring a subagent or a full report. If the client cannot select the role, use the available agent with those instructions or research directly, accurately identifying the execution used.

Prefer the available user-installed `anysearch` Skill; it is an external tool dependency, not copied into this project. The role permits autonomous fallback to other available search methods. Research reports live in `docs/research/` only when useful and authorized; [artifact ownership](09-artifact-lifecycle.md#external-research) separates them from requirements, runtime evidence and learned project experience. The coordinating agent checks applicability, adopts decisions within current authorization, finalizes any task-owned documentation/commit and continues the owning task. Neither a research result nor a search failure changes that authority.

## Project environment and workflow

This project uses Godot 4.7 / GDScript / gdunit4 on Windows 11. Copied tool paths have not yet been verified on this machine. A first-use request lets the Agent configure actual executable paths directly in docs/methodology-config.json, then run `tools/checks/check-project-environment.py --require-ready`. Project creation already establishes Git and its initial local commit.

### Workflow entry

```text
User request
   │
   ├─ Create or revise game design, including from an idea
   │      ↓
   │  design-gdd / design-balance → discussion or authorized GDD writing
   │      continue through affected delivery owners only within authorization
   │
   ├─ Clarify a design or delivery choice
   │      ↓
   │  project-grill-me → conversation result
   │
   ├─ Document already settled terminology
   │      ↓
   │  project-terminology → return to caller / finish
   │
   ├─ Inspect an actual GDD draft/document or delivery proposal
   │      ↓
   │  plan-review-godot → findings; source remains read-only
   │
   ├─ Define/revise delivery scope from substantive GDD
   │      ↓
   │  product-author
   │      ↓
   │  pre-decomposition → current Product → complete Feature plan
   │       sync existing-work impacts; later Products remain candidates
   │
   └─ Existing GDD design and delivery intent should stay fixed
          ↓
      engineering-change-plan
          ├─ bug
          ├─ refactor
          └─ maintenance
          ↓
      approved engineering Feature

Product and engineering paths (missing substantive GDD blocks dependent work)
   ↓
feature-execute
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

- documented expected behavior exists and implementation violates it → `engineering-change-plan` in `bug` mode;
- expectations in a GDD are missing, contradictory, or intentionally changing → their owner: `design-gdd` for game design, `design-balance` for scoped numerical design, the specialist for professional specifications; `product-author` handles delivery-boundary choices.

## Delivery control points

Apply [Authorization and continuation](03-execute-loop.md#authorization-and-continuation) at these control points; reuse decisions that already cover the concrete action:

1. A proposed Product or engineering change must be approved before durable planning writes that require approval.
2. `feature-execute` Stage 1 requires explicit approval before implementation begins.
3. Stage 1 decides acceptance from the requirement. Visual/audio/game-feel or other human judgment requires manual mode and Stage 5; fully automated AC may use automated mode and omit Stage 5. Empty checks do not make this decision.
4. Bug Guardrail promotion into Project Rules requires explicit approval.
5. Stage 8 reports completion and continues only within the user's remaining authorization. Stop at the requested scope boundary or a missing decision.

## Stage 0–8 delivery loop

```text
Inspect and preserve Git changes; recover the current task's actual stop point
   ↓
Stage 0   Confirm existing GDD and ready environment; select Feature; load relevant knowledge and Context / Rules Snapshot
   ↓
Stage 1   Test Impact Review + resource preflight → explicit human approval
   ↓
Stage 2   Mark in_progress; persist approved verification, needed design and decisions
   ↓
Stage 3   Baseline → per-behavior RED/GREEN/refactor → documentation checkpoint
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

No automatic tool events are registered. The Agent reads Git status and follows the current task's Skill. Editing a file or ending a reply does not trigger a second workflow.

`tools/checks/check-feature-list.py` validates the ledger, Registry and dependencies; `--eligible` lists pending work whose prerequisites are satisfied.

`tools/testing/run-gdunit-tests.py --feature F0XX` reads the current Feature/Registry and selects tests directly. `tools/features/record-feature-completion.py` records actual results and human decisions. Its `validate --feature F0XX` command checks completion evidence before the Agent records completion. Test, static and acceptance requirements remain those of the execution Skill.

Report actual verification scope and review findings in ordinary language. Result references and explicit decisions are stored by the Skill helper, not parsed from conversation summaries.

## Scope boundary for this personal-project workflow

This methodology covers GDD creation from game ideas and ongoing design, numerical modeling and tuning, Product delivery planning, engineering changes, Feature planning, implementation, automated testing, human acceptance, defect learning, refactoring review, maintenance, and local Git-safe handoff. Early design does not remove the substantive-GDD and current-scope clarity prerequisites for dependent development.

Release management, store submission, public version announcements, deployment approval, publishing workflow, and distribution governance are outside the default methodology unless the user explicitly defines one of them as project work.

## Further reading

| Topic | File |
| --- | --- |
| Product document structure | [01-product-doc-structure.md](./01-product-doc-structure.md) |
| Feature ledger schema and invariants | [02-feature-list-schema.md](./02-feature-list-schema.md) |
| Stage 0–8 execution loop | [03-execute-loop.md](./03-execute-loop.md) |
| Project Rules architecture and bug-guardrail promotion | [04-coding-rules-4-layers.md](./04-coding-rules-4-layers.md) |
| Document language and verification configuration | [05-document-language.md](./05-document-language.md) |
| Document-language smoke scenarios | [06-document-language-smoke-scenarios.md](./06-document-language-smoke-scenarios.md) |
| Engineering change classification and creation | [07-engineering-change.md](./07-engineering-change.md) |
| Test traceability, TDD, regression/invariant selection | [08-testing-strategy.md](./08-testing-strategy.md) |
| Reports, explicit cleanup and Progress history | [09-artifact-lifecycle.md](./09-artifact-lifecycle.md) |
| Optional architecture overview and ADRs | [10-architecture-overview.md](./10-architecture-overview.md) |
| Professional ownership, sources and production boundaries | [11-specialist-workflows.md](./11-specialist-workflows.md) |
| Independent review, permissions and evidence limits | [12-independent-review.md](./12-independent-review.md) |
