# 03 · Stage 0–8 `feature-execute` loop

> Canonical delivery specification for one Feature. `feature-execute` implements this workflow. Stage 1 requires approval; Stage 8 hands off according to the remaining authorization. Stage 5 applies only to the approved manual acceptance mode. Automated testing is subordinate evidence, never an autonomous completion authority.

## Shared contracts

- Require an existing substantive GDD under [GDD prerequisite and authority](01-product-doc-structure.md#gdd-prerequisite-and-authority). This applies to Product and engineering Features, including resumed work.
- Read `docs/methodology-config.json` before durable writes. Conversation uses the user's current language; durable prose uses `document_language`.
- Before the first coding Feature, complete the one-time Project Environment Bootstrap defined in [05-document-language.md](./05-document-language.md). Stage 0 reuses confirmed preparation and configured paths; repeat checks only after tool/configuration changes or actual invocation failures.
- Read the applicable active Project Rules through `AGENTS.md` and [the rule-loading contract](04-coding-rules-4-layers.md#rule-loading), including relevant `docs/project-rules.md` constraints. Retain the Feature's task-relevant snapshot; complete applicability does not require loading unrelated sections or rereading unchanged sources.
- Follow `agent-rules/00-core/git-worktree-and-commits.md`: inspect and preserve current changes, use existing task records when resuming, and resolve concrete overlaps before dependent edits. A non-empty Git status is not itself a blocker.
- Read `docs/test-registry.json` when automated testing is enabled. Testing semantics are defined in [08-testing-strategy.md](./08-testing-strategy.md).
- Release/publishing/deployment workflow is outside this loop unless explicitly represented as project work.

### Authorization and continuation

Reuse concrete user decisions across Skills, Stages and turns. Present the relevant plan and check that its actions, verification and scope are covered; ask only for a missing decision or a material change. A Skill's return ends that procedure, not an already authorized end-to-end task. Complete each Feature's applicable verification, acceptance and commit before continuing an authorized batch; independent review follows the user's chosen scope and timing under Stage 6. Authorization to implement never supplies a missing human acceptance result.

For initial Product decomposition, apply [Decomposition preview](02-feature-list-schema.md#decomposition-preview) before plan writes; that contract defines preview confirmation and explicit autonomous-planning authority, including continuation into a later Product.

### Incremental commits and whole-Feature review

One Feature may contain several validated logical commits under `agent-rules/00-core/git-worktree-and-commits.md`. Such commits retain `in_progress` and `completed_at: null`; only Stage 7 establishes completion. A clean worktree after a commit is not a reason to skip remaining work or start another Feature. Resume using the existing Feature/Progress records and Git history, including already committed work as well as current differences.

Whenever this loop calls for the final diff or scope review, inspect the combined Feature change across all its commits and remaining working-tree changes, not only the latest commit or uncommitted diff. Use the verified pre-implementation Git state and task-owned history; do not introduce a separate commit ledger.

### Delivery of existing implementation

For implementation adopted under [Adopting existing implementation](02-feature-list-schema.md#adopting-existing-implementation), use Stages 0–2 to confirm the current contract, actual implementation coverage, remaining work, acceptance mode and Test Impact Review, then persist the approved plan. Completion records are written when actual results are recorded. Reuse concrete authorization; a request to document existing work alone does not authorize execution or repairs. Git change preservation and environment requirements remain those of the shared contracts.

In Stage 3, reuse behavior already satisfying the confirmed AC. Map suitable existing tests through the Registry; add missing checks against intended behavior and meaningful boundaries, not merely assertions that mirror the implementation. For unchanged adopted behavior, a new test may pass immediately: record it as present verification, not historical TDD. Do not undo working behavior to create a RED run or reconstruct a missing pre-implementation baseline. Before any new behavior change or repair, apply the normal baseline and TDD contract to that remaining work; failures found during adoption remain real gaps, not permission to weaken the contract or broaden repairs.

For scope review, use verified original changes when available and inspect the current implementation against every adopted AC. If the original baseline cannot be recovered, disclose that limit and review the relevant current implementation and its direct callers; an empty documentation-only diff proves no behavior. The adoption-time snapshot establishes current evidence, not a claim about the original development process.

Complete applicable Stages 4–7 with evidence covering the current Product, Feature/Registry contract and implementation. Prior results must satisfy the existing snapshot and coverage rules; historical claims or notes cannot replace them. Required human acceptance and explicit review conditions still apply. Set `done` and `completed_at` only when Stage 7 succeeds, using the actual current completion time. Keep any verified earlier implementation date in notes; never backdate formal completion or replay already satisfied implementation steps.

### Progress communication

Report meaningful progress, failures, decisions needed and the final handoff in the conversation language. Combine adjacent routine steps when helpful; no message is required at every Stage boundary. Preserve the approval packet, applicable human checklist and final results. Natural wording is sufficient; conversation text is not a machine protocol, execution proof or substitute for approval.

### Static-check summary

Only a Stage that actually runs static/lint emits its result table. Read the direct Godot/parser and lint output and include scope/file count, Critical, Warning, Info, actual process result and report location. Zero is reported only when the output proves it; a failed command with no report has unavailable counts.

| Scope / files | Critical | Warning | Info | Process result | Report |
| --- | --- | --- | --- | --- | --- |
| Actual scope and count | Actual | Actual | Actual | Actual exit/status | Original report/output path |

Do not rerun global lint at every Stage. When reusing a result, say which run and unchanged relevant source are reused. The Agent checks whether intervening changes require another run. A conversational table does not replace actual execution.

## Stage 0 · select and load context

**Output:** exactly one current Feature and the context needed for its approval packet.

For Product-derived work, apply [Product-by-Product planning](02-feature-list-schema.md#product-by-product-planning). Finish the current Product's required Features before moving to the next Product. Dependency eligibility does not establish Product sequencing; preserve existing later plans, and keep engineering repairs within their authorized route.

1. Read the lightweight index and select either the user-specified Feature or a dependency-eligible `pending` Feature. `python -B tools/checks/check-feature-list.py --eligible` provides the validated DAG selection; ID is only a stable tie-breaker and dependencies may have larger IDs. Resume an existing `in_progress` Feature instead of starting another.
2. Run `git status --porcelain` and inspect relevant differences. Preserve existing changes. For a resumed `in_progress` Feature, recover its actual stop point from Feature/Progress records and current files, including already committed work. Resolve conflicting edits or a materially unclear requested result before dependent writes; do not require a clean directory or per-file authorship proof.
3. Read the confirmed configuration. Run `python -B tools/checks/check-project-environment.py --require-ready` at initialization, after tool/configuration changes, or to diagnose invocation failures. Routine Features reuse confirmed paths; incomplete setup still blocks coding.
4. Establish the relevant context from that Feature detail, its existing `docs/features/F0XX-design.md` and relevant dependency designs when present, its primary source and applicable GDD/professional sources under [source discovery](11-specialist-workflows.md#discover-and-map-sources), relevant `docs/terminology.md` definitions, relevant dependency details, current Progress, applicable Project Rules and routed `agent-rules`, test registry, and the principal implementation paths needed to bound the change. The main Agent reads these sources as needed; explicitly delegated guidance may share the background investigation under [Implementing with prepared guidance](04-coding-rules-4-layers.md#implementing-with-prepared-guidance), retaining the implementer's original-rule and current-code checks. Follow Progress history links only when relevant. Read applicable optional architecture maps and ADRs under [the architecture convention](10-architecture-overview.md), including relevant ADRs when no map exists. Before proposing an approach or searching external references, follow [project knowledge lookup](../docs/knowledge/README.md#find-relevant-knowledge-first) for this Feature. If governing sources changed since the plan adopted them, handle their actual impact through `feature-sync` before dependent execution; an ordinary continuation request needs no separate synchronization phrase.
5. Prepare a concise Context / Rules Snapshot: the Feature record, principal GDD/Product/implementation paths read, useful knowledge references, planned create/modify/delete paths, applicable rule modules and materially constraining rules with source paths, plus planned validation. There is no rule-count quota.
6. Present this snapshot once in the Stage 1 packet alongside Feature identity/status, dependencies, source, stable criteria, affected components and engineering mode when present. On continuation, reference it and show only material changes; do not reproduce the same packet at every Stage.
7. Stop dependent work on contradictory acceptance criteria, invalid dependencies, unresolved GDD design or Product delivery scope, broken test-traceability data, or an unbounded planned file surface. If the GDD itself is absent, stop the development workflow under its prerequisite.

## Stage 1 · Test Impact Review, resource preflight, and explicit approval

**Output:** implementation plan + verification plan + user decision.

Decide acceptance from the confirmed GDD design, Product delivery scope and professional/engineering intent before filling verification lists. Visual presentation, animation feel, audio/sound/music, game feel, and other human perception or judgment require `verification.acceptance_mode: "manual"`. For other requirements whose AC can all be verified automatically, choose `"automated"`. Explain the choice in the approval packet, then fill the automated mappings and applicable manual checks/regressions. Empty lists and previous PASS records do not make this decision. Null means an undecided draft.

### 1A. Determine the test scope

Read and apply [Test Impact Review](08-testing-strategy.md#test-impact-review) and [Runtime Test Impact selection](08-testing-strategy.md#runtime-test-impact-selection). These sections define Required, affected, and full scope. Using the current Feature, `affected_components`, criterion verification, and `docs/test-registry.json`, derive the Required and affected sets, then decide whether full is required. Explain the selected scope and reasons in the Stage 1 packet.

Keep affected components' registered suites in scope. Empty `unit_test_paths` adds no selector; missing registered paths and zero-test discovery are errors. Removing a registration requires an explicit reason and user approval; a runner exclusion cannot remove a deterministic requirement. Approved retirement or registry correction must change the underlying traceable contract before recomputing the selection.

Also identify:

- additional related tests justified by dependency/API impact, with concrete reasons;
- new acceptance/regression test IDs that should be created under TDD;
- new unit suites to create after approval, without registering future paths;
- necessary obsolete-test and current-reference cleanup for changed/removed contracts, reading Feature notes and affected test code under [Requirement changes and stale tests](08-testing-strategy.md#requirement-changes-and-stale-tests); include it in the same plan and reuse existing approval for that exact scope;
- criteria that remain manual-only and why automation is not appropriate.

Identify additional professional verification obligations, such as measured performance under a named workload, actual soak duration or in-context display/ listening checks. State their conditions, completion criteria and evidence location in AC or the existing Feature design; do not force them into gdUnit result fields.

### 1B. Resource/dependency preflight

1. Identify implementation files/resources likely required, external dependencies, placeholders, and out-of-scope impact. When resource preparation needs a handoff, apply [Resource requirements and handoff](01-product-doc-structure.md#resource-requirements-and-handoff), reusing the owning presentation, UI or shared design sections and checking supplied files before dependent implementation.
2. Record approved `_placeholder_` replacement needs in the owning resource section and link it from Feature AC/design when binding, with notes providing navigation. Do not duplicate the entries or treat preparation status as acceptance evidence.
3. Explain any scope expansion before coding.

When the plan adds a module, changes a public interface or moves responsibility, apply [Designing a module boundary](10-architecture-overview.md#designing-a-module-boundary) to the affected callers and contracts. Keep the reasoning in the current plan or an existing design record; this does not require an architecture map.

When a game function changes, use `docs/game-organization.md` to check the affected logic, presentation and collaboration responsibilities. Identify the actual owner of any changed business state and the result the feedback consumes; distinguish it from local display/playback state. Derive necessary implementation order and verification from those contracts, including meaningful failure, cancellation or repeated-use paths. Retain useful existing APIs and Godot ownership/lifecycle semantics; this check adds no compulsory objects, event bus or extra document.

Prepare proposed implementation decisions and reasoning for the fixed [Feature design](02-feature-list-schema.md#feature-design-and-implementation-notes); a technical choice meeting the [ADR conditions](10-architecture-overview.md#architecture-decision-records) uses its ADR for the rationale and is referenced by the design. Reuse each existing owning record, without selecting another location by explanation length or complexity; Stage 2 persists the approved content. Surface unresolved terminology and project-rule conflicts before dependent implementation; proposed rule changes follow the conversational self-check and authorization in [rule maintenance](04-coding-rules-4-layers.md#incremental-rule-maintenance). Do not create empty records or request approval merely for their presence.

Use `implementation-guidance-godot` when implementation guidance is needed for this existing Feature. The main Agent prepares it unless the current prompt or still-valid authorization explicitly requests an implementation advisor; complexity alone does not delegate it. Use the same Context / Rules Snapshot, design contract and approval packet, not another planning Stage. Delegated questions, fixed-role selection and failure handling follow that Skill.

For interface work, apply [Visual prototype before dependent implementation](01-product-doc-structure.md#visual-prototype-before-dependent-implementation). Reuse a relevant accepted foundation, or resolve the missing prototype work and its actual dependencies before implementing dependent logic. For a prototype Feature, include representative resources, the independently runnable scene and visual/interaction checks in the existing plan; use the normal manual acceptance route. Prototype approval does not accept later production behavior.

### 1C. Present approval packet

Present one concise packet containing:

- Feature scope and affected components;
- the Context / Rules Snapshot prepared in Stage 0;
- material design choices and constraints, any needed Feature design/ADR and rule-change decisions;
- Existing Safety Net to run before changes;
- new TDD acceptance/regression tests and unit suites to create;
- acceptance mode, its reason, and corresponding verification items;
- full-suite decision and reason.

Reuse explicit approval already covering this packet; otherwise ask for the missing decision to begin this Feature. Show material changes for approval without asking again about unchanged, already approved actions.

No approval → no implementation and no durable test-plan mutation.

## Stage 2 · mark `in_progress` and persist verification plan

After approval:

1. set the selected index entry to `in_progress`, `completed_at: null`;
2. update `docs/progress.md` with current Feature/batch and Stage, blockers, pending decisions, next legal action, and links to the approved plan/evidence; keep history bodies in `docs/progress/`. Persist the approved implementation design in `F0XX-design.md` under the [Feature design lifecycle](02-feature-list-schema.md#feature-design-and-implementation-notes), including the delegated advisor's bounded design write when applicable. The main Agent checks the design and maintains its Feature `notes` link. Record already confirmed rule changes/ADRs at their owning locations. Explain materially constraining rules and their concrete application with relative source links; do not copy the entire snapshot or rule body. Notes keep task reminders and references, not another implementation design;
3. persist approved `verification.acceptance_mode`, criterion verification mappings, Bug regression IDs, and `verification.test_impact` in the Feature detail. Store additional related tests as `additional_tests: [{"id": "<registry ID>", "reason": "<approved reason>"}]` and full-suite obligations as `full_suite_reasons: ["<approved reason>"]`. The runner always reads this recorded scope; changing invocation arguments must not shrink approved coverage. Removing an obligation requires an explicit approved plan revision;
4. register not-yet-created durable acceptance/regression tests in `docs/test-registry.json` with `status: planned`;
5. add newly approved component entries to the registry when required, with `unit_test_paths: []` if no unit suite exists;
6. run:

   ```powershell
   python -B tools/checks/check-feature-list.py
   ```

## Stage 3 · baseline, TDD, and implementation

Implement only the current Feature and its approved dependencies/repairs.

Before producing validation output or temporary inputs, choose their destinations under [Reports and cleanup](09-artifact-lifecycle.md#reports-and-cleanup). Reuse those locations across the task while preserving distinct evidence when needed.

### 3A. Existing Safety Net baseline

Before writing behavior-changing implementation code:

1. run the Existing Safety Net from Stage 1 with `--feature F0XX --phase baseline --scope auto`, excluding new `planned` tests that do not exist yet. A valid empty safety net returns `not_required`, creates no run report and is not a test PASS;
2. directly run script parsing/lint if useful for the pre-change baseline;
3. if an existing required test already fails, preserve the original error and report it before implementation. Do not attribute it to the current Feature or silently expand scope.

### 3B. RED

For each machine-verifiable new acceptance criterion or Bug regression:

Complete one small observable behavior's RED → GREEN → necessary refactor → relevant passing tests before starting the next behavior. A large criterion may need several cycles; planning test IDs in advance does not mean writing every test before any implementation.

1. create the test using its approved logical ID;
2. update the matching registry entry with path/case and `status: active` once the test exists;
3. run the narrowest supported selector;
4. confirm the test fails for the intended missing/broken behavior, not because of syntax, fixture, environment, or unrelated setup failure.

If a meaningful RED state cannot be produced, explain why before implementation. Do not fake TDD evidence.

When a Stage 1-approved unit suite is created, add its repository-relative file or directory path to the component's `unit_test_paths` and the Required Test Set. Register only after the suite exists, then confirm discovery and execution through the configured runner.

### 3C. GREEN and refactor

1. implement the smallest coherent change that satisfies the current criterion/repair;
2. rerun the new test until it passes;
3. perform local refactoring without changing approved behavior;
4. rerun tests protecting each meaningful refactor, then repeat the complete RED/GREEN/refactor cycle for the remaining behavior;
5. preserve accepted Product behavior outside scope.

As a coherent logical change becomes usable, run its relevant tests and direct parsing/lint or other applicable checks, then commit it automatically under the Core Git rules. Include supporting tests, resources and record updates needed to keep that committed snapshot consistent. Narrow validation must cover this change and its affected existing behavior; it does not replace the whole-Feature obligations in Stage 4. Do not split a change that can only work or be verified together, or commit a failing RED state.

Pending Feature-level human acceptance does not prevent a validated logical commit, unless the user explicitly made acceptance, review or separate commit permission a condition for that commit. Apply those task-specific conditions under the Core Git contract across planning, implementation and continuation; acceptance does not supply separately required commit permission. A failure or missing prerequisite for this logical change still blocks its commit. Keep current progress and remaining work in the existing records; continue authorized implementation and all applicable Stage 4-7 requirements.

Perform the approved test-code and current-reference cleanup with the behavior change, following [the stale-test contract](08-testing-strategy.md#requirement-changes-and-stale-tests). Registry retirement alone does not remove executable methods; preserve valid shared cases and historical records.

At implementation completion, map changed behavior to every criterion ID.

### 3D. Documentation checkpoint before final verification

Check whether this work changed accepted game design or delivery scope, added, renamed, retired or clarified durable terminology, changed the Feature design/current architecture or recorded navigation, produced an important technical decision, or revealed a useful project-rule change. Update only useful, authorized content at its owning location. If none changed, do not create a document or empty report. There is no artifact quota or separate checklist ledger.

| Content | Action and authority |
| --- | --- |
| GDD and Product delivery | `design-gdd` records approved overall game-design changes; `design-balance` maintains scoped numerical design in the owning GDD topic. `product-author` adjusts affected Product boundaries/source links. Future Products remain pre-decomposition candidates. Resolve current and already planned impacts through the existing source-commit and synchronization route. |
| Project terminology | Invoke `project-terminology` within the current documentation authorization; definitions follow [the terminology contract](01-product-doc-structure.md#project-terminology). Meaning changes use the owning Product/design route. |
| Professional requirements and presentation adoption | The current task coordinates applicable presentation/UI/art/audio/localization sources under [Specialist work and sources](11-specialist-workflows.md). Finalize resource status/locations, adopted component combinations and actual implementation/consumer links before verification; link existing acceptance records without duplicating results. Resolve substantive source impacts before dependent delivery. |
| Feature design and current architecture | Reconcile the actual implementation and approved deviations in the Feature design; update affected architecture contracts and navigation under [map maintenance](10-architecture-overview.md#maintaining-a-map), linking rather than duplicating. |
| Important technical choices | Apply the existing ADR threshold and authorization; preserve replaced decisions and evidence limits. |
| Project or specialized rules | Apply [incremental rule maintenance](04-coding-rules-4-layers.md#incremental-rule-maintenance), including a pre-write self-check for every proposed change. Persist settled constraints; unapproved candidates stay in design/Progress, not active rules. |

Handle material conflicts when discovered rather than postponing them to this checkpoint. Return from supporting workflows to the current Feature; documentation-only routing must not restart Product planning or end authorized delivery. Finalize governing document edits before Stage 4 because GDD, Product, terminology, professional specifications, presentations and their resource sections, rules, ADR and design Markdown participate in the global source fingerprint. Even editorial updates or changes to future GDD chapters may invalidate current evidence. Complete applicable verification and renewed acceptance after such changes; do not exempt these files or claim unchanged coverage.

## Stage 4 · automated verification and human checklist

**Output:** machine evidence plus concrete human-verification instructions.

Read project commands from `docs/methodology-config.json`:

- confirmed Python/Godot executable paths for direct checks described in `gdscript-lint.md`;
- `tools/testing/run-gdunit-tests.py`: fixed test entry, reading the configured Godot path;

Procedure:

1. Run the configured test runner with `--feature F0XX --scope auto`. It reads current obligations and prints the selection, reasons, deduplication and full-suite escalation. A valid `manual` plan with empty Required/affected sets and no full-suite obligation returns `not_required` without launching Godot or creating a run report; skip step 6 and retain `test_runs: []` in that case. Continue applicable static checks and actual human acceptance. Missing paths, zero discovery and unresolved failed/unfinished final runs on the same snapshot still fail.
2. Inspect the actual selected scope and test results. If full is required, run one real full suite whose executed set covers Required and affected; do not repeat equivalent runs merely to fill different Gate fields. Otherwise run the affected union, including every Required item.
3. Directly run Godot script parsing for changed scripts and necessary dependants, then the bundled lint CLI as described in `gdscript-lint.md`. Inspect actual output and exit codes. Do not add a Python wrapper, static manifest or import step.
4. For a Bug, ensure each approved `F0XX-RTyy` test is active and passes, or the approved `manual_regression` is concrete and repeatable.
5. If Stage 1 required full, the Feature’s recorded Test Impact must require it and the actual full result must pass. An unavailable or failed required full suite blocks completion; a reason or transcript cannot turn it into PASS.
6. When a run result was produced, record the actual Required Test Set, affected-test, and full-suite result, including failures:

   ```powershell
   python -B tools/features/record-feature-completion.py record-tests --feature F0XX --run <result.json>
   ```

   `record-tests` validates the supplied run results and stores their references. It neither runs nor validates static checks. The Agent separately assesses direct parsing/lint output; a passing evidence helper cannot override a static failure. Failed evidence imports clear old test references and preserve original reports.

7. Any failing machine check returns to Stage 3. Do not enter Stage 5.
8. Follow the approved acceptance mode. For `manual`, prepare the corresponding human checks. For `automated`, report actual automated coverage of every AC.

For `manual`, expand the approved checks and applicable regression into a pending JSON checklist, bind it to final content and provide its path to the user under [Manual acceptance files](manual-acceptance-files.md). That contract owns fields, reproducible steps, result import, snapshot matching and the conversation fallback. Notes link the checklist and supporting observations instead of duplicating steps. Screenshots/logs supplement the relevant action; they do not establish acceptance.

Report actual scope, failures and result paths in ordinary language.

Complete any additional performance, soak, display or listening obligations in the approved verification plan and retain their original evidence separately. Follow [specialist evidence limits](11-specialist-workflows.md#finalization-and-evidence); these results are not gdUnit runs. Passing the evidence helper alone does not prove those obligations, static checks or human experience acceptance.

For `manual`, wait for Stage 5. For `automated`, omit Stage 5 and go to Stage 5.5 for a Bug, otherwise Stage 6. Report manual acceptance as not required; do not record an accepted human decision that never occurred.

## Stage 5 · explicit human acceptance (manual mode only)

Receive the user's actual result file or explicit conversational decision under [Manual acceptance files](manual-acceptance-files.md). A valid, fully passed submission accepts its corresponding scope without another confirmation phrase.

- Accepted result → record via the applicable file or conversation route, then continue.
- Any failure → record rejection, update Progress, return to Stage 3 and repair within existing authorization, then repeat applicable Stage 4 and Stage 5 verification.
- Pending cases → retain incomplete acceptance and report what remains; do not treat partial execution as a pass.
- Ambiguous response → ask whether any criterion remains unmet.
- A minor deferral is durable only when the user explicitly accepts it and it is recorded in notes.

For a Bug Feature, accepted Stage 5 enters Stage 5.5. All others enter Stage 6.

## Stage 5.5 · Bug-learning capture

Applies only to detail files with `engineering_change: bug`.

Capture the local Feature note and assess Guardrail promotion under [Bug-learning promotion](07-engineering-change.md#bug-learning-promotion).

Do not persist failed debugging guesses, redundant traces, or incidental machine-local failures.

If a late approved rule change alters the snapshot or current obligations, repeat applicable verification and acceptance before completion.

Creating a promoted cross-Feature invariant still requires the user's approval when it expands the accepted Feature scope.

Handle approved rule changes and any affected plans under Stage 8; reuse existing synchronization authority and work already completed.

## Stage 6 · optional independent review

**Trigger:** an explicit user request for independent review. Otherwise continue to Stage 7 without a review record or a routine confirmation question. The author still checks the final diff against AC, scope and applicable rules; this needs no general self-review Stage or report. Rule mutations retain their specific conversational self-check under incremental rule maintenance.

The user chooses one Feature, several named Features, a commit range or an explicit diff, and when to review it. A review after several completed Features uses the same procedure independently of their delivery loops; it does not hold each Feature open. If the user requires review before completion or continuation, honor that condition under the existing authorization contract. An Agent may recommend review for a concrete concern, but cannot start it without that request. Do not add per-Feature review switches, pending-review states or a review queue.

**Output:** findings for the selected combined scope, with evidence and limits.

Use [Independent review](12-independent-review.md) for fresh context, neutral handoff inputs, effective permissions, isolated validation and completion limits. The `independent-reviewer` role loads only the requested applicable methods. `review-code` owns requirements and code-quality examination; other review Skills cover UX, art, audio, assets, localization or balance when requested. One instance may combine methods without a pass per Skill or Feature. The author loading the same method still performs only self-checking.

Deliver one report for the selected scope, mapping shared findings to affected Features without duplication. Review-only work stops after findings. Evaluate the problem and proposed remedy separately; reuse authorization for a concrete repair where already given. Reports and permitted isolated validation outputs must not modify reviewed artifacts, original evidence or acceptance records.

For an unfinished Feature, confirmed in-scope defects return to Stage 3. For completed Features, preserve completed history and follow the existing engineering change route. Verify the affected repair and any invalidated Stage 4 evidence; renew human acceptance when accepted behavior changes. Re-review only when the requested review condition or a concrete unresolved finding requires it. Do not continue past a confirmed completion-blocking defect or failed required check merely because review is optional.

Record only accepted, useful follow-ups in existing Feature notes; a `suggest` does not automatically create a TODO or task. No review counts belong in the completion evidence. Isolated review output does not invalidate a current run; check that the reviewed snapshot remained unchanged and satisfy the user's required review coverage before continuing.

## Stage 7 · mark complete

**Entry:** Stage 4 evidence covers all current automated obligations, or its valid manual/no-automated-obligations case is `not_required`. Required test evidence and explicit Stage 5 human acceptance for `manual` must match the current semantic content fingerprint. Git revision is provenance; content-identical status/time/history commits do not grant new acceptance or require a fictitious rerun. The Agent checks the final diff against AC and scope, confirms applicable direct parsing/lint and supplemental professional verification passed, and satisfies any explicit user review condition. The evidence helper checks tests and applicable human acceptance; it does not assess static/supplemental checks, perform review or decide whether a user condition is satisfied.

Before the completion commands, confirm the Stage 3 documentation checkpoint and any later approved governing updates are complete. If a missing edit is now made, restore applicable current verification and acceptance before marking completion. Do not defer such edits until after the Feature is recorded as done.

1. Run:

   ```powershell
   python -B tools/features/record-feature-completion.py validate --feature F0XX
   python -B tools/checks/check-feature-list.py --completion-feature F0XX
   ```

2. Record the verified result: transition the Feature to `done` and set `completed_at` to the current ISO 8601 timestamp. The status field records completion; it does not prove tests, review or human acceptance.
3. Run `python -B tools/checks/check-feature-list.py` on the final ledger. These are explicit task commands. There is no tool-event interceptor or additional terminal state machine. If implementation or contract changes invalidate the evidence, finish the relevant verification before delivery.
4. Keep task reminders, Bug learning, accepted follow-ups and links in notes. Implementation decisions, reasons and omitted-edge explanations belong in the fixed Feature design; placeholder specifications stay in their owning resource section. Before committing, finalize useful knowledge and its index updates under [knowledge maintenance](../docs/knowledge/README.md#maintain-during-authorized-work), preserving [artifact ownership](09-artifact-lifecycle.md#project-knowledge).
5. Check this task's report locations, evidence links and retained scratch purpose under [09-artifact-lifecycle.md](09-artifact-lifecycle.md#reports-and-cleanup), then archive current execution history once under `docs/progress/<Feature-or-approved-batch>.md`; leave only current state and its history link in `docs/progress.md`. Feature notes keep TODOs and links to design decisions and applicable ADRs; do not duplicate rationale or execution history. Pure Markdown archival is excluded from test fingerprints.
6. Confirm applicable test/acceptance evidence still covers the final change under the structured snapshot rules. Reuse valid results; run missing or invalidated checks rather than repeating identical verification because the Stage changed.
7. Follow `agent-rules/00-core/git-worktree-and-commits.md` to commit the remaining validated implementation and completion records, with its Feature identity, staging and post-commit checks. Earlier logical commits remain part of this Feature's delivery; do not squash them or create an empty commit merely to mark a Stage. The Core contract also owns the no-commit exception, current-branch policy and prohibited Git operations.

## Stage 8 · handoff and authorized continuation

1. If this task changed project or specialized rules, report the change and complete needed `feature-sync` impact handling before the next affected Feature. Reuse authorization and any synchronization already completed; meaning-preserving edits need no fabricated work. If an actual decision or required synchronization remains unauthorized, report that boundary and stop the dependent continuation.
2. Otherwise check the current Product's remaining scope and Feature sources/statuses. If work remains, identify the next eligible `pending` Feature or actual blocker. Only after its required Features are complete, revisit current GDD and the next pre-decomposition candidate, use `product-author` to write its delivery document and then `feature-plan` to decompose it, or reuse its existing plan. Apply the authorization boundary below; the absence of an eligible Feature does not prove Product completion.
3. Report the completed Feature, relevant implementation/test changes, verification evidence, its local commit hashes or verified commit range (or the explicit no-commit exception), post-commit worktree status, placeholder count, TODOs, and the next Feature or Product-planning step. When cleanup was required, state the actual obsolete-test/reference changes and any remaining work using existing notes/Progress.
4. Report one sentence or a few concise learning entries in this existing Stage, using `templates/feature-learning-summary.md.tmpl`. With no new reusable learning, explicitly state “No new reusable learning” (Chinese: “无新增可复用经验”). Otherwise report the context, useful approach or root cause, existing coverage, applicability and actual or proposed destination: Knowledge / Agent Rule / Methodology / Tooling / Automated Check / Regression. Link knowledge or Bug-learning notes already recorded before the commit instead of copying their bodies or starting post-commit documentation. A project-specific approach can be reusable within the project without becoming a universal rule. Do not invent an entry for every incident. A newly discovered out-of-scope tooling or rule change remains a separate authorized task.
5. Continue the next step only when it is within concrete existing authorization and its prerequisites are satisfied. Preserve Product order and each Feature's approval, acceptance and completion requirements. If the requested scope is complete, the user requested a pause, or a necessary decision is missing, stop and identify that boundary. Eligibility or completion alone grants no new scope.

## Exception handling

| Condition | Required action |
| --- | --- |
| Acceptance criteria ambiguous/contradictory | Route to the owning Product/Feature revision workflow; do not reinterpret silently. |
| Completed dependency materially incomplete | Report gap and obtain user direction. |
| Implementation needs out-of-scope files/behavior | Explain expansion and obtain approval or create another Feature. |
| Existing Safety Net fails before implementation | Preserve original error and obtain direction; do not silently absorb unrelated repair. |
| Test registry is inconsistent | Stop and repair traceability before using it to choose tests. |
| Test/command/file/Git operation fails | Preserve original error; use only safe workflow-defined recovery. |
| Context near exhaustion | Persist current state in Progress before session handoff. |
| Unrelated work arrives mid-Feature | Classify it separately; do not silently expand current scope. |
