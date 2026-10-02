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

The Feature index stays lightweight. Durable behavior, stable acceptance-criterion IDs, component impact, verification mapping, engineering classification, and notes live in per-Feature detail files. `docs/test-registry.json` is the machine-readable index that maps components to reusable tests. Human-readable values use `document_language`; machine protocol fields remain stable.

Project creation supplies the index, revision log and Test Registry with empty arrays. All three files are required even before the first Feature is planned. A missing file is a repair issue; do not replace lost records with a newly initialized ledger.

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
| `id` | Exactly `F` plus three digits. Entries remain sequential from `F001`; IDs are never reused. |
| `title` | Non-empty human-readable verb phrase. |
| `status` | `pending`, `in_progress`, `done`, `obsolete`, `obsolete_done`, or `blocked`. |
| `depends_on` | Unique existing prerequisite Feature IDs. Larger IDs are allowed; the graph must remain acyclic. |
| `estimated_scope` | Final plan accepts only `small` or `medium`; `large` must be decomposed before finalization. |
| `completed_at` | Valid ISO 8601 timestamp only for `done` or `obsolete_done`; otherwise `null`. |

Derive Feature counts from `features`. Details, revision history and the Test Registry use the fixed project-relative locations shown above; index metadata does not duplicate their paths.

IDs record allocation, not execution order. Select pending work whose prerequisites are all `done`; use stable ID order only to break ties among eligible Features. `python -B tools/checks/check-feature-list.py --eligible` validates the ledger and prints that eligible set as JSON. New pending/in-progress/blocked work cannot depend on `obsolete` or `obsolete_done`; synchronization must reconnect it to the replacement. Historical completed dependencies remain unchanged.

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
| `verification.test_impact.additional_tests` | Array of `{ "id": "...", "reason": "..." }` with unique Registry IDs and non-empty reasons. May reference another Feature's test. Referenced tests may be planned during preparation but must be active for current completion. Additional scope does not change test ownership or replace the Feature's own AC/regression mapping. |
| `verification.test_impact.full_suite_reasons` | Unique array of non-empty reasons for approved full-suite escalation beyond automatically derived triggers. An empty array records no additional escalation. |
| `source` | One precise primary Product delivery, GDD or professional source; `infrastructure` for technical work with no single documentary source. Follow the source and secondary-reference contract in `11-specialist-workflows.md`. |
| `notes` | String. Starts empty; later holds task reminders, placeholders, TODOs, deferred edges, brief bug learning and relative links to the Feature design or other owning records. Implementation decisions and their rationale belong in the design file under the contract below, regardless of explanation length. |
| `engineering_change` | Optional. When present, exactly `bug`, `refactor`, or `maintenance`. Product-derived Features omit it. |
| `bug_diagnosis` | Optional/null for compatibility. A non-null object is allowed only for `engineering_change: bug` and has exactly `actual`, `expected`, `source`, `reproduction`, `root_cause`. The first three are non-empty strings; reproduction is a non-empty ordered list of non-empty steps. Root cause may be null while investigating, but must be a non-empty confirmed cause for current completion. Non-Bug templates do not invent diagnostic evidence. |

Acceptance-criterion IDs are historical identifiers. Do not renumber criteria on a completed Feature. Product evolution creates a new Feature that changes/supersedes the old behavior.

