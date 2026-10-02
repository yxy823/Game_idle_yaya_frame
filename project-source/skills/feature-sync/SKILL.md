---
name: feature-sync
description: >-
  Synchronize existing Feature/test plans with committed GDD, Product delivery, professional specification or Project Rules changes. Use for source-impact analysis and current-plan realignment, not initial decomposition.
---

# Synchronize Feature list

Apply the existing-GDD prerequisite in methodology 01, then run the seven-stage workflow below. An existing plan does not substitute for GDD.

The core method is to identify source changes through Git diffs against a recorded anchor. Never infer historical change merely by comparing the current source documents with the current Feature plan.

Follow **Product-by-Product planning** in `methodology/02-feature-list-schema.md`. Synchronize actual effects on existing work; do not initially decompose a later Product just because its document was added or revised. When the next Product becomes current, `product-author` details its scope from the latest GDD before `feature-plan` appends its complete plan, even if those source edits predate this workflow's anchor.

## Shared contracts

Use the artifact schemas, Product order and evolution invariants in `methodology/02-feature-list-schema.md`. Apply `methodology/05-document-language.md` for new durable prose; preserve completed history and original evidence instead of translating them. Read `document_language` from the current configuration.

Git change preservation, task continuation in the target checkout and commit mechanics follow `agent-rules/00-core/git-worktree-and-commits.md`. The stages below own the committed-source comparison, approval and synchronized plan; use relevant rule sections through project `AGENTS.md` when interpreting a changed engineering contract.

Read applicable **Design scope and boundaries** in `methodology/01-product-doc-structure.md`, engineering constraints in `docs/project-rules.md` and affected Feature designs when explaining plan impacts. This workflow updates the ledger, not the governing source: game-design boundaries return to `design-gdd`, while engineering-rule writes follow the self-check and authorization in `methodology/04-coding-rules-4-layers.md`. Preserve completed Feature designs as history; current architecture and later Feature designs carry subsequent changes.

## Ledger structure

| Path | Role | Access pattern |
|---|---|---|
| `docs/feature-list.json` | Index: each Feature's `id`, `title`, `status`, `depends_on`, `estimated_scope`, and `completed_at` | Read the full index for scanning; update the index together with corresponding details |
| `docs/features/F0XX.json` | Detail: stable criteria, `affected_components`, verification mapping, source, notes | Read details on demand; update each affected detail together with the index |
| `docs/test-registry.json` | Component/test traceability used for stale-test impact analysis | Read before proposing revisions; update approved new components, replacement test mappings, retirements and path metadata |
| `docs/feature-list-revisions.json` | Append-only `revision_log` | Read the last entry for the previous anchor; append one entry in Stage 5 |

## Source documents

Read relevant `docs/terminology.md` definitions when present to interpret the source diff consistently. Terminology is not a separate behavior source to synchronize: substantive game-design changes must be expressed in GDD. Meaning-preserving terminology maintenance alone does not require this workflow; later source diffs treat its local definition/link edits as editorial changes.

Synchronization watches:

- `docs/gdd/` for game-design intent, rules, states, values, version scope and design acceptance;
- `docs/product.md` for delivery outlines, source mappings, boundaries, dependencies and order;
- existing `docs/product/NN-xxx.md` delivery documents for adopted scope, integration and delivery acceptance;
- `docs/project-rules.md` and its routed repository rule sources (for this project, `agent-rules/`) for collaboration, architecture, and technology constraints.
- Applicable professional sources in `docs/art/`, `docs/audio/`, `docs/ui/`, `docs/localization/` and `docs/presentation/`, plus other owning paths discovered through actual references.

Apply **Discover and map sources** in `methodology/11-specialist-workflows.md`. The default directory list is not exhaustive: inspect references and shared applicability. Proposed wording is not a confirmed contract. Resource status or location changes may be editorial for planning while still changing the global completion fingerprint.

Between synchronizations, module files may be added, deleted, renamed—including numeric-prefix changes—or modified. The diff analysis must handle all four cases.

## Stage 0: preflight and anchor

**Entry:** the user invokes this workflow.

**Output:** a ready environment and an identified comparison anchor.

