# 02 · Feature-list and test-traceability schema

## Structure

```text
docs/
├── feature-list.json
├── features/
│   ├── F001.json
│   ├── F001-design.md       # Optional detailed design for this Feature
│   ├── F002.json
│   └── ...
├── feature-list-revisions.json
├── test-registry.json
└── feature-completion-evidence.json
```

The Feature index stays lightweight. Each per-Feature detail file holds the Feature's behavior, stable acceptance-criterion IDs, component impact, verification mapping, engineering classification and notes. `docs/test-registry.json` is the machine-readable index that maps components to reusable tests. Human-readable values use `document_language`; machine protocol fields stay unchanged.

Project creation supplies the index, the revision log and the Test Registry with empty arrays. All three files are required even before the first Feature is planned. A missing file is a repair issue; do not replace lost records with a newly initialized ledger.

## File 1: `docs/feature-list.json`

```json
{
  "meta": {
    "generated_from": [
      "docs/gdd/**/*.md",
      "docs/product.md",
      "docs/product/**/*.md",
      "docs/project-rules.md"
    ],
    "generated_at": "2026-05-23T05:46:48Z",
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
| `id` | Exactly `F` plus three digits. The index lists IDs in sequence from `F001` without gaps. An ID is never reused. |
| `title` | Non-empty, human-readable verb phrase. |
| `status` | `pending`, `in_progress`, `done`, `obsolete`, `obsolete_done` or `blocked`. |
| `depends_on` | Unique IDs of existing Features, not including the Feature itself. A prerequisite may have a larger ID. The dependency graph must be acyclic. |
| `estimated_scope` | `small` or `medium`. Decompose larger work before writing the final plan; the validator rejects `large`. |
| `completed_at` | A valid ISO 8601 timestamp when the status is `done` or `obsolete_done`; otherwise `null`. |

Derive Feature counts from the `features` array. The detail files, the revision log and the Test Registry use the fixed paths shown in [Structure](#structure); the index metadata does not repeat these paths.

Feature IDs record the order of allocation, not the order of execution:

- A `pending` Feature is eligible when all of its prerequisites are `done`. Among eligible Features, ID order only breaks ties.
- `python -B tools/checks/check-feature-list.py --eligible` validates the ledger and prints the eligible set as JSON.
- A `pending`, `in_progress` or `blocked` Feature cannot depend on an `obsolete` or `obsolete_done` Feature. Synchronization reconnects it to the replacement.
- The dependencies of completed Features stay unchanged as history.

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
| `id` | Matches the index entry and the filename stem. |
| `description` | Non-empty observable outcome. A Product-derived Feature describes what the player or user gets. An engineering Feature states the technical repair or maintenance outcome without workflow state. |
| `affected_components` | Non-empty array of unique, stable `lower_snake_case` component or domain IDs. Use semantic components, not file paths. |
| `acceptance_criteria` | Non-empty array of criterion objects. Each object has an `ACxx` ID, non-empty `text` and a `verification` object. Plain strings are not valid criteria. Criterion IDs are unique and increase in list order. Numbers may be skipped where a criterion was removed, and a removed number is never reused. |
| `acceptance_criteria[].verification.automated_tests` | Unique acceptance-test IDs in the form `F0XX-ACyy` or `F0XX-ACyy-NN`, where `F0XX` is this Feature and `ACyy` is this criterion. |
| `acceptance_criteria[].verification.manual_checks` | Unique, non-empty, concrete checks from the manual acceptance plan. Empty for an automated plan. This list follows from the mode; it does not decide it. |
| `verification.acceptance_mode` | `manual`, `automated` or `null`. See [Acceptance mode](#acceptance-mode). |
| `verification.regression_tests` | Unique regression-test IDs created by this Feature, in the form `F0XX-RTyy` with this Feature's ID. Empty for a Feature that is not a Bug, unless a reason is stated. |
| `verification.manual_regression` | `null` when an automated regression exists or no Bug regression applies. Otherwise a concrete, repeatable manual regression check and the reason automation is impractical. A non-null value requires `acceptance_mode: "manual"`. |
| `verification.test_impact` | Optional; omit it when no extra test scope is needed. When present, it has exactly `additional_tests` and `full_suite_reasons`; the templates include both. Stage 2 stores the approved extra scope here before the final test run. This field is part of the snapshot fingerprint. |
| `verification.test_impact.additional_tests` | Array of `{ "id": "...", "reason": "..." }` objects with unique Registry test IDs and non-empty reasons. An entry may name another Feature's test. A referenced test may be `planned` during preparation but must be `active` when this Feature completes. An addition does not change test ownership and does not replace this Feature's own AC and regression mapping. |
| `verification.test_impact.full_suite_reasons` | Unique, non-empty reasons for an approved full-suite run beyond the automatic triggers. A component with `full_suite_on_change: true` triggers the full suite automatically and is not listed here. An empty array records no extra escalation. |
| `source` | One precise primary source: a Product delivery section, a GDD section or a professional specification. Use `infrastructure` for technical work without a single source document. See the source rules below. |
| `notes` | A string that starts empty. It holds task reminders, placeholders, TODOs, deferred edge cases, brief Bug learning and relative links to the Feature design or other records. Implementation decisions and their rationale go in the [Feature design](#feature-design-and-implementation-notes), whatever their length. |
| `engineering_change` | Optional. When present, exactly `bug`, `refactor` or `maintenance`. Product-derived Features omit it. |
| `bug_diagnosis` | Allowed only with `engineering_change: bug`; otherwise `null` or omitted. The object has exactly `actual`, `expected`, `source`, `reproduction` and `root_cause`. `actual`, `expected` and `source` are non-empty strings. `reproduction` is a non-empty ordered list of unique, non-empty steps. `root_cause` may be `null` during investigation. Every `done` Bug, and the Bug being completed, needs a non-empty confirmed `root_cause`. Features that are not Bugs do not invent diagnostic evidence. |

Criterion IDs are permanent identifiers. Do not renumber the criteria of a completed Feature. A later change in Product behavior creates a new Feature that changes or supersedes the earlier behavior.

### Acceptance mode

Stage 1 decides `verification.acceptance_mode` from the confirmed GDD design, Product delivery scope and professional or engineering intent, before filling the verification lists:

- `manual`: required when any criterion depends on human perception or judgment, such as visual presentation, animation feel, audio, sound, music or game feel. At least one criterion has `manual_checks`, or `manual_regression` is set. A manual plan may also map automated tests.
- `automated`: allowed only when every criterion can be verified automatically. Every criterion then lists at least one automated test, no criterion has `manual_checks`, and `manual_regression` is `null`. A Bug that uses a manual regression check therefore uses `manual`.
- `null`: an undecided draft. A `done` Feature, or the Feature being completed, cannot have `null`.

Empty lists and earlier PASS results do not decide the mode. Stage 1 explains the decision in its approval packet; Stage 5 applies only to `manual`.

### Sources

GDD and professional requirements go through the same planning, impact review and AC mapping under [Discover and map sources](11-specialist-workflows.md#discover-and-map-sources):

- A Product-derived Feature uses its current Product delivery section as `source` and links the relevant GDD design from its AC or design.
- Secondary sources are linked from the AC or design. Do not add a JSON field for them or put several paths into `source`.
- The validator only checks that `source` is non-empty text. The planning Agent verifies that the source exists, has authority and covers the Feature.
- A binding requirement never exists only in `notes`, which hold process information.

### Recorded test impact

The runner always combines the recorded `test_impact` with the scope it derives from the Registry. Store approved additions and full-suite reasons only in the Feature detail; do not create a separate plan file or extra-scope command. A change to `test_impact` requires a review of the affected scope and invalidates earlier snapshot evidence.

## Feature design and implementation notes

`docs/features/F0XX-design.md` is the fixed location for the Feature's implementation design, local technical decisions and their rationale. This includes boundaries, state ownership, lifecycle, migration, interfaces and applied constraints.

- Save such content here even when it is short. Do not put a shorter version in JSON `notes`, and do not choose another document based on complexity.
- `notes` hold reminders and the relative link `[Design](F0XX-design.md)`.
- Create the file when there is design content to save; an empty file is not required. Do not add another JSON record or design-status ledger.
- Stage 0 reads the designs of the selected Feature and of relevant dependencies.

The `implementation-guidance-godot` Skill writes requested guidance for a Feature into this same file, including for an engineering Feature. The main Agent may prepare the guidance itself; delegating it to an advisor requires the explicit authorization defined in that Skill. Work without a Feature follows [Standalone technical decisions](10-architecture-overview.md#standalone-technical-decisions), not an artificial Feature or a separate guide under `reports/`.

The design explains this change:

- the goal and boundaries, with links to the Product and AC;
- the relevant current behavior;
- the rules that materially constrain the change, and how they apply;
- responsibilities, interfaces and state ownership;
- important runtime, failure and lifecycle flows;
- the necessary implementation order and the reasoning behind the verification;
- the actual outcome and meaningful deviations.

Describe necessary dependencies, not a function-by-function recipe; ordinary implementation details remain with the implementing Agent. Give useful explanations the length they need. [feature-design.md.tmpl](templates/feature-design.md.tmpl) is an optional outline; omit sections that do not apply.

For a game function, the design records the result of the Stage 1 check against `docs/game-organization.md`: who owns the relevant business state, which state is local to presentation, and what requests, current state and one-time events mean. When animation timing affects gameplay, the design names the timing input, the interruption conditions and who decides the valid result. Explain only the contracts relevant to this change. The model requires neither separate objects nor a global event bus.

Link repository rules and records with paths relative to the design document, with useful section anchors. Explain how they apply instead of copying rule text or listing every file read. For a version-sensitive external reference, name the applicable version and separate evidence from assumptions. The design links the following records instead of repeating them:

- AC, component impact and test mappings stay in the Feature JSON and the Test Registry.
- Task state and blockers stay in Progress.

The design may also explain additional scoped measurement, duration, display or listening obligations under [Specialist work and sources](11-specialist-workflows.md).

Stage 1 prepares the design as a proposal, Stage 2 saves the approved design, and Stage 3 keeps it aligned with the implementation. These steps are defined in [Stage 1C](03-execute-loop.md#1c-design-decisions-and-guidance), [Stage 2](03-execute-loop.md#stage-2--mark-in_progress-and-persist-verification-plan) and [Stage 3](03-execute-loop.md#stage-3--baseline-tdd-and-implementation).

When the authorized task only delivers guidance:

- Prepare the proposal as in Stage 1C and save the approved design as in Stage 2, without running the rest of Stage 2.
- Saving the approved design does not authorize implementation or changes to the Feature status, verification plan or Registry.
- The owner of the original task maintains the `notes` link within the authorized scope, then ends with the requested guidance.

An implementation task still saves its approved design in Stage 2.

A detailed description of a current subsystem belongs in `docs/architecture/<subsystem>.md`, and an important cross-Feature rationale may belong in an ADR. The Feature design links them. Do not copy the same subsystem description into each Feature.

After completion, the design remains the record of that Feature. A later behavior change gets a new Feature and design, and updates the current architecture. Corrections or replacement links may clarify the record, but do not rewrite past decisions as if they had always applied. Design Markdown is part of the verification fingerprint; it does not share the exemption of JSON `notes`.

## File 3: `docs/feature-list-revisions.json`

- `feature-plan` writes the [initial planning baseline](#initial-planning-baseline).
- `feature-sync` appends one record for each later synchronization with GDD, Product, professional or Project Rules sources.
- `engineering-change-plan` does not append a record when it only creates an engineering Feature without a source change.

The initial content is `{"schema_version": 2, "revision_log": []}`. The root and every entry use `schema_version: 2`. Only schema version 2 (3 for the Registry) is valid; the tools do not read or convert other formats. Recorded entries are never rewritten.

### Initial planning baseline

Write this baseline with the first Product plan when both the Feature index and the revision log were empty before that plan. An empty copied project, or an engineering Feature alone, does not establish source coverage. When resuming an interrupted first planning task, confirm the same empty starting state and the adopted source revision from the task context and Git history. An empty revision log alone does not prove them.

1. Before writing the plan, make sure every adopted GDD, Product, professional and rule source is committed through its own workflow and authorization.
2. Resolve the source HEAD as a full commit hash. If the sources cannot be committed, or their adopted state is unclear, report the missing prerequisite. Do not use the scaffold commit instead.
3. After checking the semantic coverage of the written plan, append the entry below. Include it in the final ledger validation and in the plan commit.
4. Before finalizing, confirm that the adopted source contents still match the recorded commit.

| Field | Initial value |
| --- | --- |
| `revision_id`, `schema_version` | `R000`, `2` |
| `anchor_commit`, `synced_at_commit` | The same verified full source HEAD hash adopted by this plan |
| `revised_at`, `user_intent` | The actual timestamp; the supplied planning intent or `null` |
| `summary`, `added` | Prose describing the initial baseline, the current Product and the coverage and limits of the adopted sources; the IDs of the Features this plan adds |
| `migrations`, `dependency_changes` | Empty arrays; this entry records initial planning, not a source change |

Do not create a self-referencing plan commit, a separate baseline file or a new schema field. The baseline covers only the planned scope and the sources actually adopted, not every Product or every file at HEAD.

Later Product planning keeps the whole revision log and never moves the anchor forward, because that would hide unsynchronized changes to earlier work. Keep a recorded baseline when resuming. When the ledger already contains Features but has no baseline, do not add `R000` just because the log is empty. `feature-sync` then verifies the earlier coverage or performs an authorized alignment with the current documents.

### Synchronization records

`feature-sync` determines which source state a plan actually absorbed and handles a missing baseline. Editing a Feature file alone does not establish a source baseline. The record fields store the result:

- A normal record names the compared source states: `anchor_commit` is the state before the change and `synced_at_commit` is the state after it.
- When an approved alignment with the current documents replaces an unknown history, both fields name the inspected HEAD, and `summary` states this limitation. This sets the next baseline without claiming an earlier diff.

A GDD or professional source that enters the plan for the first time needs the same coverage check, even when its file predates the recorded anchor; see [Discover and map sources](11-specialist-workflows.md#discover-and-map-sources).

A synchronization record has these fields:

```json
{
  "schema_version": 2,
  "revision_id": "rev-contract-01",
  "revised_at": "2026-05-20T08:30:00Z",
  "anchor_commit": "e25178b4c0d2a9f61b3e7c58d0a4f92e6b1c3d70",
  "synced_at_commit": "78cfcb91a6e04d2b8f3c7a59e1d06b4c2f8a9e35",
  "user_intent": "Revise the inventory contract",
  "summary": "Replace the superseded behavior and reconnect pending work",
  "migrations": [
    {
      "kind": "revise",
      "from": ["F002"],
      "to": ["F004"],
      "reason": "The approved GDD change replaces the earlier contract",
      "source": {"path": "docs/gdd/inventory.md#capacity", "anchor_commit": "78cfcb91a6e04d2b8f3c7a59e1d06b4c2f8a9e35"}
    }
  ],
  "dependency_changes": [{"feature": "F003", "before": ["F002"], "after": ["F004"]}]
}
```

A record may also carry readable summary fields next to the typed relationships. Keep their shapes when synchronization updates them:

| Summary field | Shape |
| --- | --- |
| `added`, `obsoleted`, `depends_on_warnings` | Arrays of affected Feature IDs |
| `revised_via_new_feature` | Array of `{ "original": "F0XX", "regression": "F0YY" }` |
| `source_path_updates` | Array of `{ "feature": "F0XX", "from": "product/old-path.md", "to": "product/new-path.md" }` |

Field rules:

- `revision_id` is unique and uses letters, digits, dots, dashes and underscores.
- `anchor_commit` and `synced_at_commit` are Git commit identifiers, `revised_at` is an ISO 8601 timestamp, and `summary` is non-empty.
- Each migration has exactly `kind`, `from`, `to`, `reason` and `source`. Every Feature ID it names must exist.
- A migration `source` has exactly `path` and `anchor_commit`. `path` is repository-relative and may end with `#section`. `anchor_commit` equals the record's `anchor_commit` or `synced_at_commit`; a deleted source path refers to the commit before the change.
- Synchronization verifies the real Git diff. The validator checks the typed relationship, not whether it was approved.

