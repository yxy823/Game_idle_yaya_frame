# 03 · Stage 0–8 `feature-execute` loop

> This file defines how one Feature is delivered, from selection in Stage 0 to handoff in Stage 8. The `feature-execute` Skill runs this procedure. Implementation starts only after the Stage 1 approval. Stage 5 (human acceptance) applies only to the `manual` acceptance mode. Passing automated tests is evidence for completion; it never completes a Feature by itself.

## Shared contracts

- Require a substantive GDD under [GDD prerequisite and authority](01-product-doc-structure.md#gdd-prerequisite-and-authority). This applies to Product and engineering Features, including resumed work.
- Read `docs/methodology-config.json` before writing project files. The conversation uses the user's current language; prose written to project files uses `document_language`.
- Before the first coding Feature, complete the one-time [Project Environment Bootstrap](06-project-environment.md#project-environment-bootstrap). Stage 0 reuses the confirmed preparation and configured paths. Repeat the checks only after tool or configuration changes, or after an actual invocation failure.
- Read the applicable active Project Rules through `AGENTS.md` and [the rule-loading contract](04-project-rules.md#rule-loading), including relevant `docs/project-rules.md` constraints. Keep a task-relevant snapshot for the Feature; you do not need to load unrelated sections or reread unchanged sources.
- Follow `agent-rules/00-core/git-worktree-and-commits.md`: inspect and preserve current changes, use the task records when resuming, and resolve concrete overlaps before dependent edits. A non-empty Git status is not a blocker by itself.
- Read `docs/test-registry.json` when automated testing is enabled. Testing semantics are defined in [08-test-traceability-and-evidence.md](./08-test-traceability-and-evidence.md).
- Release, publishing and deployment are outside this loop unless they are explicitly planned as project work.

### Authorization and continuation

Reuse concrete user decisions across Skills, Stages and turns.

- Present the relevant plan and check that the authorization covers its actions, verification and scope. Ask only for a missing decision or a material change.
- When a Skill returns, only that procedure ends; an end-to-end task that is already authorized continues.
- In an authorized batch, complete each Feature's applicable verification, acceptance and commit before continuing. Independent review follows the user's chosen scope and timing under Stage 6.
- Authorization to implement never supplies a missing human acceptance result.

For the initial decomposition of a Product, apply [Decomposition preview](02-feature-list-schema.md#decomposition-preview) before writing the plan. That section defines preview confirmation and explicit autonomous-planning authority, including continuation into a later Product.

### Incremental commits and whole-Feature review

One Feature may contain several validated logical commits under `agent-rules/00-core/git-worktree-and-commits.md`. These commits keep `in_progress` and `completed_at: null`; only Stage 7 establishes completion. A clean worktree after a commit is not a reason to skip remaining work or start another Feature. When resuming, use the Feature and Progress records and Git history, including committed work as well as current differences.

Whenever this loop calls for the final diff or scope review, inspect the combined Feature change across all its commits and the remaining working-tree changes, not only the latest commit or the uncommitted diff. Start from the verified Git state before implementation and the task's own history; do not introduce a separate commit ledger.

### Progress communication

Report meaningful progress, failures, needed decisions and the final handoff in the conversation language. Combine adjacent routine steps when helpful; a message at every Stage boundary is not required. Keep the approval packet, the applicable human checklist and the final results visible. Natural wording is enough. Conversation text is not a machine protocol, proof of execution or a substitute for approval.

### Static-check summary

Only a Stage that actually runs static checks or lint reports their result table. Read the direct Godot parser and lint output, and include the scope and file count, Critical, Warning and Info counts, the actual process result and the report location. Report zero only when the output proves it; a failed command without a report has unavailable counts.

| Scope / files | Critical | Warning | Info | Process result | Report |
| --- | --- | --- | --- | --- | --- |
| Actual scope and count | Actual | Actual | Actual | Actual exit/status | Original report/output path |

Do not rerun global lint at every Stage. When reusing a result, name the run and the unchanged relevant source. The Agent checks whether later changes require another run. A table in the conversation does not replace an actual run.

## Stage 0 · select and load context

**Output:** exactly one current Feature and the context needed for its approval packet.

For Product-derived work, apply [Product-by-Product planning](02-feature-list-schema.md#product-by-product-planning) and finish the current Product's required Features before moving to the next Product. Dependency eligibility does not decide the Product sequence. Keep later plans intact, and keep engineering repairs within their authorized route.

1. Read the lightweight index and select the Feature:
   - Resume an `in_progress` Feature instead of starting another.
   - Before selecting unstarted work, check whether the current authorized scope contains `blocked` Features. If it does, inspect their recorded blockers and recheck recovery under [Status transitions](02-feature-list-schema.md#status-transitions) before querying eligibility.
   - Then select the Feature the user named, or a dependency-eligible `pending` Feature. `python -B tools/checks/check-feature-list.py --eligible` provides the validated selection. ID order only breaks ties, and a prerequisite may have a larger ID.
2. Run `git status --porcelain` and inspect relevant differences. Preserve current changes. For a resumed `in_progress` Feature, recover its actual stop point from the Feature and Progress records and the current files, including committed work. Resolve conflicting edits or a materially unclear requested result before dependent writes; a clean directory or per-file authorship proof is not required.
3. Read the confirmed configuration. Run `python -B tools/checks/check-project-environment.py --require-ready` at initialization, after tool or configuration changes, or to diagnose invocation failures. Routine Features reuse the confirmed paths; an incomplete setup still blocks coding.
4. Read the context for this Feature as needed:
   - the Feature detail, its `docs/features/F0XX-design.md` and the designs of relevant dependencies, when present;
   - its primary source and the applicable GDD and professional sources under [Discover and map sources](11-specialist-workflows.md#discover-and-map-sources);
   - relevant `docs/terminology.md` definitions and dependency details;
   - current Progress, following its history links only when relevant;
   - applicable Project Rules and routed `agent-rules`;
   - the Test Registry and the principal implementation paths needed to bound the change;
   - applicable architecture maps and ADRs under [the architecture convention](10-architecture-overview.md), including relevant ADRs when no map exists.
5. The main Agent reads these sources itself. When guidance is explicitly delegated, the advisor may share the background investigation under [Implementing with prepared guidance](04-project-rules.md#implementing-with-prepared-guidance); the implementer still checks the original rules and the current code.
6. Before proposing an approach or searching external references, follow [project knowledge lookup](../docs/knowledge/README.md#find-relevant-knowledge-first) for this Feature.
7. If governing sources changed after the plan adopted them, handle their actual impact through `feature-sync` before dependent execution. An ordinary continuation request needs no separate synchronization phrase.
8. Prepare a concise Context / Rules Snapshot: the Feature record, the principal GDD, Product and implementation paths read, useful knowledge references, the planned create, modify and delete paths, the applicable rule modules and materially constraining rules with their source paths, and the planned validation. There is no quota for the number of rules.
9. Present this snapshot once in the Stage 1 packet, together with the Feature's identity and status, dependencies, source, criteria, affected components and engineering mode when present. When continuing, refer to it and show only material changes; do not repeat the packet at every Stage.
10. Stop dependent work on contradictory acceptance criteria, invalid dependencies, unresolved GDD design or Product delivery scope, broken test-traceability data, or an unbounded set of planned files. If the GDD itself is missing, stop the development workflow under its prerequisite.

## Stage 1 · Test Impact Review, resource preflight, and explicit approval

**Output:** implementation plan + verification plan + user decision.

First decide `verification.acceptance_mode` under [Acceptance mode](02-feature-list-schema.md#acceptance-mode). Explain the choice in the approval packet, then fill the automated mappings and the applicable manual checks or regressions.

### 1A. Determine the test scope

Read and apply [Test Impact Review](08-test-traceability-and-evidence.md#test-impact-review) and [Runtime Test Impact selection](08-test-traceability-and-evidence.md#runtime-test-impact-selection). These sections define the Required, affected and full scopes. Using the current Feature, `affected_components`, the criterion verification and `docs/test-registry.json`, derive the Required and affected sets and decide whether full is required. Explain the selected scope and the reasons in the Stage 1 packet.

The Required set keeps every registered suite of each affected component. Removing a registration or a deterministic requirement follows [Registry rules](08-test-traceability-and-evidence.md#registry-rules) and [Test Impact Review](08-test-traceability-and-evidence.md#test-impact-review); a runner exclusion cannot do it.

Also identify:

- additional related tests justified by dependency or API impact, with concrete reasons;
- the acceptance and regression test IDs to create under TDD;
- the unit suites to create after approval, without registering their future paths;
- the cleanup of obsolete tests and current references for changed or removed contracts, after reading Feature notes and the affected test code under [Requirement changes and stale tests](08-test-traceability-and-evidence.md#requirement-changes-and-stale-tests); include it in the same plan and reuse an approval that covers this exact scope;
- the criteria that remain manual-only, and why automation is not appropriate;
- runtime verification outside gdUnit that the impact triggers in [Test Selection and Gates](../agent-rules/70-tests/test-selection-and-gates.md) require, such as a fresh Godot process or a reimport. Record it in this verification plan and report its actual result in Stage 4 and the handoff. It is not a full-suite reason, so do not add it to `full_suite_reasons`.

Identify additional professional verification obligations, such as measured performance under a named workload, an actual soak duration, or display and listening checks in context. State their conditions, completion criteria and evidence location in the AC or the Feature design; do not force them into gdUnit result fields.

### 1B. Resources

1. Identify the implementation files and resources likely required, external dependencies, placeholders and impact outside the scope. When resource preparation needs a handoff, apply [Resource requirements and handoff](11-specialist-workflows.md#resource-requirements-and-handoff). Reuse the presentation, UI or shared design sections that own the resources, and check supplied files before dependent implementation.
2. Record approved `_placeholder_` replacement needs in the resource section that owns them. When they are binding, link that section from the Feature AC or design; `notes` provide navigation. Do not duplicate the entries or treat preparation status as acceptance evidence.
3. Explain any scope expansion before coding.

For interface work, apply [Visual prototype before dependent implementation](13-prototypes.md#visual-prototype-before-dependent-implementation). Reuse a relevant accepted foundation, or resolve the missing prototype work and its actual dependencies before implementing dependent logic. For a prototype Feature, include representative resources, the independently runnable scene and the visual and interaction checks in the plan, and use the normal manual acceptance route. Approval of a prototype does not accept later production behavior.

### 1C. Design decisions and guidance

When the plan adds a module, changes a public interface or moves responsibility, apply [Designing a module boundary](10-architecture-overview.md#designing-a-module-boundary) to the affected callers and contracts. Keep the reasoning in the current plan or a design record; an architecture map is not required.

When a game function changes, use `docs/game-organization.md` to check the affected logic, presentation and collaboration responsibilities:

- Identify the actual owner of any changed business state and the result that the feedback consumes. Distinguish it from local display or playback state.
- Derive the necessary implementation order and verification from those contracts, including meaningful failure, cancellation and repeated-use paths.
- Keep useful current APIs and Godot ownership and lifecycle semantics. This check adds no compulsory objects, event bus or extra document.

Prepare the proposed implementation decisions and reasoning for the fixed [Feature design](02-feature-list-schema.md#feature-design-and-implementation-notes):

- A technical choice that meets the [ADR conditions](10-architecture-overview.md#architecture-decision-records) keeps its rationale in the ADR, and the design references it.
- Reuse the record that owns each kind of content; do not choose another location based on length or complexity.
- Return the proposal in the conversation. Do not save unapproved guidance as another guide or draft file. Stage 2 saves the approved content.
- Surface unresolved terminology and project-rule conflicts before dependent implementation. Proposed rule changes follow the self-check and authorization in [Incremental rule maintenance](04-project-rules.md#incremental-rule-maintenance).
- Do not create empty records or request approval merely for their presence.

Use `implementation-guidance-godot` when this Feature needs implementation guidance. The main Agent prepares it unless the current prompt or a still-valid authorization explicitly requests an implementation advisor; complexity alone does not delegate it. Use the same Context / Rules Snapshot, design contract and approval packet, not another planning Stage. Delegating the preparation does not approve the proposed design or implementation. Delegated questions, fixed-role selection and failure handling follow that Skill.

### 1D. Present approval packet

Present one concise packet containing:

- Feature scope and affected components;
- the Context / Rules Snapshot prepared in Stage 0;
- material design choices and constraints, and any needed Feature design, ADR and rule-change decisions;
- the Existing Safety Net to run before changes;
- the TDD acceptance and regression tests and the unit suites to create;
- the acceptance mode, its reason and the corresponding verification items;
- the full-suite decision and its reason.

Reuse an explicit approval that already covers this packet; otherwise ask for the missing decision to begin this Feature. Show material changes for approval without asking again about unchanged, already approved actions.

Without approval, do not implement and do not change the test plan in project files.

## Stage 2 · mark `in_progress` and persist verification plan

After approval:

1. Set the selected index entry to `in_progress` with `completed_at: null`.
2. Update `docs/progress.md` with the current Feature or batch, the Stage, blockers, pending decisions, the next allowed action, and links to the approved plan and evidence. Keep history in `docs/progress/`.
3. Save the approved implementation design in `docs/features/F0XX-design.md` under [Feature design and implementation notes](02-feature-list-schema.md#feature-design-and-implementation-notes):
   - Reuse a concrete approval that already covers the design; do not request it again.
   - When an advisor prepared the design, the main Agent passes the approval and the assigned destination to the same advisor, which may write only that design file.
   - The main Agent checks the design and maintains the Feature `notes` link, other record changes and commits.
   - Explain the materially constraining rules and how they apply, with relative source links. Do not copy the whole snapshot or rule text. `notes` keep reminders and references, not a second design.
4. Record already confirmed rule changes and ADRs at their own locations.
5. Save the approved `verification.acceptance_mode`, criterion verification mappings, Bug regression IDs and `verification.test_impact` in the Feature detail:
   - Store additional related tests as `additional_tests: [{"id": "<registry ID>", "reason": "<approved reason>"}]`.
   - Store approved full-suite escalations as `full_suite_reasons: ["<approved reason>"]`. Components with `full_suite_on_change: true` trigger full automatically and are not listed.
   - The runner always reads this recorded scope; changing invocation arguments must not shrink the approved coverage. Removing an obligation requires an explicitly approved plan revision.
6. Register the acceptance and regression tests that do not exist yet in `docs/test-registry.json` with `status: planned`.
7. Add newly approved component entries to the Registry when required, with `unit_test_paths: []` if no unit suite exists.
8. Run:

   ```powershell
   python -B tools/checks/check-feature-list.py
   ```

## Stage 3 · baseline, TDD, and implementation

Implement only the current Feature and its approved dependencies and repairs.

Before producing validation output or temporary inputs, choose their locations under [Reports and cleanup](09-records-reports-and-handoff.md#reports-and-cleanup). Reuse those locations across the task, keeping distinct evidence separate when needed.

Keep the Feature design aligned with the implementation and finalize it before Stage 4. Material changes follow [Authorization and continuation](#authorization-and-continuation); useful ordinary implementation details do not need another advisor round.

### 3A. Existing Safety Net baseline

Before writing implementation code that changes behavior:

1. Run the Existing Safety Net from Stage 1:

   ```powershell
   python -B tools/testing/run-gdunit-tests.py --feature F0XX --phase baseline --scope auto
   ```

   The baseline phase skips `planned` tests automatically because they do not exist yet. A valid empty safety net returns `not_required`, creates no run report and is not a test PASS.
2. Run script parsing and lint directly if useful for the baseline.
3. If a required test already fails, preserve the original error and report it before implementation. Do not attribute it to the current Feature or silently expand the scope.

### 3B. RED

Work in small cycles. Complete RED → GREEN → necessary refactor → passing relevant tests for one small observable behavior before starting the next. A large criterion may need several cycles. Planning test IDs in advance does not mean writing every test before any implementation.

For each machine-verifiable criterion or Bug regression in the current cycle:

1. Create the test with its approved logical ID.
2. Once the test exists, update its Registry entry with `path`, `case` and `status: active`.
3. Run the narrowest supported selector.
4. Confirm that the test fails because the intended behavior is missing or broken, not because of syntax, fixture, environment or unrelated setup failures.

If a meaningful RED state cannot be produced, explain why before implementation. Do not fake TDD evidence.

When a unit suite approved in Stage 1 is created, add its repository-relative file or directory path to the component's `unit_test_paths` and to the Required Test Set. Register it only after the suite exists, then confirm discovery and execution through the configured runner.

### 3C. GREEN and refactor

1. Implement the smallest coherent change that satisfies the current criterion or repair.
2. Rerun the new test until it passes.
3. Refactor locally without changing approved behavior.
4. Rerun the tests that protect each meaningful refactor, then repeat the RED, GREEN and refactor cycle for the remaining behavior.
5. Preserve accepted Product behavior outside the scope.

When a coherent logical change becomes usable, run its relevant tests and direct parsing, lint or other applicable checks, then commit it automatically under the Core Git rules.

- Include the supporting tests, resources and record updates that keep the committed snapshot consistent.
- Narrow validation must cover this change and the current behavior it affects. It does not replace the whole-Feature obligations in Stage 4.
- Do not split a change that only works or can only be verified as a whole, and do not commit a failing RED state.

Pending Feature-level human acceptance does not block a validated logical commit, unless the user explicitly made acceptance, review or separate commit permission a condition for that commit. Apply such task-specific conditions under the Core Git contract across planning, implementation and continuation; acceptance does not replace separately required commit permission. A failure or missing prerequisite for this logical change still blocks its commit. Keep current progress and remaining work in the task records, and continue the authorized implementation and all applicable Stage 4–7 requirements.

Perform the approved cleanup of test code and current references together with the behavior change, under [Requirement changes and stale tests](08-test-traceability-and-evidence.md#requirement-changes-and-stale-tests). Registry retirement alone does not remove executable methods. Keep valid shared cases and historical records.

When implementation is complete, map the changed behavior to every criterion ID.

### 3D. Documentation checkpoint before final verification

Check whether this work:

- changed accepted game design or delivery scope;
- added, renamed, retired or clarified project terminology;
- changed the Feature design, the current architecture or recorded navigation;
- produced an important technical decision;
- revealed a useful project-rule change.

Update only useful, authorized content at the location that owns it. If nothing changed, do not create a document or an empty report.

| Content | Action and authority |
| --- | --- |
| GDD and Product delivery | `design-gdd` records approved overall game-design changes; `design-balance` maintains scoped numerical design in its GDD topic. `product-author` adjusts affected Product boundaries and source links. Future Products remain pre-decomposition candidates. Resolve the impact on current and already planned work through the source-commit and synchronization route. |
| Project terminology | Invoke `project-terminology` within the current documentation authorization; definitions follow [the terminology contract](14-project-terminology.md). Changes in meaning go through the Product or design route that owns the term. |
| Professional requirements and presentation adoption | The current task coordinates the applicable presentation, UI, art, audio and localization sources under [Specialist work and sources](11-specialist-workflows.md). Finalize resource status and locations, adopted component combinations and links to the actual implementation and consumers before verification. Link acceptance records without duplicating their results. Resolve substantive source impacts before dependent delivery. |
| Feature design and current architecture | Reconcile the actual implementation and approved deviations in the Feature design. Update affected architecture contracts and navigation under [Maintaining a map](10-architecture-overview.md#maintaining-a-map), linking instead of duplicating. |
| Important technical choices | Apply the ADR threshold and authorization; keep replaced decisions and evidence limits. |
| Project or specialized rules | Apply [Incremental rule maintenance](04-project-rules.md#incremental-rule-maintenance), including a self-check before writing each proposed change. Save settled constraints; unapproved candidates stay in the design or Progress, not in active rules. |

Handle material conflicts when they are discovered instead of postponing them to this checkpoint. Return from supporting workflows to the current Feature; documentation routing must not restart Product planning or end authorized delivery.

Finalize these document edits before Stage 4. GDD, Product, terminology, professional specifications, presentation documents and their resource sections, rules, ADRs and design Markdown are part of the global source fingerprint described in [Artifact-backed completion and semantic freshness](08-test-traceability-and-evidence.md#artifact-backed-completion-and-semantic-freshness). A later change, even an editorial one or a change to a future GDD chapter, may invalidate current evidence. Complete the applicable verification and renewed acceptance after such a change; do not exempt these files or claim unchanged coverage.

## Stage 4 · automated verification and human checklist

**Output:** machine evidence plus concrete human-verification instructions.

Stage 4 uses these entry points:

- Direct parsing and lint use the confirmed Python and Godot paths from `docs/methodology-config.json`, as described in [GDScript lint](contracts/gdscript-lint.md).
- Tests run through `tools/testing/run-gdunit-tests.py`, which reads the configured Godot path.

Procedure:

1. Run `python -B tools/testing/run-gdunit-tests.py --feature F0XX --scope auto`. It reads the current obligations and prints the selection, reasons, deduplication and full-suite escalation.
   - It returns `not_required` only in the valid `manual` case defined in [Artifact-backed completion and semantic freshness](08-test-traceability-and-evidence.md#artifact-backed-completion-and-semantic-freshness). It then launches no Godot process and creates no run report. Skip step 6, keep `test_runs: []`, and continue with the applicable static checks and actual human acceptance.
   - Missing paths, zero discovery and unresolved failed or unfinished final runs on the same snapshot still fail.
2. Inspect the actual selected scope and test results. If full is required, run one real full suite whose executed set covers Required and affected; do not repeat equivalent runs only to fill different Gate fields. Otherwise run the affected union, including every Required item.
3. Run Godot script parsing directly for the changed scripts and necessary dependants, then the bundled lint CLI as described in [GDScript lint](contracts/gdscript-lint.md). Inspect the actual output and exit codes. Do not add a Python wrapper, static manifest or import step.
4. For a Bug, make sure each approved `F0XX-RTyy` test is active and passes, or that the approved `manual_regression` is concrete and repeatable.
5. If Stage 1 required full, the current selection must report full as required, and the actual full result must pass. The selection derives full from components with `full_suite_on_change: true` and from the recorded `full_suite_reasons`; component triggers are not copied into `full_suite_reasons`. An unavailable or failed required full suite blocks completion; a reason or a transcript cannot turn it into PASS.
6. When a run result was produced, record the actual Required, affected and full results, including failures:

   ```powershell
   python -B tools/features/record-feature-completion.py record-tests --feature F0XX --run <result.json>
   ```

   `record-tests` validates the supplied run results and stores references to them. It neither runs nor validates static checks. The Agent assesses the direct parsing and lint output separately; a passing evidence helper cannot override a static failure. A failed import clears earlier test references and keeps the original reports.

7. Any failing machine check returns to Stage 3. Do not enter Stage 5.
8. Follow the approved acceptance mode. For `manual`, prepare the corresponding human checks. For `automated`, report the actual automated coverage of every criterion.

For `manual`, expand the approved checks and applicable regression into a pending JSON checklist, bind it to the final content, and give its path to the user under [Manual acceptance files](contracts/manual-acceptance-files.md). That contract defines the fields, reproducible steps, result import, snapshot matching and the conversation fallback. Notes link the checklist and supporting observations instead of duplicating the steps. Screenshots and logs support the relevant action; they do not establish acceptance.

Report the actual scope, failures and result paths in ordinary language.

Complete any additional performance, soak, display or listening obligations in the approved verification plan, and keep their original evidence separate. Follow [Finalization and evidence](11-specialist-workflows.md#finalization-and-evidence); these results are not gdUnit runs. Run any runtime verification outside gdUnit planned in Stage 1, such as a fresh Godot process or a reimport, and report its actual result. Passing the evidence helper alone does not prove these obligations, the static checks or human acceptance of the experience.

For `manual`, wait for Stage 5. For `automated`, skip Stage 5 and go to Stage 5.5 for a Bug, otherwise to Stage 6. Report manual acceptance as not required; do not record a human decision that never happened.

## Stage 5 · explicit human acceptance (manual mode only)

Receive the user's actual result file or explicit decision in the conversation under [Manual acceptance files](contracts/manual-acceptance-files.md). A valid, fully passed submission accepts its scope without another confirmation phrase.

- Accepted result → record it through the applicable file or conversation route, then continue.
- Any failure → record the rejection, update Progress, return to Stage 3 and repair within the current authorization, then repeat the applicable Stage 4 and Stage 5 verification.
- Pending cases → keep the acceptance incomplete and report what remains; partial execution is not a pass.
- Ambiguous response → ask whether any criterion remains unmet.
- A minor deferral is valid only when the user explicitly accepts it and it is recorded in notes.

For a Bug Feature, accepted Stage 5 enters Stage 5.5. All others enter Stage 6.

## Stage 5.5 · Bug-learning capture

Applies only to a Feature with `engineering_change: bug`.

1. Capture the local Feature note and assess Guardrail promotion under [Bug-learning promotion](07-engineering-change.md#bug-learning-promotion). Do not keep failed debugging guesses, redundant traces or incidental machine-local failures.
2. Creating a promoted cross-Feature invariant requires the user's approval when it expands the accepted Feature scope.
3. If an approved rule change at this point alters the snapshot or current obligations, repeat the applicable verification and acceptance before completion.
4. Handle approved rule changes and any affected plans in Stage 8. Reuse the synchronization authority already given and the work already completed.

## Stage 6 · optional independent review

**Trigger:** an explicit user request for independent review. Otherwise continue to Stage 7 without a review record or a routine confirmation question. The author still checks the final diff against the AC, scope and applicable rules; this needs no general self-review Stage or report. Rule changes keep their own self-check under [Incremental rule maintenance](04-project-rules.md#incremental-rule-maintenance).

The user chooses the scope and the timing: one Feature, several named Features, a commit range or an explicit diff.

- A review after several completed Features uses the same procedure, independently of their delivery loops; it does not keep each Feature open.
- If the user requires review before completion or continuation, honor that condition under [Authorization and continuation](#authorization-and-continuation).
- An Agent may recommend review for a concrete concern, but cannot start it without the user's request.
- Do not add per-Feature review switches, pending-review states or a review queue.

**Output:** findings for the selected combined scope, with evidence and limits.

Use [Independent review](12-independent-review.md) for fresh context, neutral handoff inputs, effective permissions, isolated validation and completion limits. The `independent-reviewer` role loads only the requested applicable methods. `review-code` examines requirements and code quality; other review Skills cover UX, art, audio, assets, localization or balance when requested. One instance may combine methods; a separate pass per Skill or Feature is not required. When the author loads the same method, it is still only a self-check.

Deliver one report for the selected scope, mapping shared findings to the affected Features without duplication. Review-only work stops after the findings. Evaluate each problem and its proposed remedy separately, and reuse an authorization for a concrete repair where one was already given. Reports and permitted isolated validation outputs must not modify the reviewed artifacts, original evidence or acceptance records.

- For an unfinished Feature, confirmed in-scope defects return to Stage 3.
- For completed Features, keep the completed history and follow the engineering change route.
- Verify the repair and any invalidated Stage 4 evidence, and renew human acceptance when accepted behavior changes.
- Re-review only when the requested review condition or a concrete unresolved finding requires it.
- Do not continue past a confirmed completion-blocking defect or a failed required check just because review is optional.

Record only accepted, useful follow-ups in the Feature notes; a `suggest` finding does not automatically create a TODO or task. The completion evidence contains no review counts. Isolated review output does not invalidate a current run. Before continuing, check that the reviewed snapshot is unchanged and that the user's required review coverage is met.

## Stage 7 · mark complete

**Entry:** all of the following hold:

- Stage 4 evidence covers all current automated obligations, or the valid manual case without automated obligations returned `not_required`.
- The required test evidence and, for `manual`, the explicit Stage 5 acceptance match the current semantic content fingerprint. The Git revision only records provenance: a commit that changes only status, time or history content grants no new acceptance and requires no rerun.
- The Agent has checked the final diff against the AC and the scope.
- The applicable direct parsing and lint, and any supplemental professional verification, passed.
- Any explicit user review condition is satisfied.

The evidence helper checks tests and applicable human acceptance only. It does not assess static or supplemental checks, perform a review, or decide whether a user condition is met.

Before the completion commands, confirm that the Stage 3 documentation checkpoint and any later approved governing updates are complete. If a missing edit is made now, restore the applicable current verification and acceptance before marking completion. Do not postpone such edits until after the Feature is recorded as done.

1. Run:

   ```powershell
   python -B tools/features/record-feature-completion.py validate --feature F0XX
   python -B tools/checks/check-feature-list.py --completion-feature F0XX
   ```

2. Record the verified result: set the Feature to `done` and set `completed_at` to the current ISO 8601 timestamp. The status field records completion; it does not prove tests, review or human acceptance.
3. Run `python -B tools/checks/check-feature-list.py` on the final ledger. If implementation or contract changes invalidate the evidence, finish the relevant verification before delivery.
4. Keep task reminders, Bug learning, accepted follow-ups and links in notes. Implementation decisions, their reasons and explanations of omitted edge cases belong in the Feature design; placeholder specifications stay in their resource section. Before committing, finalize useful knowledge and its index under [knowledge maintenance](../docs/knowledge/README.md#maintain-during-authorized-work), keeping [artifact ownership](09-records-reports-and-handoff.md#project-knowledge).
5. Check this task's report locations, evidence links and the purpose of any retained scratch files under [Reports and cleanup](09-records-reports-and-handoff.md#reports-and-cleanup). Then archive the current execution history once under `docs/progress/<Feature-or-approved-batch>.md`, and leave only the current state and its history link in `docs/progress.md`. Feature notes keep TODOs and links to design decisions and applicable ADRs; do not duplicate the rationale or the execution history. Pure Markdown archiving does not affect test fingerprints.
6. Confirm that the applicable test and acceptance evidence still covers the final change under the snapshot rules. Reuse valid results; run missing or invalidated checks instead of repeating identical verification because the Stage changed.
7. Follow `agent-rules/00-core/git-worktree-and-commits.md` to commit the remaining validated implementation and completion records, with its Feature identity, staging and delivery reporting. Earlier logical commits remain part of this Feature's delivery; do not squash them or create an empty commit only to mark a Stage. The Core contract also defines the no-commit exception, the current-branch policy and prohibited Git operations.

## Stage 8 · handoff and authorized continuation

1. If this task changed project or specialized rules, report the change and complete the needed `feature-sync` impact handling before the next affected Feature. Reuse the authorization and any synchronization already completed; edits that keep the meaning need no invented follow-up work. If an actual decision or required synchronization is not authorized, report that boundary and stop the dependent continuation.
2. Otherwise check the current Product's remaining scope and the sources and statuses of its Features.
   - If work remains, use [Stage 0 selection](#stage-0--select-and-load-context), including its blocked-work recovery check, to identify the next eligible `pending` Feature or the actual blocker.
   - Only after the Product's required Features are complete, revisit the current GDD and the next pre-decomposition candidate. Use `product-author` to write its delivery document and then `feature-plan` to decompose it, or reuse its plan.
   - Apply the authorization boundary in step 5. Having no eligible Feature does not prove that the Product is complete.
3. Report the completed Feature, the relevant implementation and test changes, the verification evidence, its local commit hashes or verified commit range (or the explicit no-commit exception), the worktree status after the commit, the placeholder count, TODOs, and the next Feature or Product-planning step. When cleanup was required, state the actual obsolete-test and reference changes and any remaining work recorded in notes or Progress.
4. Report reusable learning with `templates/feature-learning-summary.md.tmpl`:
   - With no new reusable learning, state “No new reusable learning” (Chinese: “无新增可复用经验”). Do not invent an entry for every incident.
   - Otherwise report one sentence or a few concise entries: the context, the useful approach or root cause, the coverage already in place, the applicability, and the actual or proposed destination (Knowledge, Agent Rule, Methodology, Tooling, Automated Check or Regression).
   - Link knowledge or Bug-learning notes recorded before the commit instead of copying them or writing documentation after the commit.
   - A project-specific approach can be reusable within the project without becoming a universal rule.
   - A newly discovered tooling or rule change outside the scope is a separate authorized task.
5. Continue with the next step only when it is within a concrete authorization and its prerequisites are met. Keep the Product order and each Feature's approval, acceptance and completion requirements. If the requested scope is complete, the user asked for a pause, or a necessary decision is missing, stop and name that boundary. Eligibility or completion alone grants no new scope.

## Delivery of existing implementation

This section applies to implementation adopted under [Adopting existing implementation](02-feature-list-schema.md#adopting-existing-implementation).

Use Stages 0–2 to confirm the current contract, the actual implementation coverage, the remaining work, the acceptance mode and the Test Impact Review, then save the approved plan. Completion evidence is recorded only when actual results exist. Reuse concrete authorization; a request to document the implementation alone does not authorize execution or repairs. Git change preservation and environment requirements are those of the [shared contracts](#shared-contracts).

In Stage 3, reuse behavior that already satisfies the confirmed AC:

- Map suitable tests through the Registry. Add missing checks against the intended behavior and meaningful boundaries, not assertions that merely mirror the implementation.
- For unchanged adopted behavior, a newly written test may pass immediately. Record it as present verification, not as historical TDD.
- Do not undo working behavior to create a RED run, and do not reconstruct a missing pre-implementation baseline.
- Before any further behavior change or repair, apply the normal baseline and TDD contract to that remaining work. Failures found during adoption are real gaps; they do not permit weakening the contract or widening repairs.

For scope review, use the verified original changes when available, and inspect the current implementation against every adopted criterion. If the original baseline cannot be recovered, disclose that limit and review the relevant current implementation and its direct callers. An empty documentation-only diff proves no behavior. The snapshot at adoption establishes current evidence; it makes no claim about the original development process.

Complete the applicable Stages 4–7 with evidence covering the current Product, the Feature and Registry contract, and the implementation. Earlier results must satisfy the snapshot and coverage rules; historical claims or notes cannot replace them. Required human acceptance and explicit review conditions still apply. Set `done` and `completed_at` only when Stage 7 succeeds, using the actual completion time. Keep a verified earlier implementation date in notes. Never backdate formal completion or replay implementation steps that are already satisfied.

## Exception handling

| Condition | Required action |
| --- | --- |
| Acceptance criteria are ambiguous or contradictory | Route to the Product or Feature revision workflow that owns them; do not reinterpret them silently. |
| A completed dependency is materially incomplete | Report the gap and obtain the user's direction. |
| Implementation needs files or behavior outside the scope | Explain the expansion and obtain approval, or create another Feature. |
| The Existing Safety Net fails before implementation | Preserve the original error and obtain direction; do not silently absorb an unrelated repair. |
| The Test Registry is inconsistent | Stop and repair traceability before using it to choose tests. |
| A test, command, file or Git operation fails | Preserve the original error; use only safe recovery defined by the workflow. |
| The context is nearly exhausted | Save the current state in Progress before handing off the session. |
| Unrelated work arrives during a Feature | Classify it separately; do not silently expand the current scope. |