1. Read the project-supplied `docs/feature-list.json`, `docs/feature-list-revisions.json` and `docs/test-registry.json`; missing files require repair under the canonical schema before routing or writes.
   - If the valid index has no Features, return to current Product preparation through `product-author` and then authorized `feature-plan`; do not generate all Product documents.
   - Otherwise, use the full index for status, dependencies and derived counts. Read individual detail files only when Stage 2 mapping or Stage 4 changes require them.
2. Check Git.
   - Read and report the current branch; `main` and `master` are valid. Do not change branches.
   - Run `git status --porcelain` and inspect relevant differences. Preserve unfinished work; unrelated changes do not block source analysis. Resolve actual overlapping plan edits or conflicts before dependent writes, without stashing, discarding or absorbing other changes.
   - Sources used for synchronization must be committed separately before dependent plan writes so the diff and next anchor remain meaningful. Report any relevant uncommitted source and return its approved change to its owner; do not turn an unrelated dirty path into a blanket blocker.
3. Determine the anchor commit.
   - Prefer `synced_at_commit` from the last `revision_log` entry and verify that the commit is available in the current history. This includes the first `R000` planning baseline defined in `methodology/02-feature-list-schema.md`; its declared coverage is limited to the actually planned Product and adopted sources.
   - Without a usable recorded anchor, inspect planning commits and their actual Product/Feature contents. Choose a verified source state already reflected in the relevant plan, early enough to include all unsynchronized changes to existing work. Merely touching an index/detail, updating notes/status or adding an engineering Feature does not prove source synchronization; neither does the first appearance of an empty copied index. Later Product planning must not silently advance the baseline for older work.
   - If no reliable baseline can be established, disclose the missing historical evidence and offer whole-document alignment of current sources and the current plan. Continue that fallback only within explicit authorization; do not ask again if this concrete scope is already approved. An empty diff from an unverified recent commit is not evidence that nothing changed.
4. Report the current branch, verified anchor hash/date/subject and its source-coverage basis, or the fallback and inspected HEAD; include counts grouped by Feature status.

Before reusing any anchor for newly admitted GDD or professional sources, establish whether the affected plan actually incorporated them. A source predating the anchor can still be unsynchronized. Compare historical source/plan contents; when coverage is unknown, use the authorized current-document fallback for that affected planned scope alongside any verified diffs. Report the distinction and do not advance the anchor as if unknown history had been checked.

## Stage 1: user prior

**Entry:** Stage 0 passed.

**Output:** an optional statement of the user's main intent for this synchronization.

Reuse the user's supplied change description when present; otherwise continue directly to the diff with no prior. Ask only if inspected changes leave a material intent ambiguity. Store an actual supplied answer for Stage 2 and the revision entry, or use `user_intent: null`; do not invent a user statement from the diff.

## Stage 2: Git-diff analysis

**Entry:** Stage 1 finished or was skipped.

**Output:** a precise diff report; no files modified.

### 2.1 Collect the complete diff

For the approved whole-document fallback, read the complete current sources relevant to existing work and compare them with the current plan. Report present alignment gaps and unknown history, not invented historical additions/removals. Use the report title `Current-document alignment (historical baseline unverified; HEAD <hash>)`. Skip the unavailable before/after diff below; all scope, impact and Stage 3 approval rules still apply, including deferred planning of later Products.

Inspect committed changes from the anchor to `HEAD`. Cover all source paths and enable rename detection for module files:

```powershell
git diff --name-status -M <anchor> HEAD -- docs/gdd/
git diff -M <anchor> HEAD -- docs/gdd/

git diff <anchor> HEAD -- docs/product.md

git diff --stat -M <anchor> HEAD -- docs/product/
git diff --name-status -M <anchor> HEAD -- docs/product/
git diff -M <anchor> HEAD -- docs/product/

git diff <anchor> HEAD -- docs/project-rules.md agent-rules/

git diff --name-status -M <anchor> HEAD -- docs/art/ docs/audio/ docs/ui/ docs/localization/ docs/presentation/
git diff -M <anchor> HEAD -- docs/art/ docs/audio/ docs/ui/ docs/localization/ docs/presentation/
```

Include any additional authoritative paths discovered from references in these commands. Read current GDD and professional sources whose historical coverage is unknown even when their diff is empty; widening the path list alone cannot prove coverage.

`-M` is mandatory for module paths so a rename such as `02-foo.md` to `03-foo.md` is not misclassified as one deletion plus one addition.

