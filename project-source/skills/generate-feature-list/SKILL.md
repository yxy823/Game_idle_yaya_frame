---
name: generate-feature-list
description: "Generate or explicitly regenerate the initial Feature/test ledger from Product and Coding Rules. Use for first-time Feature planning or a confirmed full replacement; use sync-feature-list for incremental changes. English triggers: generate feature list, initialize task list, decompose the product. 中文触发：生成 feature-list、初始化任务列表、拆解产品功能。"
---

# Generate Feature list

## Purpose and routing boundary

Use this workflow only when:

- `docs/feature-list.json` does not exist and the project needs its first Feature plan; or
- the user explicitly requests a complete replacement of the existing Feature plan.

For every incremental Product change, use `sync-feature-list` instead.

If `docs/feature-list.json` already exists and the user has not explicitly authorized replacement, explain the choice between incremental synchronization and complete regeneration, then wait for confirmation. Never infer permission to discard an existing plan.

## Language contract

Before generating durable Feature content:

1. Read `document_language` from `docs/methodology-config.json`.
2. Resolve missing, invalid, or migration-sensitive configuration through `methodology/05-document-language.md` before writing any Feature files.
3. Use the language of the user's current message for conversation.
4. Write Feature titles, descriptions, acceptance criteria, human-readable `source` fragments, meta notes, and Feature notes in `document_language`.
5. Keep JSON keys, enum values, Feature IDs, dependency IDs, scopes, timestamps, filenames, paths, commands, and structural validation language-neutral and exactly as specified here.

With `document_language: en` and a Chinese conversation, discuss the plan in Chinese but write Feature prose in English. With `document_language: zh-CN` and an English conversation, discuss the plan in English but write Feature prose in Simplified Chinese.

## Four-artifact output structure

Update all four artifact types as one consistent ledger change:

| Path | Content |
|---|---|
| `docs/feature-list.json` | Lightweight index containing `meta` and each Feature's `id`, `title`, `status`, `depends_on`, `estimated_scope`, and `completed_at` |
| `docs/features/F0XX.json` | One detail file per Feature containing stable criterion IDs, `affected_components`, verification mapping, source, and notes |
| `docs/feature-list-revisions.json` | Initial empty revision log: `{"revision_log": []}` |
| `docs/test-catalog.json` | Component/test traceability catalog; create it only when absent, otherwise validate and merge without replacing existing records |

When the user explicitly confirms complete regeneration, remove every stale `docs/features/F*.json` detail before writing the replacement set so old data cannot contaminate the new index. Resolve and report the exact files before removing them; do not use an unresolved or broad destructive glob.

Complete Feature-plan regeneration does not authorize clearing the independent test catalog. Preserve existing component records and test entries, especially `kind: invariant` entries with `source_feature: null`. If an existing acceptance or regression entry conflicts with the replacement Feature plan, report the conflict and stop instead of deleting or rewriting the test silently.

## Required inputs

Read every relevant input before planning. Also read test roots/framework from `docs/methodology-config.json`:

Use this repository-rule loading path; `docs/coding_rules.md` is not a second router:

```text
AGENTS.md
-> agent-rules/00-core/README.md
-> each affected agent-rules/<module>/README.md
-> the concrete documents routed by those READMEs
```

| Path | Role |
|---|---|
| `docs/product.md` | Product positioning, users, core loop, module inventory, module dependencies, and Product-wide direction |
| `docs/product/NN-xxx.md` | Complete module behavior, data and state, UI, audio, values, acceptance criteria, and edge cases |
| `docs/coding_rules.md` | Collaboration contract and stack-independent architecture rules |
| `AGENTS.md` | Repository workflow and global rule router |
| `agent-rules/00-core/README.md` | Global engineering invariants and concrete-rule routing |
| `agent-rules/<module>/README.md` | Specialized domain routing for every module affected by the planned work |

Read in this order:

1. Read the root `AGENTS.md` and `agent-rules/00-core/README.md`.
2. Read `docs/coding_rules.md` for collaboration and stack-independent architecture constraints.
3. Read `docs/product.md` to obtain the module inventory and dependency graph.
4. Read every `docs/product/*.md` module file in the topological order declared by the Product overview.
5. Identify the affected rule domains, then read each `agent-rules/<module>/README.md`.
6. Read the relevant concrete Core documents and every concrete document routed by each affected specialized README, including its always-applicable validation document.

If the Product module inventory and the actual module files differ in number, identity, or naming, stop and report the exact mismatch. Do not guess or generate files until the inconsistency is resolved.

## Decomposition rules

