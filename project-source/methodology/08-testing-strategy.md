# 08 · Test traceability and impact-analysis strategy

> Canonical testing specification for Yaya Loop on Windows 11 / Godot 4.7 / GDScript / gdunit4. 

## Goals

The testing layer must answer four questions deterministically as the project grows:

1. Which tests verify the current Feature's acceptance criteria?
2. Which existing unit suites protect the components touched by the Feature?
3. Which historical Bug regression tests must be rerun?
4. Which cross-Feature invariants and full-suite checks are required?

The agent must derive these answers from durable project data, not from memory or intuition.

## Test taxonomy

Physical organization is based on what a test protects:

```text
tests/
├── unit/        # local code/component contracts
├── features/    # Product Feature / acceptance behavior
└── invariants/  # cross-Feature architecture/domain rules
```

`regression` is a test origin/type, not a fourth directory. A regression test lives under the layer it protects, usually `features/F0XX/` or occasionally `unit/<component>/`.

Logical IDs identify why a durable test exists:

- `F012-AC01` or `F012-AC01-02`: automated acceptance verification for Feature F012 criterion AC01.
- `F052-RT01`: regression test created by Bug-repair Feature F052.
- `INV-LIFECYCLE-01`: cross-Feature invariant test.

Ordinary low-level unit tests do not require global IDs unless they are also durable acceptance/regression/invariant evidence.

## Feature traceability

New canonical Feature details use stable acceptance-criterion IDs:

```json
{
  "id": "F012",
  "affected_components": ["save", "scene_lifecycle"],
  "acceptance_criteria": [
    {
      "id": "AC01",
      "text": "The player can save and reload the current progress.",
      "verification": {
        "automated_tests": ["F012-AC01"],
        "manual_checks": ["Save in the running game, reload, and confirm the visible state."]
      }
    }
  ],
  "verification": {
    "acceptance_mode": "manual",
    "regression_tests": [],
    "manual_regression": null,
    "test_impact": {"additional_tests": [], "full_suite_reasons": []}
  }
}
```

`ACxx` IDs are stable historical identifiers. Do not renumber accepted criteria merely because Product requirements later evolve. A later change creates a new Feature rather than rewriting completed Feature history.

`affected_components` is a small machine-readable set of stable domain/component IDs such as `inventory`, `save`, `combat`, or `scene_lifecycle`. Use semantic components, not individual file paths.

## `docs/test-catalog.json`

The test catalog is the machine-readable bridge from changed components to existing safety-net tests.

```json
{
  "meta": {
    "schema_version": 2
  },
  "components": [
    {
      "id": "inventory",
      "unit_test_paths": ["tests/unit/inventory"],
      "full_suite_on_change": false
    },
    {
      "id": "scene_lifecycle",
      "unit_test_paths": ["tests/unit/scene_lifecycle"],
      "full_suite_on_change": true
    }
  ],
  "tests": [
    {
      "id": "F052-RT01",
      "kind": "regression",
      "source_feature": "F052",
      "criterion_id": null,
      "components": ["inventory", "scene_lifecycle"],
      "path": "tests/features/F052/scene_transition_regression_test.gd",
      "case": "test_f052_rt01_reopen_inventory_after_scene_change",
      "status": "active"
    },
    {
      "id": "INV-LIFECYCLE-01",
      "kind": "invariant",
      "source_feature": null,
      "criterion_id": null,
      "components": ["scene_lifecycle"],
      "path": "tests/invariants/lifecycle/stale_node_reference_test.gd",
      "case": "test_inv_lifecycle_01_stale_node_reference_is_not_reused",
      "status": "active"
    }
  ]
}
```

### Catalog rules

