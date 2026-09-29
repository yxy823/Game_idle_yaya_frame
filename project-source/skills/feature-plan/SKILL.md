---
name: feature-plan
description: Decompose the current documented Product delivery scope into complete Features. Requires existing GDD sources; reuse existing plans and use feature-sync for changes.
---

# Generate Feature list

## Authority and inputs

Use **Product-by-Product planning**, **Decomposition preview**, **Decomposition rules**, **Requirement coverage review** and the index/detail/revision/Registry contracts in `methodology/02-feature-list-schema.md`. This Skill owns the planning procedure and component merge below; it does not maintain another schema.

When the requested scope already has implementation but lacks Feature records, also apply **Adopting existing implementation** in that specification. Reuse the actual implementation and tests in the proposal; planning does not mark the adopted work complete.

Apply `methodology/05-document-language.md` before durable prose. Resolve `document_language` from confirmed configuration; preserve existing history. Before durable writes, apply the change-preservation and commit contract in `agent-rules/00-core/git-worktree-and-commits.md`.

Apply the GDD prerequisite in methodology 01. Read the current Product's approved delivery document and the actual GDD topics it adopts, with `docs/product.md` for boundaries, dependencies and order. If the current delivery document is missing, use `product-author` to detail that unit within existing authorization before planning. Consult relevant terminology, professional requirements and project rules. Later Products remain overview outlines; do not create their documents or Features. Reuse unchanged reading on continuation.

Follow **Discover and map sources** in `methodology/11-specialist-workflows.md`: include applicable GDD, UI, art, audio, resource and localization requirements through actual links and shared applicability. Preserve one primary `source`; put precise secondary references in concrete AC or the optional Feature design. Map each relevant requirement to an observable outcome and a verification action, not a generic “conforms to the Bible”. `meta.generated_from` names actual source locations, not proof that every file or later Product has been planned.

| Existing artifact | Needed context |
| --- | --- |
| `docs/feature-list.json` | Full lightweight index: current Product, prior plan coverage, statuses, IDs and prerequisites |
| `docs/features/F0XX.json` | Selected, prerequisite or potentially conflicting details |
| `docs/feature-list-revisions.json` | Existing revision history/anchor; establish the eligible first baseline under the schema |
| `docs/test-registry.json` | Existing component/test records before proposing additions |

An existing empty or populated ledger can receive the current Product's first plan. Reuse already planned scope and route its changes to `feature-sync`. Do not replace earlier plans. Require the creator-supplied index, revision log and Registry under the canonical schema; a missing file requires repair before planning. Report a missing current or previously documented Product source; a future outline intentionally has no file and is not a mismatch.

## Plan and write

1. Identify the current Product and its approved scope from actual source and completion state. Establish needed runnable infrastructure only when it does not already exist. Apply accepted architecture constraints and **Visual prototype before dependent implementation** in `methodology/01-product-doc-structure.md` to the actual prerequisite order; production domain/presentation separation does not require developing business logic before an independent visual prototype. Check applicable `docs/project-rules.md` hard constraints as well. Do not decompose a conflicting Product into an apparently valid plan; resolve the rule/Product choice through the existing owner. Note an actual need for detailed Feature design or an ADR for Stage 1 rather than creating one for every work item.
2. Propose independently verifiable, session-sized outcomes under the canonical decomposition rules, including their outcome and prerequisite checks. Use the current Product as the primary delivery source and precise GDD/professional links in AC or design. Cover its complete necessary scope in this plan; do not encode class structure as game design or pre-plan later Products.
3. Present the canonical **Decomposition preview** in the conversation, including Feature counts and every Feature's summary/dependencies, why this Product is next and the requirement coverage correspondence. Apply its confirmation and explicit autonomous-planning rules before any Registry or Feature-plan write; resolve missing material decisions.
4. After Step 3 permits writing, establish the committed source state for an eligible first plan under **Initial planning baseline** in `methodology/02-feature-list-schema.md`. Then run the Registry merge below before any Feature-plan write. Continue only after a validated conflict-free merge.
5. Append new index entries and only their detail files, using canonical initial planning values. Update index time, decomposition notes and actual newly used GDD and professional source locations in `meta.generated_from`. Preserve existing Features, unrelated metadata and revision history. After semantic coverage review, append only the eligible initial baseline under that contract before final validation. Later Product planning does not advance the synchronization anchor. Do not rewrite Registry data by hand after a successful merge.
6. Complete validation and semantic review below. Refresh the same proposal with actual IDs and remaining work rather than creating another report file.
7. Follow the Git contract above for explicit task-owned staging, cached-diff review and the local commit. Use `chore(feature-plan): <中文行为摘要>`; omit `Work item` because this creates a plan. Do not stage a broad `docs/features/` path.
8. Report the result and first eligible Feature for this Product. Return to the calling workflow under **Authorization and continuation** in `methodology/03-execute-loop.md`; authorized implementation uses `feature-execute`. Planning success grants no later-Product scope.