### 2.2 Classify every change

Use the user prior and actual diff to classify every hunk:

- **Substantive addition:** a new GDD rule, professional constraint or adopted delivery scope.
- **Substantive revision:** changed behavior, value, condition, or meaning.
- **Substantive removal:** removed behavior, newly explicit exclusion, or deleted module.
- **Editorial adjustment:** wording, formatting, typo, or pure rename with unchanged meaning. It produces no Feature change.

A path rename with unchanged content is editorial. A rename plus content change has both a path correction and the appropriate substantive classification.

### 2.3 Map changes to existing Features

Use the primary `source`, secondary AC/design references and shared applicability to map additions, revisions and removals. Identify all affected planned modules, including consumers missing a direct link, and follow their relevant dependencies:

- addition to the current/already planned scope → propose needed new Features;
- addition or revision confined to a later, unplanned Product → keep the design in GDD and delivery outline in `docs/product.md`; defer its detailed Product and Features;
- revision → identify every affected Feature ID;
- removal → identify every affected Feature ID.

Before proposing additions, check whether generation since the anchor already incorporated that source change into existing Feature scope/AC. Do not create duplicate Features for already covered changes. This checks an observed source diff against the plan; it does not replace Git as the source of change history.

Later Product changes can still affect existing behavior through a real shared contract. Analyze those affected Features and tests without decomposing the later Product as a whole. If the entire diff concerns unplanned later Products with no existing-work impact, report the deferred scope and stop without ledger or revision-log writes. Mixed diffs handle existing-work impacts normally and mention deferred scope in the ordinary report; no new tracking fields are needed.

Consider whether a changed pending scope now needs splitting or merging. Report the exact source/replacement IDs, scope boundaries and every downstream dependency change. Walk transitive dependents where the changed contract propagates; direct dependents alone are not a complete impact analysis. Do not renumber old Features.

For a source-file rename/removal, inspect primary sources and secondary references, including links and section anchors in Product and Feature designs. A path correction is reported separately and is not itself a substantive Feature change. Distinguish corrections to authoritative source inputs from references maintained with the plan. Classify by the document's role, not its Markdown extension: list source repairs and their owners separately from Feature `source`, AC or design navigation updates. Do not repair either during analysis.

### 2.4 Analyze downstream regression and stale-test impact

Compare every proposed `affected_components` ID with the current Registry. Include new component records and conflicting existing records in the proposal, using the Test registry contract in `.agents/skills/feature-plan/SKILL.md`.

For every substantively revised or removed Feature with existing implementation or tests, list its direct dependents and follow relevant downstream effects. Also read `docs/test-registry.json` and identify tests whose ID-derived owning Feature or components overlap the changed behavior. Classify each affected test as `still_valid`, `superseded`, `needs_new_coverage`, or `uncertain`. For proposed retirement, identify its reason, anchored governing source, replacement Feature/test IDs, and revision ID using `methodology/02-feature-list-schema.md`. Do not retire or rewrite a test merely because a source changed; include the proposed test action in the Stage 2 report and require Stage 3 confirmation.

Follow **Requirement changes and stale tests** in `methodology/08-testing-strategy.md`: read affected test code, including unit tests without Registry IDs. Include necessary assertion/method/file cleanup, affected current references or registrations, and its owning Feature in the same report. Retiring Registry metadata does not remove cases from a selected suite.

### 2.5 Report the diff

Apply **Requirement coverage review** in `methodology/02-feature-list-schema.md` to the changed requirements and actual downstream impacts. Make omissions, unresolved choices and remaining test/implementation work visible; a valid ledger or recorded source anchor alone does not prove semantic alignment.

Report in the current conversation language. Include the verified anchor or explicit fallback, editorial changes, old-to-new source paths, substantive additions/revisions/removals with affected IDs/statuses and proposed actions, actual downstream/test impacts, material differences from supplied user intent, and unresolved decisions. Omit empty categories.

Use the canonical correspondence format: **source requirement/change → Feature and AC → test/check action → gap or next action**. Keep one reviewable report; do not copy the full Product or create a second coverage artifact.

### 2.6 Stop before writing

Stage 2 only reports. Stage 3 must establish approval before any write.

## Stage 3: user review and decision

**Entry:** Stage 2 produced the report.

**Output:** approved actions and a committed source state ready for plan writes.

