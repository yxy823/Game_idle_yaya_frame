---
name: execute-next-feature
description: >-
  Execute exactly one approved Feature through test impact review, TDD/verification, applicable human acceptance, independent requirements and code-quality review, and completion gating. English triggers: execute next feature, implement F0XX, continue feature. 中文触发：执行下一个 Feature、实现 F0XX、继续当前 Feature。
---

# Execute next Feature

## Authority

Follow `methodology/03-execute-loop.md`, `methodology/08-testing-strategy.md`, `methodology/02-feature-list-schema.md`, active Coding Rules, and `docs/methodology-config.json`.

Human control is mandatory:

- Stage 1 explicit approval before implementation;
- Stage 5 explicit human acceptance when the approved acceptance mode is manual;
- explicit approval before promoting Bug guardrails to Coding Rules;
- Stage 8 stop so the user decides the next action.

Automated tests never imply human acceptance. Features approved for automated acceptance omit Stage 5; they do not record fictitious human acceptance.

## Progress communication

Report meaningful progress, actual failures, decisions needed and final handoff in the
conversation language. Adjacent routine steps may share an update; do not emit a
message for every Stage or tool action. Keep the approval packet, applicable human
checklist and final result reviewable. Use natural wording, not fixed evidence strings.
Updates do not replace actual test results or grant approval.

When this Stage actually executes static/lint, include the canonical compact
static table: scope/file count, Critical, Warning, Info, process result and
report location. Read the structured result; unavailable counts are not zero.
Use the runner output and original report. Do not rerun full lint at every Stage.
If reusing a run, identify its run and same content snapshot; prose does not replace Gate evidence.

## Stage 0 — select and load

For Product-derived work, apply **Product-by-Product planning** in
`methodology/02-feature-list-schema.md`: stay with the current Product until
its required Features are complete. The eligible command checks dependencies,
not Product sequencing. Preserve any pre-existing later plans; engineering
repairs and maintenance retain their own authorized routing.

1. Read `docs/feature-list.json`; resume the authorized current Feature/batch, otherwise use the requested Feature or a DAG-eligible `pending` Feature. `tools/checks/check-feature-list.py --eligible` derives eligibility; larger IDs may be prerequisites and IDs only break ties. Do not invent batch authorization.
2. Run `git status --porcelain` under `agent-rules/00-core/git-worktree-and-commits.md`. Execute on the current branch, including `main` or `master`; do not change branches. A new Feature requires a clean worktree. A resumed Feature may continue only when every dirty path is demonstrably owned by that Feature; stop on unrelated or ambiguous changes.
3. Read the confirmed environment configuration. Incomplete Bootstrap blocks coding; never guess commands. Run `python -B tools/checks/check-project-environment.py --require-ready` during initialization, after tool/configuration changes, or when diagnosing an actual invocation failure. Ordinary Features reuse confirmed paths without repeating version discovery.
4. Load detail, Product source, relevant definitions in `docs/CONTEXT.md` when present, dependency details, current Progress, complete Coding Rules, `docs/methodology-config.json`, `docs/test-registry.json` when testing is enabled, and the principal implementation files/directories needed to bound the change. Follow only relevant Progress history links. Read applicable optional architecture maps and ADRs under `methodology/10-architecture-overview.md`, including relevant ADRs when no map exists. Complete Coding Rules means `docs/coding_rules.md`, `agent-rules/00-core/README.md`, and every routed installed module applicable to the Feature.
   Before choosing an approach or searching external material, consult
   `docs/knowledge/README.md` and the relevant topic indexes and entries.
   Check their conditions against this Feature; reuse reading on continuation
   unless scope or evidence changed. Empty topics are normal.
5. Present a concise Context / Rules Snapshot containing the Feature record path; principal Product and implementation paths read; useful knowledge references when any; expected create/modify/delete paths; applicable `agent-rules/**` modules; three to six task-relevant rules with source paths; and principal planned validation. Reference sources instead of copying whole documents.
6. Report ID/title/status/dependencies/source, `affected_components`, stable criterion IDs/text, engineering mode, and the snapshot.
7. Stop on contradictory Product intent, invalid ledger/registry data, unresolved dependencies, or an unbounded planned file surface.

## Stage 1 — Test Impact Review + preflight + approval

