# 00 · Methodology overview

> This is the entry to the project workflow: how the methodology, Skills, project documents and commands relate, and which entry handles each kind of task.

The methodology covers game design from an idea onward, numerical modeling and tuning, Product delivery planning, Feature planning and implementation, engineering changes, automated testing, human acceptance, defect learning and local Git-safe handoff. Release management, store submission, public version announcements, deployment approval, publishing workflow, and distribution governance are outside the default methodology unless the user explicitly defines one of them as project work.

## Mental model: specification and execution

```text
methodology/                         canonical workflow specification
     │
     ├──────────────→ Skills         agent-executable workflows
     │                    │
     │                    ▼
     │               project docs/  maintained GDD, Product, Feature, Rules, Progress
     │                    ▲
     └──────────────→ Commands       explicit validation when the task needs it
```

- `methodology/` defines the workflow. Skills under `.agents/skills/` carry it out.
- Project documents live under `docs/`; [docs/README.md](../docs/README.md) describes each file and directory. New projects ship pages that only state their purpose; their presence is not a GDD, a delivery plan or a decision.
- `docs/methodology-config.json` holds `document_language` and the Python and Godot executable paths, under [document language](05-document-language.md) and [project environment](06-project-environment.md).
- Commands under `tools/` run only when a task calls them. No tool runs automatically when a file changes or a reply ends.

## Skill groups

| Group | Skills |
| --- | --- |
| Game design | `design-gdd`, `design-balance` |
| Product delivery | `product-author`, `product-spec-elicitor` |
| Clarification and terminology | `project-grill-me`, `wayfinder-godot`, `project-terminology` |
| Professional design | `design-game-presentation`, `design-ui-spec`, `design-art-direction`, `design-audio-direction`, `design-visual-asset-spec`, `design-audio-asset-spec`, `design-localization-spec` |
| Planning | `feature-plan`, `feature-sync`, `plan-review-godot` |
| Delivery | `feature-execute`, `implementation-guidance-godot`, `prototype-godot` |
| Engineering | `engineering-change-plan`, `engineering-refactor-select` |
| Feedback and diagnosis | `feedback-triage-godot`, `bug-diagnosis-godot` |
| Environment, verification and evidence | `project-environment-godot`, `project-verification-godot`, `manual-acceptance-godot`, `verification-evidence-godot` |
| Integration and measurement | `content-asset-integration`, `content-localization`, `diagnostics-instrumentation`, `diagnostics-performance`, `diagnostics-soak-test` |
| Independent review | `review-code`, `review-ux`, `review-art`, `review-audio`, `review-assets`, `review-localization`, `review-balance` |
| Worktrees | `worktree-create-godot`, `worktree-integrate-godot` |
| Guidance, handoff and improvement | `project-next-step-advisor`, `task-handoff-godot`, `retro-godot`, `loop-me-godot` |
| Documentation writing | `technical-documentation-writing-godot` |

## Canonical task routing

