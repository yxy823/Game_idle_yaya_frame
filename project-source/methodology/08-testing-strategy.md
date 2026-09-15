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

## `docs/test-registry.json`

The test registry is the machine-readable bridge from changed components to existing safety-net tests.

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

### Registry rules

- Component IDs are stable `lower_snake_case` identifiers.
- `unit_test_paths` contain repository-relative paths to existing unit suite files or directories protecting that component and required whenever it is affected. The non-empty examples above assume those suites already exist.
- A component without unit suites uses `unit_test_paths: []`; never prefill future directories. Propose new unit suites in Stage 1, then register their paths after the approved Stage 3 creation and include them in the Required Test Set.
- A missing or deleted registered suite path is a registry error, not an empty safety net. Do not silently filter it out; removing a registration requires an explicit reason and user approval. Merge/strict validation checks path existence; the configured runner must establish actual discovery and execution.
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

The affected set contains Required plus active acceptance tests intersecting affected components. The agent may add related tests from other components when dependency/API analysis shows material impact, recording the exact reason. It may not remove any deterministic requirement. Approved retirement changes the underlying Product/Registry contract instead of adding a runner exclusion.

Ordinary downstream regression belongs to the Feature implementing the change.
Carry the affected behavior and coverage gaps from its notes into Stage 1; use
existing component selection or approved additional tests without changing their
ownership. Repeating valid tests alone does not require another Feature. Separate
implementation, repair or an independently agreed deliverable may justify one.

A full suite is required when any of these is true:

- an affected registry component has `full_suite_on_change: true`;
- infrastructure/toolchain changes actually affect the project broadly; a maintenance label alone does not require full;
- a dependency/toolchain upgrade can affect broad behavior;
- impact analysis cannot bound the affected components reliably;
- the user explicitly requires it.

For other local Features, targeted verification is sufficient before applicable acceptance unless project Coding Rules state otherwise.

## Runtime Test Impact selection

The runner reads the current Feature and Test Registry through
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

Full scope covers the existing configured test roots. An absent, unregistered layer contributes no selector; a registered missing suite is an error, and every selected existing root must discover tests. A same-snapshot successful full run can satisfy Required and affected subsets without rerunning them. A necessary full escalation without a successful full result remains blocked; a human checklist or hand-entered `approved_unavailable` label cannot turn it into automated PASS.

## Artifact-backed completion and semantic freshness

For a valid `manual` acceptance plan only, when the current Required and affected
sets are both empty and full suite is not required, no automated run is needed.
Keep the initialized `test_runs: []`; do not call the runner or `record-tests` just
to manufacture evidence. The helper derives `not_required`, never an empty PASS.
Current mappings and registered paths must still be valid; an unresolved failed or
unfinished final run for the same Feature/snapshot still blocks completion. Record
actual human acceptance on the current snapshot, and assess
applicable static checks. Any automated obligation retains the normal real-run requirement.

Each invocation creates one isolated `reports/gdunit-wrapper/run-<id>/` directory.
The runner writes one `result.json` (schema 1) before setup and finalizes that same
file after execution. It records Feature/phase/scope, selected paths, the real command,
source fingerprint, process outcome and errors, plus references/hashes for the
original `engine.log`, `discovery.json`, JUnit and diagnostics. Case identities and
totals are read from those original reports when needed, not copied into more summaries.

The gdUnit extension writes actual expanded discovery with this run ID and engine PID.
Discovery must match the JUnit cases; source declarations detect omitted suites.
Native diagnostics cannot be hidden by green JUnit. Windows process ownership is
checked in memory, and timeout cleanup terminates only the owned process tree.

Before engine preflight/launch, `result.json` records either a running attempt or
a failed preparation. Invalid historical JSON/schema/identity/sequence produces
a warning on stderr with the affected path; preserve the original and allow a new
measurement. This warning does not decide the current run's result. Snapshot-read
errors still produce a failed current result without launching Godot.
This requires a writable report directory; a filesystem write failure must still
be reported as such, not as a successfully saved result.

Completion still rejects damaged referenced results. Its history scan excludes
another Feature only after reading a supported schema, matching run identity and
a valid different Feature ID. Current-Feature damage and unreadable or unidentified
damage still block completion until investigated and resolved under authorization.
Successful execution alone does not remove that evidence limitation.

A local sequence computed from readable results with valid headers orders attempts
without depending on filesystem timestamp precision; a tied sequence cannot clear
another attempt. For the same Feature/content, an unresolved final
failure cannot be hidden by an older success or a later narrower run. Recovery uses a
later successful run covering the failed scope; preserve the original failure and
diagnose its cause. An `auto` preparation record with no command, selectors or
process has not chosen an execution scope. Recover it with a later affected run,
or full when the same snapshot's current obligations require full. This does not
relax recovery for an actual full failure or accept inconsistent auto records.
Baseline/focused runs do not grant final completion. There is no
separate journal, execution lock, invocation, verdict, process report or session receipt.

Record results with:

```powershell
python -B .agents/skills/execute-next-feature/scripts/record-feature-completion.py record-tests --feature F0XX --run reports/gdunit-wrapper/run-<id>/result.json
```