- Component IDs are stable `lower_snake_case` identifiers.
- `unit_test_paths` contain repository-relative paths to existing unit suite files or directories protecting that component and required whenever it is affected. The non-empty examples above assume those suites already exist.
- A component without unit suites uses `unit_test_paths: []`; never prefill future directories. Propose new unit suites in Stage 1, then register their paths after the approved Stage 3 creation and include them in the Required Test Set.
- A missing or deleted registered suite path is a catalog error, not an empty safety net. Do not silently filter it out; removing a registration requires an explicit reason and user approval. Merge/strict validation checks path existence; the configured runner must establish actual discovery and execution.
- `full_suite_on_change: true` means any Feature touching that component requires the configured full suite before completion.
- Test `kind` is exactly `acceptance`, `regression`, or `invariant`.
- `source_feature` is required for acceptance/regression tests and `null` for invariant tests.
- `criterion_id` is required only for acceptance tests.
- `status` is `planned`, `active`, or `retired`.
- `planned` permits a `tests` entry's TDD registration before a physical test exists; it does not apply to `unit_test_paths`. The Feature currently being completed must reference only `active`, resolvable automated tests. Historical completed mappings may point to traceably retired tests under the schema's replacement contract.
- A retired test preserves its historical ID and records reason, Product change source/revision, and replacement Feature/tests. It does not enter the active safety net. Strict validation checks the migration chain; the completion-specific check still requires active direct verification for the current Feature.
- Moving a test file updates `path`; the logical test ID remains stable.

## Test Impact Review

Before implementation, `execute-next-feature` must produce a Test Impact Review. The Required Test Set is derived as follows:

```text
Required Test Set =
    current Feature acceptance tests
  + current Feature regression tests
  + unit_test_paths for affected_components
  + active regression tests whose components intersect affected_components
  + active invariant tests whose components intersect affected_components
  + approved additional tests in verification.test_impact
```

An empty `unit_test_paths` array contributes no unit selector and does not trigger an empty targeted run. Every registered suite for an affected component must enter the Required Test Set; a missing path or a targeted run discovering zero tests is an error, not PASS.

The affected set contains Required plus active acceptance tests intersecting affected components. The agent may add related tests from other components when dependency/API analysis shows material impact, recording the exact reason. It may not remove any deterministic requirement. Approved retirement changes the underlying Product/Catalog contract instead of adding a runner exclusion.

A full suite is required when any of these is true:

- an affected catalog component has `full_suite_on_change: true`;
- the change modifies shared project-wide infrastructure or test infrastructure;
- a dependency/toolchain upgrade can affect broad behavior;
- impact analysis cannot bound the affected components reliably;
- the user explicitly requires it.

For other local Features, targeted verification is sufficient before applicable acceptance unless project Coding Rules state otherwise.

## Runtime Test Impact selection

The runner reads the current Feature and Test Catalog through
`tools/lib/test_selection.py`. There is no separate plan command, plan file or plan hash.

After Stage 1 approval, Stage 2 stores extra tests and full-suite obligations in
the Feature's `verification.test_impact`: `additional_tests: [{id, reason}]`
and `full_suite_reasons: [reason]`. The runner always includes these obligations.
Agent judgment supplies impact analysis and any needed additions; scripts only
translate the recorded mappings into executable selections.

```text
python -B tools/testing/run-gdunit-tests.py --godot-binary <confirmed-executable> --feature F0XX --scope auto
```

Default `--scope auto` executes affected tests including Required, escalating to
one full run when required. Explicit `required`, `affected` and `full` scopes
support iteration. Output includes selection reasons, deduplicated selectors and
full-suite reasons. `--phase baseline` omits planned tests that do not yet exist;
baseline runs cannot authorize completion. Final selection rejects unresolved or
retired direct mappings and missing paths. `--target` remains a focused/TDD
diagnostic route; it does not produce completion evidence. Use the configured
`test_cmd` with these arguments; do not maintain another affected-command field.

The adapter executes deduplicated suite/directory selectors supported by the configured runner; case-level obligations are checked against actual JUnit cases. Selecting a suite may run extra cases. Every selected path must discover and execute tests; missing cases/suites, zero discovery, skipped required cases, invalid paths, runtime diagnostics, timeout and runner failure fail closed. `tools/testing/gdunit_evidence_runner.gd` records gdUnit's actual expanded discovery before execution, including every parameterized case and its source method. This complete identity set must exactly equal the JUnit testcase set. GdUnit source declarations supplement runtime discovery to detect omitted suites; declarations alone never prove execution.

The supplemental declaration inventory resolves `GdUnitTestSuite` ancestry through direct inheritance, repository script paths and project `class_name` bases. Non-suite helper methods named `test_*` do not become execution obligations; unresolved base expressions fail closed rather than silently dropping genuine suite coverage.

Full scope covers the existing configured test roots. An absent, unregistered layer contributes no selector; a registered missing suite is an error, and every selected existing root must discover tests. A same-snapshot successful full run can satisfy Required and affected subsets without rerunning them. A necessary full escalation without a successful full manifest remains blocked; a human checklist or hand-entered `approved_unavailable` label cannot turn it into automated PASS.

