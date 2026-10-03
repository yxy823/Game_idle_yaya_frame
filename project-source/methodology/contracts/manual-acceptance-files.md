# Manual acceptance files

This contract supplies the Stage 4 checklist and Stage 5 results for a `manual` Feature. `verification.acceptance_mode` remains the per-Feature decision. An `automated` Feature does not create an empty manual checklist. The project only exchanges files; no external application, launcher, service or tool-specific metadata is required or inspected.

## Definitions and preparation

The approved Feature owns `acceptance_criteria[].verification.manual_checks` and `verification.manual_regression`. The Agent expands those obligations using [the checklist template](../templates/manual-acceptance-checklist.json.tmpl). Provide the entry scene, initial state, ordered inputs, observable expected feedback and necessary reset in the checklist. Include timing, build/device, parameters or seed when relevant. Check semantic coverage against the AC and actual implementation; structural validation cannot prove the steps are sufficient. Notes link the checklist and retain decisions rather than duplicating its steps.

Use UTF-8 JSON (a UTF-8 BOM is accepted), without comments, trailing commas or duplicate object keys. Input and result use the same structure:

| Field | Contract |
| --- | --- |
| `schema_version` | Number `1`. |
| `feature_id` | The current `F0XX`. One file contains one Feature. |
| `title`, `description` | Optional strings; human-readable content follows the project document language. |
| `snapshot` | `null` in an unprepared draft; `prepare-manual` fills the existing `git_revision` and `working_tree_fingerprint`. Users preserve these fields in the result. |
| `tests` | Nonempty array covering every approved manual obligation; additional automatic-only AC are not converted to manual work. |
| `tests[].id` | Unique, nonempty, stable within the checklist/result pair, e.g. `F001-AC01-M01`. Do not match by title or array position. |
| `tests[].source_ref` | `AC01/1` identifies the first manual check under AC01 (one-based); `manual_regression` identifies the Feature's manual regression obligation. Every current reference must be covered. Several concrete cases may cover one reference. These references belong to the bound snapshot, not an independent registry. |
| `tests[].title`, `tests[].expected_result` | Nonempty strings describing the operation and observable result. |
| `tests[].preconditions`, `tests[].steps` | Arrays of nonempty strings; preconditions defaults to `[]`, steps requires at least one entry. |
| `tests[].status`, `tests[].comment` | `pending` / `passed` / `failed` (default `pending`), and a string for actual observations (default empty). New checklists require pending status and empty comments. |

Additional fields are permitted and ignored by acceptance logic. Do not put mandatory acceptance meaning in unknown fields. Preserve known definitions and associations in returned results; only status and comment carry user edits. Changes to AC, steps or expected results follow the existing revision route.

Keep both originals under `reports/manual-acceptance/`, normally `reports/manual-acceptance/F001/manual-acceptance-checklist.json` and `reports/manual-acceptance/F001/manual-acceptance-checklist.result.json`. For another attempt, use a separate directory when earlier evidence must remain. Names are conventions; explicit paths and document content determine identity. Copy a submitted result into this report boundary if it arrives elsewhere, preserving the submitted original. Do not overwrite the checklist with results. The existing report retention/Git policy applies; cross-machine handoff needs the referenced originals, not just a commit or a Markdown summary.

After writing the draft, bind it to the final implementation:

```powershell
python -B tools/features/record-feature-completion.py prepare-manual --feature F001 --checklist reports/manual-acceptance/F001/manual-acceptance-checklist.json
```

This validates coverage and records the actual snapshot; it does not invent steps or run tests. A prepared file cannot be rebound. Finish code and contract changes before preparation; reporting and notes do not invalidate the snapshot. Provide a clickable checklist path and a brief execution/result-return explanation to the user. No second hand-maintained checklist or mandatory report is needed.

## Receive actual user results

Read the user's submitted file and comments before recording it. A submitted, valid result in which all required cases are `passed` is the user's explicit acceptance of that checklist's scope; do not ask for another acceptance phrase. Contradictory or ambiguous comments require clarification of that specific issue. The parser compares structure and status, not natural-language meaning, user identity or whether a person actually performed the actions. Do not import Agent-generated passing samples or silently discover a file as human acceptance.

```powershell
python -B tools/features/record-feature-completion.py record-acceptance --feature F001 --checklist reports/manual-acceptance/F001/manual-acceptance-checklist.json --result reports/manual-acceptance/F001/manual-acceptance-checklist.result.json
```

The importer matches IDs and definitions with the unchanged original, checks Feature/source references and the original snapshot against current content, and derives `accepted` (all passed), `rejected` (any failed), or `pending` (otherwise). A successful command means the actual status was recorded, not that acceptance passed or the Feature is done. Invalid files return a nonzero exit code without replacing existing evidence; stop that import and resolve the reported mismatch instead of falling back to an old acceptance.

The completion evidence retains the original snapshot and `human_acceptance.source` with project-relative `checklist` and `result` paths. Completion validation rereads those originals; missing files, changed definitions, stale content or no-longer-passed results block file-based acceptance. No per-item copy or second result ledger is created. Git revision is provenance: a content-identical commit alone does not require retesting. Reports do not enter the source fingerprint, so saving user results cannot invalidate the implementation that was tested.

## Conversation and subsequent work

The existing `record-acceptance --feature F001 --status accepted|rejected` route remains for an explicit conversational decision tied to actual current scope. It has no fabricated file reference. Use either the file or conversation route for a decision, never demand both. Do not use a conversation entry to bypass an invalid file; the user must explicitly resolve the discrepancy or make a new, clear decision. Minor deferrals still require explicit acceptance and notes.

Failures follow the execute loop and existing implementation authorization; comments proposing new requirements do not authorize them. After a source or acceptance-contract change, reassess and renew affected verification before completion. Purely editorial report corrections do not force a business rerun. Manual acceptance does not replace automated obligations, direct static checks, requested review conditions or the normal completion checks.