1. **Each Feature must be the smallest independently verifiable complete behavior.** Describe what a user can do or what observable result the system produces, not an implementation class or internal layer.
2. **Order execution by prerequisites.** IDs are stable allocation identifiers; a Feature may depend on any existing ID, including a larger one, provided the graph is acyclic. The first Feature must establish runnable infrastructure and must not depend on Product behavior.
3. **Follow module dependencies.** If module A depends on module B, plan B's core Features before A's dependent Features.
4. **Follow architecture constraints.** When Coding Rules require data/presentation separation or pure core rules, schedule data and rule behavior before its presentation behavior.
5. **Fit one AI session.** `small` and `medium` are allowed; any proposed `large` Feature must be split before output.
6. **Do not overdesign.** Include only behavior committed in Product. Exclude explicitly out-of-scope behavior and edge cases that Product explicitly chooses not to handle.
7. **Describe what plus observable acceptance, never how.** Every acceptance criterion must state how a human or automated check can verify the result; reject adjectives such as “correct” without an observable condition.
8. **Prefer complete coverage to elegance.** Every committed module behavior and numeric rule needs corresponding Feature coverage.
9. **Make `source` precise.** Point to the module path and section, for example `product/03-combat.md#Numeric rules`; use `infrastructure` only for infrastructure Features.

## Stable JSON schemas

### Index: `docs/feature-list.json`

```json
{
  "meta": {
    "generated_from": [
      "docs/product.md",
      "docs/product/**/*.md",
      "docs/coding_rules.md"
    ],
    "generated_at": "<ISO 8601 timestamp>",
    "total_features": 1,
    "details_dir": "docs/features/",
    "revisions_file": "docs/feature-list-revisions.json",
    "test_catalog_file": "docs/test-catalog.json",
    "notes": "<decomposition summary in document_language>"
  },
  "features": [
    {
      "id": "F001",
      "title": "<verb phrase in document_language>",
      "status": "pending",
      "depends_on": [],
      "estimated_scope": "small",
      "completed_at": null
    }
  ]
}
```

`estimated_scope` may be `small` or `medium` in final output. `large` is a diagnostic value that requires further decomposition and must never remain in generated output.

### Detail: `docs/features/F0XX.json`

```json
{
  "id": "F001",
  "description": "<two to four sentences in document_language describing observable outcomes>",
  "affected_components": ["<stable_lower_snake_case_component>"],
  "acceptance_criteria": [
    {
      "id": "AC01",
      "text": "<specific observable condition in document_language>",
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
  "source": "<module path and localized section, or infrastructure>",
  "notes": ""
}
```

### Revision log: `docs/feature-list-revisions.json`

```json
{
  "schema_version": 2,
  "revision_log": []
}
```


### Test catalog: `docs/test-catalog.json`

Create a new empty schema only when `docs/test-catalog.json` does not exist. For a new catalog, initialize `meta.schema_version` to `2`, `components` to an empty array, and `tests` to an empty array before adding generated components. Existing catalogs must use version 2. Reject an unsupported format without rewriting it.

When the catalog already exists, read and validate it before any Feature-plan write. Preserve every existing component object, test ID, test mapping, status, path/case, and `full_suite_on_change` value. Never reset `tests` to an empty array and never remove an independent invariant merely because the Feature plan is being regenerated.

Create one candidate component entry for every generated `affected_components` ID that is not already represented. Set `unit_test_paths` to `[]` when no unit suite exists; never prefill a future `test_unit_root/<component>` directory. Non-empty entries are repository-relative paths to existing suite files or directories that must enter the component's Required Test Set. Register a new suite only after its approved Stage 3 creation, as defined in `methodology/08-testing-strategy.md`. Set `full_suite_on_change` to `false` for a new component unless Product/Coding Rules explicitly identify it as cross-cutting. If a generated component ID already exists, reuse its complete existing record; if the planned contract requires different paths or a different full-suite flag, report that as a conflict instead of overwriting it.

Use the project-owned merge helper from the repository root. The temporary candidate file contains a JSON array of complete component objects, or an object with a `components` array; it must not be committed.

```powershell
python -B .agents/skills/generate-feature-list/scripts/merge_test_catalog.py `
  --catalog docs/test-catalog.json `
  --components <temporary-component-candidates.json>
```

The helper validates schema version, component records, registered unit suite path existence, unique component/test IDs, and test-to-component mappings before writing. Retired entries additionally require valid source/reason/replacement/revision relationships against the adjacent Feature index and revision log, using the shared `tools/lib/feature_evolution.py` contract. A malformed existing catalog, missing registered suite path, duplicate ID, missing component mapping, or non-identical candidate for an existing component is a blocking conflict. It writes only after the complete merge validates and preserves all existing test entries by value. Path existence does not prove test discovery; execution must confirm the registered suite actually runs tests.

```json
{
  "meta": {"schema_version": 2},
  "components": [
    {
      "id": "inventory",
      "unit_test_paths": [],
      "full_suite_on_change": false
    }
  ],
  "tests": []
}
```

## Field invariants

