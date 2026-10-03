---
name: feature-sync
description: >-
  Synchronize existing Feature/test plans with committed GDD, Product delivery, professional specification or Project Rules changes. Use for source-impact analysis and current-plan realignment, not initial decomposition.
---

# Synchronize Feature list

Apply the [GDD prerequisite](../../../methodology/01-product-doc-structure.md#gdd-prerequisite-and-authority), then run Stages 0–6 below. An existing plan does not substitute for GDD.

Identify source changes through Git diffs against a recorded anchor. Never infer historical change by comparing the current sources with the current plan. Without a usable anchor, or for a source now in scope whose coverage by the anchor is unknown, follow [Anchor recovery and current-document alignment](references/anchor-and-fallback.md). Synchronize actual effects on existing work under [Product-by-Product planning](../../../methodology/02-feature-list-schema.md#product-by-product-planning); a later Product's changed document is not a reason to decompose it now.

## Shared contracts

- **Plan files and schemas:** `docs/feature-list.json` (index), `docs/features/F0XX.json` (details), `docs/test-registry.json` and the append-only `docs/feature-list-revisions.json`, as defined in `methodology/02-feature-list-schema.md`. Registry semantics follow [Registry rules](../../../methodology/08-test-traceability-and-evidence.md#registry-rules). Read the full index; read details, Registry and the last revision entry when a Stage needs them.
- **Language:** apply `methodology/05-document-language.md` to new prose; preserve completed history and original evidence untranslated.
- **Git:** follow `agent-rules/00-core/git-worktree-and-commits.md` for change preservation, the target checkout, staging and commits.
- **Source owners:** this workflow updates the plan, not the source documents. Game-design boundaries return to [design-gdd](../design-gdd/SKILL.md); engineering-rule writes follow the self-check in `methodology/04-project-rules.md`. Read **Design scope and boundaries** in methodology 01, `docs/project-rules.md` and affected Feature designs when explaining impacts. Completed Feature designs stay as history.

## Sources watched

- `docs/gdd/`: game-design intent, rules, states, values, version scope and design acceptance.
- `docs/product.md` and the documented `docs/product/NN-xxx.md` files: delivery outlines, adopted scope, boundaries, dependencies and order.
- `docs/project-rules.md` and its routed rule sources (`agent-rules/`): collaboration, architecture and technology constraints.
- Professional sources in `docs/art/`, `docs/audio/`, `docs/ui/`, `docs/localization/` and `docs/presentation/`, plus other source paths found through actual references under **Discover and map sources** in `methodology/11-specialist-workflows.md`.

Proposed wording is not a confirmed contract. A resource status or location change may be editorial for planning while still changing the completion fingerprint. Use `docs/terminology.md`, when present, to read the diff consistently; terminology is not a separate behavior source, and its meaning-preserving edits are editorial. Module files may be added, deleted, renamed (including numeric-prefix changes) or modified between synchronizations; handle all four cases.

## Stage 0: preflight and anchor

1. Read the index, revision log and Registry. A missing file requires repair before routing or writes. If the valid index has no Features, return to current Product preparation through [product-author](../product-author/SKILL.md) and authorized [feature-plan](../feature-plan/SKILL.md).
2. Check Git. Report the current branch (`main` and `master` are valid) and do not change it. Inspect `git status --porcelain` and the relevant differences; preserve unrelated work and resolve actual overlapping plan edits before dependent writes.
3. **Source-first rule:** every source document used by this synchronization, including approved repairs from Stage 3, must be committed in a separate, earlier commit before any dependent plan write. The diff and the next anchor then identify an actual committed state. Report a relevant uncommitted source and return it to its owner; an unrelated dirty path is not a blocker. If a source change is still uncommitted at Stage 4, or appears during plan writes, preserve it and stop dependent synchronization.
4. Use `synced_at_commit` from the last `revision_log` entry as the anchor and verify that it is in the current history. This includes the `R000` baseline under [Initial planning baseline](../../../methodology/02-feature-list-schema.md#initial-planning-baseline), whose coverage is limited to its planned Product and adopted sources. Otherwise use [the reference](references/anchor-and-fallback.md).
5. Report the branch, the anchor hash, date, subject and coverage basis (or the authorized fallback and inspected HEAD), and Feature counts by status.

## Stage 1: user prior

Reuse the user's change description when supplied; otherwise continue without one. Ask only if the inspected changes leave a material ambiguity about intent. Record an actual answer for Stage 2 and the revision entry, or `user_intent: null`; never invent one from the diff.

## Stage 2: Git-diff analysis

Stage 2 writes nothing.

### Collect the diff

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

Add any other source paths found through references. `-M` is mandatory, so that a rename such as `02-foo.md` to `03-foo.md` is not read as a deletion plus an addition.

### Classify every hunk

- **Substantive addition:** a new GDD rule, professional constraint or adopted delivery scope.
- **Substantive revision:** changed behavior, value, condition or meaning.
- **Substantive removal:** removed behavior, a newly explicit exclusion or a deleted module.
- **Editorial adjustment:** wording, formatting, a typo or a pure rename. It changes no Feature. A rename with content changes is both a path correction and a substantive change.

### Map changes to Features

- An addition to the current or already planned scope → propose the needed new Features, unless planning since the anchor already covers it.
- An addition or revision confined to a later, unplanned Product → keep it in GDD and `docs/product.md` and defer its Features. If the whole diff is of this kind, report the deferred scope and stop without writes; a mixed diff mentions the deferred scope in its report.
- A revision or removal → identify every affected Feature ID, using the primary `source`, AC and design references and shared applicability. Follow transitive dependents that the changed contract reaches, including consumers without a direct link.

A later Product's change can still affect existing work through a real shared contract; analyze that impact without decomposing the later Product. For a changed pending scope, consider a split or merge and report the source and replacement IDs, boundaries and dependency changes. Do not renumber Features.

For a renamed or removed source file, list separately the repairs to source documents (with their owners) and the Feature `source`, AC or design-navigation updates kept with the plan. A path correction is not a substantive change. Do not repair either during analysis.

### Analyze test impact

- Compare every proposed `affected_components` ID with the Registry, and include new and conflicting component records in the proposal.
- For each revised or removed Feature with implementation or tests, follow its dependents and the tests whose owning Feature or components overlap the change. Classify each test as `still_valid`, `superseded`, `needs_new_coverage` or `uncertain`.
- For a proposed retirement, identify the reason, anchored source, replacement Feature and test IDs and revision ID under [File 4](../../../methodology/02-feature-list-schema.md#file-4-docstest-registryjson). A source change alone is not a reason to retire a test.
- Follow **Requirement changes and stale tests** in methodology 08: read the affected test code, including unit tests without Registry IDs, and name the cleanup and the Feature that will own it.

### Report

Apply [Requirement coverage review](../../../methodology/02-feature-list-schema.md#requirement-coverage-review) in the conversation language. Include the anchor or fallback, editorial changes and path renames, substantive changes with affected IDs, statuses and proposed actions, downstream and test impacts, differences from the user's intent and unresolved decisions. Omit empty categories.

## Stage 3: user review and decision

Compare the report's concrete actions with existing approval and ask only about unapproved material choices: scope, retirement, dependencies or similar. Keep approval for unchanged actions. A cancellation stops writes; general intent, silence or the report itself is not approval.

Complete approved source-link repairs through the source's own Skill and commit them under the source-first rule before any Stage 4 write. Do not start a nested synchronization. If authorization or the commit is unavailable, report it and leave the plan unchanged. After a repair, re-read the affected sources and refresh the Stage 2 analysis against the original anchor or the fallback; the repair commit does not prove earlier coverage. Reuse unchanged approvals, resolve only newly affected choices, and start Stage 4 only when the sources and the analysis agree with the committed state.

## Stage 4: apply confirmed changes

1. Merge approved new components with the [Test registry merge procedure](../feature-plan/SKILL.md#test-registry-docstest-registryjson) in `feature-plan`. Resolve conflicting records explicitly; never overwrite them.
2. Apply the confirmed Feature, test and retirement changes with [Apply confirmed plan changes](references/apply-plan-changes.md). The index and its details change together.

## Stage 5: record, validate and commit

1. Update the index time and append one version-2 revision under [File 3](../../../methodology/02-feature-list-schema.md#file-3-docsfeature-list-revisionsjson).
   - Preserve the canonical `meta.generated_from` entries and add the GDD and professional locations actually considered, without claiming future scope. The revision itself does not go into index metadata.
   - Use the readable summary fields and the typed `migrations` and `dependency_changes`; empty arrays are valid for an editorial synchronization.
   - `synced_at_commit` is mandatory: the committed source state analyzed now, and the next anchor. `source_path_updates` keeps rename traceability.
   - For the fallback, or for sources aligned only at HEAD, see [Record the revision](references/anchor-and-fallback.md#record-the-revision).
2. Run `python -B tools/checks/check-feature-list.py`. Review the diff against the approved actions: preserved history, correct sources and anchor, real dependencies, and cleanup and replacement coverage assigned to the responsible Feature. Correct task-owned errors before committing.
3. Stage only the task-owned plan files and approved Feature design navigation edits, as **Staging** in the Core Git rules requires. Commit `chore(feature-plan): <中文行为摘要>` unless the user requested no commit; the `feature-plan` scope names the plan files, as in initial planning. Summarize the anchor, plan changes and validation in the body, then check the post-commit status.

## Stage 6: handoff

Report the anchor, counts of added, obsoleted, regression and source-path-update records, the next eligible Feature (`python -B tools/checks/check-feature-list.py --eligible`) or the next Product to revisit, and rollback or regression warnings. Refresh the coverage correspondence with what was actually written. Distinguish plan alignment from pending implementation and verification; do not present deferred Products or unresolved gaps as synchronized, and keep follow-ups in the owning Feature or Progress.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).

## Exception handling

| Condition | Required response |
|---|---|
| No reliable anchor | Offer current-document alignment under [the reference](references/anchor-and-fallback.md) and disclose unknown history |
| Changes too broad to classify | Narrow the scope with the user; do not recommend full regeneration because of file or line counts |
| Diff conflicts with the user's intent | Pause, list the mismatches and ask about unintended source edits |
| A current or documented Product source is missing | Report it and repair the source before dependent writes; a future outline entry has no file by design |
| Pre-existing plan data is invalid | Report the original error and agree the repair scope; do not invent history |
| This task wrote invalid JSON or a partial result | Inspect it, correct the task's own errors and revalidate; stop if recovery is unclear or overlaps preserved work |
| A file or Git operation fails | Preserve the error; fix a task-owned invocation error, but never bypass a permission denial, reset history, discard work or expand scope |
