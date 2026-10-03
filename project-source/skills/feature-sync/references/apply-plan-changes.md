# Apply confirmed plan changes

Use this reference in [feature-sync](../SKILL.md) Stage 4, after the Registry merge. Field shapes and initial planning values are defined in `methodology/02-feature-list-schema.md`. The actions below say what may change; they do not redefine fields or authorize rewriting completed behavior.

## Additions

- Append new index entries and matching details with never-used IDs and the canonical initial values.
- Make the source section precise, and explain when new behavior extends a completed capability.
- Product-derived additions omit `engineering_change`. Preserve that field on engineering Features during source correction, note and status changes, or permitted pending revisions.

## Removals

Every removal appends a localized, timestamped removal reason to the detail `notes`.

| Current status | Confirmed action |
|---|---|
| `pending` | Set index `status` to `obsolete` |
| `blocked` | Set index `status` to `obsolete`; preserve the recorded blocker |
| `in_progress` | Set index `status` to `obsolete`; warn that written code may require an explicitly authorized rollback |
| `done` | Set index `status` to `obsolete_done`; preserve `id`, `description` and `acceptance_criteria`; append a new Feature that removes the implemented behavior, with dependencies chosen from actual impact |
| `obsolete` or `obsolete_done` | Keep the status unchanged; note that the exclusion was confirmed again |

Do not translate or substantively rewrite the removed `done` Feature. Its status transition and removal note record the confirmed deletion; the new removal Feature carries the implementation work.

A Feature that becomes `obsolete` cannot keep `planned` Registry tests:

- When the retirement has a replacement, retire those tests with provenance under Test traceability below.
- When the Feature is retired without a replacement, delete its `planned` Registry entries; they were never implemented. See [File 4](../../../../methodology/02-feature-list-schema.md#file-4-docstest-registryjson) in methodology 02.

## Revisions

| Current status | Confirmed action |
|---|---|
| `pending` | Before execution, update the detail `description`, `affected_components` and criterion text or IDs; keep still-valid planned verification mappings; explicitly retire superseded planned Registry entries; append a localized, timestamped revision note; change the index `title` only when affected |
| `blocked` | Apply the `pending` action, then recheck the recorded blocker under [Status transitions](../../../../methodology/02-feature-list-schema.md#status-transitions); keep `blocked` while it remains, or restore `pending` with the resolved prerequisite and reason in `notes` |
| `in_progress` | Apply the `pending` action and warn that the current implementation may need adjustment |
| `done` | Do not modify the original index entry or detail. Append a new Feature that revises the implementation for the new rule, depends on the original ID and states the new behavior in its acceptance criteria |
| `obsolete` or `obsolete_done` | Normally do nothing. If the user wants reactivation, require an explicit decision and append a new Feature |

## Source-path corrections

- Correct affected primary `source` paths and secondary links in plan records or Feature design navigation, including historical navigation where needed. A link correction is not permission to rewrite completed requirements or decisions. Repairs to the source documents themselves belong to Stage 3.
- Record primary Feature `source` changes in `source_path_updates` using its `{ feature, from, to }` shape. Record secondary document and link corrections in the ordinary report and revision summary; do not overload this field or add another registry.
- A path correction is not a substantive revision.

## Splits, merges and dependencies

- Splits and merges follow the `split` and `merge` rows of the migration table under [File 3](../../../../methodology/02-feature-list-schema.md#file-3-docsfeature-list-revisionsjson): new Features get never-used IDs with independently testable scope, and the original entries stay as `obsolete` or `obsolete_done`. A completed source's description, criteria and historical mappings remain unchanged.
- Rewrite affected pending and blocked dependencies to the actual replacement prerequisites, even when their IDs are larger. For blocked work, recheck the recorded recovery condition after the replacement; a valid but unfinished dependency leaves the restored work `pending` and not yet eligible.
- Review in-progress work explicitly before changing its scope or dependencies. Do not rewrite completed dependency history.
- Record each operation in `migrations` and each dependency edit in `dependency_changes` of the version-2 revision. Check both the migration graph and the execution graph for cycles, unknown IDs, self-dependencies and obsolete prerequisites.
- Add, revise, split, merge and retire are incremental operations. Never regenerate the whole plan because an insertion would disturb numeric execution order.

## Downstream regression

Assign ordinary downstream verification to the Feature that implements this change, using **Test Impact Review** in `methodology/08-test-traceability-and-evidence.md`. Record the affected behavior, the tests or manual checks that already cover it and any coverage gap in that Feature's notes for Stage 1. Preserve test ownership; a note cannot decline required checks. Create another Feature only for a separate implementation, repair or independently agreed deliverable, not merely to rerun a dependent Feature's valid tests.

## Test traceability updates

Completed Feature criteria and test IDs are never rewritten in place; Product evolution creates a new Feature with new IDs. Registry retirement fields, schema versions and validation rules are defined under [File 4](../../../../methodology/02-feature-list-schema.md#file-4-docstest-registryjson) in methodology 02.

- **Superseded active tests:** Stage 2 shows the exact test ID and its retirement relationship. After explicit Stage 3 confirmation, set `status: retired` and add the `retirement` object. Preserve the original ID, source mapping, path, case and completed evidence. Keeping a wrong assertion active to satisfy old history is prohibited.
- **Test-code cleanup:** record approved test-code and current-reference cleanup in the `notes` of the new or unfinished Feature that owns it, with exact paths, methods and the intended action. Leave the implementation to [feature-execute](../../feature-execute/SKILL.md), and report it as pending until it is performed and verified. Do not delete historical Feature or Registry records.
- **Still-valid tests:** regression and invariant tests that remain valid stay `active`; `feature-execute` later selects them through component intersection.
- **Replacement IDs:** new Features declare `affected_components`, and ordinary new test IDs are finalized in `feature-execute` Stage 1 and 2. When an approved retirement needs replacement IDs, plan those IDs against the new criteria now and register them as `planned`, with `path: null` if needed. This does not authorize implementation or imply coverage; the replacement Feature must activate and execute them before completion.
- **Retiring active tests without replacement** is blocked; the new removal Feature's contract verifies a removed behavior.
- Keep `docs/test-registry.json` machine-readable; it is not a narrative revision log.
