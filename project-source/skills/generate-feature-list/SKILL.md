---
name: generate-feature-list
description: "Decompose only the current Product into Features and append them to the project ledger. Use for the first Product or the next Product after the current Product's Features are complete. Reuse existing plans and use sync-feature-list for their changes. English triggers: generate feature list, decompose current product, plan next product. 中文触发：拆分当前 Product、生成 Feature、规划下一个 Product。"
---

# Generate Feature list

## Authority and inputs

Use **Product-by-Product planning**, **Decomposition preview**, **Decomposition
rules**, **Requirement coverage review** and the index/detail/revision/Registry contracts in
`methodology/02-feature-list-schema.md`. This Skill owns the planning procedure
and component merge below; it does not maintain another schema.

When the requested scope already has implementation but lacks Feature records,
also apply **Adopting existing implementation** in that specification. Reuse
the actual implementation and tests in the proposal; planning does not mark
the adopted work complete.

Apply `methodology/05-document-language.md` before durable prose. Resolve
`document_language` from confirmed configuration; preserve existing history.
Before durable writes, apply the preflight and ownership contract in
`agent-rules/00-core/git-worktree-and-commits.md`.

Read the selected Product's complete approved specification, with
`docs/product.md` to establish order and shared requirements. Consult relevant
terminology definitions, prerequisite/affected module sections, configuration and
rules through `AGENTS.md`. Other Product modules are context only when needed,
not work to decompose now. Reuse unchanged reading on continuation.

| Existing artifact | Needed context |
| --- | --- |
| `docs/feature-list.json` | Full lightweight index: current Product, prior plan coverage, statuses, IDs and prerequisites |
| `docs/features/F0XX.json` | Selected, prerequisite or potentially conflicting details |
| `docs/feature-list-revisions.json` | Existing revision history/anchor to preserve |
| `docs/test-registry.json` | Existing component/test records before proposing additions |

An absent, empty or populated ledger can receive the current Product's first
plan. Reuse already planned scope and route its changes to `sync-feature-list`.
Do not replace earlier plans. An absent index with orphaned details/history is
a repair question, not permission to initialize over them. Report actual module
inventory/file mismatches and resolve them before planning; do not guess names.

## Plan and write

1. Identify the current Product and its approved scope from actual source and
   completion state. Establish needed runnable infrastructure only when it does
   not already exist. Apply accepted architecture constraints and **Visual
   prototype before dependent implementation** in `methodology/01-product-doc-structure.md`
   to the actual prerequisite order; production domain/presentation separation
   does not require developing business logic before an independent visual prototype.
   Check applicable `docs/project-rules.md` hard constraints as well. Do not decompose a conflicting Product into an apparently valid plan; resolve the rule/Product choice through the existing owner. Note an actual need for detailed Feature design or an ADR for Stage 1 rather than creating one for every work item.
2. Propose independently verifiable, session-sized outcomes under the canonical
   decomposition rules. Use precise source sections and observable criteria;
   do not encode class structure as Product behavior or pre-plan later Products.
3. Present the canonical **Decomposition preview** in the conversation, including
   Feature counts and every Feature's summary/dependencies, why this Product is
   next and the requirement coverage correspondence. Apply its confirmation and
   explicit autonomous-planning rules before any Registry or Feature-plan write;
   resolve missing material decisions.
4. After Step 3 permits writing, run the Registry merge below before any
   Feature-plan write. Continue only after absent-registry initialization or
   validated conflict-free merge.
5. Append new index entries and only their detail files, using canonical initial
   planning values. Update index totals/time and decomposition notes. Initialize
   the revision log only if absent; preserve existing Features, metadata unrelated
   to this addition and revision history. Planning a newly current Product does
   not advance the synchronization anchor. Do not rewrite Registry data by hand
   after a successful merge.
6. Complete validation and semantic review below. Refresh the same proposal with
   actual IDs and remaining work rather than creating another report file.
7. Follow the Git contract above for explicit task-owned staging, cached-diff
   review and the local commit. Use
   `chore(feature-plan): <中文行为摘要>`; omit `Work item` because this creates
   a plan. Do not stage a broad `docs/features/` path.
8. Report the result and first eligible Feature for this Product. Return to the
   calling workflow under **Authorization and continuation** in
   `methodology/03-execute-loop.md`; authorized implementation uses
   `execute-next-feature`. Planning success grants no later-Product scope.

## Test registry: `docs/test-registry.json`

This is the fixed project-relative location used by the merge helper, checker,
test selector and completion check. Do not add a configurable path or repeat it
in Feature-index metadata. Run the merge command from the project root.

Create a new empty schema only when `docs/test-registry.json` does not exist. For a new registry, initialize `meta.schema_version` to `2`, `components` to an empty array, and `tests` to an empty array before adding generated components. Existing registries must use version 2. Reject an unsupported format without rewriting it.

When the registry already exists, read and validate it before any Feature-plan write. Preserve every existing component object, test ID, test mapping, status, path/case, and `full_suite_on_change` value. Never reset `tests` to an empty array or remove an independent invariant when adding another Product's Features.

Create one candidate component entry for every generated `affected_components` ID that is not already represented. Set `unit_test_paths` to `[]` when no unit suite exists; never prefill a future `test_unit_root/<component>` directory. Non-empty entries are repository-relative paths to existing suite files or directories that must enter the component's Required Test Set. Register a new suite only after its approved Stage 3 creation, as defined in `methodology/08-testing-strategy.md`. Set `full_suite_on_change` to `false` for a new component unless Product/Project Rules explicitly identify it as cross-cutting. If a generated component ID already exists, reuse its complete existing record; if the planned contract requires different paths or a different full-suite flag, report that as a conflict instead of overwriting it.

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

## Validation and semantic review

After all related files are consistent, run:

`python -B tools/checks/check-feature-list.py`

This checks JSON parsing and cross-file invariants together. Use a separate
syntax check only to diagnose an individual error. The Agent still reviews
what the checker cannot establish:

- The chosen Product is current and unplanned; its required scope is covered
  without duplicate infrastructure, excluded behavior or premature later plans.
- The written Feature count, boundaries and dependencies match the confirmed
  preview or the latest preview under explicit autonomous-planning authority.
- Sources name the actual requirement sections; dependencies reflect real
  prerequisites and applicable architecture constraints.
- New records use the schema's initial planning values, and the actual diff
  preserves previous Features, revision anchors, Registry records and independent
  invariants except for approved component additions.

Resolve failed validation or a material semantic gap before reporting completion.