GDD and professional requirements participate in the same planning, impact and AC mapping under [Discover and map sources](11-specialist-workflows.md#discover-and-map-sources). A Product-derived Feature uses the current Product delivery section as its primary source and links applicable GDD design in AC/design. Use those existing links for secondary sources, not a new JSON field or a multi-path `source` string. The validator checks `source` as non-empty text; the planning Agent must verify source existence, authority and coverage. A binding requirement must not exist only in process-only `notes`.

The runner always reads recorded `test_impact` obligations together with the deterministic Registry scope. Store approved additions and full-suite reasons in the Feature itself; there is no second plan file or extra-scope command. Changing that record requires review of the affected scope and invalidates prior snapshot evidence.

## Feature design and implementation notes

`docs/features/F0XX-design.md` is the fixed body for that Feature's implementation design, local technical decisions and rationale, including boundaries, state ownership, lifecycle, migration, interfaces and applied constraints. Use it whenever this content is saved, even when the explanation is brief; do not place a shorter version in JSON `notes` or choose another document based on complexity. Notes provide reminders and the relative link `[Design](F0XX-design.md)`. Create the file when there is design content to save, not as an empty presence requirement. Do not add another JSON record or design-status ledger. Stage 0 reads existing designs for the selected Feature and relevant dependencies.

The `implementation-guidance-godot` method uses this same contract for requested guidance on an existing Feature, including an engineering Feature. The main Agent can prepare it; a separately delegated advisor requires the explicit authorization defined by that Skill. Work without a Feature follows [Standalone technical decisions](10-architecture-overview.md#standalone-technical-decisions), not an artificial Feature or a separate guide under `reports/`.

The design explains this change: goal and boundaries with Product/AC links; relevant existing behavior; materially constraining rules and how they apply; responsibilities, interfaces and state ownership; important runtime/failure/lifecycle flows; necessary implementation order and verification reasoning; actual outcome and meaningful deviations. Describe necessary dependencies rather than a function-by-function recipe; ordinary implementation details remain with the implementing Agent. Expand useful explanations without a fixed length. Use [feature-design.md.tmpl](templates/feature-design.md.tmpl) as an optional outline, omitting irrelevant sections.

For game functions, use the responsibility and collaboration model in `docs/game-organization.md` to explain relevant business-state owners, presentation-local state and the meaning of requests, current state and one-time events. When animation timing affects gameplay, identify the timing input, interruption conditions and who decides the valid result. Explain the contracts relevant to this change; the model mandates neither separate objects nor a global event bus. The same document ownership applies throughout the game's development.

Reference repository rules and records using paths relative to the design document, with useful section anchors. Explain their concrete application rather than copying rule bodies or recording every file read. Version-sensitive external references identify the applicable version and separate evidence from assumptions. AC, component impact and executable test mappings/obligations remain in Feature JSON/Registry; the design links them rather than duplicating them. Additional scoped measurement, duration, display or listening obligations may be explained in the design under `11-specialist-workflows.md`. Task state and blockers remain in Progress.

The design follows the existing Feature lifecycle:

- Stage 1 develops a reviewable proposal and identifies genuinely missing decisions. Unapproved implementation guidance is returned in the conversation, not saved as another guide or draft file. Delegating its preparation does not approve its proposed design or implementation.
- Stage 2 persists the approved design in the same `docs/features/F0XX-design.md`. Reuse an existing concrete approval that covers the design; do not request it again. When preparation was delegated, the main Agent passes the approval and assigned destination to the same advisor, which may write only that design file. The main Agent checks the result and owns the Feature `notes` link, other record changes and commits.
- Stage 3 keeps that design aligned with implementation and finalizes it before Stage 4. Material changes follow the existing authorization contract; useful ordinary implementation details do not need another advisor round.

When the authorized task only delivers guidance, reuse the proposal and approved-design persistence contract above without starting the full Stage 2 execution workflow. Saving the approved design does not authorize implementation or updates to Feature status, verification plans or Registry. The original task owner maintains the Feature `notes` link only within the authorized scope, then ends with the requested guidance result. An actual implementation task still persists its approved design in Stage 2.

A detailed current subsystem description belongs in `docs/architecture/<subsystem>.md`, and an important cross-Feature rationale may belong in an ADR; the Feature design links those owners. Do not copy the same subsystem description into each Feature.

After completion, retain the design as the account of that Feature. Later behavior changes get a new Feature/design and update the current architecture. Corrections or replacement links may clarify history without rewriting past decisions as though they had always applied. Design Markdown participates in the current verification fingerprint; it does not inherit the process-only exemption of JSON `notes`.

## File 3: `docs/feature-list-revisions.json`

`feature-plan` establishes the first eligible planning baseline below; `feature-sync` appends one record for each later governing-source synchronization.

Initial content is `{"schema_version": 2, "revision_log": []}`. The root and each revision entry use schema version 2; no old-format parsing or automatic migration is provided. Current-format history remains immutable. `engineering-change-plan` does not append a revision merely for creating an engineering Feature without a source change.

### Initial planning baseline

When both the Feature index and revision log were empty before this first Product plan, establish one baseline with the plan. An empty copied project or an engineering Feature alone does not establish source coverage. For an interrupted first planning task, verify the same pre-write empty state and adopted source revision from its existing task context and Git history; do not infer them from an empty revision log alone.

Before writing the plan, ensure all adopted GDD, Product, professional and rule sources are committed under their owning workflow and existing authorization. Resolve the actual source HEAD as a full commit hash. If sources cannot be committed or their adopted state is unclear, report the prerequisite rather than using the scaffold commit. After checking the written plan's semantic coverage, append the following version-2 entry and include it in the final ledger validation and plan commit:

| Field | Initial value |
| --- | --- |
| `revision_id`, `schema_version` | `R000`, `2` |
| `anchor_commit`, `synced_at_commit` | The same verified source HEAD adopted by this plan |
| `revised_at`, `user_intent` | Actual timestamp; supplied planning intent or `null` |
| `summary`, `added` | Initial baseline, current Product and adopted source coverage/limits in prose; the actual new Feature IDs |
| `migrations`, `dependency_changes` | Empty arrays; this records initial planning, not a historical source change |

Recheck that the adopted source contents still match the recorded commit before finalizing. No self-referencing plan commit, additional baseline file or new schema field is needed. This baseline covers only the planned scope and actually adopted sources, not every Product or every file present at HEAD.

Later Product planning preserves the entire revision log and never advances the anchor: it must not hide unsynchronized changes to earlier work. A populated ledger with no baseline uses `feature-sync` to verify prior coverage or perform an authorized current-document alignment; do not backfill `R000` just because the log is empty. Preserve an existing baseline on continuation.

### Synchronization records

On synchronization without a usable recorded baseline, a Feature-file edit alone is not a source baseline; `feature-sync` must verify which source state the plan actually absorbed. If approved current-document alignment is needed because that history is unknown, the existing anchor fields both identify the inspected HEAD and `summary` records this limitation. This establishes the next baseline without claiming an earlier diff. Newly admitted GDD or professional sources require the same coverage check even when their files predate an existing anchor; see `11-specialist-workflows.md`.

New synchronization records use these fields in addition to the existing summary, anchor and human-readable metadata:

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
      "reason": "The approved GDD change replaces the earlier contract",
      "source": {"path": "docs/gdd/inventory.md#capacity", "anchor_commit": "78cfcb9"}
    }
  ],
  "dependency_changes": [{"feature": "F003", "before": ["F002"], "after": ["F004"]}]
}
```

Existing readable revision summaries use the following fields alongside the typed relationships; preserve their shapes when synchronization updates them.

| Summary field | Shape |
| --- | --- |
| `added`, `obsoleted`, `depends_on_warnings` | Arrays of affected Feature IDs |
| `revised_via_new_feature` | Array of `{ "original": "F0XX", "regression": "F0YY" }` |
| `source_path_updates` | Array of `{ "feature": "F0XX", "from": "product/old-path.md", "to": "product/new-path.md" }` |

`revision_id` is unique and uses letters/digits/dot/dash/underscore. Each migration requires exactly `kind`, `from`, `to`, `reason`, and `source`; all Feature references must exist. `source` has exactly repository-relative `path` (optional `#section`) and `anchor_commit`, which identifies this revision's before or after source commit. Deleted source paths refer to the before commit; synchronization verifies the real Git diff. The validator checks the typed relationship, not approval by itself.

