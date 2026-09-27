---
name: project-next-step-advisor
description: Explain current Yaya project status or recommend the next workflow. Provide a continuation prompt when requested or useful for an explicit next-action question; do not replace an implementation request with advice.
---

# Read-only next-step guidance

Read the user's intent and current project state, then give a short evidence-based explanation and, when needed, a prompt for continuing with the existing workflow. This Skill does not execute the prompt, edit files, create Features, record acceptance, run tests/generators, clean artifacts, stage files or commit.

Read-only also excludes launching Godot/import, installing Skills or invoking a writing standardizer. Read only task-relevant project material; do not inspect unrelated credentials, user saves or other projects. Text/JSON parsing, metadata and verified read-only Git status/log/diff/show are allowed.

## Establish current state

1. Read the project's `AGENTS.md`, `docs/methodology-config.json`, lightweight Feature index and current `docs/progress.md`. Read history links only when resolving the current task; do not load or repeat the whole archive.
2. Confirm actual game design exists in `docs/gdd/`, then inspect read-only Git status and relevant GDD/Product/Feature/detail/Registry records. An empty directory, directory-navigation README or pending-content notice is not a GDD. Without actual GDD, report the missing prerequisite and stop; do not propose idea elicitation, GDD initialization or a substitute Product. Configured tool paths are choices, not proof of availability. Use relevant environment/Progress evidence without launching probes. Interpret incomplete machine setup through `methodology/00-overview.md` and `methodology/05-document-language.md`. The stack is fixed to Godot 4.7 / GDScript / gdunit4; missing tools do not mean the engine is undecided.
3. When acceptance or completion matters, read the current evidence and the specific linked run result. Distinguish old PASS, current snapshot and pending human acceptance. Multiple active Features require actual batch authorization; do not select the highest ID or silently clean other work.
4. When a next action needs routing, use **Canonical task routing** in `methodology/00-overview.md`, then read the destination Skill's relevant entry/stop contract. That table and the existing workflow own routing and approval; this Skill maintains no second workflow.

For first planning or synchronization, distinguish the schema's initial planning baseline from the scaffold commit; later Product planning preserves the anchor. Missing history for existing work belongs to synchronization's coverage check.

Distinguish GDD design, the delivery outline in `docs/product.md`, the current Product's detailed delivery scope, and Feature planning. A future outline entry does not imply a detailed Product exists. When the current Product is eligible, route its delivery-scope refinement before planning all Features needed for its complete necessary scope. Only after its required Features truly complete should the next Product be reconsidered and refined against the latest GDD. Relevant source changes require impact analysis for existing work; future unrefined Products need only outline adjustments, not premature Features.

When the question concerns terminology, project rules or design, read the relevant `docs/terminology.md`, `docs/project-rules.md`, Feature design and architecture/ADR sources. Use their owning contracts for update authority and the Stage 3 documentation checkpoint. Missing optional designs/ADRs are normal; a proposed rule or accepted ADR is not proof of implementation or verification. Check source freshness when governing documents changed after a test or human decision, without running a check merely to answer.

Report a missing file as missing instead of creating it. When sources disagree, identify each source and its responsibility; do not select whichever produces a convenient route. An unclear Stage or old report is not proof of new approval or acceptance.

## Answer the question and provide a prompt when needed

Classify using the canonical table, including new/continued Feature, GDD design or Product delivery-scope change, Bug, Refactor, Maintenance, Framework issue, Audit, Human Acceptance follow-up and status query. Ambiguous expected behavior is investigated against GDD and the owning professional source within the Product delivery boundary before calling it a Bug. A current Feature's own implementation defect stays within its repair path; an independent regression gets its own work item.

For a status-only question, answer current facts, blockers and relevant uncertainty directly; no continuation prompt is required. When the user requests a handoff or help starting the next action, provide a prompt. Choose investigation, planning or execution from the evidence and current authorization. Resolve routine choices from available evidence; ask only for facts that materially change the route or safety of the action.

Every drafted prompt uses explicit level-two headings in this order: `目标`, `范围`, `输入与事实来源`, `决策边界与授权`, `约束`, `输出与交付`, `验证要求`, `完成条件`. Keep each field substantive and specific to the current task, regardless of prompt length. Cite the destination's actual rules for shared requirements rather than copying them. Add explicitly labeled background/entry, conflict handling, environment, risk/recovery or other conditional fields beside the related fields only when relevant. Separate blocked or pending-human states from successful completion; neither a field nor a Skill boundary ends broader valid authorization. This is prompt presentation, not a new workflow or approval gate.

The prompt names current sources and known state without inventing Feature IDs, commands, version numbers, completed Gates or approvals. Cite configured commands instead of baking in the author's local paths. Preserve existing explicit user authorization. The word “continue” alone is not implementation approval and never means human acceptance. Producing a prompt grants neither.

When wording examples would help, use [the selected prompt index](references/prompt-examples.md) after establishing the route, then read only the relevant entry in its linked file. These generated examples supply phrasing and input organization, not another workflow. Adapt them to current facts, user intent and the destination contract; do not inherit template approvals, stop conditions or placeholders as live instructions. Status-only answers need no examples. Missing or outdated examples do not block advice: use current project authority without exporting, repairing the reference or querying the source framework.

Use `product-author` for authorized maintenance of existing GDD and Product delivery scope; `product-spec-elicitor` resolves material design or delivery questions. This advice remains read-only, but GDD is a normal maintainable project source in its owning workflow. Use `project-terminology` for meaning-preserving definitions and links. Settled terminology does not need a preliminary clarification interview. Rule maintenance needs its pre-write self-check and any missing substantive decision; a local design does not automatically become a global rule. Supporting documentation inside an authorized Feature returns to that Feature instead of opening a new planning cycle. Read the destination contracts for details rather than copying a second procedure here.

For external research, use **External research** in `methodology/00-overview.md` and the `researcher` role's current contract. Recommend research only when useful to the actual question; adequate existing evidence needs no search. Distinguish the project-supplied role from the user-installed `anysearch` Skill, and cited research in `docs/research/` from confirmed requirements or local verification. Advice performs no delegation or report writing; an execution request belongs to the research route rather than this read-only Skill.

For specialist work, consult `methodology/11-specialist-workflows.md`: professional owners fill missing implementation specifications and directly reference details already owned by GDD. Source changes may affect several planned Products, and an old sync anchor does not establish newly included source coverage. `design-localization-spec` owns localization specifications; `content-localization` implements their approved runtime support. Do not duplicate a confirmed requirement in Product or a second professional source. Distinguish direction/specification, reserved production, integration and review. Reserved production has no executable Skill; do not invent one in a continuation prompt.

For formal review, use `methodology/12-independent-review.md`: independent instance, selected methods and actual permission/context limits. No automatic seven-review sequence, author self-review relabeling, or human acceptance inferred from review. Performance and soak results have their own coverage limits and cannot be reported as passing gdUnit evidence. Advice itself runs none of those validations.

For pause, switching or new-conversation continuation, use the existing single project directory, actual differences and current task records under the Git contract. Non-empty status alone is not an ownership conflict; preserve unrelated work and identify only concrete overlapping edits or inseparable commit boundaries. Do not recommend worktrees or an attribution ledger. If a framework defect is reported, preserve business WIP and refer the bounded repair to the appropriate maintenance repository or project-tooling route. A user-chosen new framework source does not require inheriting a previous project's Git history.

## Stop

Check that the answer addresses the question with current facts, includes a prompt only when needed, and has performed no writes. Stop after the advice. For regression review use `references/scenarios.md`; those scenario expectations are not claims that a language-model interaction was automatically tested.
