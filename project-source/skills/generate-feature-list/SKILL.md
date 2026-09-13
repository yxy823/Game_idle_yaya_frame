---
name: generate-feature-list
description: "Decompose only the current Product into Features and append them to the project ledger. Use for the first Product or the next Product after the current Product's Features are complete. Reuse existing plans and use sync-feature-list for their changes. English triggers: generate feature list, decompose current product, plan next product. 中文触发：拆分当前 Product、生成 Feature、规划下一个 Product。"
---

# Generate Feature list

## Purpose and routing boundary

Follow **Product-by-Product planning** in `methodology/02-feature-list-schema.md`.
Use this workflow to initially decompose the current Product, whether the
project ledger is absent, empty, or already contains previous Products. Finish
the current Product's required Features before planning the next Product.

Identify the selected Product and its approved scope before writing. Reuse an
existing plan for that scope; use `sync-feature-list` for changes to it. A ledger
that contains earlier Products is normal and is not a request for replacement.
Do not decompose all Product modules, clear the ledger or regenerate old tasks.

## Language contract

Before generating durable Feature content:

1. Read `document_language` from `docs/methodology-config.json`.
2. Resolve missing, invalid, or migration-sensitive configuration through `methodology/05-document-language.md` before writing any Feature files.
3. Use the language of the user's current message for conversation.
4. Write Feature titles, descriptions, acceptance criteria, human-readable `source` fragments, meta notes, and Feature notes in `document_language`.
5. Keep JSON keys, enum values, Feature IDs, dependency IDs, scopes, timestamps, filenames, paths, commands, and structural validation language-neutral and exactly as specified here.

With `document_language: en` and a Chinese conversation, discuss the plan in Chinese but write Feature prose in English. With `document_language: zh-CN` and an English conversation, discuss the plan in English but write Feature prose in Simplified Chinese.

## Four-artifact output structure

Keep these artifact types consistent when adding the current Product's plan:

| Path | Content |
|---|---|
| `docs/feature-list.json` | Lightweight index containing `meta` and each Feature's `id`, `title`, `status`, `depends_on`, `estimated_scope`, and `completed_at` |
| `docs/features/F0XX.json` | One detail file per Feature containing stable criterion IDs, `affected_components`, verification mapping, source, and notes |
| `docs/feature-list-revisions.json` | Initialize the version-2 empty log only when absent; preserve an existing log unchanged |
| `docs/test-registry.json` | Component/test traceability registry; create it only when absent, otherwise validate and merge without replacing existing records |

Read the existing index, selected/prerequisite Feature details, revision log and
Registry before planning. Append only new index entries and detail files;
preserve all existing records, IDs and completion history. If a record conflicts
with the proposed scope, resolve the conflict through the owning workflow,
without deleting or silently rewriting it. Missing index with orphaned details
or existing history is a repair question, not permission to initialize over it.

## Required inputs

Read every relevant input before planning. Also read test roots/framework from `docs/methodology-config.json`:

Read relevant definitions in `docs/CONTEXT.md` when present and use the agreed
names consistently. CONTEXT explains vocabulary; Product remains the source
of behavior and AC. A terminology-only request belongs to the standardizer's
terminology maintenance route and does not generate a Feature plan.

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
| Current `docs/product/NN-xxx.md` | Complete approved behavior, data and state, UI, audio, values, acceptance criteria, and edge cases for this Product |
| `docs/coding_rules.md` | Collaboration contract and stack-independent architecture rules |
| `AGENTS.md` | Repository workflow and global rule router |
| `agent-rules/00-core/README.md` | Global engineering invariants and concrete-rule routing |
| `agent-rules/<module>/README.md` | Specialized domain routing for every module affected by the planned work |

Read in this order:

1. Read the root `AGENTS.md` and `agent-rules/00-core/README.md`.
2. Read `docs/coding_rules.md` for collaboration and stack-independent architecture constraints.
3. Read `docs/product.md` to identify the actual Product execution order and dependencies; confirm the current Product against existing Feature sources/statuses.
4. Read the current Product's complete specification and only the other module sections needed to understand prerequisites or affected contracts. Later modules are context, not scope to decompose now.
5. Identify the affected rule domains, then read each `agent-rules/<module>/README.md`.
6. Read the relevant concrete Core documents and every concrete document routed by each affected specialized README, including its always-applicable validation document.

If the Product module inventory and the actual module files differ in number, identity, or naming, stop and report the exact mismatch. Do not guess or generate files until the inconsistency is resolved.

## Decomposition rules