Compare the report's concrete actions with existing user approval. If scope, retirement, dependencies or other material choices remain unapproved, ask only about those choices; retain approval for unchanged actions when revising the report. A cancellation stops writes. General intent, silence or the report itself does not supply missing approval.

When analysis finds necessary source-link repairs, complete the approved repairs through the owning source entry before any Stage 4 write, including Registry merges. Treat this as supporting source maintenance, returning here rather than starting a nested synchronization. Check the complete task-owned source diff and commit it separately under the project Git rules. If authorization or the source commit is unavailable, report that prerequisite and leave the plan unchanged.

Then recheck Git status and the actual source HEAD. Re-read the affected sources and refresh the Stage 2 analysis against the original verified anchor (or the authorized current-document fallback); the repair commit is not proof of earlier plan coverage. Reuse unchanged approvals and resolve only newly affected choices. Stage 4 starts only when sources and analysis agree with that committed state. If only plan references need correction, skip source maintenance and its commit.

## Stage 4: apply confirmed changes

**Entry:** Stage 3 established approval of the final actions, and source Markdown is committed separately.

**Output:** a consistent index and affected detail files. Every addition or revision must update the correct sides together.

Before rewriting Features or test retirements, merge approved new components using the existing `tools/features/merge-test-registry.py` command and candidate format in the Test registry contract above. Preserve existing records; conflicting existing IDs must be resolved explicitly, not overwritten. Use `unit_test_paths: []` if no suite exists and `full_suite_on_change: false` unless the approved contract requires it. Do not invent future paths or commit temporary candidates. Then apply the confirmed Feature/replacement-test/retirement changes and the Stage 5 revision record before strict cross-file validation.

### Schema and history

Use the index/detail field ownership and initial planning values in `methodology/02-feature-list-schema.md`. The actions below specify what may change; they do not redefine field shapes or authorize rewriting completed behavior.

### Additions

Append new index entries and matching details with never-used IDs and canonical initial values. Make the source section precise and explain when new behavior extends a completed capability. Product-derived additions omit `engineering_change`; preserve that field on existing engineering Features during source correction, notes, status changes or permitted pending revisions.

### Removals

| Current status | Confirmed action |
|---|---|
| `pending` | Set index `status` to `obsolete`; append a localized timestamped removal reason to detail `notes` |
| `blocked` | Set index `status` to `obsolete`; preserve the recorded blocker and append a localized timestamped removal reason to detail `notes` |
| `in_progress` | Set index `status` to `obsolete`; append the reason; warn that written code may require an explicitly authorized rollback |
| `done` | Set index `status` to `obsolete_done`; append a localized timestamped removal reason to detail `notes`; preserve `id`, `description`, and `acceptance_criteria`; append a new Feature that removes the implemented behavior, with dependencies chosen from actual impact |
| `obsolete` or `obsolete_done` | Keep status unchanged; append a localized note that exclusion was confirmed again |

Do not translate or substantively rewrite the removed `done` Feature. Its status transition and removal note record the confirmed source/scope deletion; the new removal Feature carries the implementation work.

### Revisions

| Current status | Confirmed action |
|---|---|
| `pending` | Update detail `description`, `affected_components`, and criterion text/IDs before execution; preserve any still-valid planned verification mapping, explicitly retire superseded planned registry entries, append a localized timestamped revision note; change index `title` only when affected |
| `blocked` | Apply the `pending` action, then recheck the recorded blocker under **Status transitions** in methodology 02; retain `blocked` while it remains, or restore `pending` with the resolved prerequisite and reason in `notes` |
| `in_progress` | Apply the `pending` action and warn that current implementation may need adjustment |
| `done` | Do not modify the original index entry or detail. Append a new Feature that revises the implementation for the new GDD rule, depends on the original ID, and states the new behavior in its acceptance criteria |
| `obsolete` or `obsolete_done` | Normally do nothing. If the user wants reactivation, require an explicit decision and append a new Feature |

### Source-path corrections

- Correct affected primary `source` paths and secondary links in plan records or Feature design navigation, including historical navigation where needed. Preserve completed requirements and decisions; link correction is not permission to rewrite their content. Authoritative source-input repairs belong to Stage 3, not this stage.
- Record primary Feature `source` changes in `source_path_updates` using its existing `{ feature, from, to }` shape. Record secondary document/link corrections in the ordinary report and revision summary; do not overload this field or add another registry.
- Do not treat path correction as substantive revision.

