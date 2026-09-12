# 02 · Feature-list and test-traceability schema

## Structure

```text
docs/
├── feature-list.json
├── features/
│   ├── F001.json
│   ├── F002.json
│   └── ...
├── feature-list-revisions.json
├── test-catalog.json
└── gate-evidence.json
```

The Feature index stays lightweight. Durable behavior, stable acceptance-criterion IDs, component impact, verification mapping, engineering classification, and notes live in per-Feature detail files. `docs/test-catalog.json` is the machine-readable index that maps components to reusable tests. Human-readable values use `document_language`; machine protocol fields remain stable.

## File 1: `docs/feature-list.json`

```json
{
  "meta": {
    "generated_from": [
      "docs/product.md",
      "docs/product/**/*.md",
      "docs/coding_rules.md"
    ],
    "generated_at": "2026-05-23T05:46:48Z",
    "total_features": 2,
    "details_dir": "docs/features/",
    "revisions_file": "docs/feature-list-revisions.json",
    "test_catalog_file": "docs/test-catalog.json",
    "notes": "Decompose in dependency order and keep each Feature independently verifiable."
  },
  "features": [
    {
      "id": "F001",
      "title": "Create the project shell and open an empty main window",
      "status": "done",
      "depends_on": [],
      "estimated_scope": "small",
      "completed_at": "2026-05-16T10:30:00Z"
    },
    {
      "id": "F002",
      "title": "Show the first interactive Product behavior",
      "status": "pending",
      "depends_on": ["F001"],
      "estimated_scope": "medium",
      "completed_at": null
    }
  ]
}
```

### Index fields

| Field | Requirement |
| --- | --- |
| `id` | Exactly `F` plus three digits. Entries remain sequential from `F001`; IDs are never reused. |
| `title` | Non-empty human-readable verb phrase. |
| `status` | `pending`, `in_progress`, `done`, `obsolete`, `obsolete_done`, or `blocked`. |
| `depends_on` | Unique existing prerequisite Feature IDs. Larger IDs are allowed; the graph must remain acyclic. |
| `estimated_scope` | Final plan accepts only `small` or `medium`; `large` must be decomposed before finalization. |
| `completed_at` | Valid ISO 8601 timestamp only for `done` or `obsolete_done`; otherwise `null`. |

`meta.total_features` must equal the number of index entries. `meta.test_catalog_file`, when present, must point to `docs/test-catalog.json`.

IDs record allocation, not execution order. Select pending work whose prerequisites
are all `done`; use stable ID order only to break ties among eligible Features.
`python -B tools/checks/check-feature-list.py --eligible` validates the ledger and prints
that eligible set as JSON. New pending/in-progress/blocked work cannot depend on
`obsolete` or `obsolete_done`; synchronization must reconnect it to the replacement.
Historical completed dependencies remain unchanged.

## File 2: `docs/features/F0XX.json`

Product-derived Feature:

```json
{
  "id": "F042",
  "description": "The player can place a wooden-wall blueprint and complete construction so the finished wall blocks pathfinding.",
  "affected_components": ["building", "pathfinding"],
  "acceptance_criteria": [
    {
      "id": "AC01",
      "text": "Selecting Wooden Wall enters placement mode.",
      "verification": {
        "automated_tests": [],
        "manual_checks": []
      }
    },
    {
      "id": "AC02",
      "text": "The completed wall blocks pathfinding.",
      "verification": {
        "automated_tests": [],
        "manual_checks": []
      }
    }
  ],
  "verification": {
    "acceptance_mode": null,
    "regression_tests": [],
    "manual_regression": null
  },
  "source": "product/04-building.md#wooden-wall",
  "notes": ""
}
```

Engineering Feature:

```json
{
  "id": "F043",
  "description": "Repair reopening the detail panel after a scene transition while preserving the documented panel behavior.",
  "affected_components": ["detail_panel", "scene_lifecycle"],
  "acceptance_criteria": [
    {
      "id": "AC01",
      "text": "The documented reopen behavior is restored.",
      "verification": {
        "automated_tests": [],
        "manual_checks": []
      }
    }
  ],
  "verification": {
    "acceptance_mode": null,
    "regression_tests": ["F043-RT01"],
    "manual_regression": null
  },
  "source": "product/03-detail-panel.md#reopen-behavior",
  "notes": "",
  "engineering_change": "bug"
}
```