1. **Each Feature must be the smallest independently verifiable complete behavior.** Describe what a user can do or what observable result the system produces, not an implementation class or internal layer.
2. **Order execution by prerequisites.** IDs are stable allocation identifiers; a Feature may depend on any existing ID, including a larger one, provided the graph is acyclic. Establish missing runnable infrastructure for the current Product; do not create another infrastructure Feature when the required foundation already exists.
3. **Follow Product order.** If Product A requires unfinished Product B, deliver B first. Decompose A only after the current Product's required Features are complete.
4. **Follow architecture constraints.** When Coding Rules require data/presentation separation or pure core rules, schedule data and rule behavior before its presentation behavior.
5. **Fit one AI session.** `small` and `medium` are allowed; any proposed `large` Feature must be split before output.
6. **Do not overdesign.** Include only the current Product's approved scope. Leave later Products unplanned even when their documents are already committed. Exclude explicitly out-of-scope behavior and deliberately deferred edge cases.
7. **Describe what plus observable acceptance, never how.** Every acceptance criterion must state how a human or automated check can verify the result; reject adjectives such as “correct” without an observable condition.
8. **Cover the current Product completely.** Its required behaviors and numeric rules need corresponding Feature coverage; later Products do not need placeholder Features or test registrations.
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


### Test registry: `docs/test-registry.json`

This is the fixed project-relative location used by the merge helper, checker,
test selector and completion check. Do not add a configurable path or repeat it
in Feature-index metadata. Run the merge command from the project root.

Create a new empty schema only when `docs/test-registry.json` does not exist. For a new registry, initialize `meta.schema_version` to `2`, `components` to an empty array, and `tests` to an empty array before adding generated components. Existing registries must use version 2. Reject an unsupported format without rewriting it.

When the registry already exists, read and validate it before any Feature-plan write. Preserve every existing component object, test ID, test mapping, status, path/case, and `full_suite_on_change` value. Never reset `tests` to an empty array or remove an independent invariant when adding another Product's Features.

Create one candidate component entry for every generated `affected_components` ID that is not already represented. Set `unit_test_paths` to `[]` when no unit suite exists; never prefill a future `test_unit_root/<component>` directory. Non-empty entries are repository-relative paths to existing suite files or directories that must enter the component's Required Test Set. Register a new suite only after its approved Stage 3 creation, as defined in `methodology/08-testing-strategy.md`. Set `full_suite_on_change` to `false` for a new component unless Product/Coding Rules explicitly identify it as cross-cutting. If a generated component ID already exists, reuse its complete existing record; if the planned contract requires different paths or a different full-suite flag, report that as a conflict instead of overwriting it.

Use the project-owned merge helper from the repository root. The temporary candidate file contains a JSON array of complete component objects, or an object with a `components` array; it must not be committed.

```powershell
python -B .agents/skills/generate-feature-list/scripts/merge_test_registry.py `
  --components <temporary-component-candidates.json>
```

The helper validates schema version, component records, registered unit suite path existence, unique component/test IDs, and test-to-component mappings before writing. Retired entries additionally require valid source/reason/replacement/revision relationships against the adjacent Feature index and revision log, using the shared `tools/lib/feature_evolution.py` contract. A malformed existing registry, missing registered suite path, duplicate ID, missing component mapping, or non-identical candidate for an existing component is a blocking conflict. It writes only after the complete merge validates and preserves all existing test entries by value. Path existence does not prove test discovery; execution must confirm the registered suite actually runs tests.

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

- `id`: start at `F001` only for the first plan; otherwise append after the greatest existing ID, including retired entries. Preserve three digits and all earlier IDs. Index IDs, detail IDs, and detail filename stems must match one to one.
- `depends_on`: include only actual prerequisite Feature IDs. Store it only in the index. The infrastructure Feature has an empty array. Later IDs are allowed; use `python -B tools/checks/check-feature-list.py --eligible` for pending execution order and never hide prerequisite ordering only in notes.
- `acceptance_criteria`: use stable sequential `ACxx` IDs. Each criterion stores `text` plus empty verification arrays initially; the approved execution-time verification plan fills them.
- `affected_components`: non-empty unique stable semantic component IDs in `lower_snake_case`; do not use file paths.
- `verification`: initialize `regression_tests` to `[]` and `manual_regression` to `null`.
- `source`: point to an existing Product module and section; use `infrastructure` for the infrastructure Feature. For the uncommon cross-module case, identify the primary module.
- `estimated_scope`: store only in the index. `small` fits one implementation and verification session; `medium` fits one session with multiple debugging passes; split every `large` proposal.
- `status`: initialize each new Feature to `pending`; preserve existing statuses. Other stable values—`in_progress`, `done`, `obsolete`, `obsolete_done`, and `blocked`—belong to execution and synchronization workflows. Store status only in the index.
- `completed_at`: initialize new values to `null`; preserve existing values. Store it only in the index.
- `notes`: initialize new detail values to an empty string; preserve existing notes. Store it only in detail files.
- `engineering_change`: optional detail-only enum reserved for `engineering-change-standardizer`; allowed values are `bug`, `refactor`, and `maintenance`. Product-derived Features created here omit it.
- `revision_log`: initialize the version-2 empty log only when absent and store it only in `docs/feature-list-revisions.json`. Appending a newly current Product does not reset or advance the source synchronization anchor; it reads that Product's current specification directly.
- Existing test registry records are independent durable traceability. Adding a Product's plan may append needed components but may not silently reset, retire, renumber, remap, or delete existing tests.

Never place an unescaped `"` inside a JSON string. Escape embedded ASCII double quotes as `\"`, or use natural quotation marks appropriate to `document_language` when they cannot be mistaken for JSON delimiters.