## Test registry: `docs/test-registry.json`

This is the fixed project-relative location used by the merge helper, checker, test selector and completion check. Do not add a configurable path or repeat it in Feature-index metadata. Run the merge command from the project root.

Use the project-supplied version-3 registry and version-2 revision log under `methodology/02-feature-list-schema.md`.

Read and validate the registry before any Feature-plan write. Preserve every existing component object, test ID, test mapping, status, path/case, and `full_suite_on_change` value. Never reset `tests` to an empty array or remove an independent invariant when adding another Product's Features.

Create one candidate component entry for every generated `affected_components` ID that is not already represented. Set `unit_test_paths` to `[]` when no unit suite exists. Apply **Registry rules** in `methodology/08-testing-strategy.md` for path requirements, registration timing and Required Test Set inclusion. Set `full_suite_on_change` to `false` for a new component unless Product/Project Rules explicitly identify it as cross-cutting. If a generated component ID already exists, reuse its complete existing record; if the planned contract requires different paths or a different full-suite flag, report that as a conflict instead of overwriting it.

Use the project-owned merge helper from the repository root. The temporary candidate file contains a JSON array of complete component objects, or an object with a `components` array; it must not be committed.

```powershell
python -B tools/features/merge-test-registry.py `
  --components <temporary-component-candidates.json>
```

The helper requires the adjacent Feature index and revision log, then validates schema version, component records, repository boundaries and existence for current test paths, unique component/test IDs, and test-to-component mappings before writing. Path and historical-record semantics follow the Registry contract in `methodology/02-feature-list-schema.md`. Retired entries additionally require valid source/reason/replacement/revision relationships using the shared `tools/lib/feature_evolution.py` contract. A malformed existing registry, invalid or missing current test path, duplicate ID, missing component mapping, or non-identical candidate for an existing component is a blocking conflict. It writes only after the complete merge validates and preserves all existing test entries by value. Path existence does not prove test discovery; execution must confirm the registered suite actually runs tests.

```json
{
  "meta": {"schema_version": 3},
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

This checks JSON parsing and cross-file invariants together. Use a separate syntax check only to diagnose an individual error. The Agent still reviews what the checker cannot establish:

- The chosen Product is current and unplanned; its required scope is covered without duplicate infrastructure, excluded behavior or premature later plans.
- The written Feature count, boundaries and dependencies match the confirmed preview or the latest preview under explicit autonomous-planning authority.
- Sources name the actual requirement sections; dependencies reflect real prerequisites and applicable architecture constraints.
- New records use the schema's initial planning values, and the actual diff preserves previous Features, revision anchors, Registry records and independent invariants except for approved component additions and the eligible first baseline. Verify its source commit and covered scope; an existing plan with missing history is not a fresh empty ledger.

Resolve failed validation or a material semantic gap before reporting completion.
