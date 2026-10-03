# 08 · Test traceability and evidence

> This document decides which tests a change needs, why they are selected, and how their results count as completion evidence. How to write Godot tests is defined in [agent-rules/70-tests](../agent-rules/70-tests/README.md); the gdUnit runner's implementation details are in [gdunit4-profile.md](../agent-rules/70-tests/gdunit4-profile.md).

## Goals

The testing layer must answer four questions deterministically as the project grows:

1. Which tests verify the current Feature's acceptance criteria?
2. Which existing unit suites protect the components touched by the Feature?
3. Which historical Bug regression tests must be rerun?
4. Which cross-Feature invariants and full-suite checks are required?

The Agent derives these answers from the Feature records and the Test Registry, not from memory or intuition.

## Test taxonomy

Physical organization is based on what a test protects:

```text
tests/
├── unit/        # local code/component contracts
├── features/    # Product Feature / acceptance behavior
└── invariants/  # cross-Feature architecture/domain rules
```

`regression` describes where a test came from, not a fourth directory. A regression test lives under the layer it protects, usually `features/F0XX/` and occasionally `unit/<component>/`.

Logical IDs identify why a registered test exists:

- `F012-AC01` or `F012-AC01-02`: automated acceptance verification for Feature F012 criterion AC01.
- `F052-RT01`: regression test created by Bug-repair Feature F052.
- `INV-LIFECYCLE-01`: cross-Feature invariant test.

Ordinary low-level unit tests need no logical ID unless they are also acceptance, regression or invariant evidence.

A regression test proves that one concrete defect does not return; an invariant test proves a generalized cross-Feature rule. How a Bug's Guardrail may become an invariant is defined in [Bug-learning promotion](07-engineering-change.md#bug-learning-promotion).

## Feature traceability

Feature details use stable acceptance-criterion IDs:

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

`affected_components` is a small set of stable domain or component IDs, such as `inventory`, `save`, `combat`, or `scene_lifecycle`. Use semantic components, not individual file paths.

## `docs/test-registry.json`

The Test Registry always lives at `docs/test-registry.json`. It maps changed components to the tests that protect them. This document is the single source for its rules; Skills and other methodology documents link here.

```json
{
  "meta": {
    "schema_version": 3
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
      "components": ["inventory", "scene_lifecycle"],
      "path": "tests/features/F052/scene_transition_regression_test.gd",
      "case": "test_f052_rt01_reopen_inventory_after_scene_change",
      "status": "active"
    },
    {
      "id": "INV-LIFECYCLE-01",
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
- `unit_test_paths` lists repository-relative paths to unit suite files or directories that protect the component. They are required whenever the component is affected. The non-empty examples above assume those suites already exist.
- A component without unit suites uses `unit_test_paths: []`. Never prefill future directories. Propose new unit suites in Stage 1, register their paths after they are created in the approved Stage 3, and include them in the Required Test Set.
- A missing or deleted registered suite path is a Registry error, not an empty safety net. Do not silently filter it out. Removing a registration requires an explicit reason and user approval. Merge and strict validation check that the path exists; only an actual run proves discovery and execution (see [What fails a run](#what-fails-a-run)).
- `full_suite_on_change: true` means any Feature touching that component requires the full suite before completion.
- The unique logical ID determines identity:
  - `F0XX-ACyy` or `F0XX-ACyy-NN`: acceptance for that Feature and criterion;
  - `F0XX-RTyy`: regression for that Feature;
  - `INV-<DOMAIN>-NN`: an invariant with no Feature or criterion. `DOMAIN` starts with an uppercase letter or digit and uses uppercase letters, digits, underscores or hyphens.
- Do not store separate `kind`, `source_feature` or `criterion_id` fields.
- `status` is `planned`, `active`, or `retired`.
- `planned` lets a `tests` entry be registered for TDD before the test file exists. It does not apply to `unit_test_paths`.
- The Feature being completed references only `active`, resolvable automated tests. Completed Features may keep mappings to retired tests that are traceable under the schema's replacement contract.
- A retired test keeps its ID and records the reason, the Product change source or revision, and the replacement Feature or tests. It does not enter the active safety net. Strict validation checks this replacement chain; the completion check still requires active direct verification for the current Feature.
- Moving a test file updates `path`; the logical test ID remains stable.

## Test Impact Review

`feature-execute` performs the Test Impact Review in Stage 1, before implementation. The Required Test Set is:

```text
Required Test Set =
    current Feature acceptance tests
  + current Feature regression tests
  + unit_test_paths for affected_components
  + active regression tests whose components intersect affected_components
  + active invariant tests whose components intersect affected_components
  + approved additional tests in verification.test_impact