| `kind` | Cardinality and action |
| --- | --- |
| `add` | Empty `from`, one or more new `to` IDs. |
| `revise` | One `from`, one `to`. Pending/in-progress work can retain its ID; a completed contract gets a new ID. |
| `split` | One `from`, at least two disjoint new `to` IDs. Keep the source as `obsolete`/`obsolete_done`. |
| `merge` | At least two `from`, one disjoint new `to` ID. Keep the sources as `obsolete`/`obsolete_done`. |
| `retire` | One or more `from`, zero or more disjoint `to` IDs. Keep sources as `obsolete`/`obsolete_done`; removal of implemented behavior requires replacement implementation work. |

Append replacement IDs without renumbering or deleting old entries. Review all downstream edges during split/merge/revision; no execution ordering belongs only in prose. `dependency_changes` records unique `feature` entries with unique existing `before`/`after` IDs. Consecutive recorded changes must chain, and the final `after` must equal the current index. Feature migration relationships and the actual dependency graph are separately acyclic. Old summary arrays can remain for readable history; `migrations` and `dependency_changes` are the machine-readable relationships.

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

Registry semantics and ID formats are canonicalized in [08-testing-strategy.md](./08-testing-strategy.md#registry-rules). The logical ID determines the test's kind, owning Feature and acceptance criterion; do not store these a second time. Feature references encoded in IDs must resolve to existing Features.

Registry schema version 3 is the only supported format; revision history remains version 2. No old-format parsing or automatic migration is provided. Every retired entry requires explicit retirement provenance:

```json
{
  "reason": "The approved GDD contract supersedes this assertion",
  "source": {"path": "docs/gdd/inventory.md#capacity", "anchor_commit": "78cfcb9"},
  "replacement": {"feature_id": "F004", "test_ids": ["F004-AC01"]},
  "revision_id": "rev-contract-01"
}
```

Store this object under `retirement`, preserving the test's original ID, source Feature/criterion, and historical path/case. Its source and replacement must match the referenced version-2 migration (`from` contains the old source Feature; `to` contains the replacement Feature). Invariant retirements match the source and target without inventing a source Feature. Replacement test IDs must exist, belong to the replacement Feature and appear in its AC/regression verification mapping so the execution plan actually selects them. A replacement may be `planned` while its Feature is pending/in-progress/blocked; this is a visible coverage gap, never passing evidence. A completed replacement requires active coverage or another fully traceable retirement chain. Cycles, missing provenance, missing replacements, and planned coverage owned by completed/obsolete Features fail validation. Source deletion may remove a retired test file; active paths must still exist.

`retired.path` may be null if the superseded planned test was never materialized. Preserve any already-known historical path instead of clearing it. Retirement does not automatically remove a runnable test function: implementation must deliberately replace/remove superseded assertions so full discovery executes the current contract.

An approved revision of a pending/in-progress Feature may remove an old AC from its current detail. A retired acceptance test keeps the historical criterion encoded in its test ID without requiring the old AC to remain in the current detail; its source Feature and complete retirement/replacement provenance must still validate. Planned and active acceptance tests must reference a current AC. This does not authorize rewriting completed Feature history or treating planned replacement tests as passed.

Completed Feature criteria/test IDs and archived completion evidence are historical records. Do not rewrite them to simulate current behavior. The active safety net is selected from current `active` Registry records. Normal strict validation accepts historical `done` references to traceably retired tests, but current completion must pass `python -B tools/checks/check-feature-list.py --completion-feature F0XX`, which requires that Feature's own mapped automated tests to be active. Completion additionally requires actual execution evidence for automated obligations; retirement is never a substitute for passing tests. Retired entries without provenance fail validation; do not invent a reason or replacement to make them pass.

`unit_test_paths` is an array of component unit-suite paths; the example assumes the inventory suite exists. Path requirements, empty-suite handling and registration timing follow [Registry rules](08-testing-strategy.md#registry-rules).

Component suite paths and active test paths must stay inside the repository after resolution. Registration and selection reject absolute paths, drive-qualified paths, parent traversal and links resolving outside the repository. Registry paths are repository-relative, without a `res://` prefix. Planned and retired test entries retain the existing nullable/historical path contract; they do not require an existing executable file.

## File 5: `docs/feature-completion-evidence.json`

This repository-owned JSON file holds the current Feature's completion evidence. PASS requires a real result.json, original JUnit/discovery/diagnostics and actual test set matched against the approved Required/affected/full plan. Caller-supplied pass counts cannot create PASS. A valid manual plan with no Required/affected tests and no full-suite obligation keeps `test_runs: []` and derives `not_required`, not PASS; actual human acceptance and applicable static checks still apply. Unresolved failed or unfinished final runs on the same snapshot still block completion. Test and applicable human acceptance evidence must match the current semantic snapshot. Production, tests, configuration, GDD, Product, professional sources, Project Rules, Feature AC/verification and Registry semantics participate in that snapshot. Pure status/completion timestamps, Feature notes and Progress/history archival do not invalidate business test evidence.

The current evidence schema is version 8. It keeps real test-run references plus applicable human acceptance. Required/affected/full test conclusions are calculated from those artifacts rather than persisted again. Static checks are executed and assessed directly by the Agent, outside this file. The schema is shown in `methodology/templates/feature-completion-evidence.json.tmpl`; the execution contract is in [08-testing-strategy.md](./08-testing-strategy.md). The normal command is:

```powershell
python -B tools/features/record-feature-completion.py record-tests --feature F0XX --run reports/gdunit-wrapper/F0XX/run-<id>/result.json
```

Repeat `--run` when a plan is covered by multiple real runs. An unavailable full suite is a reported blocker, not a caller-entered PASS.

`tools/features/record-feature-completion.py` records evidence and provides the explicit `validate --feature F0XX` check used before completion. Assistant summaries and a `done` field do not supply missing evidence. No automatic Hook supervises the index edit.

## Bug learning in notes

After successful automated verification and any required human acceptance of an engineering Feature with `engineering_change: bug`, append a concise `BUG learning` block using [the canonical fields](07-engineering-change.md#bug-learning-promotion).

Do not store dead-end debugging transcripts or transient guesses.

## Status transitions

```text
pending ──execute Stage 2──→ in_progress ──Stage 7 after applicable completion checks──→ done
   │                              │
   │                              └──explicitly abandoned──→ pending
   ├──source synchronization retires work──→ obsolete
   └──invalid prerequisite──→ blocked

done ──Product evolution removes implemented behavior──→ obsolete_done
```

The `in_progress → done` transition follows Stage 7 of [the execution loop](03-execute-loop.md): satisfy the decided acceptance plan, applicable tests and direct static checks, and any explicit user review condition. Independent review is optional under Stage 6; the completion record contains no review counts. The Agent runs the explicit evidence check for the current code snapshot and records the actual result.

## Machine invariants

The final ledger must satisfy all of the following:

- Index, revision log and test registry exist, and JSON parses for them and every `F*.json` detail.
- Feature IDs match `F\d{3}`, are unique, and are sequential in index order.
- Index IDs and detail filename stems are exactly one-to-one in final state.
- Detail `id` equals its filename stem.
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
- Test-registry component IDs and test IDs are unique.
- Test-registry references resolve to existing Features/components.
- A historical `done` Feature's tests remain registryued as active or traceably retired. Current completion requires active mapped automated tests and real matching execution evidence.
- Version-2 revisions and test retirements satisfy the migration, source, replacement and dependency-chain rules above.

Run the final strict validator from the repository root:

```powershell
python -B tools/checks/check-feature-list.py
```

During normal editing, the Agent can update related files together before running the explicit checker. The command always checks the complete ledger; it is not registered as a per-edit Hook.

## Product-by-Product planning

Apply the [existing GDD prerequisite](01-product-doc-structure.md#gdd-prerequisite-and-authority). Pre-decompose the agreed delivery horizon in `docs/product.md`, then detail and deliver one Product at a time in the actual execution order. The Feature planning unit is the current `docs/product/NN-<delivery>.md` with its approved scope and GDD references. The overview holds candidate boundaries, source mapping, dependencies and suggested order; file numbers are stable identities, not an instruction to detail or plan every Product at once.

1. Identify the current Product from the user's request, pre-decomposition order and existing Feature `source`/status records. Read relevant Progress for context. Revisit applicable GDD design and actual earlier delivery results, then use `product-author` to write or update this Product's delivery document within existing authorization. Resolve unclear current scope and necessary cross-system rules before decomposing; do not detail future Products to settle one shared rule.
2. Decompose the current Product's complete necessary scope into multiple independently verifiable Features in one planning pass. Include only infrastructure needed to deliver that scope; reuse existing infrastructure and completed prerequisite Features. If another Product must be delivered first, correct the order rather than pre-planning both Products.
3. Leave later Products as concise pre-decomposition entries in `product.md`. Do not write their detailed delivery documents or allocate Feature IDs, detailed Feature AC or test registrations. Read their GDD dependencies only as needed for current decisions.
4. Finish the current Product's required Features before decomposing the next Product. Check actual Feature completion and outstanding scope: no eligible task, an empty plan, or a Product document marked `done` does not prove implementation is complete. `pending`, `in_progress` and `blocked` work is unfinished; explicitly withdrawn scope follows existing retirement rules.
5. After completion, revisit the next candidate against the current GDD and what was learned. Adjust pre-decomposition if needed, write that Product's delivery document and then decompose it under existing authorization. Stage 8 follows [Authorization and continuation](03-execute-loop.md#authorization-and-continuation); completion alone does not authorize planning or implementing the next Product.

`feature-plan` handles the first and each subsequent Product's initial decomposition by appending to the same ledger. Allocate IDs after the greatest existing ID; preserve previous Features, test Registry records and revision history. If the selected scope already has a plan, reuse it; changed requirements use `feature-sync` rather than duplicating or regenerating that plan.

`feature-sync` analyzes GDD and other governing-source changes against existing work, including completed behavior and actual downstream dependencies. Changes affecting only a later, unplanned candidate update its pre-decomposition as needed without creating detailed Product documents or Features. When that candidate becomes current, read its full applicable current GDD and professional design even if those edits predate the latest sync anchor. Do not interpret a global source anchor as proof that every Product has been detailed or decomposed. `meta.generated_from` names source locations, not coverage.

Use the existing Product order, Feature sources/statuses and ordinary Progress notes. Do not add a Product queue, registry, completion flag or duplicate ledger. Pre-existing plans remain intact; this rule does not authorize deleting future Features or rewriting completed history.

### Decomposition preview

For each current Product's initial decomposition, present a concise preview in the conversation before writing its Feature index/details, revision log or Test Registry, including component merges. This also applies when planning is called from Product writing or adoption of existing implementation. Keep the preview in the existing planning proposal:

- Identify the Product and approved scope; state the number of new Features and the ledger total before and after the addition. Distinguish reused work from new entries; derive the count from complete outcomes, not a preset quota.
- List every proposed Feature in a compact table or list: provisional label, title, one-sentence scope and observable result, and prerequisites. State the reason for the chosen granularity and any exclusions or unresolved choices.
- Include the requirement coverage correspondence defined below in the same proposal; the overview does not replace coverage review or detailed AC.

By default, wait for the user's confirmation of this concrete decomposition before these writes. Approval of Product intent or a general request to plan or implement does not by itself approve an unseen decomposition. Reuse an already confirmed, unchanged proposal across turns; do not ask for the same decision again. If the count, work boundaries or dependencies materially change, refresh the preview and resolve the changed decision before writing.

When the user explicitly authorizes autonomous decomposition and continuation within a defined scope, including a Goal that grants this authority, show the preview before writing and continue without another approval. Merely using Goal mode does not supply that authority. This exception also covers refreshed previews within that authorization; missing Product decisions or scope changes still require the user's decision.

After writes and validation, refresh the same proposal with actual IDs, counts and remaining work. Preview acceptance authorizes plan recording, not additional implementation or human acceptance. Do not add a preview file, approval field, status or supervisory script; this is an Agent workflow obligation, not a check performed by the ledger validator.

## Adopting existing implementation

When implementation predates its Product or Feature records, a substantive GDD is still required before delivery planning. If it is missing, return the design gap to `design-gdd` within the user's scope; existing code can inform that work but cannot silently become approved design. Use `product-author` to establish the current delivery boundary from sufficiently clear design, resolving approved game-design changes through `design-gdd` or scoped numerical changes through `design-balance`. Apply Product-by-Product planning to the requested current delivery; implementation does not waive prerequisite completion or expand the planning horizon. Keep later candidates at pre-decomposition level.

Reuse an existing Feature covering the outcome. If no record covers it, create ordinary Product-derived Features around independently verifiable outcomes, not hypothetical historical coding steps or one Feature per source file. Derive AC from confirmed intent and map each to the existing implementation, usable tests and remaining gaps in the normal requirement coverage review. Do not weaken AC to fit a defect or create duplicate work just to rerun tests.

New records use the canonical initial planning values: `pending` and `completed_at: null`. In their existing `notes`, state that implementation predates formal recording, link verified files/commits and decisions, and name remaining implementation or verification. Missing history stays unknown; do not invent prior Features, approvals, RED runs or acceptance dates. Preserve existing completed records and evidence under the normal evolution rules.

Documentation-only work stops after the authorized Product/plan writes and their required checks and commits; report implemented scope separately from formal completion. Authorized delivery uses [Delivery of existing implementation](03-execute-loop.md#delivery-of-existing-implementation) to verify and finish from the current state. No extra status, adoption ledger or evidence format is needed.

## Decomposition rules

1. Each Feature is the smallest independently verifiable complete behavior or engineering outcome.
2. Plan only the current Product under the rule above; reuse or establish the runnable infrastructure it needs, then follow its Feature dependencies.
3. Final Features are `small` or `medium`; decompose `large` work.
4. Product-derived Features implement their Product delivery scope from confirmed GDD and professional sources; they do not invent absent design rules.
5. Engineering Features preserve GDD design and approved delivery intent unless the substantive change has been approved through its owning route.
6. Each Feature declares semantic `affected_components`; keep the set minimal and meaningful.
7. New acceptance criteria receive stable `ACxx` identifiers in order.
8. A `bug` Feature requires regression coverage when deterministic automation is feasible; an explicit repeatable human regression check is allowed only with a concrete reason automation is impractical.
9. `refactor` Features state behavior-preservation evidence.
10. `maintenance` Features state the technical success condition and compatibility/invariant to preserve.

Check each proposed outcome with a concrete precondition, action or engineering check, and observable result. A class, file or layer name alone does not establish a complete Feature. A technical outcome can be independently verifiable without a player-facing interface; do not force every Feature to include UI, persistence and every code layer.

Presentation-only, logic-only and cross-layer are useful scope descriptions, not new Feature types or fields. A single Feature may deliver shop-purchase rules, interface feedback and their connection when that is a coherent, bounded outcome. State the relevant rule result, perceptual result and integration checks in its existing AC/design and verification plan. Split only for independently verifiable outcomes or real dependencies; the two-layer model does not require separate Features or a logic-first implementation order.

For each `depends_on`, identify the capability, contract, running foundation or accepted decision supplied by the prerequisite. Ask whether the current Feature could still be correctly completed and verified without that result. Retain actual dependencies and applicable architecture constraints; do not encode numbering or a preferred sequence as a dependency. Explain non-obvious dependencies in the existing decomposition preview or Feature design, without adding schema fields or a separate checklist. Reuse completed prerequisites and the [Product prerequisite distinctions](01-product-doc-structure.md#delivery-outcomes-and-prerequisites).

For interface work, apply [Visual prototype before dependent implementation](01-product-doc-structure.md#visual-prototype-before-dependent-implementation). Plan a required independent visual foundation as an ordinary Feature with `depends_on` links from the logic that needs its decisions; narrow checks can remain inside an existing Feature. Reuse validated foundations and do not make unrelated logic wait for all art, or create a separate prototype status/type.

## Requirement coverage review

In the existing planning or synchronization report, show a small table or clear list connecting **source requirement → Feature and AC → test/check action → gap or next action**. Initial decomposition covers the current Product's whole approved scope; synchronization covers changed requirements and actual downstream impacts, including removals. Editorial changes and later unplanned Products need only a brief disposition, not placeholder Features or an all-Product audit.

Read the requirement and AC meanings in both directions: find missing behavior, unsupported or duplicated scope, and Features too broad to verify independently. A source link, matching ID or old `done` status alone does not establish coverage. Distinguish existing verification from tests/checks still to be planned or written; do not invent test IDs or PASS results to fill the report.

Refresh the report against the files actually written before handoff. Name any unmapped requirement, unresolved choice and remaining implementation/verification; do not call an incomplete current plan fully synchronized. State approved exclusions and deferred scope explicitly. Keep actionable follow-ups in the owning Feature or current Progress, with links, not in a separate coverage ledger. Planning alignment does not mean the new behavior has been implemented or tested.

## Ownership

| Operation | Owner | Main files changed |
| --- | --- | --- |
| Initial decomposition of the current Product | `feature-plan` | append index/details and needed components; use the project-supplied revision log/registry and preserve existing history |
| GDD/Product/professional/Project-Rules synchronization | `feature-sync` | index/details + revision log + needed components and affected test traceability |
| Bug/refactor/maintenance Feature creation | `engineering-change-plan` | index + engineering details + needed components; test plan is finalized during execution |
| Feature execution and completion notes | `feature-execute` | status, verification mapping, test registry, notes, Progress, implementation/test files |
| Smell candidate selection | `engineering-refactor-select` | read-only selection; returns to engineering standardizer |