### Splits, merges and dependencies

- A split retains its original entry as `obsolete`/`obsolete_done` and appends two or more never-used Feature IDs with independently testable scope.
- A merge retains all original entries as `obsolete`/`obsolete_done` and appends one never-used Feature ID covering the approved combined scope. A completed source's description, criteria and historical mappings remain unchanged.
- Rewrite affected pending and blocked dependencies to the actual replacement prerequisites, even when their IDs are larger. For blocked work, recheck the recorded recovery condition after the replacement; a valid but unfinished dependency leaves restored work pending and ineligible until that dependency is done. Review in-progress work explicitly before changing its scope/dependencies. Do not rewrite completed dependency history.
- Record each operation as typed `migrations` and each dependency edit as `dependency_changes` in a version-2 revision. Check both the migration graph and execution DAG for cycles, unknown IDs, self-dependencies and obsolete prerequisites.
- Add/revise/split/merge/retire are incremental operations; never regenerate the whole ledger merely because an insertion would disrupt numeric execution order.

### Downstream regression

Assign ordinary downstream verification to the Feature implementing this change, using **Test Impact Review** in `methodology/08-testing-strategy.md`. Record the affected behavior, existing tests or manual checks, and any coverage gap in that Feature's notes for Stage 1. Preserve existing test ownership; required checks cannot be declined through a note. Create another Feature only for a separate implementation, repair or independently agreed deliverable, not merely to rerun a dependent Feature's valid tests.


### Test traceability updates

- Completed Feature criteria/test IDs are historical records and are never rewritten in place. Product evolution creates a new Feature with new `ACxx`/test IDs.
- When an existing active test encodes a superseded contract, Stage 2 must show its exact ID and retirement relationship. After explicit Stage 3 confirmation, set `status: retired` and persist `retirement` with reason, anchored source, replacement Feature/test IDs and `revision_id`. Preserve its original ID/source mapping/path/case and completed evidence. Strict validation accepts this historical reference; keeping a wrong assertion active to satisfy old history is prohibited.
- Record approved test-code and current-reference cleanup in the owning new or unfinished Feature's `notes`, with exact paths/methods and intended action. Leave implementation to `feature-execute`; report it as pending until performed and verified. Do not delete historical Feature/Registry records.
- Still-valid regression/invariant tests remain active and will be selected later by `feature-execute` through component intersection.
- New Feature additions declare `affected_components`; ordinary new test IDs are finalized in `feature-execute` Stage 1/2. When an approved retirement needs replacement IDs, explicitly plan those IDs against the new criteria now and register them as `planned`, possibly with `path: null`. This does not authorize implementation or imply coverage. The replacement Feature must activate and execute them before completion. Retirement without replacement is blocked; a removed behavior is verified by the new removal contract.
- Keep `docs/test-registry.json` machine-readable; do not use it as a narrative revision log.
- Registries use schema version 3; revision roots and entries retain version 2. Append revisions without rewriting current-format history. Unsupported formats and retired records lacking provenance fail validation; do not invent migration data.

## Stage 5: update metadata, validate, and commit

**Entry:** Stage 4 completed.

**Output:** updated metadata, one appended revision entry, validation evidence, and a Git commit.

1. Update index time and append one version-2 revision under **File 3** in `methodology/02-feature-list-schema.md`. Preserve the canonical `meta.generated_from` entries, adding actual GDD and professional source locations considered by this plan without claiming all future scope is covered; do not put the revision into index metadata. Record actual changes in the canonical readable summary fields where applicable; typed migrations/dependency changes carry the machine-readable relationships.

`synced_at_commit` is the next run's anchor and is mandatory. It must identify the committed source-document state analyzed by this synchronization. `source_path_updates` preserves rename traceability, including mappings for immutable completed history.

For an approved whole-document fallback, use the actually inspected HEAD for both `anchor_commit` and `synced_at_commit`, and state in the existing `summary` that current alignment established this baseline while earlier source history is unknown. This records a new comparison point, not a reconstructed historical diff. Migration sources must be supported by inspected content; unresolved historical claims stay unresolved. Do not invent a commit, add tracking fields or rewrite older revisions.