| `kind` | Cardinality and action |
| --- | --- |
| `add` | Empty `from`; one or more `to` IDs. |
| `revise` | One `from` and one `to`. A pending or in-progress Feature can keep its ID; a completed contract gets a new ID. |
| `split` | One `from`; at least two appended `to` IDs, disjoint from `from`. The source stays as `obsolete` or `obsolete_done`. |
| `merge` | At least two `from`; one appended `to` ID, disjoint from `from`. The sources stay as `obsolete` or `obsolete_done`. |
| `retire` | One or more `from`; zero or more `to` IDs, disjoint from `from`. The sources stay as `obsolete` or `obsolete_done`. Removing implemented behavior requires replacement implementation work. |

Append replacement IDs; never renumber or delete entries. During a split, merge or revision, review all downstream dependency edges; an execution order must not exist only in prose.

- `dependency_changes` has at most one entry per `feature`. Its `before` and `after` lists contain unique, existing IDs and never the Feature itself.
- Successive changes for the same Feature must chain: each `before` equals the previous `after`. The latest `after` equals the current `depends_on`.
- The migration relationships and the dependency graph must each be acyclic.

Readable summary arrays may stay as history; `migrations` and `dependency_changes` are the machine-readable relationships.

## File 4: `docs/test-registry.json`

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
    }
  ],
  "tests": [
    {
      "id": "F052-RT01",
      "components": ["inventory"],
      "path": "tests/features/F052/inventory_regression_test.gd",
      "case": "test_f052_rt01_reopen_inventory_after_scene_change",
      "status": "active"
    }
  ]
}
```

| Field | Requirement |
| --- | --- |
| `meta.schema_version` | Integer `3`. Only schema version 3 (2 for the revision log) is valid; the tools do not read or convert other formats. |
| `components[].id` | Unique `lower_snake_case` component ID. |
| `components[].unit_test_paths` | Unique paths of existing unit-suite files or directories; `[]` when the component has no unit suite. The example assumes that `tests/unit/inventory` exists. |
| `components[].full_suite_on_change` | Boolean. |
| `tests[].id` | Unique logical test ID. Its format identifies the test's kind, owning Feature and criterion; do not store these in separate fields. The owning Feature must exist. |
| `tests[].components` | Non-empty array of unique component IDs from `components`. |
| `tests[].path` | Path of the test file. Required and existing when the status is `active`; `null` or a path when `planned` or `retired`. |
| `tests[].case` | `null` or a non-empty test case name. |
| `tests[].status` | `planned`, `active` or `retired`. |
| `tests[].retirement` | Required when the status is `retired` and not allowed otherwise; see [Retired tests](#retired-tests). |

Registry paths are repository-relative and have no `res://` prefix. Unit-suite paths and active test paths must stay inside the repository after resolution. Registration and selection reject absolute paths, drive-qualified paths, `..` segments and links that resolve outside the repository.