## Artifact-backed completion and semantic freshness

Each actual wrapper invocation creates an isolated run directory with invocation, engine log, wrapper verdict, actual `discovery.json`, `process-ownership.json`, current JUnit/diagnostics, `session-receipt.json` and `manifest.json`. The run manifest uses schema 4 with a pre-launch `attempt_hash`; older run schemas cannot authorize a new import. It records real command, start/end time, before/after snapshot, Feature ID, phase, scope, selectors, declared/runtime-discovered/executed test identities, process verdict, and artifact hashes and timestamps. Discovery, diagnostics and wrapper verdict must identify the same engine process. The Windows process owner used by the test runner attaches a job before the launcher starts, records observed members, and terminates only that job on timeout/interruption. An engine identity absent from that observed scope fails closed.

The actual engine writes a session receipt after its reporters and diagnostic session finish, before quitting. It binds this run ID, engine PID, exit code and invocation hash to the exact discovery, JUnit and diagnostics paths/hashes. The invocation in turn binds the Feature ID and source fingerprint. Gate checks these bindings against wrapper/process evidence and current source, as well as the exact discovery/execution sets. A copied old report cannot become current by updating its file timestamp or manifest hash; missing or changed session evidence, source changes and incomplete discoveries invalidate the result.

Filesystem `st_mtime_ns` and wall-clock start/end values are audit metadata, not freshness authority. Gate does not require nanosecond equality or ordering against the start time: timestamp rounding, copying or filesystem precision can change those relations without changing run contents. Neutral regressions exercise two-second timestamp precision, metadata-only changes, stale reports, tampering and normal runs. Do not use sleeps or repeated runs to obtain a favorable timestamp; preserve original failures and repair the binding contract.

Record completed runs with:

```text
python -B .agents/skills/execute-next-feature/scripts/write-gate-evidence.py record-tests --feature F0XX --run reports/gdunit-wrapper/run-<id>/manifest.json
```

Repeat `--run` only when multiple runs are needed to cover the set. One full manifest is sufficient for all covered subsets. The helper and Completion Gate read the current Feature/Catalog, manifest, wrapper verdict, JUnit nodes/counters, executed identities and runtime diagnostic evidence. Counts are derived output; callers cannot submit counts or a pass label to create PASS. A failed import clears the affected run reference. Completion evidence uses schema 6 and stores run references and actual human decisions, without persistent required/affected/full summaries or `gate_status`. Static output is read directly by the Agent, outside this evidence file. Validators calculate those conclusions from current artifacts; there is no cached PASS to synchronize.

The test runner uses `tools/lib/execution_attempts.py`, one Git-local
`yaya-verification-attempts.json` and an OS-lifetime execution lease. Each Feature
test attempt is registered before executable/preflight checks. Only final runs
authorize completion; baseline and focused/TDD runs remain separate.
For the same Feature and actual source, a later failed or unfinished final scope
blocks older PASS references, without a separate plan file to synchronize.
Referenced successes must cover the current Feature/Catalog selection. A later verified run
must cover the attempted selectors and scope; affected covers required; full must
actually cover the complete contract. A narrow pass cannot clear an unresolved
full attempt. Do not change the phase,
omit a failing final run or rewrite the journal to hide a failure.

The journal is replaced atomically before launch; ordering does not use mtimes.
The Windows byte lock is released on process death, so no stale owner file needs
deletion or PID guessing. Concurrent execution fails immediately. Preserve the
interrupted record, establish the cause and actual process exit, then run the
corrected verification. A corrupt journal blocks completion; preserve it and
recover from trustworthy records/backup, never reset it to revive old evidence.

`working_tree_fingerprint` v2 hashes tracked/nonignored source content, including Product, rules, tests, runner/configuration and semantic Feature/Catalog data. Feature AC text, verification (including approved Test Impact), affected components and Catalog selectors/status/retirement participate. Known top-level process fields (`status`, timestamps, `notes`), Progress Markdown/current history, run artifacts are exempt. Revision-log entry timestamps, summary and notes are excluded; migration relations, revision IDs and source anchors remain semantic. Nested test status is semantic. Git revision is retained as provenance; a process-only commit with identical semantic content does not force another test run. Moving Progress prose to `docs/progress/*.md` alone never invalidates tests. New or unknown contract fields remain included.

