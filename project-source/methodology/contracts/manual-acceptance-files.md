# Manual acceptance files

This contract defines the Stage 4 checklist and the Stage 5 result file for a `manual` Feature. Each Feature's `verification.acceptance_mode` decides whether it applies; an `automated` Feature does not create an empty manual checklist. The project only exchanges files. No external application, launcher, service or tool-specific metadata is required or inspected.

## Definitions and preparation

The approved Feature defines the obligations in `acceptance_criteria[].verification.manual_checks` and `verification.manual_regression`. The Agent expands them into a checklist using [the checklist template](../templates/manual-acceptance-checklist.json.tmpl).

- Give the entry scene, initial state, ordered inputs, observable expected feedback and any necessary reset.
- Include timing, build or device, parameters or seed when relevant.
- Check coverage against the AC and the actual implementation. Structural validation cannot prove the steps are sufficient.
- Feature notes link the checklist and keep decisions; they do not copy its steps.

Use UTF-8 JSON (a UTF-8 BOM is accepted), without comments, trailing commas or duplicate object keys. Input and result use the same structure:

| Field | Contract |
| --- | --- |
| `schema_version` | Number `1`. |
| `feature_id` | The current `F0XX`. One file contains one Feature. |
| `title`, `description` | Optional strings; human-readable content follows the project document language. |
| `snapshot` | `null` in an unprepared draft; `prepare-manual` fills in `git_revision` and `working_tree_fingerprint`. Users keep these fields unchanged in the result. |
| `tests` | Nonempty array covering every approved manual obligation. AC verified only automatically are not turned into manual work. |
| `tests[].id` | Unique, nonempty and stable across the checklist and result, for example `F001-AC01-M01`. Do not match by title or array position. |
| `tests[].source_ref` | `AC01/1` identifies the first manual check under AC01 (one-based); `manual_regression` identifies the Feature's manual regression obligation. Every current reference is covered, and several cases may cover one reference. These references belong to the bound snapshot, not to a separate registry. |
| `tests[].title`, `tests[].expected_result` | Nonempty strings describing the operation and observable result. |
| `tests[].preconditions`, `tests[].steps` | Arrays of nonempty strings; preconditions defaults to `[]`, steps requires at least one entry. |
| `tests[].status`, `tests[].comment` | `pending`, `passed` or `failed` (default `pending`), and a string for actual observations (default empty). A new checklist has every status `pending` and every comment empty. |

Other fields are allowed and ignored by the acceptance logic, so do not put required acceptance meaning in them. The returned result keeps the known definitions and associations; only `status` and `comment` carry user edits. Changes to AC, steps or expected results go through the Feature revision route in `feature-sync`.

Keep both originals under `reports/manual-acceptance/`, normally `reports/manual-acceptance/F001/manual-acceptance-checklist.json` and `reports/manual-acceptance/F001/manual-acceptance-checklist.result.json`.

- For another attempt, use a separate directory when earlier evidence must stay.
- These names are conventions; the explicit paths and the file content determine identity.
- If a submitted result arrives elsewhere, copy it into this directory and keep the submitted original.
- Do not overwrite the checklist with results.
- Retention and Git handling follow [Reports and cleanup](../09-records-reports-and-handoff.md#reports-and-cleanup). Moving to another machine needs the referenced originals, not just a commit or a Markdown summary.

After writing the draft, bind it to the final implementation:

```powershell
python -B tools/features/record-feature-completion.py prepare-manual --feature F001 --checklist reports/manual-acceptance/F001/manual-acceptance-checklist.json
```

This validates coverage and records the actual snapshot. It does not invent steps or run tests. A prepared file cannot be bound again, so finish code and contract changes first. Which later edits invalidate the snapshot is defined by the [content fingerprint](../08-test-traceability-and-evidence.md#content-fingerprint).

Give the user a clickable checklist path and a short explanation of how to run the checks and return the result. No second hand-maintained checklist or mandatory report is needed.

## Receive actual user results

Read the user's submitted file and comments before recording it.

- A submitted, valid result in which every required case is `passed` is the user's explicit acceptance of that checklist's scope. Do not ask for another acceptance phrase.
- Contradictory or ambiguous comments need clarification of that specific issue.
- The parser compares structure and status only. It does not check natural-language meaning, user identity or whether a person actually performed the actions.
- Do not import Agent-generated passing samples, and do not treat a file found on disk as human acceptance.

```powershell
python -B tools/features/record-feature-completion.py record-acceptance --feature F001 --checklist reports/manual-acceptance/F001/manual-acceptance-checklist.json --result reports/manual-acceptance/F001/manual-acceptance-checklist.result.json
```

The importer matches IDs and definitions with the unchanged original, checks the Feature and source references and the original snapshot against the current content, and derives the status:

- `accepted`: all cases passed;
- `rejected`: any case failed;
- `pending`: otherwise.

A successful command means the actual status was recorded. It does not mean acceptance passed or the Feature is done. An invalid file returns a nonzero exit code and leaves the recorded evidence unchanged. Stop that import and resolve the reported mismatch; do not fall back to an earlier acceptance.

The completion evidence keeps the original snapshot and `human_acceptance.source` with project-relative `checklist` and `result` paths. Completion validation rereads those originals. Missing files, changed definitions, stale content or results that are no longer all `passed` block file-based acceptance. No per-item copy or second result ledger is created. Freshness follows the [content fingerprint](../08-test-traceability-and-evidence.md#content-fingerprint); reports are outside it, so saving user results does not invalidate the tested implementation.

## Conversation and subsequent work

For an explicit decision given in the conversation, record it with `record-acceptance --feature F001 --status accepted|rejected`. The decision must apply to the actual current scope, and the record carries no file reference.

- Use either the file route or the conversation route for one decision; never require both.
- Do not use a conversation entry to bypass an invalid file. The user must resolve the discrepancy or make a new, clear decision.
- A minor deferral still needs explicit acceptance and a note.

Failures follow the [execute loop](../03-execute-loop.md) within the current implementation authorization; comments proposing new requirements do not authorize them. After a source or acceptance-contract change, reassess and renew the affected verification before completion. Editorial corrections to reports do not require rerunning business tests. Manual acceptance does not replace automated obligations, direct static checks, requested review conditions or the normal completion checks.