### Detail fields

| Field | Requirement |
| --- | --- |
| `id` | Must match both the index entry and filename stem. |
| `description` | Non-empty observable outcome. Product Features focus on What; engineering Features state the technical repair/maintenance outcome without embedding workflow state. |
| `affected_components` | Non-empty unique array of stable `lower_snake_case` component/domain IDs. Use semantic components, not file paths. |
| `acceptance_criteria` | Non-empty array of canonical criterion objects. Each object has stable `ACxx` ID, non-empty `text`, and a `verification` object. String-form criteria are not supported. |
| `acceptance_criteria[].verification.automated_tests` | Unique logical acceptance-test IDs. New canonical IDs are `F0XX-ACyy` or `F0XX-ACyy-NN`. |
| `verification.acceptance_mode` | Stage 1 decision: `manual` for human perception/judgment (visual, audio, feel, etc.); `automated` when all AC can be verified automatically. Null is an undecided draft and cannot complete. Decide from requirements before filling checks. |
| `acceptance_criteria[].verification.manual_checks` | Concrete checks produced by the manual acceptance plan; empty for an automated plan. This list does not determine the mode. |
| `verification.regression_tests` | Unique regression IDs created by this Feature, normally `F0XX-RTyy`. Empty for non-Bug Features unless explicitly justified. |
| `verification.manual_regression` | `null` when automated regression exists or no Bug regression applies; otherwise a concrete repeatable manual regression check and reason automation is impractical. |
| `verification.test_impact` | Optional when no extra test scope is needed; templates include exactly `additional_tests` and `full_suite_reasons`. Stage 2 persists the approved additional scope here before final test execution. This semantic field is part of the snapshot fingerprint. |
| `verification.test_impact.additional_tests` | Array of `{ "id": "...", "reason": "..." }` with unique Catalog IDs and non-empty reasons. May reference another Feature's test. Referenced tests may be planned during preparation but must be active for current completion. Additional scope does not change test ownership or replace the Feature's own AC/regression mapping. |
| `verification.test_impact.full_suite_reasons` | Unique array of non-empty reasons for approved full-suite escalation beyond automatically derived triggers. An empty array records no additional escalation. |
| `source` | Precise Product source when a behavioral contract exists; `infrastructure` for technical work with no single Product source. |
| `notes` | String. Starts empty; later holds durable implementation decisions, placeholders, TODO smell suggestions, deferred edges, and bug learning. |
| `engineering_change` | Optional. When present, exactly `bug`, `refactor`, or `maintenance`. Product-derived Features omit it. |
| `bug_diagnosis` | Optional/null for compatibility. A non-null object is allowed only for `engineering_change: bug` and has exactly `actual`, `expected`, `source`, `reproduction`, `root_cause`. The first three are non-empty strings; reproduction is a non-empty ordered list of non-empty steps. Root cause may be null while investigating, but must be a non-empty confirmed cause for current completion. Non-Bug templates do not invent diagnostic evidence. |

Acceptance-criterion IDs are historical identifiers. Do not renumber criteria on a completed Feature. Product evolution creates a new Feature that changes/supersedes the old behavior.

The runner always reads recorded `test_impact` obligations together with the
deterministic Catalog scope. Store approved additions and full-suite reasons
in the Feature itself; there is no second plan file or extra-scope command.
Changing that record requires review of the affected scope and invalidates
prior snapshot evidence.

## File 3: `docs/feature-list-revisions.json`

`sync-feature-list` appends one record for each Product/Coding-Rules synchronization:

Initial content is `{"schema_version": 2, "revision_log": []}`. The root and each
revision entry use schema version 2; no old-format parsing or automatic migration
is provided. Current-format history remains immutable. `engineering-change-standardizer`
does not append a revision merely for creating an engineering Feature without a source change.

New synchronization records use these fields in addition to the existing summary,
anchor and human-readable metadata:

```json
{
  "schema_version": 2,
  "revision_id": "rev-contract-01",
  "revised_at": "2026-05-20T08:30:00Z",
  "anchor_commit": "e25178b",
  "synced_at_commit": "78cfcb9",
  "user_intent": "Revise the inventory contract",
  "summary": "Replace the old behavior and reconnect pending work",
  "migrations": [
    {
      "kind": "revise",
      "from": ["F002"],
      "to": ["F004"],
      "reason": "The approved Product change replaces the earlier contract",
      "source": {"path": "docs/product/02-inventory.md#capacity", "anchor_commit": "78cfcb9"}
    }
  ],
  "dependency_changes": [{"feature": "F003", "before": ["F002"], "after": ["F004"]}]
}
```