A newly initialized Git working repository can verify before its initial commit.
Its snapshot records `git_revision: "UNBORN"` only when HEAD names a valid branch
whose ref does not yet exist; non-repositories, malformed refs and missing commit
objects fail. The same source fingerprint covers staged and nonignored untracked
files. Creating the initial commit with identical semantic content preserves the
run evidence, as does a later process-only commit. Neither commit supplies missing
tests, bootstrap readiness, human acceptance or review.

When the approved acceptance mode is manual, human acceptance remains separate, snapshot-specific evidence. A semantic/source change after acceptance requires renewed acceptance. Run evidence lifecycle follows the common artifact policy; failed runs stay active for diagnosis and evidence referenced by current Gate/acceptance is retained.

## TDD execution contract

When `docs/methodology-config.json` enables automated testing, the normal Feature flow is:

```text
Test Impact Review
        ↓
explicit Stage 1 human approval
        ↓
run Existing Safety Net baseline
        ↓
write/register new acceptance or regression tests
        ↓
RED: prove the new test fails for the intended missing/broken behavior
        ↓
implement smallest coherent change
        ↓
GREEN: new tests pass
        ↓
run final affected or necessary full scope + static checks
        ↓
Stage 5 explicit human acceptance (only for the approved manual mode)
        ↓
code-smell review + rerun only if the semantic snapshot changed
        ↓
done gate
```

A pre-existing baseline failure must be reported before implementation. Do not attribute it to the current Feature or silently repair it as scope expansion.

Stage 4 imports verified run manifests into `docs/gate-evidence.json`; Stage 6 records the final code-smell result against the same semantic snapshot. `.agents/skills/execute-next-feature/scripts/write-gate-evidence.py validate --feature F0XX` checks this evidence; `tools/checks/check-feature-list.py --strict --completion-feature F0XX` checks the completion-specific Feature/Catalog contract. The Agent separately assesses direct parsing/lint output; the evidence helper does not prove those checks ran or supply a required human decision.

Stage 6 reuses current successful manifests after a review without source or verification changes. If fixes change the snapshot, read the current selection and run its affected scope or one necessary full suite, then renew affected acceptance. A successful full run covers Required and affected; do not run Required again merely to fill a second Gate field.

Stage 1 first chooses `verification.acceptance_mode` from the requirement, then
fills the corresponding checks. Visual presentation, animation, audio/sound/music,
game feel and other human judgment require `manual`; requirements whose AC can all
be checked automatically may use `automated`. Empty lists or existing PASS results
never decide the mode. Automated mode omits Stage 5 without recording fake human
acceptance; manual mode still requires the user’s explicit decision.

## Requirement changes and stale tests

When Product behavior changes, old tests are not automatically authoritative. `sync-feature-list` must perform Test Impact Review before implementation:

- still-valid contract → keep test active;
- changed contract → create/update verification through the new Feature;
- superseded contract → retire the obsolete test deliberately;
- new behavior → add new acceptance test IDs;
- Bug fix → add regression coverage unless deterministic automation is impractical.

Never change implementation merely to satisfy a test whose underlying Product/Feature contract has been superseded.

## Bug regression and guardrail promotion

Bug repair captures both historical evidence and generalized prevention:

```text
Bug Feature
├── regression test → F0XX-RT01
└── BUG learning Guardrail
        ↓ explicit human approval only
   Coding Rule / invariant
        ↓
   INV-<DOMAIN>-01 when machine-verifiable
```

A regression test proves that the concrete historical defect does not return. An invariant test proves a generalized cross-Feature rule. They are complementary and may both exist.

## Runner boundary

After the one-time Project Environment Bootstrap is `ready`, `docs/methodology-config.json` supplies confirmed Godot/gdunit4 commands and test roots. GdUnit discovery, flags, JUnit identities and session diagnostics implement this concrete stack. Readiness and evidence import reject other runner identifiers. Do not add an adapter selection layer or represent an unsupported runner's self-reported counts as compatible evidence.

For gdUnit4 specifically, a project may keep the plugin under `addons/gdUnit4/` while keeping project tests under the canonical `tests/unit`, `tests/features`, and `tests/invariants` roots. The Yaya Loop taxonomy is therefore a project convention, not a gdUnit4 directory requirement.