When verified historical differences and newly admitted sources with unknown coverage are handled together, retain the verified before/after anchors for the known differences, identify which sources were aligned only at current HEAD in `summary`, and claim no historical diff for those sources. Support each migration from an actually inspected before/after source; unresolved source coverage blocks claiming complete synchronization.

Use the exact migration cardinalities and retirement fields in `methodology/02-feature-list-schema.md`. Empty migrations/dependency changes are valid for editorial synchronization. The new entry's source commit is one of its `anchor_commit` or `synced_at_commit`; verify the actual source diff. Revision IDs are stable and unique; retirement records refer to this ID, never a free-text note.

2. Run `python -B tools/checks/check-feature-list.py` on the completed set. It includes JSON parsing; a separate syntax check is only for diagnosing an error. Then review the actual diff against the approved actions: preserve historical IDs and completed definitions, confirm source sections and the inspected source anchor, and check that dependencies express real prerequisites. Confirm required test-code/reference cleanup and downstream verification belong to the responsible Feature, with unfinished implementation and replacement coverage clearly reported. Correct task-owned errors under Exception handling before committing.

3. Follow the Core Git contract for explicit staging of the task-owned index, affected details, approved Feature design navigation edits, Registry and revision log; complete cached-diff checks and create the eligible local `chore(feature-plan): <中文行为摘要>` commit unless the user requested no commit. Summarize the verified anchor, material plan changes and actual validation in its body, then check post-commit status.

Source changes belong in a separate earlier commit, including the approved repairs handled in Stage 3. If a source change remains uncommitted at Stage 4 entry or appears during plan writes, preserve it and stop dependent synchronization. Inspect any task-owned partial plan under Exception handling; do not absorb other work or commit a partial result as synchronized. The next anchor must identify the actually analyzed committed source state.

## Stage 6: handoff

**Entry:** Stage 5 completed.

**Output:** a synchronization summary in the current conversation language.

Report:

- the anchor hash used for analysis;
- counts of added, obsoleted, regression, and source-path-update records;
- the next executable Feature for the current Product or authorized engineering work, using `python -B tools/checks/check-feature-list.py --eligible` for dependency readiness; otherwise the next Product to revisit after current completion;
- rollback warnings for obsolete in-progress work and every outstanding regression concern.

Refresh the Stage 2 correspondence with the actual written Feature/AC and test relationships. Distinguish plan alignment from pending implementation, test creation and verification; keep actionable follow-ups in the owning Feature or current Progress. Do not present deferred Products or unresolved current-plan gaps as fully synchronized, and do not create a separate coverage/state file.

Return the synchronized plan and remaining work to the calling workflow. Continue through the appropriate Skill when that work is already explicitly authorized; otherwise stop at the requested planning result or the missing decision.

## Exception handling

| Condition | Required response |
|---|---|
| No reliable anchor can be established | Offer current whole-document alignment, disclose unknown history, and use explicit scope authorization |
| Source changes are too broad to classify reliably | Narrow the affected scope with the user, preserving current records and Product order; do not recommend full-project regeneration based on file or line counts |
| Diff and user prior conflict materially | Pause, enumerate mismatches, and ask the user to check for unintended source edits |
| Current or previously documented Product source is missing | Report the discrepancy and repair its source before dependent writes; future overview-only entries intentionally have no detail file |
| Pre-existing index, detail, or revision data is invalid | Report the original error and resolve the repair scope; do not invent missing history or change unrelated data |
| This task introduces invalid JSON or an incomplete authorized write | Inspect the actual partial result, correct errors introduced by the approved actions, and rerun the relevant validation; stop dependent writes if the intended recovery is unclear or overlaps preserved work |
| A file or Git operation fails | Preserve the error and classify it; correct a task-owned invocation error or use permitted recovery, but do not bypass a permission denial, reset/restore history, discard work, or expand scope |

## Workflow map

```text
Stage 0: preflight and anchor
    ↓
Stage 1: optional user prior
    ↓
Stage 2: Git-diff analysis and report
    ↓
Stage 3: establish approval; repair/commit source inputs if needed → refresh Stage 2 analysis and affected decisions
    ↓
Stage 4: apply confirmed index/detail changes
    ↓
Stage 5: update metadata and revision log, validate, commit
    ↓
Stage 6: summarize → return to authorized work or stop
```