`revision_id` is unique and uses letters/digits/dot/dash/underscore. Each migration
requires exactly `kind`, `from`, `to`, `reason`, and `source`; all Feature references
must exist. `source` has exactly repository-relative `path` (optional `#section`)
and `anchor_commit`, which identifies this revision's before or after source commit.
Deleted source paths refer to the before commit; synchronization verifies the real
Git diff. The validator checks the typed relationship, not approval by itself.

| `kind` | Cardinality and action |
| --- | --- |
| `add` | Empty `from`, one or more new `to` IDs. |
| `revise` | One `from`, one `to`. Pending/in-progress work can retain its ID; a completed contract gets a new ID. |
| `split` | One `from`, at least two disjoint new `to` IDs. Keep the source as `obsolete`/`obsolete_done`. |
| `merge` | At least two `from`, one disjoint new `to` ID. Keep the sources as `obsolete`/`obsolete_done`. |
| `retire` | One or more `from`, zero or more disjoint `to` IDs. Keep sources as `obsolete`/`obsolete_done`; removal of implemented behavior requires replacement implementation work. |

Append replacement IDs without renumbering or deleting old entries. Review all
downstream edges during split/merge/revision; no execution ordering belongs only
in prose. `dependency_changes` records unique `feature` entries with unique existing
`before`/`after` IDs. Consecutive recorded changes must chain, and the final `after`
must equal the current index. Feature migration relationships and the actual
dependency graph are separately acyclic. Old summary arrays can remain for readable
history; `migrations` and `dependency_changes` are the machine-readable relationships.

