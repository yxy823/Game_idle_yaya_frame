---
name: project-next-step-advisor
description: "Explain Godot project status or match the next action to the shared development prompt catalog, drafting a concrete continuation prompt when needed. Use for status questions and next-step advice. Not for doing the requested work itself; advice never replaces implementation."
---

# Read-only next-step guidance

Read the user's intent and current project state, then give a short evidence-based explanation and, when needed, a prompt for continuing with the project's workflow. This Skill does not execute the prompt, edit files, create Features, record acceptance, run tests or generators, clean artifacts, stage files or commit.

Read-only also excludes launching Godot or an import, installing Skills and invoking a documentation-writing Skill. Read task-relevant project material and the shared Godot prompt catalog below; do not inspect unrelated credentials, user saves or other projects. Text and JSON parsing, metadata and verified read-only Git status, log, diff and show are allowed.

## Establish current state

1. Read the project's `AGENTS.md`, `docs/methodology-config.json`, lightweight Feature index and current `docs/progress.md`. Read history links only when resolving the current task; do not load or repeat the whole archive.
2. Determine whether `docs/gdd/` contains actual design, a draft or only navigation and purpose statements. Do not infer adopted design from a directory, file title or scaffold.
   - A missing GDD routes game creation to `design-gdd` and blocks dependent Product planning or implementation until the relevant design exists. Initial design, its clarification, numeric derivation and design review may precede Product and Features.
   - Inspect read-only Git status and the relevant GDD, Product, Feature, detail and Registry records.
   - Configured tool paths are choices, not proof of availability. Use relevant environment and Progress evidence without launching probes. Interpret incomplete machine setup through `methodology/00-overview.md` and `methodology/06-project-environment.md`.
   - The stack is fixed to Godot 4.7, GDScript and gdunit4; missing tools do not mean the engine is undecided.
3. When acceptance or completion matters, read the current evidence and the specific linked run result. Distinguish an old PASS, the current snapshot and pending human acceptance. Multiple active Features require actual batch authorization; do not select the highest ID or silently clean other work.
4. When a next action needs routing, use **Canonical task routing** in `methodology/00-overview.md`, then read the relevant entry and stop conditions of the destination Skill. That table and the destination workflow own routing and approval; this Skill maintains no second workflow.

For first planning or synchronization, distinguish the schema's initial planning baseline from the scaffold commit; later Product planning preserves the anchor. Missing history for implemented work belongs to synchronization's coverage check.

Distinguish GDD design, the delivery outline in `docs/product.md`, the current Product's detailed scope and actual Feature completion. An outline entry is not a detailed Product, and a planned Feature is not completed delivery. For the next Product action, apply **Product-by-Product planning** in `methodology/02-feature-list-schema.md` through the canonical route. Check relevant source changes against planned and completed work; future unrefined Products remain at outline level.

When explaining where game logic, presentation or their collaboration belongs, use the project guide `docs/game-organization.md`. Follow a concrete function from its GDD rules and experience goals to the applicable UI or presentation, actual architecture and Feature verification. These are responsibility views, not new task types or a requirement to split a cross-layer Feature. Route by the user's requested design, implementation or review outcome; do not send every presentation-related task to `design-game-presentation`.

For game-design or delivery choices, read the relevant GDD topics and questions under **Design scope and boundaries** and **Open design questions** in `methodology/01-product-doc-structure.md` before recommending work. Use a question's actual dependency to explain the next decision or evidence needed; unrelated questions do not block a clear task.

For terminology, engineering rules or technical design:

- Read the applicable `docs/terminology.md`, `docs/project-rules.md`, Feature design and architecture or ADR sources. Their owning methodology sections define update authority and the Stage 3 documentation checkpoint; game-design exclusions remain in GDD.
- Judge a missing design or ADR by whether corresponding content or a qualifying decision exists, not by game size or explanation length.
- A proposed rule or accepted ADR is not proof of implementation or verification.
- Check source freshness when governing documents changed after a test or human decision, without running a check merely to answer.