First decide acceptance from the requirement itself. Visual presentation, animation feel,
audio/sound/music, game feel, or other human perception/judgment requires
`verification.acceptance_mode: "manual"`. Otherwise, when all AC can be verified
automatically, propose `"automated"`. Explain the choice in the Stage 1 packet.
Then populate the corresponding automated mappings and manual checks/regressions.
Empty check arrays are an output of planning, never the reason to choose a mode.
A draft may use null until Stage 1 decides; do not infer the choice from existing test results.

Derive the deterministic Required Test Set:

```text
current Feature automated acceptance tests
+ current Feature regression tests
+ component unit_test_paths
+ active regression tests intersecting affected_components
+ active invariant tests intersecting affected_components
```

Apply the existing-suite contract in `methodology/08-testing-strategy.md`: `unit_test_paths: []` contributes no unit selector; every registered suite for an affected component must be included. Missing registered paths or zero-test discovery are errors, not exclusions or PASS. Any removal of a registration requires an explicit reason and user approval.

The affected union also includes active acceptance tests intersecting affected components. Add other related tests only with concrete reasons. A runner exclusion cannot remove a deterministic requirement; approved retirement or registry correction changes the underlying traceable contract before recomputing the selection. Include any proposed new unit suites in the Stage 1 plan, without registering future paths.

For changed or removed contracts, read the cleanup actions in Feature notes and
the affected test code under **Requirement changes and stale tests** in
`methodology/08-testing-strategy.md`. Include necessary test-code and current-reference
cleanup in this same plan. Existing approval for that exact scope remains valid.

Determine whether full suite is required when:

- an affected registry component has `full_suite_on_change: true`;
- infrastructure or toolchain changes have actual project-wide impact; task classification alone is insufficient;
- dependency upgrade has broad impact;
- impact cannot be bounded reliably;
- user requires it.

For each criterion propose:

- automated test logical ID(s), when deterministic automation is valuable;
- concrete manual check(s), when human observation remains necessary.

For Bug Features propose at least one `F0XX-RTyy` regression test unless automation is genuinely impractical; otherwise state an explicit repeatable manual regression and the concrete reason.

Present one approval packet containing Feature scope, affected components, the Context / Rules Snapshot, Existing Safety Net, new TDD tests, acceptance mode with its reason, corresponding checks, and full-suite decision. The packet must make clear what was read, which rules apply, what will change, and how it will be validated. Wait for explicit approval. Do not write implementation or durable test-plan data before approval.

## Stage 2 — mark in progress and persist approved verification plan

After approval:

1. set status to `in_progress`, `completed_at: null`;
2. update current Progress with Stage/state, blockers, pending decisions, next legal action and links to plans/evidence; history bodies remain under `docs/progress/`;
3. persist `verification.acceptance_mode`, criterion `verification` mappings, Feature `verification.regression_tests/manual_regression`, and `verification.test_impact` with approved `additional_tests: [{id, reason}]` and `full_suite_reasons: [reason]`. The runner reads these stored obligations directly; reducing them requires explicit plan revision approval;
4. add new durable acceptance/regression registry entries with `status: planned`;
5. add approved component registry entries when missing, using `unit_test_paths: []` if no unit suite exists;
6. initialize `docs/feature-completion-evidence.json` with `python -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py initialize --feature F0XX`;
7. run `python -B tools/checks/check-feature-list.py`.

## Stage 3 — baseline + TDD + implementation

### Existing Safety Net baseline

Run the Stage 1 Existing Safety Net before behavior-changing implementation, excluding new planned tests that do not exist. Preserve and report any pre-existing failure. Do not silently repair unrelated baseline failures.

### RED

For every new machine-verifiable acceptance/regression test:

1. create the test with its approved logical ID;
2. update registry `path`, optional `case`, and `status: active`;
3. run the narrowest supported selector;
4. verify failure is caused by the intended missing/broken behavior, not bad setup/syntax/environment.

If meaningful RED cannot be demonstrated, explain why; never fabricate TDD evidence.

When creating a Stage 1-approved unit suite, register its repository-relative file or directory path in the component's `unit_test_paths` only after it exists, and include it in the Required Test Set. Confirm discovery and execution through the configured runner.

### GREEN

Implement the smallest coherent change until the new test passes. Refactor locally while preserving behavior. Repeat by criterion. Do not expand Feature scope without user approval.