The ID formats and what these fields mean for test selection, registration timing and completion are defined in [Registry rules](08-test-traceability-and-evidence.md#registry-rules).

### Retired tests

A `retired` entry keeps its original ID, and therefore its owning Feature and criterion, plus its historical `path` and `case`. Its `retirement` object has exactly these fields:

```json
{
  "reason": "The approved GDD contract supersedes this assertion",
  "source": {"path": "docs/gdd/inventory.md#capacity", "anchor_commit": "78cfcb91a6e04d2b8f3c7a59e1d06b4c2f8a9e35"},
  "replacement": {"feature_id": "F004", "test_ids": ["F004-AC01"]},
  "revision_id": "rev-contract-01"
}
```

The validator checks the retirement chain:

- `revision_id` names a schema-version-2 revision. One of its migrations has the same `source` and lists `replacement.feature_id` in `to`. For a Feature-owned test, that migration also lists the owning Feature in `from`. An invariant test has no owning Feature, so only the source and the replacement must match.
- `replacement.test_ids` is non-empty and does not contain the retired test. Every replacement test exists in the Registry, belongs to `replacement.feature_id` and appears in that Feature's AC or regression mapping, so the execution plan actually selects it.
- A replacement test may be `planned` only while its Feature is `pending`, `in_progress` or `blocked`. This is a visible coverage gap, never passing evidence. A completed replacement Feature needs active coverage or another fully traceable retirement chain.
- Retirement chains cannot form cycles. Missing provenance or a missing replacement fails validation; do not invent a reason or a replacement to make it pass.

A `planned` test whose owning Feature is `done`, `obsolete` or `obsolete_done` also fails validation. When a Feature is retired without replacement, remove its `planned` Registry entries, which were never implemented.

A retired test's `path` may be `null` when the superseded test was never written. Keep a known historical path instead of clearing it. Deleting the source may remove a retired test file. Retirement does not remove a runnable test function: the implementation deliberately replaces or removes superseded assertions so that full discovery runs the current contract.

An approved revision of a `pending` or `in_progress` Feature may remove a criterion from the current detail. The remaining and added criteria keep increasing IDs and leave the removed number unused, so a later criterion never takes over a retired test ID.

- A retired acceptance test keeps the criterion encoded in its ID; that criterion does not need to stay in the current detail. The test's owning Feature and its complete retirement chain must still validate.
- `planned` and `active` acceptance tests must refer to a current criterion.
- This does not permit rewriting a completed Feature or treating planned replacement tests as passed.

The criteria, test IDs and archived completion evidence of a completed Feature are historical records. Do not rewrite them to imitate current behavior. Which tests form the active safety net, and which statuses a completing Feature may reference, are defined in [Registry rules](08-test-traceability-and-evidence.md#registry-rules).

## File 5: `docs/feature-completion-evidence.json`

This file holds the current Feature's completion evidence in schema version 8; the shape is shown in [the template](templates/feature-completion-evidence.json.tmpl). Write it only through `tools/features/record-feature-completion.py`, and check it with its `validate --feature F0XX` command. What counts as evidence, when the result is `not_required`, and when evidence becomes stale are defined in [Artifact-backed completion and semantic freshness](08-test-traceability-and-evidence.md#artifact-backed-completion-and-semantic-freshness).

## Bug learning in notes

After successful automated verification and any required human acceptance of a Feature with `engineering_change: bug`, append a concise `BUG learning` block with [the canonical fields](07-engineering-change.md#bug-learning-promotion).

Do not store dead-end debugging transcripts or transient guesses.

## Status transitions

```text
pending ──execute Stage 2──→ in_progress ──Stage 7 after applicable completion checks──→ done
   │                              │
   │                              └──explicitly abandoned──→ pending
   ├──source synchronization retires work──→ obsolete
   └──invalid prerequisite──→ blocked

in_progress ──source synchronization retires work──→ obsolete

blocked ──prerequisite validity restored──→ pending
blocked ──source synchronization retires work──→ obsolete

done ──source synchronization retires or replaces implemented behavior──→ obsolete_done
```

`blocked` marks a `pending` Feature whose required source decision, input or dependency contract is invalid or unavailable.

- Record the concrete blocker and the recovery condition in the detail `notes`.
- `blocked` does not permit broken dependency IDs or obsolete prerequisites.
- A valid Feature that waits for an unfinished dependency stays `pending`; it is simply not eligible yet.
- A Feature already `in_progress` keeps that status and records its blocker in the current execution record. Do not switch it to `blocked`, which would discard its execution state.

During authorized synchronization or continuation, recheck the recorded blocker against the current sources and dependencies:

- A revision may update blocked work, and a dependency replacement must include it.
- Restore `blocked` to `pending` only when the recorded prerequisite is valid and available again, and append the reason to `notes`. The usual check that all prerequisites are `done` then applies.
- Restoration alone does not start execution or establish completion.
- A confirmed withdrawal uses `obsolete` and keeps the original blocker and the retirement reason as history.

The `in_progress → done` transition follows Stage 7 of [the execution loop](03-execute-loop.md). It requires the decided acceptance plan, the applicable tests and direct static checks, and any explicit user review condition. Independent review is optional under Stage 6, and the completion record contains no review counts. The Agent runs the explicit evidence check for the current code snapshot and records the actual result.

## Machine invariants

Field rules are listed in the tables above. `python -B tools/checks/check-feature-list.py` also checks these rules across fields and files:

- **Files:** the index, the revision log and the Registry exist. They and every `docs/features/F*.json` parse as JSON without duplicate keys.
- **Index and details:** the set of index IDs equals the set of detail filename stems, and each detail `id` equals its filename stem.
- **Dependencies:** every prerequisite exists and is not the Feature itself, and the graph is acyclic. A `pending`, `in_progress` or `blocked` Feature cannot depend on an `obsolete` or `obsolete_done` Feature.
- **Components:** every `affected_components` ID exists in the Registry `components`.
- **Test references:** every test ID in a detail's `automated_tests`, `regression_tests` or `test_impact.additional_tests` exists in the Registry. The Feature encoded in a Registry test ID exists. A `planned` or `active` acceptance test refers to a current criterion of its Feature.
- **Planned tests:** a `planned` test cannot belong to a `done`, `obsolete` or `obsolete_done` Feature.
- **Registry:** `meta.schema_version` is the integer `3`. Every `unit_test_paths` entry and every `active` test path exists inside the repository. `full_suite_on_change` is a boolean.
- **Acceptance mode:** when the mode is decided, the checks match it under [Acceptance mode](#acceptance-mode). `automated` has an automated test for every criterion, no `manual_checks` and no `manual_regression`; `manual` has at least one `manual_checks` entry or a `manual_regression`.
- **Test impact:** `test_impact`, when present, has exactly `additional_tests` and `full_suite_reasons`.
- **Done Features:** a `done` Feature has a decided `acceptance_mode`. Every test it references is `active` or traceably `retired`.
- **Done Bugs:** a `done` Bug has `regression_tests` or a `manual_regression`, and a non-empty `bug_diagnosis.root_cause`.
- **Revisions and retirements:** the rules in [File 3](#file-3-docsfeature-list-revisionsjson) and [Retired tests](#retired-tests).

`--completion-feature F0XX` applies the done rules to the Feature being completed and also requires every test it references, including additional tests, to be `active`.

The test selection in `tools/lib/test_selection.py`, used by the runner and by `record-feature-completion.py`, additionally requires at the final phase that every criterion has at least one automated test or manual check.

Run the strict validator from the repository root after editing related files together:

```powershell
python -B tools/checks/check-feature-list.py
```

It always checks the complete ledger.

## Product-by-Product planning

Apply the [GDD prerequisite](01-product-doc-structure.md#gdd-prerequisite-and-authority). Pre-decompose the agreed delivery horizon in `docs/product.md`, then detail and deliver one Product at a time in the actual execution order.

- The Feature planning unit is the current `docs/product/NN-<delivery>.md`, with its approved scope and GDD references.
- `docs/product.md` holds candidate boundaries, source mapping, dependencies and the suggested order.
- File numbers are stable identities. They do not mean that every Product is detailed or planned at once.

1. Identify the current Product from the user's request, the pre-decomposition order and the `source` and status of existing Features. Read relevant Progress for context. Revisit the applicable GDD design and the actual results of earlier deliveries. Then use `product-author` to write or update this Product's delivery document within the current authorization. Resolve unclear scope and necessary cross-system rules before decomposing; do not detail future Products to settle one shared rule.
2. Decompose the current Product's complete necessary scope into independently verifiable Features in one planning pass. Include only the infrastructure needed for that scope, and reuse available infrastructure and completed prerequisite Features. If another Product must be delivered first, correct the order instead of planning both Products ahead.
3. Leave later Products as concise pre-decomposition entries in `product.md`. Do not write their detailed delivery documents, allocate their Feature IDs, or write their AC or test registrations. Read their GDD dependencies only as needed for current decisions.
4. Finish the current Product's required Features before decomposing the next Product. Check actual Feature completion and remaining scope. Having no eligible Feature, an empty plan, or a Product document marked `done` does not prove that implementation is complete. `pending`, `in_progress` and `blocked` work is unfinished; explicitly withdrawn scope follows the retirement rules.
5. After completion, revisit the next candidate against the current GDD and what was learned. Adjust the pre-decomposition if needed, write that Product's delivery document, and then decompose it within the current authorization. Stage 8 follows [Authorization and continuation](03-execute-loop.md#authorization-and-continuation); completion alone does not authorize planning or implementing the next Product.

`feature-plan` writes the initial decomposition of the first and of each later Product by appending to the same ledger. It allocates IDs after the greatest ID in use and keeps the earlier Features, Registry records and revision history. If the selected scope already has a plan, reuse it; changed requirements go through `feature-sync` instead of a duplicated or regenerated plan.

`feature-sync` analyzes changes to GDD, Product, professional and Project Rules sources against planned and completed work, including actual downstream dependencies.

- A change that affects only a later, unplanned candidate updates its pre-decomposition as needed. It does not create detailed Product documents or Features.
- When that candidate becomes current, read its full applicable GDD and professional design, even if those edits predate the latest synchronization anchor.
- A global source anchor does not prove that every Product has been detailed or decomposed. `meta.generated_from` names source locations, not coverage.

Use the Product order, the Feature sources and statuses, and ordinary Progress notes. Do not add a Product queue, registry, completion flag or second ledger. This rule keeps earlier plans intact; it does not authorize deleting future Features or rewriting completed history.

### Decomposition preview

For each current Product's initial decomposition, present a concise preview in the conversation before writing its Feature index entries, details, revision log or Test Registry, including component merges. This also applies when Product writing or the adoption of existing implementation calls planning. Present the preview as part of the planning proposal:

- Identify the Product and its approved scope. State the number of Features to add and the ledger total before and after. Distinguish reused work from added entries. Derive the count from complete outcomes, not a preset quota.
- List every proposed Feature in a compact table or list: provisional label, title, one-sentence scope and observable result, and prerequisites. State the reason for the chosen granularity and any exclusions or unresolved choices.
- Include the [requirement coverage review](#requirement-coverage-review) in the same proposal; the preview does not replace coverage review or detailed AC.

By default, wait for the user's confirmation of this concrete decomposition before these writes. Approval of the Product intent, or a general request to plan or implement, does not approve a decomposition the user has not seen. Reuse a confirmed, unchanged proposal across turns; do not ask for the same decision again. If the count, work boundaries or dependencies change materially, refresh the preview and resolve the changed decision before writing.

When the user explicitly authorizes autonomous decomposition and continuation within a defined scope, show the preview before writing and continue without another approval. A Goal that grants this authority counts; using Goal mode alone does not. This exception also covers refreshed previews within that authorization. Missing Product decisions and scope changes still require the user's decision.

After the writes and validation, refresh the same proposal with the actual IDs, counts and remaining work. Accepting the preview authorizes recording the plan; it does not authorize further implementation or replace human acceptance. Do not add a preview file, approval field or status; the ledger validator does not check this step.

## Adopting existing implementation

When implementation exists before its Product or Feature records, a substantive GDD is still required before delivery planning.

- If the GDD is missing, return the design gap to `design-gdd` within the user's scope. The code can inform that work but cannot silently become approved design.
- Use `product-author` to set the current delivery boundary from sufficiently clear design. Resolve approved game-design changes through `design-gdd` and scoped numerical changes through `design-balance`.
- Apply Product-by-Product planning to the requested current delivery. Existing implementation does not waive prerequisite completion or widen the planning horizon. Keep later candidates at the pre-decomposition level.

Reuse a Feature that already covers the outcome. If none covers it, create ordinary Product-derived Features around independently verifiable outcomes, not around imagined historical coding steps or one Feature per source file. Derive AC from confirmed intent. In the normal requirement coverage review, map each criterion to the implementation, usable tests and remaining gaps. Do not weaken AC to fit a defect, or create duplicate work just to rerun tests.

Records created this way start with `status: "pending"` and `completed_at: null`. In `notes`, state that the implementation predates formal recording, link the verified files, commits and decisions, and name the remaining implementation or verification. Missing history stays unknown; do not invent earlier Features, approvals, RED runs or acceptance dates. Keep completed records and their evidence under the normal evolution rules.

A documentation-only task stops after the authorized Product and plan writes, their required checks and commits. Report the implemented scope separately from formal completion. Authorized delivery uses [Delivery of existing implementation](03-execute-loop.md#delivery-of-existing-implementation) to verify and finish from the current state. Do not add a status, adoption ledger or evidence format for this case.

## Decomposition rules

1. Each Feature is the smallest independently verifiable complete behavior or engineering outcome.
2. Plan only the current Product under the rule above. Reuse or establish the runnable infrastructure it needs, then follow its Feature dependencies.
3. Final Features are `small` or `medium`; decompose larger work.
4. Product-derived Features implement their Product delivery scope from confirmed GDD and professional sources; they do not invent missing design rules.
5. Engineering Features preserve the GDD design and the approved delivery intent unless the substantive change has been approved through its own route.
6. Each Feature declares semantic `affected_components`; keep the set minimal and meaningful.
7. Each criterion gets a stable `ACxx` ID, increasing in list order.
8. A `bug` Feature requires regression coverage when deterministic automation is feasible. An explicit, repeatable human regression check is allowed only with a concrete reason why automation is impractical.
9. `refactor` Features state the evidence that behavior is preserved.
10. `maintenance` Features state the technical success condition and the compatibility or invariant to preserve.

Check each proposed outcome for a concrete precondition, action or engineering check, and an observable result. A class, file or layer name alone does not make a complete Feature. A technical outcome can be independently verifiable without a player-facing interface; do not force every Feature to include UI, persistence and every code layer.

Presentation-only, logic-only and cross-layer describe scope; they are not Feature types or fields. One Feature may deliver shop-purchase rules, interface feedback and their connection when that is a coherent, bounded outcome. State the rule result, the perceptual result and the integration checks in its AC, design and verification plan. Split only for independently verifiable outcomes or real dependencies. The two-layer model does not require separate Features or a logic-first implementation order.

For each `depends_on` entry, identify what the prerequisite supplies: a capability, a contract, a running foundation or an accepted decision. Ask whether the current Feature could still be completed and verified correctly without it. Keep actual dependencies and applicable architecture constraints; do not encode numbering or a preferred sequence as a dependency. Explain dependencies that are not obvious in the decomposition preview or the Feature design, without adding schema fields or a separate checklist. Reuse completed prerequisites and the [Product prerequisite distinctions](01-product-doc-structure.md#delivery-outcomes-and-prerequisites).

For interface work, apply [Visual prototype before dependent implementation](13-prototypes.md#visual-prototype-before-dependent-implementation). Plan a required independent visual foundation as an ordinary Feature, and add `depends_on` links from the logic that needs its decisions. Narrow checks can stay inside a planned Feature. Reuse validated foundations. Do not make unrelated logic wait for all art, and do not create a separate prototype status or type.

## Requirement coverage review

In the planning or synchronization report, show a small table or clear list that connects **source requirement → Feature and AC → test or check action → gap or next action**.

- Initial decomposition covers the current Product's whole approved scope.
- Synchronization covers changed requirements and their actual downstream impacts, including removals.
- Editorial changes and later unplanned Products need only a brief disposition, not placeholder Features or an audit of all Products.

Read the meanings of requirements and AC in both directions. Look for missing behavior, unsupported or duplicated scope, and Features too broad to verify independently. A source link, a matching ID or a `done` status alone does not establish coverage. Distinguish verification already in place from tests and checks still to be planned or written; do not invent test IDs or PASS results to fill the report.

Refresh the report against the files actually written before handoff:

- Name every unmapped requirement, unresolved choice and remaining implementation or verification. Do not call an incomplete plan fully synchronized.
- State approved exclusions and deferred scope explicitly.
- Keep actionable follow-ups in the responsible Feature or in current Progress, with links, not in a separate coverage ledger.

Planning alignment does not mean that the behavior has been implemented or tested.

## Ownership

| Operation | Owner | Main files changed |
| --- | --- | --- |
| Initial decomposition of the current Product | `feature-plan` | Appends index entries, details and needed components; uses the project-supplied revision log and Registry and keeps their history |
| GDD, Product, professional or Project Rules synchronization | `feature-sync` | Index, details, revision log, needed components and affected test traceability |
| Bug, refactor or maintenance Feature creation | `engineering-change-plan` | Index, engineering details and needed components; the test plan is finalized during execution |
| Feature execution and completion notes | `feature-execute` | Status, verification mapping, Test Registry, notes, Progress, implementation and test files |
| Smell candidate selection | `engineering-refactor-select` | Read-only selection; returns the chosen candidate to `engineering-change-plan` |