```

Every registered suite of an affected component enters the Required Test Set. An empty `unit_test_paths` array adds no unit selector.

The affected set is the Required Test Set plus active acceptance tests of the affected components.

- The Agent may add related tests from other components when dependency or API analysis shows material impact, recording the exact reason.
- The Agent may not remove any requirement derived above. An approved retirement changes the Product or Registry contract; it never becomes a runner exclusion.
- The Godot impact conditions in [test-selection-and-gates.md](../agent-rules/70-tests/test-selection-and-gates.md) can widen the verification, for example with fresh-process startup or reimport checks. Record such additions in the Stage 1 verification plan. Checks that are not gdUnit runs are reported with the results; they do not go into `full_suite_reasons`.

Ordinary downstream regression belongs to the Feature that implements the change. Carry the affected behavior and coverage gaps from its notes into Stage 1, and use component selection or approved additional tests without changing their ownership. Rerunning valid tests does not need another Feature. A separate implementation, repair or independently agreed deliverable may justify one.

A full suite is required when any of these is true:

- an affected Registry component has `full_suite_on_change: true`;
- an infrastructure or toolchain change actually affects the project broadly (a maintenance label alone does not);
- a dependency or toolchain upgrade can affect broad behavior;
- impact analysis cannot bound the affected components reliably;
- the user explicitly requires it.

The full-suite triggers in `test-selection-and-gates.md` also apply; record them as `full_suite_reasons`. For other local Features, targeted verification is enough before applicable acceptance unless Project Rules say otherwise.

## Runtime Test Impact selection

The runner reads the current Feature and the Test Registry through `tools/lib/test_selection.py`. There is no separate plan command, plan file or plan hash.

After Stage 1 approval, Stage 2 stores the extra obligations in the Feature's `verification.test_impact`:

- `additional_tests: [{id, reason}]`
- `full_suite_reasons: [reason]`

The runner always includes these obligations. Agent judgment supplies the impact analysis and any additions; scripts only turn the recorded mappings into selections.

Run from the project root with the configured Python interpreter:

```text
python -B tools/testing/run-gdunit-tests.py --feature F0XX --scope auto
```

The runner uses the Godot path in `docs/methodology-config.json`. `--godot-binary <path>` is an optional override for one run.

| Option | Meaning |
| --- | --- |
| `--scope auto` (default) | Runs the affected set, which includes Required, and escalates to one full run when full is required. |
| `--scope required`, `affected`, `full` | Explicit scopes for iteration. `full` selects `tests/` recursively; empty layer directories add no obligation. |
| `--phase baseline` | Leaves out planned tests that do not exist yet. A baseline run never authorizes completion. |
| `--target <path>` | Focused or TDD diagnosis. It never produces completion evidence. |

Output lists the selection reasons, the deduplicated selectors and any full-suite reasons. Final selection rejects unresolved or retired direct mappings and missing paths.

The runner executes deduplicated suite and directory selectors, so selecting a suite may run extra cases. Case-level obligations are checked against the cases that actually ran. How discovery, JUnit cases and diagnostics are matched is described in [gdunit4-profile.md](../agent-rules/70-tests/gdunit4-profile.md).

### What fails a run

A run fails, and never counts as PASS, when any of these occurs:

- a selected path or a registered suite path is missing or invalid;
- a selected path, a targeted run or a full run discovers zero tests;
- a required case or suite is missing or skipped, or a final automated mapping is not implemented;
- the discovered cases, including every expanded parameterized case, do not exactly match the executed JUnit cases;
- a suite declared in the test sources was not discovered;
- runtime diagnostics, a timeout or a runner failure occur.

This list is the single statement of these failures; other documents link here.

Source declarations only detect omitted suites; they never prove execution. The declaration scan resolves `GdUnitTestSuite` ancestry through direct inheritance, repository script paths and project `class_name` bases. Helper methods named `test_*` outside a suite are not obligations, and an unresolved base expression fails instead of silently dropping a suite.

A same-snapshot successful full run satisfies the Required and affected sets without rerunning them. A required full escalation without a successful full result stays blocked. A human checklist or a hand-entered `approved_unavailable` label cannot turn it into an automated PASS.

## Artifact-backed completion and semantic freshness

### No automated obligations: `not_required`

In final verification, the runner returns `not_required` only for a valid `manual` acceptance plan with empty Required and affected sets and no full-suite obligation.

- Invoke the runner normally. It checks the current plan and any unresolved same-snapshot failures, then exits 0 with a JSON status on stdout. It does not launch Godot, read the engine configuration or create a run report.
- Do not call `record-tests` for this outcome. Recording the actual human acceptance creates the completion record with `test_runs: []`. Applicable static checks are still required.
- A baseline selection may also be empty, because new planned tests do not exist yet.
- An explicit `--scope full` or `--require-test` still requires a real run, and the failures under [What fails a run](#what-fails-a-run) still apply.
- `not_required` never clears an earlier failed or unfinished final run.

### Run records

Each Feature invocation creates one `reports/gdunit-wrapper/<Feature-ID>/run-<id>/` directory; focused runs use `reports/gdunit-wrapper/focused/run-<id>/`. The runner writes one `result.json` (schema 1) before setup and finalizes the same file after execution. It records the Feature, phase, scope, selected paths, the real command, the source fingerprint, the process outcome and errors, and references and hashes for the original reports. Case identities and totals are read from those original reports when needed, not copied into more summaries. The file layout and the discovery checks are in [gdunit4-profile.md](../agent-rules/70-tests/gdunit4-profile.md).

Completion reads only the current Feature's run directory:

- Damaged referenced results and invalid history in that directory, including a mismatched Feature ID, block completion. Investigate and resolve the damage under authorization; a new passing run does not erase it.
- Invalid earlier history produces a warning on stderr with the affected path. Keep the original and allow a new run; the warning does not decide the current run's result.
- A snapshot-read error produces a failed current result without launching Godot. A filesystem write failure is reported as such, never as a saved result.
- Other Feature directories and focused runs are not read.

Attempts are ordered by a per-Feature sequence computed from readable results with valid headers, not by file timestamps. A tied sequence cannot clear another attempt.

- For the same Feature and content, an unresolved final failure cannot be hidden by an older success or a later narrower run.
- Recovery needs a later successful run that covers the failed scope. Keep the original failure and diagnose its cause.
- An `auto` preparation record with no command, selectors or process has not chosen a scope. Recover it with a later affected run, or a full run when the same snapshot's obligations require full. This does not relax recovery from an actual full failure or accept inconsistent `auto` records.
- Baseline and focused runs never grant final completion.

There is no separate journal, execution lock, invocation record, verdict file, process report or session receipt.

### Recording results

```powershell
python -B tools/features/record-feature-completion.py record-tests --feature F0XX --run reports/gdunit-wrapper/F0XX/run-<id>/result.json
```

- Repeat `--run` only for distinct runs needed to cover the obligations. One full run covers Required and affected.
- The helper computes coverage from the current Feature, the Registry and the original reports. Caller-provided pass labels or totals cannot create PASS.
- A failed import clears earlier references.
- Completion schema 8 stores test references and actual human acceptance. It holds no review counts, Required, affected or full totals, or cached gate status.
- The Agent assesses parsing and lint results directly.

Hashes, current-source binding and run identity detect accidental stale reuse or altered files. These locally editable records are not a security signature against someone rewriting all evidence. File modification times and clock precision never authorize completion. Do not add sleeps or rerun unchanged failures to get a green result.

### Content fingerprint

`working_tree_fingerprint` v2 hashes tracked and non-ignored source content. Evidence is valid only for the fingerprint it was produced against.

Included:

- GDD, Product, rules, tests, runner and configuration;
- semantic Feature and Registry data: AC text, verification (including the approved Test Impact), affected components, and Registry selectors, status and retirement;
- `docs/gdd/`, `docs/terminology.md`, `docs/project-rules.md`, professional specifications, presentation documents (including adopted alternatives and resource sections), Feature design Markdown and architecture and ADR documents;
- revision-log migration relations, revision IDs and source anchors, and nested test status;
- new or unknown contract fields;
- non-Markdown files under `docs/knowledge/` and `docs/research/`;
- every other Markdown file not excluded below.

Excluded:

- top-level Feature process fields: `status`, timestamps and `notes`;
- Progress Markdown and current history;
- explanatory Markdown under `docs/knowledge/` and `docs/research/`;
- revision-log entry timestamps, summary and notes;
- run artifacts and reports;
- ordinary `README.md` files (case-insensitive), except those under `.agents/`, `agent-rules/`, `methodology/`, `docs/gdd/`, `docs/product/` and `docs/features/`, which hold instructions or governing contracts.

Consequences:

- Knowledge and research are reference material. They never hold executable inputs, requirements, rules or validation contracts.
- Moving a long design out of JSON `notes` into Markdown does not give that Markdown the notes exemption.
- Moving a README into one of the listed directories changes the fingerprint. A substantive GDD entry may be named `README.md`; it is still a governing source. Keep requirements and validation rules in their authoritative files, not in a usage README.
- The fingerprint is global, not filtered by Feature references. Editorial wording, future GDD chapters and resource status or location edits can invalidate current evidence even when they need no Feature-plan change. Finalize these documents at the Stage 3 checkpoint before final verification; later changes follow the normal freshness rules.
- Moving Progress prose or organizing knowledge and research Markdown never invalidates tests. Documentation changes still need their facts, links and examples checked, without rerunning business tests.
- Completed Feature records are not reopened automatically.

Git state:

- Project creation supplies the initial commit. Verification requires a valid current commit; missing or broken Git state fails.
- The fingerprint also covers staged and non-ignored untracked files. Deleting or renaming an included file changes the content identity; a path already missing but still in the Git index contributes nothing. Staging or committing that deletion or rename afterwards keeps the fingerprint unchanged.
- The Git revision is provenance. A commit with identical semantic content keeps run evidence valid but supplies no missing tests, readiness, human acceptance or review.

When the approved acceptance mode is manual, human acceptance is separate evidence bound to its snapshot. A semantic or source change after acceptance requires renewed acceptance. Run records follow [Reports and cleanup](09-records-reports-and-handoff.md#reports-and-cleanup): failed runs stay available for diagnosis, and evidence referenced by the current Completion Gate or acceptance is kept.

### Supplemental evidence

Performance, soak and other specialist evidence follows [Finalization and evidence](11-specialist-workflows.md#finalization-and-evidence). The run-evidence import supports actual gdUnit results only. Other measurement, display or listening obligations stay in their AC and design verification plan and are assessed by the owning task and any requested independent review. Do not fabricate gdUnit run evidence or use supplemental results to waive required tests.

## TDD execution contract

When the Feature has automated obligations, the normal Feature flow is:

```text
Test Impact Review
        ↓