Repeat `--run` only for distinct runs needed to cover the obligations. One full run
can cover Required/affected. The helper computes coverage from the current Feature,
Registry and original reports; caller-provided pass labels or totals cannot create PASS.
Failed imports clear old references. Completion schema 8 stores test references and
actual human acceptance; no review counts, required/affected/full totals or cached gate status.
Parsing/lint results are assessed directly by the Agent.

Hashes, current-source binding and run identity detect accidental stale reuse or
altered artifacts. These locally editable records are not an independent security
signature against someone rewriting all evidence. File mtimes and wall-clock precision
do not authorize completion. Do not add sleeps or rerun unchanged failures to get green.

`working_tree_fingerprint` v2 hashes tracked/nonignored source content, including Product, rules, tests, runner/configuration and semantic Feature/Registry data. Feature AC text, verification (including approved Test Impact), affected components and Registry selectors/status/retirement participate. Known top-level process fields (`status`, timestamps, `notes`), Progress Markdown/current history, explanatory Markdown under `docs/knowledge/`, and run artifacts are exempt. Knowledge indexes and entries are contextual reference material; they must not own executable inputs, requirements, rules or validation contracts. Non-Markdown files there still participate.

Ordinary `README.md` files (case-insensitive filename) explain usage and navigation; adding, editing, moving or deleting them does not invalidate test evidence. README files under `.agents/`, `agent-rules/`, `methodology/`, `docs/product/` and `docs/features/` remain inputs because those directories own instructions or verification contracts. Moving a README into one of these directories therefore changes the fingerprint. Keep executable inputs, requirements and validation rules in their existing authoritative files rather than a usage README; other Markdown files remain included unless explicitly exempt above. Documentation changes still require checking facts, links and examples, without automatically rerunning business tests.

Revision-log entry timestamps, summary and notes are excluded; migration relations, revision IDs and source anchors remain semantic. Nested test status is semantic. Git revision is retained as provenance; a process-only commit with identical semantic content does not force another test run. Moving Progress prose or organizing knowledge Markdown alone never invalidates tests. New or unknown contract fields remain included.

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

For behavior implemented before formal recording, apply [Delivery of existing implementation](03-execute-loop.md#delivery-of-existing-implementation)
to distinguish present verification from unavailable historical baseline/RED
evidence. New behavior changes and repairs still follow the normal TDD flow below.

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
requirements and code-quality review + reverify repairs or concrete evidence gaps
        ↓
done gate
```

A pre-existing baseline failure must be reported before implementation. Do not attribute it to the current Feature or silently repair it as scope expansion.

Stage 4 imports verified run results into `docs/feature-completion-evidence.json` when automated obligations exist; Stage 5 records actual human acceptance when required. `.agents/skills/execute-next-feature/scripts/record-feature-completion.py validate --feature F0XX` checks this evidence; `tools/checks/check-feature-list.py --completion-feature F0XX` checks the completion-specific Feature/Registry contract. The Agent separately assesses direct parsing/lint output and any explicit user review condition under the execution loop. The evidence helper does not prove static checks or review ran, or supply a required human decision.

A requested Stage 6 review reuses current successful run results without source or verification changes. If fixes change the snapshot, recalculate the current obligations, repeat applicable Stage 4 verification (including the no-automated-obligations case above), then renew affected acceptance. A successful full run covers Required and affected; do not run Required again merely to fill a second Gate field.

Stage 1 first chooses `verification.acceptance_mode` from the requirement, then
fills the corresponding checks. Visual presentation, animation, audio/sound/music,
game feel and other human judgment require `manual`; requirements whose AC can all
be checked automatically may use `automated`. Empty lists or existing PASS results
never decide the mode. Automated mode omits Stage 5 without recording fake human
acceptance; manual mode still requires the user's actual file submission or
explicit conversational decision under [Manual acceptance files](manual-acceptance-files.md).

## Requirement changes and stale tests

When Product behavior changes, old tests are not automatically authoritative. `sync-feature-list` must perform Test Impact Review before implementation:

- still-valid contract → keep test active;
- changed contract → create/update verification through the new Feature;
- superseded contract → retire the obsolete test deliberately;
- new behavior → add new acceptance test IDs;
- Bug fix → add regression coverage unless deterministic automation is impractical.

Registry retirement does not remove executable tests: gdUnit discovers methods
under selected suite/directory paths, including retired cases still in those
files. Read affected test code as well as Registry; ordinary unit tests may have
no logical ID. Use the existing sync report to identify obsolete assertions,
methods/files, affected current references and the owning Feature. After approval,
keep necessary cleanup actions in that Feature's `notes`; planning does not edit
test code or establish that cleanup has happened.

During that Feature's approved implementation, delete or replace superseded
assertions and update affected active mappings, `unit_test_paths` and current
requirement/usage references. Remove obsolete empty suites and their registrations
within the approved scope. Preserve still-valid cases sharing those files and
unaffected regressions/invariants. Retired Registry records retain historical
ID/source/path/case and provenance; completed Feature records and historical
evidence are not cleanup targets.

Use normal verification and author checking to inspect the final diff, affected
references and current discovery/original results. Required cleanup left open
means that change is not complete; a `retired` label or a TODO alone is insufficient.
Keep pending work in the owning Feature notes or current Progress, and report
actual cleanup and remaining work at handoff. Unrelated cleanup stays outside
scope. No separate cleanup ledger, checker or unconditional full run is needed.

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
