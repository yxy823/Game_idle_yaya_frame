# 03 · Stage 0–8 `execute-next-feature` loop

> Canonical delivery specification for one Feature. `execute-next-feature` implements this workflow. Stage 1 approval and the final handoff stop are mandatory; Stage 5 applies only to the approved manual acceptance mode. Automated testing is subordinate evidence, never an autonomous completion authority.

## Shared contracts

- Read `docs/methodology-config.json` before durable writes. Conversation uses the user's current language; durable prose uses `document_language`.
- Before the first coding Feature, complete the one-time Project Environment Bootstrap defined in [05-document-language.md](./05-document-language.md). Every Stage 0 requires `environment_bootstrap.status: ready`; it reads the confirmed configuration rather than rediscovering commands.
- Read the complete active Coding Rules before implementation and retain the relevant rule snapshot for the Feature. In this repository that means `docs/coding_rules.md`, `agent-rules/00-core/README.md`, and every routed module applicable to the Feature.
- Follow `agent-rules/00-core/git-worktree-and-commits.md`. A new Feature execution starts from a clean worktree; a resumed Feature may retain only changes demonstrably owned by that same Feature.
- Read `docs/test-catalog.json` when automated testing is enabled. Testing semantics are defined in [08-testing-strategy.md](./08-testing-strategy.md).
- Execute and locally commit on the current Git branch, including `main` or `master`, subject to all existing approval, clean-worktree, acceptance, and Completion Gates. Do not automatically create, switch, merge, or delete branches. Never force-push or use `reset --hard`.
- Never start implementation, infer human acceptance, promote a Bug guardrail, or start the next Feature without the required explicit user decision.
- Release/publishing/deployment workflow is outside this loop unless explicitly represented as project work.

### Stage conversation updates

- After completing each Stage (0–8, including Stage 5.5 when applicable), the agent must immediately send one user-visible conversation message **before any operation belonging to the next Stage**. Do not batch updates, defer them to the final report, or fabricate retrospective messages for completed work.
- Use the current conversation language and 1–3 sentences to state the Stage number and name, work actually completed, actual check results, and whether execution continues or waits (and for what). Keep this a stage summary, not a tool-by-tool log. Required context snapshots, approval packets, human checklists, and handoff details remain required; the short update summarizes rather than replaces them.
- Updates add no approval checkpoints. Stage 1 presents its approval packet and reports that approval is pending; only after explicit approval report Stage 1 complete, before Stage 2 operations. Stage 4 reports whether the approved plan requires Stage 5 human acceptance; report Stage 5 complete only after explicit acceptance has been recorded. Stage 8 uses its final handoff message as the completion update and stops. Other Stages report and continue within existing authorization; existing conditional approvals, including Bug-guardrail promotion, remain unchanged.
- On `BLOCKED`, failure, or a return to an earlier Stage, immediately report the current Stage, reason, actual check result, and next action before dependent operations. Do not describe blocked or incomplete work as completed.
- Include the unchanged Stage 4 / Stage 6 exact summary line once in that Stage's same message, alongside the 1–3 sentences in the conversation language. Do not emit it as a separate duplicate update; these fixed summary lines remain untranslated.
- Conversation updates do not replace structured `docs/gate-evidence.json` or any existing approval, acceptance, or Completion Gate. Do not introduce report files or chat-text/regex gates for this requirement.

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

**Output:** exactly one current Feature and a fixed Context / Rules Snapshot.

1. Read the lightweight index and select either the user-specified Feature or a dependency-eligible `pending` Feature. `python -B tools/checks/check-feature-list.py --eligible` provides the validated DAG selection; ID is only a stable tie-breaker and dependencies may have larger IDs. Resume an existing `in_progress` Feature instead of starting another.
2. Run `git status --porcelain`. A new Feature requires no output. For a resumed `in_progress` Feature, reconcile every reported path with its durable Feature/Progress record and stop if any path is unrelated or ownership is ambiguous.
3. Run `python -B tools/checks/check-project-environment.py --require-ready`. If it fails, stop and route the missing setup through an explicit maintenance/project-setup change; never guess a command or continue past a blocked Gate.
4. Load that Feature detail, its Product source, relevant dependency details, current Progress, complete Coding Rules, test catalog, and the principal implementation files/directories needed to bound the change. Follow Progress history links only when relevant. Read the optional Architecture Overview/subsystem map when the change touches its responsibility or dependency boundaries.
5. Build a concise snapshot that lists:
   - the current Feature record path;
   - the principal Product and implementation paths read;
   - files expected to be created, modified, or deleted;
   - applicable `agent-rules/**` modules;
   - three to six task-relevant rules, with source paths, that materially constrain the implementation;
   - the principal planned validation.