Perform the approved obsolete-test and reference cleanup with the behavior change.
Preserve still-valid cases and historical records; Registry retirement alone leaves
executable methods in place. Apply the cleanup contract in `methodology/08-testing-strategy.md`.

## Stage 4 — automated verification + applicable human checklist

Read the Python/Godot paths, `test_cmd` from `docs/methodology-config.json` or the repository's explicit authoritative equivalent. Never invent runner syntax.

1. Read the current Feature/Test Registry obligations. When any Required/affected test or full-suite obligation exists, run the configured test runner with `--feature F0XX --scope auto`. It selects and deduplicates tests and prints selection reasons; no separate plan file is written. Only a valid `manual` plan with empty Required and affected sets and no full-suite obligation may omit this run and `record-tests`, leaving `test_runs: []`. Report automated verification as `not_required`, never as an empty PASS; manual acceptance, review and applicable static checks remain required.
2. Inspect the selection and actual results. A required full run covers Required/affected subsets once for the same content snapshot; otherwise execute the affected union, which includes Required. Never repeat equivalent runs only to fill separate Gate fields.
3. Directly run Godot script parsing for changed scripts and necessary dependants, and the bundled lint CLI, following `methodology/gdscript-lint.md`. Read their actual exit codes and output. Required failures block completion. Do not create a wrapper, static manifest, or scripted import step.
4. For Bug Features verify every approved regression ID is active/passing, or use the explicitly approved manual regression gap.
5. A required full suite must actually pass; failure, unavailable execution, missed cases or stale evidence block completion.
6. Import actual evidence with `python -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py record-tests --feature F0XX --run <result.json>`. Counts are computed from the current selection, result.json and original reports; caller-supplied counts and transcript prose cannot authorize PASS.
7. Any failure returns to Stage 3.
8. For `acceptance_mode: manual`, produce reproducible instructions from the approved human checks: entry scene, starting state, actual input, expected feedback and relevant reset steps. Follow the conditional timing/seed/media guidance in `methodology/03-execute-loop.md` Stage 4; reuse `manual_checks` and Feature notes. For `automated`, report the actual automated AC coverage.

Report the actual test scope, failures and result path in ordinary language.

For `manual`, wait for Stage 5. For `automated`, omit Stage 5 and proceed to Stage 5.5 for a Bug or Stage 6 otherwise; report that manual acceptance was not required, not that the user accepted.

## Stage 5 — explicit human acceptance (manual mode only)

Do not infer success from tests, screenshots, logs, silence, or partial user comments.

- explicit acceptance → record `python -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py record-acceptance --feature F0XX --status accepted`; Bug goes to Stage 5.5, other Features to Stage 6;
- any failure → record `--status rejected`, update Progress, and return to Stage 3;
- ambiguous response → ask whether any material criterion remains unmet.

## Stage 5.5 — Bug learning

Append:

```text
BUG learning
Root cause: <causal implementation defect>
Trigger: <minimum trigger/precondition>
Regression coverage: <F0XX-RTyy IDs, or approved manual regression>
Guardrail: <general prevention principle>
```

If Guardrail deserves Coding Rules, show exact proposed rule + destination and wait for explicit approval. If it can be machine-enforced as a cross-Feature invariant, propose `INV-<DOMAIN>-NN`; do not create it as scope expansion without approval.

## Stage 6 — independent requirements and code-quality review

Use one fresh context/subagent equivalent for the review specified in
`methodology/03-execute-loop.md` Stage 6. It reads the approved Feature scope
and AC, relevant Product, existing CONTEXT definitions and accepted architecture decisions, relevant project knowledge, full Coding Rules, final diff and changed
files, original verification results and applicable human feedback. It performs
no writes and checks requirements first, then code quality; an implementer's
summary alone proves neither.

Return a concise conclusion for each aspect and one set of `must_fix`,
`suggest`, `acceptable` findings with criterion/rule and file/evidence
references. Missing requirements, unintended scope and unsupported verification
claims belong in this same review. For contract changes, check the final diff,
affected current references and actual discovery/results to confirm required old
assertions were removed or replaced and valid coverage remains. Unfinished
required cleanup is a `must_fix`, not a completed retirement. Reuse Feature notes and `record-smell`;
do not add another review Stage or evidence format. Reuse current successful
runs unless a concrete unanswered risk or a repair requires verification.

