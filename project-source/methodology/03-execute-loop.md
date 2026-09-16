# 03 · Stage 0–8 `execute-next-feature` loop

> Canonical delivery specification for one Feature. `execute-next-feature` implements this workflow. Stage 1 requires approval; Stage 8 hands off according to the remaining authorization. Stage 5 applies only to the approved manual acceptance mode. Automated testing is subordinate evidence, never an autonomous completion authority.

## Shared contracts

- Read `docs/methodology-config.json` before durable writes. Conversation uses the user's current language; durable prose uses `document_language`.
- Before the first coding Feature, complete the one-time Project Environment Bootstrap defined in [05-document-language.md](./05-document-language.md). Every Stage 0 requires `environment_bootstrap.status: ready`; it reads the confirmed configuration rather than rediscovering commands.
- Read the applicable active Coding Rules through `AGENTS.md` and [the rule-loading contract](04-coding-rules-4-layers.md#rule-loading), including relevant `docs/coding_rules.md` constraints. Retain the Feature's task-relevant snapshot; complete applicability does not require loading unrelated sections or rereading unchanged sources.
- Follow `agent-rules/00-core/git-worktree-and-commits.md`. A new Feature execution starts from a clean worktree; a resumed Feature may retain only changes demonstrably owned by that same Feature.
- Read `docs/test-registry.json` when automated testing is enabled. Testing semantics are defined in [08-testing-strategy.md](./08-testing-strategy.md).
- Release/publishing/deployment workflow is outside this loop unless explicitly represented as project work.

### Authorization and continuation

Reuse concrete user decisions across Skills, Stages and turns. Present the relevant
plan and check that its actions, verification and scope are covered; ask only for
a missing decision or a material change. A Skill's return ends that procedure,
not an already authorized end-to-end task. Complete each Feature's applicable
verification, acceptance and commit before continuing an authorized batch;
independent review follows the user's chosen scope and timing under Stage 6.
Authorization to implement never supplies a missing human acceptance result.

For initial Product decomposition, apply [Decomposition preview](02-feature-list-schema.md#decomposition-preview)
before plan writes; that contract defines preview confirmation and explicit
autonomous-planning authority, including continuation into a later Product.

### Incremental commits and whole-Feature review

One Feature may contain several validated logical commits under
`agent-rules/00-core/git-worktree-and-commits.md`. Such commits retain
`in_progress` and `completed_at: null`; only Stage 7 establishes completion.
A clean worktree after a commit is not a reason to skip remaining work or start
another Feature. Resume using the existing Feature/Progress records and Git
history, including already committed work as well as current differences.

Whenever this loop calls for the final diff or scope review, inspect the combined
Feature change across all its commits and remaining working-tree changes, not
only the latest commit or uncommitted diff. Use the verified pre-implementation
Git state and task-owned history; do not introduce a separate commit ledger.

### Delivery of existing implementation

For implementation adopted under [Adopting existing implementation](02-feature-list-schema.md#adopting-existing-implementation),
use Stages 0–2 to confirm the current contract, actual implementation coverage,
remaining work, acceptance mode and Test Impact Review, then persist the approved
plan and initialize completion evidence. Reuse concrete authorization; a request
to document existing work alone does not authorize execution or repairs. Git
ownership and environment requirements remain those of the shared contracts.

In Stage 3, reuse behavior already satisfying the confirmed AC. Map suitable
existing tests through the Registry; add missing checks against intended behavior
and meaningful boundaries, not merely assertions that mirror the implementation.
For unchanged adopted behavior, a new test may pass immediately: record it as
present verification, not historical TDD. Do not undo working behavior to create
a RED run or reconstruct a missing pre-implementation baseline. Before any new
behavior change or repair, apply the normal baseline and TDD contract to that
remaining work; failures found during adoption remain real gaps, not permission
to weaken the contract or broaden repairs.

For scope review, use verified original changes when available and inspect the
current implementation against every adopted AC. If the original baseline cannot
be recovered, disclose that limit and review the relevant current implementation
and its direct callers; an empty documentation-only diff proves no behavior.
The adoption-time snapshot establishes current evidence, not a claim about the
original development process.

Complete applicable Stages 4–7 with evidence covering the current Product,
Feature/Registry contract and implementation. Prior results must satisfy the
existing snapshot and coverage rules; historical claims or notes cannot replace
them. Required human acceptance and explicit review conditions still apply.
Set `done` and `completed_at` only when Stage 7 succeeds, using the actual current
completion time. Keep any verified earlier implementation date in notes; never
backdate formal completion or replay already satisfied implementation steps.

### Progress communication

Report meaningful progress, failures, decisions needed and the final handoff in the
conversation language. Combine adjacent routine steps when helpful; no message is
required at every Stage boundary. Preserve the approval packet, applicable human
checklist and final results. Natural wording is sufficient; conversation text is
not a machine protocol, execution proof or substitute for approval.

### Static-check summary

Only a Stage that actually runs static/lint emits its result table. Read the
direct Godot/parser and lint output and include scope/file count, Critical,
Warning, Info, actual process result and report location. Zero is reported only
when the output proves it; a failed command with no report has unavailable counts.

| Scope / files | Critical | Warning | Info | Process result | Report |
| --- | --- | --- | --- | --- | --- |
| Actual scope and count | Actual | Actual | Actual | Actual exit/status | Original report/output path |

Do not rerun global lint at every Stage. When reusing a result, say which run
and unchanged relevant source are reused. The Agent checks whether intervening
changes require another run. A conversational table does not replace actual execution.

## Stage 0 · select and load context

**Output:** exactly one current Feature and the context needed for its approval packet.

For Product-derived work, apply [Product-by-Product planning](02-feature-list-schema.md#product-by-product-planning).
Finish the current Product's required Features before moving to the next
Product. Dependency eligibility does not establish Product sequencing; preserve
existing later plans, and keep engineering repairs within their authorized route.

1. Read the lightweight index and select either the user-specified Feature or a dependency-eligible `pending` Feature. `python -B tools/checks/check-feature-list.py --eligible` provides the validated DAG selection; ID is only a stable tie-breaker and dependencies may have larger IDs. Resume an existing `in_progress` Feature instead of starting another.
2. Run `git status --porcelain`. A new Feature requires no output. For a resumed `in_progress` Feature, reconcile every reported path with its durable Feature/Progress record and stop if any path is unrelated or ownership is ambiguous.
3. Read the confirmed configuration. Run `python -B tools/checks/check-project-environment.py --require-ready` at initialization, after tool/configuration changes, or to diagnose invocation failures. Routine Features reuse confirmed paths; incomplete setup still blocks coding.
4. Load that Feature detail, its Product source, relevant definitions in `docs/CONTEXT.md` when present, relevant dependency details, current Progress, applicable Coding Rules, test registry, and the principal implementation files/directories needed to bound the change. Follow Progress history links only when relevant. Read applicable optional architecture maps and ADRs under [the architecture convention](10-architecture-overview.md), including relevant ADRs when no map exists.
   Before proposing an approach or searching external references, consult
   `docs/knowledge/README.md` and the relevant topic indexes and entries.
   Check their applicability to this Feature; reuse prior reading on continuation
   unless scope or evidence changed. An empty or unrelated topic adds no blocker.
5. Prepare a concise Context / Rules Snapshot: the Feature record, principal Product/implementation paths read, useful knowledge references, planned create/modify/delete paths, applicable rule modules and materially constraining rules with source paths, plus planned validation. There is no rule-count quota.
6. Present this snapshot once in the Stage 1 packet alongside Feature identity/status, dependencies, source, stable criteria, affected components and engineering mode when present. On continuation, reference it and show only material changes; do not reproduce the same packet at every Stage.
7. Stop on contradictory acceptance criteria, invalid dependencies, unresolved Product intent, broken test-traceability data, or an unbounded planned file surface.

## Stage 1 · Test Impact Review, resource preflight, and explicit approval

**Output:** implementation plan + verification plan + user decision.

Decide acceptance from Product/engineering intent before filling verification lists.
Visual presentation, animation feel, audio/sound/music, game feel, and other human
perception or judgment require `verification.acceptance_mode: "manual"`.
For other requirements whose AC can all be verified automatically, choose
`"automated"`. Explain the choice in the approval packet, then fill the
automated mappings and applicable manual checks/regressions. Empty lists and
previous PASS records do not make this decision. Null means an undecided draft.

### 1A. Determine the test scope

Read and apply [Test Impact Review](08-testing-strategy.md#test-impact-review) and
[Runtime Test Impact selection](08-testing-strategy.md#runtime-test-impact-selection).
These sections define Required, affected, and full scope. Using the current Feature,
`affected_components`, criterion verification, and `docs/test-registry.json`, derive
the Required and affected sets, then decide whether full is required. Explain the
selected scope and reasons in the Stage 1 packet.

Keep affected components' registered suites in scope. Empty `unit_test_paths` adds
no selector; missing registered paths and zero-test discovery are errors. Removing a registration
requires an explicit reason and user approval; a runner exclusion cannot remove a
deterministic requirement. Approved retirement or registry correction must change
the underlying traceable contract before recomputing the selection.

Also identify:

- additional related tests justified by dependency/API impact, with concrete reasons;
- new acceptance/regression test IDs that should be created under TDD;
- new unit suites to create after approval, without registering future paths;
- necessary obsolete-test and current-reference cleanup for changed/removed
  contracts, reading Feature notes and affected test code under
  [Requirement changes and stale tests](08-testing-strategy.md#requirement-changes-and-stale-tests);
  include it in the same plan and reuse existing approval for that exact scope;
- criteria that remain manual-only and why automation is not appropriate.

### 1B. Resource/dependency preflight

1. Identify implementation files/resources likely required, external dependencies, placeholders, and out-of-scope impact.
2. Register `_placeholder_` resources in Feature notes with replacement guidance when approved.
3. Explain any scope expansion before coding.

### 1C. Present approval packet

Present one concise packet containing:

- Feature scope and affected components;
- the Context / Rules Snapshot prepared in Stage 0;
- Existing Safety Net to run before changes;
- new TDD acceptance/regression tests and unit suites to create;
- acceptance mode, its reason, and corresponding verification items;
- full-suite decision and reason.

Reuse explicit approval already covering this packet; otherwise ask for the
missing decision to begin this Feature. Show material changes for approval
without asking again about unchanged, already approved actions.

No approval → no implementation and no durable test-plan mutation.

## Stage 2 · mark `in_progress` and persist verification plan

After approval:

1. set the selected index entry to `in_progress`, `completed_at: null`;
2. update `docs/progress.md` with current Feature/batch and Stage, blockers, pending decisions, next legal action, and links to the approved plan/evidence; keep history bodies in `docs/progress/`;
3. persist approved `verification.acceptance_mode`, criterion verification mappings, Bug regression IDs, and `verification.test_impact` in the Feature detail. Store additional related tests as `additional_tests: [{"id": "<registry ID>", "reason": "<approved reason>"}]` and full-suite obligations as `full_suite_reasons: ["<approved reason>"]`. The runner always reads this recorded scope; changing invocation arguments must not shrink approved coverage. Removing an obligation requires an explicit approved plan revision;
4. register not-yet-created durable acceptance/regression tests in `docs/test-registry.json` with `status: planned`;
5. add newly approved component entries to the registry when required, with `unit_test_paths: []` if no unit suite exists;
6. initialize the current Feature's structured completion evidence:

   ```powershell
   python -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py initialize --feature F0XX
   ```

7. run:

   ```powershell
   python -B tools/checks/check-feature-list.py
   ```

## Stage 3 · baseline, TDD, and implementation

Implement only the current Feature and its approved dependencies/repairs.

Before producing validation output or temporary inputs, choose their destinations
under [Reports and cleanup](09-artifact-lifecycle.md#reports-and-cleanup). Reuse
those locations across the task while preserving distinct evidence when needed.

### 3A. Existing Safety Net baseline

Before writing behavior-changing implementation code:

1. run the Existing Safety Net from Stage 1, excluding new `planned` tests that do not exist yet;
2. directly run script parsing/lint if useful for the pre-change baseline;
3. if an existing required test already fails, preserve the original error and report it before implementation. Do not attribute it to the current Feature or silently expand scope.

### 3B. RED

For each machine-verifiable new acceptance criterion or Bug regression:

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
4. repeat for the remaining criteria;
5. preserve accepted Product behavior outside scope.

As a coherent logical change becomes usable, run its relevant tests and direct
parsing/lint or other applicable checks, then commit it automatically under the
Core Git rules. Include supporting tests, resources and record updates needed
to keep that committed snapshot consistent. Narrow validation must cover this
change and its affected existing behavior; it does not replace the whole-Feature
obligations in Stage 4. Do not split a change that can only work or be verified
together, or commit a failing RED state.

Pending Feature-level human acceptance does not prevent a validated logical
commit, unless the user explicitly made acceptance/review a condition for that
commit. A failure or missing prerequisite for this logical change still blocks
its commit. Keep current progress and remaining work in the existing records;
continue authorized implementation and all applicable Stage 4-7 requirements.

Perform the approved test-code and current-reference cleanup with the behavior
change, following [the stale-test contract](08-testing-strategy.md#requirement-changes-and-stale-tests).
Registry retirement alone does not remove executable methods; preserve valid
shared cases and historical records.

At implementation completion, map changed behavior to every criterion ID.

## Stage 4 · automated verification and human checklist

**Output:** machine evidence plus concrete human-verification instructions.

Read project commands from `docs/methodology-config.json`:

- confirmed Python/Godot executable paths for direct checks described in `gdscript-lint.md`;
- `test_cmd`: project test runner entrypoint or documented targeted command;

Procedure:

1. Read the current Feature/Registry obligations. If any Required/affected test or full-suite obligation exists, run the configured test runner with `--feature F0XX --scope auto`. It prints the selection, reasons, deduplication and full-suite escalation. No independent plan file is written. Missing or zero-discovery selectors fail. Only a valid `manual` plan with empty Required and affected sets and no full-suite obligation may omit the run and step 6, retaining `test_runs: []`; report `not_required`, not PASS. Continue applicable static checks and actual human acceptance. This case cannot hide an unresolved failed/unfinished final run on the same snapshot.
2. Inspect the actual selected scope and test results. If full is required, run one real full suite whose executed set covers Required and affected; do not repeat equivalent runs merely to fill different Gate fields. Otherwise run the affected union, including every Required item.
3. Directly run Godot script parsing for changed scripts and necessary dependants,
   then the bundled lint CLI as described in `gdscript-lint.md`. Inspect actual
   output and exit codes. Do not add a Python wrapper, static manifest or import step.
4. For a Bug, ensure each approved `F0XX-RTyy` test is active and passes, or the approved `manual_regression` is concrete and repeatable.
5. If Stage 1 required full, the Feature’s recorded Test Impact must require it and the actual full result must pass. An unavailable or failed required full suite blocks completion; a reason or transcript cannot turn it into PASS.
6. Record the actual Required Test Set, affected-test, and full-suite result, including failures:

   ```powershell
   python -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py record-tests --feature F0XX --run <result.json>
   ```

   `record-tests` validates the supplied run results and stores their references.
   It neither runs nor validates static checks. The Agent separately assesses direct
   parsing/lint output; a passing evidence helper cannot override a static failure.
   Failed evidence imports clear old test references and preserve original reports.

7. Any failing machine check returns to Stage 3. Do not enter Stage 5.
8. Follow the approved acceptance mode. For `manual`, prepare the corresponding
   human checks. For `automated`, report actual automated coverage of every AC.

For `manual`, expand the approved checks and applicable regression into a pending
JSON checklist, bind it to final content and provide its path to the user under
[Manual acceptance files](manual-acceptance-files.md). That contract owns fields,
reproducible steps, result import, snapshot matching and the conversation fallback.
Notes link the checklist and supporting observations instead of duplicating steps.
Screenshots/logs supplement the relevant action; they do not establish acceptance.

Report actual scope, failures and result paths in ordinary language.

For `manual`, wait for Stage 5. For `automated`, omit Stage 5 and go to Stage 5.5
for a Bug, otherwise Stage 6. Report manual acceptance as not required; do not
record an accepted human decision that never occurred.

## Stage 5 · explicit human acceptance (manual mode only)

Receive the user's actual result file or explicit conversational decision under
[Manual acceptance files](manual-acceptance-files.md). A valid, fully passed
submission accepts its corresponding scope without another confirmation phrase.

- Accepted result → record via the applicable file or conversation route, then continue.
- Any failure → record rejection, update Progress, return to Stage 3 and repair within existing authorization, then repeat applicable Stage 4 and Stage 5 verification.
- Pending cases → retain incomplete acceptance and report what remains; do not treat partial execution as a pass.
- Ambiguous response → ask whether any criterion remains unmet.
- A minor deferral is durable only when the user explicitly accepts it and it is recorded in notes.

For a Bug Feature, accepted Stage 5 enters Stage 5.5. All others enter Stage 6.

## Stage 5.5 · Bug-learning capture

Applies only to detail files with `engineering_change: bug`.

Append to Feature notes:

```text
BUG learning
Root cause: <causal implementation defect>
Trigger: <minimum trigger/precondition>
Regression coverage: <F0XX-RTyy logical IDs, or approved manual regression reason/check>
Guardrail: <general principle preventing the same defect class>
```

Do not persist failed debugging guesses, redundant traces, or incidental machine-local failures.

Evaluate whether the Guardrail is reusable enough for Coding Rules according to [04-coding-rules-4-layers.md](./04-coding-rules-4-layers.md). If so, show the exact proposed prescriptive rule and destination and establish explicit approval under Authorization and continuation. Never promote automatically.

If the Guardrail becomes a machine-verifiable cross-Feature invariant, propose an `INV-<DOMAIN>-NN` test and registry entry. Creating that invariant still requires the user's approval when it expands the accepted Feature scope.

If a Coding Rule is approved, Stage 8 requires `sync-feature-list` before another
Feature starts; use existing synchronization authorization or obtain the missing decision.

## Stage 6 · optional independent requirements and code-quality review

**Trigger:** an explicit user request for independent review. Otherwise continue
to Stage 7 without a review record or a routine confirmation question. The author
still checks the final diff against AC, scope and applicable rules; this needs
no separate self-review Stage or report.

The user chooses one Feature, several named Features, a commit range or an
explicit diff, and when to review it. A review after several completed Features
uses the same procedure independently of their delivery loops; it does not hold
each Feature open. If the user requires review before completion or continuation,
honor that condition under the existing authorization contract. An Agent may
recommend review for a concrete concern, but cannot start it without that request.
Do not add per-Feature review switches, pending-review states or a review queue.

**Output:** findings for the selected combined scope, with evidence and limits.

The reviewer must be a fresh-context subagent/session or equivalent independent
context. If unavailable, report the independence limitation; do not call the
author's check independent review. It performs no writes and reads the selected
Features' approved scope and AC, relevant Product, existing CONTEXT definitions
and accepted architecture decisions, relevant project knowledge, applicable
Coding Rules, actual final diff, directly affected callers
and changed files, and original verification results with applicable human
feedback. Treat the implementer's summary as claims to check against these
sources, not as independent evidence. Establish the compared commits or working
diff and current combined behavior; avoid repeating a full pass for each Feature
or expanding to unrelated project history.

Use one review pass for both questions:

1. **Requirements:** Does the implementation satisfy every current AC, preserve
   required existing behavior, and stay within approved scope? Check that the
   cited tests and manual observations actually exercise the claimed behavior.
   Report missing, stale or inconclusive evidence as a gap; do not invent an
   acceptance decision or rewrite AC to fit the implementation. For changed or
   removed contracts, inspect the final diff, affected current references and
   actual discovery/results for required obsolete-test cleanup and retained valid
   coverage. Unfinished required cleanup is `must_fix`; Registry status alone
   cannot establish completion.
2. **Code quality:** Inspect oversized files, duplicated domain knowledge,
   misplaced type dispatch, magic values, duplicated constants/enums, God
   Objects, stack-specific anti-patterns, presentation/domain coupling,
   comments that restate code, and defects requiring repeated repair attempts.
   Check changed boundaries against applicable accepted ADRs and architecture maps.

Return a short conclusion for each question plus the existing `must_fix`,
`suggest`, and `acceptable` findings, with criterion/rule and file/evidence
references. Keep the two conclusions separate even when grouping findings by
severity, and identify the relevant question(s) for each finding. State evidence
gaps explicitly; one question's conclusion cannot stand in for the other's.
Findings from either question contribute to the same review result.

Deliver one report in the conversation, or at the user's specified report path.
Map shared findings to all affected Features without duplicating the explanation.
Review-only work stops after findings; severity labels do not authorize repairs.
Evaluate the problem and proposed remedy separately before implementing the
user-selected scope. Reuse authorization that already covers a specific repair.

For an unfinished Feature, confirmed in-scope defects return to Stage 3. For
completed Features, preserve completed history and follow the existing engineering
change route. Verify the affected repair and any invalidated Stage 4 evidence;
renew human acceptance when accepted behavior changes. Re-review only when the
requested review condition or a concrete unresolved finding requires it.
Do not continue past a confirmed completion-blocking defect or failed required
check merely because review is optional.

Record only accepted, useful follow-ups in existing Feature notes; a `suggest`
does not automatically create a TODO or task. No review counts belong in the
completion evidence. A read-only review does not invalidate a current successful
run; further execution needs an authorized, concrete verification need.

## Stage 7 · mark complete

**Entry:** Stage 4 evidence covers all current automated obligations, or its valid manual/no-automated-obligations case is `not_required`. Required test evidence and explicit Stage 5 human acceptance for `manual` must match the current semantic content fingerprint. Git revision is provenance; content-identical status/time/history commits do not grant new acceptance or require a fictitious rerun. The Agent checks the final diff against AC and scope, confirms applicable direct parsing/lint passed, and satisfies any explicit user review condition. The evidence helper checks tests and applicable human acceptance; it does not assess static checks, perform review or decide whether a user condition is satisfied.

1. Run:

   ```powershell
   python -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py validate --feature F0XX
   python -B tools/checks/check-feature-list.py --completion-feature F0XX
   ```

2. Record the verified result: transition the Feature to `done` and set
   `completed_at` to the current ISO 8601 timestamp. The status field records
   completion; it does not prove tests, review or human acceptance.
3. Run `python -B tools/checks/check-feature-list.py` on the final ledger.
   These are explicit task commands. There is no tool-event interceptor or
   additional terminal state machine. If implementation or contract changes
   invalidate the evidence, finish the relevant verification before delivery.
4. Persist durable implementation decisions, placeholder guidance, omitted edges, Bug learning, and accepted follow-ups. Extract useful successful approaches, debugging methods and failure lessons into the appropriate `docs/knowledge/` topic before committing, following its README. Update an existing entry before duplicating it, link the original Feature/evidence, and maintain the nearest index. No new entry is required when existing material suffices. Knowledge is explanatory Markdown; code, tests and governing contracts keep their normal locations and verification requirements.
5. Check this task's report locations, evidence links and retained scratch purpose under [09-artifact-lifecycle.md](09-artifact-lifecycle.md#reports-and-cleanup), then archive current execution history once under `docs/progress/<Feature-or-approved-batch>.md`; leave only current state and its history link in `docs/progress.md`. Feature notes own local decisions/TODOs and link important technical ADRs; do not duplicate rationale or execution history. Pure Markdown archival is excluded from test fingerprints.
6. Confirm applicable test/acceptance evidence still covers the final change under the structured snapshot rules. Reuse valid results; run missing or invalidated checks rather than repeating identical verification because the Stage changed.
7. Follow `agent-rules/00-core/git-worktree-and-commits.md` to commit the remaining validated implementation and completion records, with its Feature identity, staging and post-commit checks. Earlier logical commits remain part of this Feature's delivery; do not squash them or create an empty commit merely to mark a Stage. The Core contract also owns the no-commit exception, current-branch policy and prohibited Git operations.

## Stage 8 · handoff and authorized continuation

1. If Stage 5.5 changed Coding Rules, report and complete the required `sync-feature-list` before starting another Feature when that synchronization is authorized. Otherwise request the missing authorization and stop.
2. Otherwise check the current Product's remaining scope and Feature sources/statuses. If work remains, identify the next eligible `pending` Feature or actual blocker. Only after its required Features are complete, recommend revisiting and decomposing the next Product with `generate-feature-list`, or reusing its existing plan. No eligible Feature is not itself proof of Product completion.
3. Report the completed Feature, relevant implementation/test changes, verification evidence, its local commit hashes or verified commit range (or the explicit no-commit exception), post-commit worktree status, placeholder count, TODOs, and the next Feature or Product-planning step. When cleanup was required, state the actual obsolete-test/reference changes and any remaining work using existing notes/Progress.
4. Report one sentence or a few concise learning entries in this existing Stage, using `templates/feature-learning-summary.md.tmpl`. With no new reusable learning, explicitly state “No new reusable learning” (Chinese: “无新增可复用经验”). Otherwise report the context, useful approach or root cause, existing coverage, applicability and actual or proposed destination: Knowledge / Agent Rule / Methodology / Tooling / Automated Check / Regression. Link knowledge or Bug-learning notes already recorded before the commit instead of copying their bodies or starting post-commit documentation. A project-specific approach can be reusable within the project without becoming a universal rule. Do not invent an entry for every incident. A newly discovered out-of-scope tooling or rule change remains a separate authorized task.
5. Continue the next step only when it is within concrete existing authorization
   and its prerequisites are satisfied. Preserve Product order and each Feature's
   approval, acceptance and completion requirements. If the requested scope is
   complete, the user requested a pause, or a necessary decision is missing, stop
   and identify that boundary. Eligibility or completion alone grants no new scope.

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