- `id`: start at `F001`, increase sequentially, and preserve three digits. Index IDs, detail IDs, and detail filename stems must match one to one.
- `depends_on`: include only actual prerequisite Feature IDs. Store it only in the index. The infrastructure Feature has an empty array. Later IDs are allowed; use `python -B tools/checks/check-feature-list.py --eligible` for pending execution order and never hide prerequisite ordering only in notes.
- `acceptance_criteria`: use stable sequential `ACxx` IDs. Each criterion stores `text` plus empty verification arrays initially; the approved execution-time verification plan fills them.
- `affected_components`: non-empty unique stable semantic component IDs in `lower_snake_case`; do not use file paths.
- `verification`: initialize `regression_tests` to `[]` and `manual_regression` to `null`.
- `source`: point to an existing Product module and section; use `infrastructure` for the infrastructure Feature. For the uncommon cross-module case, identify the primary module.
- `estimated_scope`: store only in the index. `small` fits one implementation and verification session; `medium` fits one session with multiple debugging passes; split every `large` proposal.
- `status`: initialize every Feature to `pending`. Other stable values—`in_progress`, `done`, `obsolete`, `obsolete_done`, and `blocked`—belong to execution and synchronization workflows. Store status only in the index.
- `completed_at`: initialize every value to `null` and store it only in the index.
- `notes`: initialize every detail value to an empty string and store it only in detail files.
- `engineering_change`: optional detail-only enum reserved for `engineering-change-standardizer`; allowed values are `bug`, `refactor`, and `maintenance`. Product-derived Features created here omit it.
- `revision_log`: initialize it to an empty array and store it only in `docs/feature-list-revisions.json`.
- Existing test catalog records are independent durable traceability. Initial generation and complete Feature-plan regeneration may append missing components but may not silently reset, retire, renumber, remap, or delete existing tests.

Never place an unescaped `"` inside a JSON string. Escape embedded ASCII double quotes as `\"`, or use natural quotation marks appropriate to `document_language` when they cannot be mistaken for JSON delimiters.

Validate the index, every detail file, the revision log, and the test catalog with:

`python -B -m json.tool <path> > $null`

After all related files have been written, run the cross-file invariant validator:

`python -B tools/checks/check-feature-list.py`

## Mandatory self-check

Before reporting completion, verify every item:

- [ ] The first Feature is runnable infrastructure with no Product-behavior dependency.
- [ ] The dependency graph is acyclic, all prerequisites exist, and pending eligibility follows dependencies rather than numeric ID order.
- [ ] No final `estimated_scope` is `large`.
- [ ] Every committed core behavior in every Product module has Feature coverage.
- [ ] No explicitly excluded or deliberately unhandled behavior appears in the plan.
- [ ] Feature order reflects Coding Rules such as data/presentation separation and pure core rules.
- [ ] Every detail `source` resolves to an existing Product module and section, or is exactly `infrastructure`.
- [ ] Every Feature has stable sequential `ACxx` criterion IDs and non-empty `affected_components`.
- [ ] Every affected component exists in `docs/test-catalog.json`.
- [ ] Every referenced dependency ID exists.
- [ ] Every initial status is `pending`, every `completed_at` is `null`, and every detail `notes` is `""`.
- [ ] `docs/feature-list-revisions.json` is exactly the empty revision-log structure.
- [ ] A new `docs/test-catalog.json` uses schema version 2 and contains every generated component ID; existing current-format records remain intact.
- [ ] Components without existing unit suites use `unit_test_paths: []`; every registered unit suite path resolves to an existing repository file or directory.
- [ ] If the test catalog predated this run, every existing component record, test ID, complete test mapping, and `full_suite_on_change` value is preserved.
- [ ] Complete regeneration did not remove an independent invariant; any stale acceptance/regression conflict was reported rather than silently cleared.
- [ ] The set of index IDs equals the set of `docs/features/F*.json` filename stems and equals `meta.total_features` in count.
- [ ] The index, every detail file, the revision log, and the test catalog pass JSON parsing without unescaped double quotes.

Fix every failed check before presenting the generated files as complete.

## Output sequence

1. After reading all inputs, give the user a plan summary of no more than six sentences. State the decomposition order and layers, total Feature count, approximate count per module, and every Product contradiction or ambiguity.
2. If any question remains, stop and wait for the user's answer. Do not write JSON.
3. When there is no unresolved question, prepare the temporary component-candidate JSON and run the merge helper before any Feature-plan write. Continue only after it has either created the absent catalog or validated and merged the existing one without conflict.
4. Write the index, every detail file, and the empty revision log; create `docs/features/` if necessary. Do not rewrite the catalog by hand after the helper succeeds.
5. Run the complete self-check and JSON validation.
6. Follow `agent-rules/00-core/git-worktree-and-commits.md`: inspect and stage only the explicit generated Feature-plan paths, run all cached-diff checks, and create one local `chore(feature-plan): <中文行为摘要>` commit unless the user explicitly requested no commit. Do not use a broad `docs/features/` staging path, and omit `Work item` because this commit creates the plan rather than implementing one Feature. Confirm `git status --short` afterward.
7. Only after all checks and the local commit pass, report the generated files and identify the first executable Feature.
8. Do not implement or start the first Feature. Execution belongs to `execute-next-feature`.

Acceptance planning follows `methodology/02-feature-list-schema.md`: decide from the requirement before filling checks. Visual/audio/feel or other human judgment requires manual acceptance; fully automated AC may use automated acceptance. Leave `verification.acceptance_mode: null` only while undecided, and resolve it in execute Stage 1. Empty check arrays do not decide the mode.