## File 4: `docs/test-catalog.json`

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
    }
  ],
  "tests": [
    {
      "id": "F052-RT01",
      "kind": "regression",
      "source_feature": "F052",
      "criterion_id": null,
      "components": ["inventory"],
      "path": "tests/features/F052/inventory_regression_test.gd",
      "case": "test_f052_rt01_reopen_inventory_after_scene_change",
      "status": "active"
    }
  ]
}
```

Catalog semantics are canonicalized in [08-testing-strategy.md](./08-testing-strategy.md). Test IDs are unique. `kind` is `acceptance`, `regression`, or `invariant`; status is `planned`, `active`, or `retired`. Acceptance/regression tests reference a valid source Feature. Invariant tests have `source_feature: null`.

Catalog schema version 2 is the only supported format. Every retired entry requires
explicit retirement provenance:

```json
{
  "reason": "The approved Product contract supersedes this assertion",
  "source": {"path": "docs/product/02-inventory.md#capacity", "anchor_commit": "78cfcb9"},
  "replacement": {"feature_id": "F004", "test_ids": ["F004-AC01"]},
  "revision_id": "rev-contract-01"
}
```

Store this object under `retirement`, preserving the test's original ID, source
Feature/criterion, and historical path/case. Its source and replacement must match
the referenced version-2 migration (`from` contains the old source Feature; `to`
contains the replacement Feature). Invariant retirements match the source and target
without inventing a source Feature. Replacement test IDs must exist, belong to
the replacement Feature and appear in its AC/regression verification mapping so
the execution plan actually selects them. A replacement may be `planned` while its Feature is
pending/in-progress/blocked; this is a visible coverage gap, never passing evidence.
A completed replacement requires active coverage or another fully traceable retirement
chain. Cycles, missing provenance, missing replacements, and planned coverage owned
by completed/obsolete Features fail validation. Source deletion may remove a retired
test file; active paths must still exist.

`retired.path` may be null if the superseded planned test was never materialized.
Preserve any already-known historical path instead of clearing it. Retirement does
not automatically remove a runnable test function: implementation must deliberately
replace/remove superseded assertions so full discovery executes the current contract.

Completed Feature criteria/test IDs and archived completion evidence are historical
records. Do not rewrite them to simulate current behavior. The active safety net is
selected from current `active` Catalog records. Normal strict validation accepts
historical `done` references to traceably retired tests, but current completion must
pass `python -B tools/checks/check-feature-list.py --completion-feature F0XX`, which
requires that Feature's own mapped automated tests to be active. Completion additionally
requires actual execution evidence; retirement is never a substitute for passing tests.
Retired entries without provenance fail validation; do not invent a reason or
replacement to make them pass.

`unit_test_paths` lists repository-relative paths to existing unit suite files or directories; the example assumes the inventory suite exists. Use `[]` when no unit suite exists, and register new suites only after their approved creation. Missing registered paths are validation errors; `planned` applies to test entries, not future unit suite paths.

## File 5: `docs/gate-evidence.json`

This repository-owned JSON file holds the current Feature's completion evidence.
PASS requires a real result.json, original JUnit/discovery/diagnostics and actual test set matched
against the approved Required/affected/full plan. Caller-supplied pass counts cannot
create PASS. Test and review evidence must match the current semantic snapshot.
Production, tests, configuration, Product, Coding Rules, Feature AC/verification and
Catalog semantics participate in that snapshot. Pure status/completion timestamps,
Feature notes and Progress/history archival do not invalidate business test evidence.

The current evidence schema is version 7. It keeps real test-run references plus
applicable human acceptance and review records. Required/affected/full test
conclusions are calculated from those artifacts rather than persisted again.
Static checks are executed and assessed directly by the Agent, outside this file. The schema is shown in
`methodology/templates/gate-evidence.json.tmpl`; the execution contract is in
[08-testing-strategy.md](./08-testing-strategy.md). The normal command is:

```powershell
python -B .agents/skills/execute-next-feature/scripts/write-gate-evidence.py record-tests --feature F0XX --run reports/gdunit-wrapper/run-<id>/result.json
```

Repeat `--run` when a plan is covered by multiple real runs. An unavailable full
suite is a reported blocker, not a caller-entered PASS.

`.agents/skills/execute-next-feature/scripts/write-gate-evidence.py` records evidence and provides the explicit `validate --feature F0XX` check used before completion. Assistant summaries and a `done` field do not supply missing evidence. No automatic Hook supervises the index edit.

## Bug learning in notes

After successful automated verification and any required human acceptance of an engineering Feature with `engineering_change: bug`, append a concise `BUG learning` block:

```text
BUG learning
Root cause: <causal implementation defect>
Trigger: <minimum precondition>
Regression coverage: <logical regression test ID(s), or approved manual regression reason/check>
Guardrail: <general implementation principle preventing the same defect class>
```

Do not store dead-end debugging transcripts or transient guesses.

## Status transitions

```text
pending ──execute Stage 2──→ in_progress ──Stage 7 after applicable acceptance + review──→ done
   │                              │
   │                              └──explicitly abandoned──→ pending
   ├──source synchronization retires work──→ obsolete
   └──invalid prerequisite──→ blocked