This table is the single source for task routing. Guidance Skills read it together with the destination workflow; they keep no separate lifecycle or approval table. Every row that plans delivery, implements, repairs or runs an experiment needs a substantive GDD under [GDD prerequisite and authority](01-product-doc-structure.md#gdd-prerequisite-and-authority). The Boundary column says when to choose the entry and what it does not include.

| Task type | Entry | Boundary |
| --- | --- | --- |
| Develop a game idea, write or deepen a GDD, or consolidate design materials | `design-gdd` | Starts from the available goals and sources; no complete GDD, Product, Feature or ready engine is needed. Does not create a Product or Feature. |
| Design or adjust numerical models, formulas and parameters | `design-balance` | Use for models and values, including on an early GDD draft. Gameplay changes go to `design-gdd`, runtime changes to implementation, and formal balance review to `review-balance`. |
| Clarify a game-design choice, delivery boundary or ambiguous term | `project-grill-me`, or `product-spec-elicitor` for delivery questions | Use when a material uncertainty affects the current task. Discussion alone writes nothing. |
| Resolve several material unknowns whose answers affect one another | `wayfinder-godot` | Use when the unknowns depend on each other. No compulsory interview, prototype, worktree or new record type; it does not widen the task's authorization. |
| Assess feedback or an external report before choosing work | `feedback-triage-godot` | Use before deciding what work the feedback needs. Classification does not authorize a repair or create a Feature. |
| Investigate the cause of a concrete abnormal behavior | `bug-diagnosis-godot` | Use for a specific failure. An investigation-only request does not permit implementation changes. |
| Examine a GDD draft or document, or a Product or Feature proposal | `plan-review-godot` | Use for findings returned to the document's author; a GDD review needs no Product or Feature. Not a formal [independent review](12-independent-review.md), and not a mandatory gate. |
| Reflect on actual task experience, including recurring friction | `retro-godot` | Use with evidence from real tasks. Returns suggestions only; no automatic rule edits, reports, checks or work items. |
| Design how to handle a recurring or anticipated activity the user names | `loop-me-godot` | Use without waiting for a failure. Returns a design; adds no Stage and implements nothing. |
| Investigate external facts or compare approaches | Coordinating agent, optionally delegating to `researcher` | Use when the answer needs external sources; see [External research](09-records-reports-and-handoff.md#external-research). No mandatory research Stage, new Feature or automatic adoption. |
| Record or maintain settled project vocabulary | `project-terminology` | Use for meaning-preserving definitions under [Project terminology](14-project-terminology.md). Creates no Product plan and synchronizes no Features; behavior changes go to `design-gdd`. |
| Maintain project-wide or specialized rules | Current authorized task, under [incremental rule maintenance](04-project-rules.md#incremental-rule-maintenance) | Use for `docs/project-rules.md` or rule modules. Every proposed change is reported before writing; standalone rule work needs no Feature. |
| Explain a Feature design or an important technical decision | Current planning or design task, under [Feature design](02-feature-list-schema.md#feature-design-and-implementation-notes) and [architecture and ADRs](10-architecture-overview.md) | Implementation design goes in the Feature design file; qualifying technical rationale goes in an ADR. Does not change Product scope or project rules. |
| Choose visual or sound direction | `design-art-direction`, `design-audio-direction` | Use for the shared standards in the Art Bible or Sound Bible under [specialist work](11-specialist-workflows.md). Needs no complete game design; produces no assets. |
| Plan a game moment from experience goals or a casual description, or compare its component approaches | `design-game-presentation` | Use for [presentation documents](11-specialist-workflows.md#game-presentation-documents); can support early GDD exploration. Does not include code, asset production or acceptance. |
| Specify an interface or individual assets | `design-ui-spec`, `design-visual-asset-spec`, `design-audio-asset-spec` | Use for professional specifications that refine the GDD. Delivery scope stays in Product. |
| Prepare visual art, music or sound effects | Reserved under [specialist work](11-specialist-workflows.md#design-production-integration-and-review) | No production Skill exists. Record the specifications and available resources. |
| Define language coverage and locale conventions | `design-localization-spec` | Can stand alone. Game rules stay in the GDD and term definitions in `docs/terminology.md`. |
| Integrate supplied assets or implement approved localization | `content-asset-integration`, `content-localization` | Use inside an authorized Feature or experiment to apply approved specifications; not standalone delivery. |
| Add diagnostic signals, measure performance or run a soak scenario | `diagnostics-instrumentation`, `diagnostics-performance`, `diagnostics-soak-test` | Use to gather evidence. Measurement does not authorize a repair. |
| Explicitly requested prototype or technical spike | `prototype-godot` in the target project | Use to answer one hypothesis under [Prototypes](13-prototypes.md). An independent experiment needs no Product or Feature; one inside a Feature keeps that Feature's workflow. |
| Establish layout, resource scale and interaction readability before dependent logic | `prototype-godot`, within current Product delivery or an authorized experiment | Use under [Visual prototype before dependent implementation](13-prototypes.md#visual-prototype-before-dependent-implementation). Specifications supply the inputs; the runnable scene and human acceptance belong to execution. |
| List and hand off the minimum resource files for a task | Current task, with `design-visual-asset-spec` or `design-audio-asset-spec` as needed | Use under [Resource requirements and handoff](11-specialist-workflows.md#resource-requirements-and-handoff). Does not produce or integrate assets. |
| Prepare or reuse a separate checkout for an authorized task | `worktree-create-godot` | Use when the task needs another checkout. A separate path does not isolate runtime data. |
| Bring an adopted worktree result into a target, or resume an interrupted or conflicted integration | `worktree-integrate-godot` | Use for the selected result and target. Does not choose between competing results or authorize cleanup. |
| Pre-decompose delivery scope from a GDD | `product-author` | Writes only the requested `product.md` horizon. |
| Revise game design | `design-gdd`, or `design-balance` for scoped numerical design | A design edit does not automatically create a Product or Feature. |
| Revise current Product delivery scope | `product-author` | Future Products stay at pre-decomposition level. |
| Implementation exists without adequate Product or Feature records | `product-author`, then the planning and delivery routes | Use under [Adopting existing implementation](02-feature-list-schema.md#adopting-existing-implementation). Needs confirmed GDD design; does not invent history or authorize repairs beyond the stated gaps. |
| Detail the next Product after current delivery completes | `product-author`, then `feature-plan` when authorized | Use after the current Product's required Features are complete, under [Product-by-Product planning](02-feature-list-schema.md#product-by-product-planning). |
| Decompose the current Product | `feature-plan` | Plans only the current Product. |
| Source synchronization | `feature-sync` | Use when committed GDD, Product, professional or rule sources changed. Does not perform initial decomposition. |
| Continue current Feature | `feature-execute` | “Continue” alone does not supply a missing approval or acceptance. |
| Execute an eligible planned Feature | `feature-execute` | Selects by the dependency order; Stage 1 approval still applies. |
| Prepare implementation guidance for a planned Feature | `implementation-guidance-godot`, normally used by the main agent | Delegates to `implementation-advisor` only on explicit user request or still-valid task authorization, never because of complexity alone. |
| Bug in the current unfinished Feature | That Feature's repair route | Repair within its scope with regression coverage. |
| Independent Bug in completed behavior | `engineering-change-plan` in bug mode | Use when behavior violates a documented requirement; missing or changing expectations go to their design owner under [Classification boundary](07-engineering-change.md#classification-boundary). |
| Refactor | `engineering-change-plan` in refactor mode | Behavior stays the same. Use `engineering-refactor-select` first only when the user asks to choose a smell. |
| Maintenance | `engineering-change-plan` in maintenance mode | Use for technical success criteria, compatibility, migration and validation work. |
| Project tooling issue | `engineering-change-plan` | Use for a problem in a project-owned tool. |
| Audit | Matching review Skill in a fresh `independent-reviewer` instance | Use only for a requested formal review under [independent review](12-independent-review.md). Does not repair or supply human acceptance. |
| Configure, update or recover project tools, or complete a needed first resource scan | `project-environment-godot` | Use under [project environment](06-project-environment.md). Does not prove game behavior or need a Feature. |
| Run requested parsing, lint, existing tests or a scoped scene check | `project-verification-godot` | Use with or without a Feature. Reports actual results; does not repair, accept or complete delivery. |
| Prepare pending human checks or record actual user acceptance | `manual-acceptance-godot` | Use under [manual acceptance files](contracts/manual-acceptance-files.md). Preparing checks is not acceptance; recording results does not advance a Stage or grant commit permission. |
| Inspect, import or recover verification evidence | `verification-evidence-godot` | Use under [evidence and freshness](08-test-traceability-and-evidence.md#artifact-backed-completion-and-semantic-freshness). Routes only the reruns or human follow-up actually needed. |
| Status query | Read-only explanation, or `project-next-step-advisor` | Does not start work or run readiness checks just to answer. |
| Save a requested pause or prepare another conversation to continue the same task | `task-handoff-godot` | Creates no Feature, handoff ledger, conversation or message. |

How to apply the table:

- Choose investigation, planning or execution from the available evidence and the user's current authorization. The user's current authorization takes precedence over generic workflow wording.
- Triage, diagnosis, environment work, verification, manual acceptance, evidence handling, wayfinding and worktree work are callable methods, not Stages or a fixed sequence. Use them when the task needs them, including for a direct bounded request.
- A method's return does not end a broader authorized task, and does not turn a limited check into full delivery; see [Authorization and continuation](03-execute-loop.md#authorization-and-continuation).
- Drafted task prompts use [Continuation prompts](09-records-reports-and-handoff.md#continuation-prompts).
- Git operations follow `agent-rules/00-core/git-worktree-and-commits.md`.

## Further reading

| Topic | File |
| --- | --- |
| GDD and Product documents: names, scope, open questions, candidate ideas and Product structure | [01-product-doc-structure.md](01-product-doc-structure.md) |
| Feature ledger schema, revisions and Product-by-Product planning | [02-feature-list-schema.md](02-feature-list-schema.md) |
| Stage 0–8 execution loop, authorization and continuation | [03-execute-loop.md](03-execute-loop.md) |
| Project rules: responsibilities, loading and incremental maintenance | [04-project-rules.md](04-project-rules.md) |
| Document language | [05-document-language.md](05-document-language.md) |
| Tool configuration and Project Environment Bootstrap | [06-project-environment.md](06-project-environment.md) |
| Bug, refactor and maintenance changes | [07-engineering-change.md](07-engineering-change.md) |
| Test traceability, Test Impact Review, TDD and completion evidence | [08-test-traceability-and-evidence.md](08-test-traceability-and-evidence.md) |
| Reports, research, knowledge, Progress and handoff | [09-records-reports-and-handoff.md](09-records-reports-and-handoff.md) |
| Optional architecture overview and ADRs | [10-architecture-overview.md](10-architecture-overview.md) |
| Specialist documents, source mapping, UI and presentation documents, and resource handoff | [11-specialist-workflows.md](11-specialist-workflows.md) |
| Independent review | [12-independent-review.md](12-independent-review.md) |
| Visual and logic prototypes | [13-prototypes.md](13-prototypes.md) |
| Project terminology | [14-project-terminology.md](14-project-terminology.md) |
| How the Agent reads parser and lint results | [contracts/gdscript-lint.md](contracts/gdscript-lint.md) |
| Manual acceptance checklist and result files | [contracts/manual-acceptance-files.md](contracts/manual-acceptance-files.md) |
| Templates for Products, Features, ADRs and other files | [templates/README.md](templates/README.md) |