Report a missing file as missing instead of creating it. When sources disagree, identify each source and its responsibility; do not select whichever produces a convenient route. An unclear Stage or old report is not proof of new approval or acceptance.

For implementation guidance on an existing Feature, use the canonical `implementation-guidance-godot` route and read that Skill. The main agent normally prepares the guidance; complexity or asking for advice does not authorize delegation. Preserve explicit user delegation already given for this task, and distinguish it from approval of a proposed design. A failed `implementation-advisor` attempt stops dependent work with its reason; do not recommend automatic model substitution or main-agent takeover. This read-only advisor neither delegates nor writes the design.

## Answer the question and provide a prompt when needed

Classify using the canonical table, including initial GDD design, GDD or numeric design change, Product delivery scope, new or continued Feature, Bug, Refactor, Maintenance, Framework issue, Audit, Human Acceptance follow-up and status query. Investigate ambiguous expected behavior against GDD and the owning professional source, within the Product delivery boundary, before calling it a Bug. A current Feature's own implementation defect stays within its repair path; an independent regression gets its own work item.

For a status-only question, answer current facts, blockers and relevant uncertainty directly; it needs no catalog lookup or continuation prompt. When advice calls for help starting the next action, provide a prompt. An actual request to save a pause or prepare a task handoff belongs to `task-handoff-godot`; do not replace its requested result with advice. Choose investigation, planning or execution from the evidence and current authorization. Resolve routine choices from available evidence; ask only for facts that materially change the route or the safety of the action.

Every drafted prompt follows **Continuation prompts** in `methodology/09-records-reports-and-handoff.md`: fill its fields with current facts and the destination's actual rules. The format is not another workflow or approval gate.

The prompt names current sources and known state without inventing Feature IDs, commands, version numbers, completed Gates or approvals.

- For GDD references, follow the actual entry and verify the owning file and heading. New document targets use **GDD document names** in `methodology/01-product-doc-structure.md`, without inventing alternate names or claiming unwritten topics exist.
- Cite configured commands instead of baking in the author's local paths.
- Preserve the user's explicit authorization. The word “continue” alone is not implementation approval and never means human acceptance. Producing a prompt grants neither.

When recommending a next action or drafting a reply, use the shared catalog at `D:/A_Games/Game_idle_yaya_frame/framework/prompt-scenarios/prompts/godot-development-prompts.json`. It contains the single `Godot 项目开发` Project. Inspect category and scenario names, then read relevant candidate bodies; do not load every prompt body. Match the user's objective, current state, prerequisites, scope and expected result, not just similar words. Use the selected scenario's input organization and instructions to draft a concrete continuation with current facts. Name the selected category and scenario and explain why it fits.

The catalog is task material, not current authorization or proof that its referenced capability exists in this project. Verify the destination against the project's own rules and Skill. Preserve actual approvals, limits and remaining verification; replace placeholders with known facts and identify material gaps. Reading a catalog entry does not invoke it, and an advisor entry must not recursively invoke this Skill.

If no candidate fits, distinguish missing task inputs from missing scenario coverage. Fill or ask for necessary inputs; adapt a catalog entry when its objective and execution boundary still fit. Recommend adding or revising a scenario only for a concrete uncovered objective or a materially different boundary: identify the closest entry, the difference, and the proposed category, name and purpose. Give any useful current advice from project authority, but label an unmatched draft as task-specific. Do not modify the shared catalog or create a local prompt collection.

## Route common question types

Pick the destination from the canonical table and read its Skill or methodology section before drafting a prompt. This table only names the distinction the advice must make clear; the destination owns its rules.