done ──Product evolution removes implemented behavior──→ obsolete_done
```

The `in_progress → done` transition requires the decided acceptance plan to be satisfied, explicit Stage 5 human acceptance for manual mode, successful Stage 4 tests and direct static checks, and structured Stage 6 `must_fix: 0` evidence. The Agent runs the explicit evidence check for the current code snapshot and records the actual result.

## Machine invariants

The final ledger must satisfy all of the following:

- JSON parses for index, revision log, test catalog, and every `F*.json` detail.
- Feature IDs match `F\d{3}`, are unique, and are sequential in index order.
- Index IDs and detail filename stems are exactly one-to-one in final state.
- Detail `id` equals its filename stem.
- `meta.total_features` equals the index count.
- Status and scope values use only allowed enums.
- `completed_at` matches status semantics.
- Dependencies contain no duplicates, all exist, and never reference self; later IDs are valid prerequisites.
- Dependency graph is acyclic.
- `description`, `source`, criterion text, and manual verification items are non-empty strings where present.
- `affected_components` are unique valid component IDs.
- Acceptance criterion IDs are unique and sequential within each newly written Feature.
- Automated acceptance test IDs match the owning Feature/criterion.
- Bug regression test IDs match the owning Feature.
- `notes` is a string.
- `engineering_change`, when present, is one of `bug`, `refactor`, `maintenance`.
- Test-catalog component IDs and test IDs are unique.
- Test-catalog references resolve to existing Features/components.
- A historical `done` Feature's tests remain catalogued as active or traceably retired. Current completion requires active mapped automated tests and real matching execution evidence.
- Version-2 revisions and test retirements satisfy the migration, source, replacement and dependency-chain rules above.

Run the final strict validator from the repository root:

```powershell
python -B tools/checks/check-feature-list.py
```

During normal editing, the Agent can update related files together before running the explicit checker. The command always checks the complete ledger; it is not registered as a per-edit Hook.

## Product-by-Product planning

Decompose one Product at a time in the actual execution order. In the current
document layout, the planning unit is one `docs/product/NN-<module>.md` module
with its currently approved scope. `docs/product.md` provides the overview,
dependencies and intended order; file numbers are stable identities, not a
command to execute or plan every module at once.

1. Identify the current Product from the user's request, Product order and
   existing Feature `source`/status records. Read relevant Progress for context.
   Resolve an ambiguous scope or unfinished prerequisite before decomposing.
2. Decompose the current Product's required behavior into complete, verifiable
   Features. Include only infrastructure needed to deliver that scope; reuse
   existing infrastructure and completed prerequisite Features. If another
   Product must be delivered first, correct the order rather than pre-planning
   both Products.
3. Leave later Products at the Product-document level. They may already have
   descriptions, but do not allocate their Feature IDs, detailed Feature AC or test
   registrations yet. Read them only as needed to understand dependencies.
4. Finish the current Product's required Features before decomposing the next
   Product. Check actual Feature completion and outstanding scope: no eligible
   task, an empty plan, or a Product document marked `done` does not prove
   implementation is complete. `pending`, `in_progress` and `blocked` work is
   unfinished; explicitly withdrawn scope follows existing retirement rules.
5. After completion, revisit the next Product against what was learned and its
   current requirements, then decompose it under the user's existing planning
   authorization. Feature delivery still stops at Stage 8; completion alone
   does not authorize automatically planning or implementing the next Product.

`generate-feature-list` handles the first and each subsequent Product's initial
decomposition by appending to the same ledger. Allocate IDs after the greatest
existing ID; preserve previous Features, test Catalog records and revision
history. If the selected scope already has a plan, reuse it; changed requirements
use `sync-feature-list` rather than duplicating or regenerating that plan.

`sync-feature-list` still analyzes effects on existing work, including completed
behavior and real downstream dependencies. Changes to a later, unplanned Product
do not create Features now. When that Product becomes current, generation reads
its complete current specification, even if its edits predate the latest sync
anchor. Do not interpret a global source anchor as proof that every Product has
been decomposed. `meta.generated_from` names source locations, not coverage.

Use the existing Product order, Feature sources/statuses and ordinary Progress
notes. Do not add a Product queue, registry, completion flag or duplicate ledger.
Pre-existing plans remain intact; this rule does not authorize deleting future
Features or rewriting completed history.

## Decomposition rules

1. Each Feature is the smallest independently verifiable complete behavior or engineering outcome.
2. Plan only the current Product under the rule above; reuse or establish the runnable infrastructure it needs, then follow its Feature dependencies.
3. Final Features are `small` or `medium`; decompose `large` work.
4. Product-derived Features do not invent behavior absent from Product documents.
5. Engineering Features preserve Product intent unless a separate Product change has been approved.
6. Each Feature declares semantic `affected_components`; keep the set minimal and meaningful.
7. New acceptance criteria receive stable `ACxx` identifiers in order.
8. A `bug` Feature requires regression coverage when deterministic automation is feasible; an explicit repeatable human regression check is allowed only with a concrete reason automation is impractical.
9. `refactor` Features state behavior-preservation evidence.
10. `maintenance` Features state the technical success condition and compatibility/invariant to preserve.

## Ownership

| Operation | Owner | Main files changed |
| --- | --- | --- |
| Initial decomposition of the current Product | `generate-feature-list` | append index/details and needed components; initialize missing revision log/catalog, preserve existing history |
| Product/Coding-Rules synchronization | `sync-feature-list` | index/details + revision log + affected test traceability |
| Bug/refactor/maintenance Feature creation | `engineering-change-standardizer` | index + engineering details; test plan is finalized during execution |
| Feature execution and completion notes | `execute-next-feature` | status, verification mapping, test catalog, notes, Progress, implementation/test files |
| Smell candidate selection | `pick-refactor-smell` | read-only selection; returns to engineering standardizer |