6. Report Feature ID/title, status, dependencies, source, stable acceptance-criterion IDs/text, `affected_components`, engineering mode if present, and the snapshot. Reference rules; do not reproduce entire rule documents.
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

### 1A. Derive the Required Test Set

Using `affected_components`, criterion verification, and `docs/test-catalog.json`, compute:

```text
Required Test Set =
    current Feature automated acceptance tests
  + current Feature regression tests
  + unit_test_paths for affected_components
  + active regression tests intersecting affected_components
  + active invariant tests intersecting affected_components
```

Apply the existing-suite contract in [08-testing-strategy.md](./08-testing-strategy.md). Empty `unit_test_paths` contributes no unit selector; each registered suite for an affected component is required. Missing registered paths or zero-test discovery are errors and must not be silently filtered out. Removing a registration requires an explicit reason and user approval.

Also identify:

- related older Feature acceptance tests whose public API/behavior is materially affected;
- whether a full suite is required by `full_suite_on_change`, broad infrastructure/toolchain impact, uncertain impact bounds, or explicit user direction;
- new acceptance/regression test IDs that should be created under TDD;
- new unit suites to create after approval, without registering future paths;
- criteria that remain manual-only and why automation is not appropriate.

Do not remove a deterministic Required Test Set item through a runner exclusion, even with an approval note. An approved retirement or catalog correction must change the underlying traceable contract before recomputing the selection.

### 1B. Resource/dependency preflight

1. Identify implementation files/resources likely required, external dependencies, placeholders, and out-of-scope impact.
2. Register `_placeholder_` resources in Feature notes with replacement guidance when approved.
3. Explain any scope expansion before coding.

### 1C. Present approval packet

Present one concise packet containing:

- Feature scope and affected components;
- the Stage 0 Context / Rules Snapshot: records and implementation paths read, applicable rule modules, three to six key constraints, and planned create/modify/delete paths;
- Existing Safety Net to run before changes;
- new TDD acceptance/regression tests and unit suites to create;
- acceptance mode, its reason, and corresponding verification items;
- full-suite decision and reason.

Ask for explicit approval to begin this Feature.

No approval → no implementation and no durable test-plan mutation.

## Stage 2 · mark `in_progress` and persist verification plan

After approval:

1. set the selected index entry to `in_progress`, `completed_at: null`;
2. update `docs/progress.md` with current Feature/batch and Stage, blockers, pending decisions, next legal action, and links to the approved plan/evidence; keep history bodies in `docs/progress/`;
3. persist approved `verification.acceptance_mode`, criterion verification mappings, Bug regression IDs, and `verification.test_impact` in the Feature detail. Store additional related tests as `additional_tests: [{"id": "<catalog ID>", "reason": "<approved reason>"}]` and full-suite obligations as `full_suite_reasons: ["<approved reason>"]`. The runner always reads this recorded scope; changing invocation arguments must not shrink approved coverage. Removing an obligation requires an explicit approved plan revision;
4. register not-yet-created durable acceptance/regression tests in `docs/test-catalog.json` with `status: planned`;
5. add newly approved component entries to the catalog when required, with `unit_test_paths: []` if no unit suite exists;
6. initialize the current Feature's structured completion evidence:

   ```powershell
   python -B .agents/skills/execute-next-feature/scripts/write-gate-evidence.py initialize --feature F0XX
   ```

7. run:

   ```powershell
   python -B tools/checks/check-feature-list.py --strict
   ```

## Stage 3 · baseline, TDD, and implementation

Implement only the current Feature and its approved dependencies/repairs.

### 3A. Existing Safety Net baseline

Before writing behavior-changing implementation code:

1. run the Existing Safety Net from Stage 1, excluding new `planned` tests that do not exist yet;
2. directly run script parsing/lint if useful for the pre-change baseline;
3. if an existing required test already fails, preserve the original error and report it before implementation. Do not attribute it to the current Feature or silently expand scope.

### 3B. RED

For each machine-verifiable new acceptance criterion or Bug regression:

1. create the test using its approved logical ID;
2. update the matching catalog entry with path/case and `status: active` once the test exists;
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

Do not create an implementation commit before the Feature has passed its
applicable Stage 4-7 Gates. Preserve task ownership throughout the working
tree so Stage 7 can stage this Feature without absorbing unrelated changes.

At implementation completion, map changed behavior to every criterion ID.

## Stage 4 · automated verification and human checklist

**Output:** machine evidence plus concrete human-verification instructions.

Read project commands from `docs/methodology-config.json`:

- confirmed Python/Godot executable paths for direct checks described in `gdscript-lint.md`;
- `test_cmd`: project test runner entrypoint or documented targeted command;
- `full_test_cmd`: optional broader/full suite.

Procedure:

1. Run the configured test runner with `--feature F0XX --scope auto`. It reads the current Feature/Catalog and prints required/affected selection, reasons, deduplication and full-suite escalation. No independent plan file is written. Missing or zero-discovery selectors fail.
2. Inspect the actual selected scope and test results. If full is required, run one real full suite whose executed set covers Required and affected; do not repeat equivalent runs merely to fill different Gate fields. Otherwise run the affected union, including every Required item.
3. Directly run Godot script parsing for changed scripts and necessary dependants,
   then the bundled lint CLI as described in `gdscript-lint.md`. Inspect actual
   output and exit codes. Do not add a Python wrapper, static manifest or import step.
4. For a Bug, ensure each approved `F0XX-RTyy` test is active and passes, or the approved `manual_regression` is concrete and repeatable.
5. If Stage 1 required full, the Feature’s recorded Test Impact must require it and the actual full result must pass. An unavailable or failed required full suite blocks completion; a reason or transcript cannot turn it into PASS.
6. Record the actual Required Test Set, affected-test, and full-suite result, including failures:

   ```powershell
   python -B .agents/skills/execute-next-feature/scripts/write-gate-evidence.py record-tests --feature F0XX --run <run-manifest.json>
   ```

   `record-tests` validates the supplied test manifests and stores their references.
   It neither runs nor validates static checks. The Agent separately assesses direct
   parsing/lint output; a passing evidence helper cannot override a static failure.
   Failed evidence imports clear old test references and preserve original reports.

7. Any failing machine check returns to Stage 3. Do not enter Stage 5.
8. Follow the approved acceptance mode. For `manual`, prepare the corresponding
   human checks. For `automated`, report actual automated coverage of every AC.

Before following the approved acceptance route, include this exact human-readable evidence summary once in the Stage 4 conversation update:

```text
Test verification: pass (feature: F0XX, required: <N>, failed: 0, full_suite: <pass|not_required>)
```

For `manual`, wait for Stage 5. For `automated`, omit Stage 5 and go to Stage 5.5
for a Bug, otherwise Stage 6. Report manual acceptance as not required; do not
record an accepted human decision that never occurred.

## Stage 5 · explicit human acceptance (manual mode only)

Wait for the user to report the checklist result.

- Explicit acceptance of all material criteria → record it with `python -B .agents/skills/execute-next-feature/scripts/write-gate-evidence.py record-acceptance --feature F0XX --status accepted`, then continue.
- Any failure → record `--status rejected`, update Progress, return to Stage 3, repair, then repeat Stage 4 and Stage 5.
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

Evaluate whether the Guardrail is reusable enough for Coding Rules according to [04-coding-rules-4-layers.md](./04-coding-rules-4-layers.md). If so, show the exact proposed prescriptive rule and destination, then wait for explicit user approval. Never promote automatically.

If the Guardrail becomes a machine-verifiable cross-Feature invariant, propose an `INV-<DOMAIN>-NN` test and catalog entry. Creating that invariant still requires the user's approval when it expands the accepted Feature scope.

If a Coding Rule is approved, Stage 8 must stop and require `sync-feature-list` before another Feature starts.

## Stage 6 · independent fresh-context code-smell scan

**Output:** independent structured review, repairs, verification reruns, and exact completion evidence.

The reviewer must be a fresh-context subagent/session or equivalent independent context. It reads the complete Coding Rules and changed files, performs no writes, and returns structured `must_fix`, `suggest`, and `acceptable` findings.

At minimum inspect: oversized files, duplicated domain knowledge, misplaced type dispatch, magic values, duplicated constants/enums, God Objects, stack-specific anti-patterns, presentation/domain coupling, comments that restate code, and defects that required repeated repair attempts.

Processing rules:

1. Every `must_fix` is repaired before completion.
2. After each repair batch, read the current Feature/Catalog selection and follow Stage 4: run one full suite when required, otherwise the affected union including Required, plus direct script parsing and lint. A full run covering those subsets on the same content snapshot needs no separate Required/affected run.
3. If a smell repair may change behavior already accepted by the user, return to Stage 3 and repeat Stages 4–6, including human acceptance.
4. Re-scan until `must_fix` is empty.
5. Append each `suggest` to Feature notes with `TODO`; report `acceptable` without turning it into durable debt automatically.
6. Before completion, verify the final repair snapshot has the actual successful full result required by the approved Feature verification or project Coding Rules. Reuse the covering run from step 2 when its snapshot still matches; later semantic changes require a new run.
7. After any code/test change, record the rerun Stage 4 results again. Record the final review with `python -B .agents/skills/execute-next-feature/scripts/write-gate-evidence.py record-smell --feature F0XX --must-fix 0 --suggest <N> --acceptable <M>`.

Do not continue while any required test/static/full-suite check is failing.

Only then include this exact human-readable review summary once in the Stage 6 conversation update, before Stage 7 operations:

```text
Code smell scan: pass (feature: F0XX, must_fix: 0, suggest: <N>, acceptable: <M>)
```

## Stage 7 · mark complete

**Entry:** verified Stage 4 run evidence for the current semantic content fingerprint, explicit Stage 5 human acceptance when the approved mode is `manual`, and structured Stage 6 `must_fix: 0` evidence for the same snapshot all exist. Git revision is provenance; content-identical status/time/history commits do not grant new acceptance or require a fictitious rerun. The Agent must also confirm direct parsing/lint passed for the final changes; the evidence helper does not assess static checks.

1. Run:

   ```powershell
   python -B .agents/skills/execute-next-feature/scripts/write-gate-evidence.py validate --feature F0XX
   python -B tools/checks/check-feature-list.py --strict --completion-feature F0XX
   ```

2. Record the verified result: transition the Feature to `done` and set
   `completed_at` to the current ISO 8601 timestamp. The status field records
   completion; it does not prove tests, review or human acceptance.
3. Run `python -B tools/checks/check-feature-list.py --strict` on the final ledger.
   These are explicit task commands. There is no tool-event interceptor or
   additional terminal state machine. If implementation or contract changes
   invalidate the evidence, finish the relevant verification before delivery.
4. Persist durable implementation decisions, placeholder guidance, omitted edges, Bug learning, and Stage 6 TODOs.
5. Archive current execution history once under `docs/progress/<Feature-or-approved-batch>.md`; leave only current state and its history link in `docs/progress.md`. Feature notes own durable decisions/TODOs, not a duplicate of the archive. Pure Markdown archival is excluded from test fingerprints.
6. Inspect `git status --short` and classify every path as owned by this Feature. Stop if any path is unrelated or ambiguous.
7. Stage only this Feature's explicit paths or inspected hunks. Do not use `git add .`, `git add -A`, or broad globs.
8. Run `git diff --cached --check`, inspect `git diff --cached --stat`, and inspect the complete `git diff --cached`. Remove any unrelated staged content.
9. Run every validation applicable to the final staged change. Existing Stage 4/6 evidence remains valid only under the structured snapshot rules; rerun any invalidated Gate rather than relying on prose.
10. Unless the user explicitly requested no commit, create one local commit without another confirmation. Use `<type>(<scope>): <中文行为摘要>`; use the Feature ID as scope and include `Work item: docs/features/F0XX.json` in the body. A non-trivial body summarizes the change, reason, meaningful implementation decisions, and principal validation.
11. Run `git status --short` after the commit and confirm no task change was omitted and no unexpected file was generated. Correct a committed mistake with a new commit, never `--amend`.

Do not push, tag, amend, rebase, reset, modify remotes, use `--no-verify`, merge,
create, switch, or delete branches automatically. Feature execution and eligible
local commits remain on the current branch, including `main` or `master`.

## Stage 8 · handoff and stop

1. If Stage 5.5 changed Coding Rules, report that source synchronization is required. Ask for explicit authorization to run `sync-feature-list`, then stop.
2. Otherwise find the first eligible `pending` Feature whose dependencies are `done`.
3. Report the completed Feature, relevant implementation/test changes, verification evidence, local commit hash (or the explicit no-commit exception), post-commit worktree status, placeholder count, TODOs, and next eligible Feature.
4. Add one sentence or a few concise learning entries in this existing Stage, using `templates/stage8-learning.md.tmpl`. With no new generalizable learning, explicitly state “No new generalizable learning” (Chinese: “无新增可泛化经验”). Otherwise record trigger, root cause, existing-rule coverage, generalizability and recommended destination: Agent Rule / Methodology / Tooling / Automated Check / Regression. Link an existing Bug-learning note instead of copying it. Do not invent a new rule for every incident. A newly discovered tooling change becomes a separate maintenance task requiring approval; do not expand the completed Feature silently.
5. Stop. The user decides whether to continue, review, synchronize, or pause.

## Exception handling

| Condition | Required action |
| --- | --- |
| Acceptance criteria ambiguous/contradictory | Route to the owning Product/Feature revision workflow; do not reinterpret silently. |
| Completed dependency materially incomplete | Report gap and obtain user direction. |
| Implementation needs out-of-scope files/behavior | Explain expansion and obtain approval or create another Feature. |
| Existing Safety Net fails before implementation | Preserve original error and obtain direction; do not silently absorb unrelated repair. |
| Test catalog is inconsistent | Stop and repair traceability before using it to choose tests. |
| Test/command/file/Git operation fails | Preserve original error; use only safe workflow-defined recovery. |
| Context near exhaustion | Persist current state in Progress before session handoff. |
| Unrelated work arrives mid-Feature | Classify it separately; do not silently expand current scope. |