| Question type | Destination | Distinction to make clear |
| --- | --- | --- |
| Game design, numeric design, delivery scope or terminology | `design-gdd`, `design-balance`, `product-author` or `project-terminology` | Changing game rules, tuning an authorized numeric topic, arranging delivery and maintaining meaning-preserving definitions are different tasks. Initial design and draft review need no Product or Feature. |
| A project-wide or specialized rule | The current task, under **Incremental rule maintenance** in `methodology/04-project-rules.md` | A local design does not automatically become a global rule. |
| Supporting documentation inside an authorized Feature | That Feature | It does not open a new planning cycle. |
| Feedback or an external report, or the cause of a concrete failure | `feedback-triage-godot` or `bug-diagnosis-godot` | Classifying feedback differs from finding a cause. Neither creates a Feature, relaxes requirements or authorizes a repair. |
| The overall structure of a module, with no abnormal behavior | The current-state audit in `review-code` | This is an audit, not a diagnosis. |
| Environment preparation, requested checks, human acceptance or evidence recovery | `project-environment-godot`, `project-verification-godot`, `manual-acceptance-godot` or `verification-evidence-godot` | Tool readiness, executed checks, actual user acceptance and evidence applicability are different facts. None adds a Feature, Stage or full delivery run. |
| A requested UI or logic prototype | `prototype-godot` within the current Feature or an authorized experiment | Actual Godot execution and observations differ from planned checks and production acceptance. HTML is not the default substitute. |
| Several unknowns whose answers affect one another | `wayfinder-godot`; a single ordinary question uses `project-grill-me` | Clear work stays with its owner. The advisor explains the route without exploring. |
| A separate checkout, or bringing selected results back | `worktree-create-godot` or `worktree-integrate-godot` (a conflicted integration uses the latter's conditional reference) | A separate checkout does not isolate data, and integration neither selects a winner nor permits cleanup. Checks in an existing worktree need no creation step. |
| External facts or approach comparison | **External research** in `methodology/09-records-reports-and-handoff.md` and the `researcher` role | The project's `researcher` role differs from the user-installed `anysearch` Skill. Cited research in `docs/research/` is not a confirmed requirement or local verification. |
| An observable game moment, interface, asset or localization specification | The fixed owners in `methodology/11-specialist-workflows.md`, such as `design-game-presentation`, `design-ui-spec`, the asset specification Skills or `design-localization-spec` | Direction or specification, integration (`content-asset-integration`, `content-localization`) and review are separate. Asset production is reserved and has no Skill; do not invent one in a prompt. |
| Formal review | The review Skills in an independent instance, under `methodology/12-independent-review.md` | No automatic review sequence. Author self-checking is not independent review, and a review is not human acceptance. |
| Performance or soak measurement | `diagnostics-performance` or `diagnostics-soak-test` | Their results have their own coverage limits and are not passing gdUnit evidence. |
| Inspecting a proposal, clarifying an undecided requirement or auditing implemented work | `plan-review-godot`, `project-grill-me` or a review Skill | These are three different requests. Plan inspection is not a required step before planning, implementation or completion; its findings neither authorize edits nor advance a Stage. |
| Reflecting on actual task experience | `retro-godot` | A retrospective is optional and its findings do not authorize edits. |
| Designing how recurring or anticipated work should be handled | `loop-me-godot` | Unlike a retrospective, it needs no prior failure, and it does not become a Stage. |
| Pausing, switching or continuing in a new conversation | `task-handoff-godot` for a requested stop point or copyable handoff; resuming a recorded stop returns to the target task | Ordinary continuation needs no extra handoff or worktree. A non-empty Git status alone is not an ownership conflict. |
| A framework defect found during project work | The framework maintenance repository or the project-tooling route in `engineering-change-plan` | Preserve the business work in progress. A newly chosen framework source does not require the previous project's Git history. |

Already authorized follow-up returns to its original owner. The advice itself runs, delegates, creates and integrates nothing.

When advice concerns committing, read the relevant sections of `agent-rules/00-core/git-worktree-and-commits.md` and the task's actual commit conditions. Distinguish a validated logical change ready for an incremental commit from whole-Feature completion. Preserve any separately required acceptance or explicit commit permission; do not infer that permission from an acceptance result or a generic continuation request. This Skill only explains the next action and never stages or commits.

## Stop

Check that the answer addresses the question with current facts, explains the selected scenario or genuine coverage gap when recommending an action, includes a prompt only when needed, and has performed no writes. Stop after the advice.