Every `must_fix` must be repaired. After each repair batch confirm the current Feature verification mappings and repeat the applicable Stage 4 checks, including its no-automated-obligations decision. A successful full run covering Required/affected on the same content snapshot satisfies those subsets without duplicate runs. Before completion, verify all required results cover the final repair snapshot and import them again after code/test changes. If repair may alter behavior already human-accepted, return through Stages 3–5.

Append `suggest` items to Feature notes as TODOs. Re-review until `must_fix` is zero,
record the result with `python -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py record-smell`,
and summarize material findings and remaining work in ordinary language.

## Stage 7 — completion

Entry requires verified runs for all current automated obligations (or the Stage 4 `not_required` case) and Stage 6 review evidence matching the current semantic content fingerprint, plus explicit Stage 5 human acceptance when `acceptance_mode` is `manual`. An unresolved failed/unfinished final run on the same snapshot still blocks completion, even with no current automated obligations. Applicable direct script parsing and lint must also have passed; the evidence helper does not assess these checks. Git revision is provenance; pure workflow status/time and Progress archive edits do not require another identical run. A summary alone does not prove execution.

Run:

```powershell
python -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py validate --feature F0XX
python -B tools/checks/check-feature-list.py --completion-feature F0XX
```

Then set status `done` and `completed_at` to current ISO 8601 timestamp. Validate the final ledger after the status update. Archive the current history once under `docs/progress/<Feature-or-approved-batch>.md`; keep only an index link and current handoff in Progress. Feature notes own local decisions and TODOs and link important technical ADRs without repeating their rationale or execution history. Follow `methodology/09-artifact-lifecycle.md`.

Before the local commit, finalize useful successful approaches, debugging methods
and failure lessons in the matching `docs/knowledge/` topic under its README.
Update existing entries and the nearest index; link original Feature/evidence
instead of copying history. No new learning requires no entry. Review new prose
and links; keep runnable helpers and governing contracts in their normal locations.
Pure knowledge Markdown does not invalidate business-test evidence, while changes
to source, tests or contracts still require their applicable verification.

Before the local commit:

1. inspect `git status --short` and stop if any path is unrelated or ownership is ambiguous;
2. stage only this Feature's explicit paths or inspected hunks; never use `git add .`, `git add -A`, or broad globs;
3. run `git diff --cached --check`, inspect `git diff --cached --stat`, and inspect the complete `git diff --cached`;
4. run every validation applicable to the final staged change and rerun any Gate invalidated by later code/test changes;
5. unless the user explicitly requested no commit, create one local commit without asking again, using `<type>(F0XX): <中文行为摘要>` and a body containing `Work item: docs/features/F0XX.json` plus the meaningful change/reason/validation summary;
6. run `git status --short` after commit. Use a new correction commit for any committed defect; never amend.

Create the eligible local commit on the current branch, including `main` or `master`, only after the Gates above pass. Do not automatically push, tag, amend, rebase, reset, modify remotes, use `--no-verify`, or create, switch, merge, or delete branches.

## Stage 8 — handoff and stop

If Bug learning changed Coding Rules, request explicit authorization to run `sync-feature-list` and stop. Otherwise report completion, verification evidence, the local commit hash (or explicit no-commit exception), post-commit status, TODOs/placeholders, and next work within the current Product.

When test/reference cleanup was required, report what was actually handled and
any remaining work using existing notes/Progress; do not claim completion from
Registry status alone.

Check current Product scope against its Feature sources/statuses. If required
work remains, identify the next eligible Feature or the actual blocker. Only
after the current Product is complete, recommend revisiting and decomposing the
next Product with `generate-feature-list` (or reusing its existing plan). Do not
equate an empty eligible list with Product completion, and do not start the next
Product's planning automatically.

Within this same Stage add one sentence or a few entries of learning feedback,
following `methodology/templates/stage8-learning.md.tmpl`. With none, explicitly
say “No new reusable learning” (Chinese: “无新增可复用经验”). Otherwise give
context, successful approach or root cause, existing coverage, applicability and
actual or proposed destination: Knowledge / Agent Rule / Methodology / Tooling /
Automated Check / Regression. Link notes finalized before the commit, without
copying them or starting new documentation writes at handoff. Project-specific
reusable methods count. Do not automatically create rules; newly identified
out-of-scope changes remain separate authorized work. Stop for the user's decision.