Validate the index, every detail file, the revision log, and the test registry with:

`python -B -m json.tool <path> > $null`

After all related files have been written, run the cross-file invariant validator:

`python -B tools/checks/check-feature-list.py`

## Mandatory self-check

Before reporting completion, verify every item:

- [ ] Exactly one current Product is being decomposed; the preceding Product's required Features are complete, and the chosen scope has not already been planned.
- [ ] Required runnable infrastructure exists or is included without duplicating the existing foundation.
- [ ] The dependency graph is acyclic, all prerequisites exist, and pending eligibility follows dependencies rather than numeric ID order.
- [ ] No final `estimated_scope` is `large`.
- [ ] Every required behavior of the current Product has Feature coverage; later Products have received no new Features or test registrations.
- [ ] No explicitly excluded or deliberately unhandled behavior appears in the plan.
- [ ] Feature order reflects Coding Rules such as data/presentation separation and pure core rules.
- [ ] Every detail `source` resolves to an existing Product module and section, or is exactly `infrastructure`.
- [ ] Every Feature has stable sequential `ACxx` criterion IDs and non-empty `affected_components`.
- [ ] Every affected component exists in `docs/test-registry.json`.
- [ ] Every referenced dependency ID exists.
- [ ] New statuses are `pending`, new `completed_at` values are `null`, and new detail `notes` are `""`; all previous Feature records remain unchanged.
- [ ] A missing revision log is initialized with schema version 2; an existing log and its source anchors remain unchanged.
- [ ] A new `docs/test-registry.json` uses schema version 2 and contains every generated component ID; existing current-format records remain intact.
- [ ] Components without existing unit suites use `unit_test_paths: []`; every registered unit suite path resolves to an existing repository file or directory.
- [ ] If the test registry predated this run, every existing component record, test ID, complete test mapping, and `full_suite_on_change` value is preserved.
- [ ] Existing history and independent invariants remain intact; any acceptance/regression conflict was reported rather than silently cleared.
- [ ] The set of index IDs equals the set of `docs/features/F*.json` filename stems and equals `meta.total_features` in count.
- [ ] The index, every detail file, the revision log, and the test registry pass JSON parsing without unescaped double quotes.

Fix every failed check before presenting the generated files as complete.

## Output sequence

Use **Requirement coverage review** in `methodology/02-feature-list-schema.md`
within the summary below: connect each current requirement to proposed Feature/AC,
verification work and any gap. Reuse existing coverage where it still matches;
new test mappings may remain for execution-time planning. After writing, refresh
the same summary with actual IDs and remaining work instead of creating another
report file or repeating the whole Product specification.

1. After reading the needed inputs, give a concise summary naming the current Product, its scope, why it is next, proposed new Features and dependencies, and any material ambiguity. Distinguish newly added work from the existing ledger total; do not estimate later Products' Feature lists.
2. If any question remains, stop and wait for the user's answer. Do not write JSON.
3. When there is no unresolved question, prepare the temporary component-candidate JSON and run the merge helper before any Feature-plan write. Continue only after it has either created the absent registry or validated and merged the existing one without conflict.
4. Append the approved new entries to the index and write only their detail files; create `docs/features/` if necessary. Update index totals/time and its decomposition summary to identify the Product just planned. Initialize the revision log only if absent. Preserve existing Features, metadata unrelated to this addition and all revision history. Do not rewrite the registry by hand after the helper succeeds.
5. Run the complete self-check and JSON validation.
6. Follow `agent-rules/00-core/git-worktree-and-commits.md`: inspect and stage only the explicit generated Feature-plan paths, run all cached-diff checks, and create one local `chore(feature-plan): <中文行为摘要>` commit unless the user explicitly requested no commit. Do not use a broad `docs/features/` staging path, and omit `Work item` because this commit creates the plan rather than implementing one Feature. Confirm `git status --short` afterward.
7. Only after all checks and the local commit pass, report the added files and first executable Feature for the current Product. State that later Products remain for planning after this Product is complete.
8. Stop without implementing a Feature or decomposing the next Product. Execution belongs to `execute-next-feature`.

Acceptance planning follows `methodology/02-feature-list-schema.md`: decide from the requirement before filling checks. Visual/audio/feel or other human judgment requires manual acceptance; fully automated AC may use automated acceptance. Leave `verification.acceptance_mode: null` only while undecided, and resolve it in execute Stage 1. Empty check arrays do not decide the mode.