explicit Stage 1 human approval
        ↓
run Existing Safety Net baseline
        ↓
write and register new acceptance or regression tests
        ↓
RED: prove the new test fails for the intended missing or broken behavior
        ↓
implement the smallest coherent change
        ↓
GREEN: new tests pass
        ↓
necessary local refactor + rerun relevant tests; repeat the cycle for the next behavior
        ↓
Stage 3 documentation checkpoint
        ↓
run final affected or necessary full scope + static checks
        ↓
Stage 5 explicit human acceptance (only for the approved manual mode)
        ↓
Stage 6 independent review only when requested
        ↓
Completion Gate
```

For behavior implemented before it was formally recorded, apply [Delivery of existing implementation](03-execute-loop.md#delivery-of-existing-implementation) to separate present verification from baseline and RED evidence that can no longer be produced. New behavior changes and repairs follow the flow above.

Report a baseline failure that already exists before implementation. Do not attribute it to the current Feature or silently repair it as scope expansion.

RED, GREEN and refactor apply per small observable behavior, not as all tests first and then all implementation. One criterion may need several cycles. Keep tests focused on observable contracts, and rerun relevant tests after meaningful refactoring. Focused and TDD results never replace the final affected or full evidence.

Completion evidence is checked by these commands; the Agent assesses the rest:

- Stage 4 imports verified run results into `docs/feature-completion-evidence.json` when automated obligations exist. Stage 5 records actual human acceptance when it is required.
- `tools/features/record-feature-completion.py validate --feature F0XX` checks this evidence.
- `tools/checks/check-feature-list.py --completion-feature F0XX` checks the completion-specific Feature and Registry contract.
- The Agent assesses parsing and lint output and any explicit user review condition under the [execute loop](03-execute-loop.md). The evidence helper does not prove that static checks or review ran, and it cannot supply a required human decision.

A requested [Stage 6 review](03-execute-loop.md#stage-6--optional-independent-review) reuses current successful run results when no source or verification changed. If fixes change the snapshot, recalculate the current obligations, repeat the applicable Stage 4 verification (including the [`not_required`](#no-automated-obligations-not_required) case), then renew affected acceptance. A successful full run covers Required and affected; do not run Required again only to fill a second field.

Stage 1 first chooses `verification.acceptance_mode` from the requirement, then fills in the matching checks.

- Visual presentation, animation, audio, sound, music, game feel and other human judgment require `manual`.
- A requirement whose AC can all be checked automatically may use `automated`.
- Empty lists or earlier PASS results never decide the mode.
- Automated mode skips Stage 5 without recording fake human acceptance. Manual mode requires the user's actual file submission or explicit decision in the conversation, under [Manual acceptance files](contracts/manual-acceptance-files.md).

## Requirement changes and stale tests

When GDD design, Product delivery scope or professional requirements change, earlier tests are not automatically authoritative. `feature-sync` assesses the affected tests in its synchronization report. The Feature that implements the change then performs the Test Impact Review in its Stage 1. The outcomes are:

- still-valid contract → keep the test active;
- changed contract → create or update verification through the new Feature;
- superseded contract → retire the obsolete test deliberately;
- new behavior → add new acceptance test IDs;
- Bug fix → add regression coverage unless deterministic automation is impractical.

Registry retirement does not remove executable tests: gdUnit discovers every method under the selected suite and directory paths, including retired cases still in those files. Read the affected test code as well as the Registry; ordinary unit tests may have no logical ID. The sync report identifies obsolete assertions, methods and files, affected current references and the owning Feature. After approval, record the needed cleanup actions in that Feature's `notes`. Planning does not edit test code or claim that cleanup has happened.

During that Feature's approved implementation:

- delete or replace superseded assertions;
- update affected active mappings, `unit_test_paths` and current requirement and usage references;
- remove obsolete empty suites and their registrations within the approved scope;
- keep still-valid cases that share those files, and keep unaffected regressions and invariants;
- keep retired Registry records with their ID, source, path, case and provenance. Completed Feature records and earlier evidence are not cleanup targets.

Use normal verification and the author check to inspect the final diff, affected references, current discovery and original results. Required cleanup left open means the change is not complete; a `retired` label or a TODO alone is not enough. Keep pending work in the owning Feature notes or current Progress, and report actual cleanup and remaining work at handoff. Unrelated cleanup stays out of scope. No separate cleanup ledger, checker or unconditional full run is needed.

Never change implementation only to satisfy a test whose Product or Feature contract has been superseded.

## Runner boundary

After [Project Environment Bootstrap](06-project-environment.md#project-environment-bootstrap) has passed its checks, the fixed runner reads the Godot executable from `docs/methodology-config.json` and selects tests from the Feature and the Registry. GdUnit discovery, flags, JUnit identities and session diagnostics implement this stack. Evidence import validates the actual gdUnit reports. There is no configurable adapter and no second copy of test roots or commands.

The gdUnit4 plugin lives under `addons/gdUnit4/`, while project tests stay under the `tests/unit`, `tests/features` and `tests/invariants` roots. This taxonomy is a project convention, not a gdUnit4 directory requirement.
