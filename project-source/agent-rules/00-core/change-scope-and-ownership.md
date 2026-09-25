# Change Scope and Ownership

Control how far a task may modify the repository while preserving existing work.

## Locate the change before editing

- **[MUST]** Read the relevant current implementation and its actual callers or resource consumers. Locate the behavior owner rather than inferring the change site from a filename, symptom, or copied example.
- **[MUST]** Identify the affected contracts, modules, data and validation routes before choosing the change. Trace necessary dependencies; do not require an unrelated whole-repository reading pass.
- **[PREFER]** Briefly state the intended change, material impact and relevant validation before implementation. Reuse a still-valid approved plan; this explanation is not an additional approval gate or a mandatory separate plan file.

## Task scope

- **[MUST]** Make the smallest coherent change that completely satisfies the requested behavior. Minimal means minimal complete impact, not smallest file count.
- **[MUST]** Classify changes as Requested Change, Necessary Dependent Change, or Incidental Issue.
- **[MUST]** Necessary dependent migrations required for correctness are implicit task scope when the causal relationship is clear, the change is minimal, and validation expands accordingly.
- **[MUST]** Incidental issues are not modified by default. They may be reported separately unless they block the task, create immediate correctness/safety risk, or the user explicitly expands scope.
- **[MUST]** Already touching a file or directory is not sufficient reason to expand scope.
- **[MUST]** Do not perform unrelated rename, formatting, directory reorganization, warning cleanup, dead-code cleanup, API modernization, scene normalization, or refactor.

## Existing work and shared contracts

- **[MUST]** Do not overwrite, reset, revert or delete unrelated existing project changes. Patch against the current state.
- **[MUST]** Unknown or unrelated existing modifications are work to preserve, not garbage.
- **[MUST]** Preserve existing public APIs, dependencies and local code style unless a concrete requirement makes a change necessary. Explain any necessary contract or dependency change and its consumers; do not add a dependency merely for convenience when the existing stack suffices.
- **[MUST]** A shared/public contract change must migrate all known necessary consumers or use an explicitly designed staged compatibility mechanism.
- **[MUST]** Lint/metric thresholds alone do not authorize structural refactoring; a split/refactor must improve a real responsibility, dependency, or maintainability boundary.
- **[MUST]** Do not build speculative general-purpose frameworks for hypothetical future consumers.

## Deletion and derived outputs

- **[MUST]** Before deleting an artifact, confirm ownership, inbound consumers, dynamic references/registries, generated/source relationship, and save/mod/data compatibility where relevant.
- **[MUST]** `unused` or `unreferenced` only creates a deletion candidate; it does not grant deletion permission.
- **[MUST]** When an authoritative source changes and project policy requires committed derived outputs, regenerate them through the formal pipeline and validate determinism/staleness.
- **[MUST]** If a tool produces a large unrelated serialization/formatting diff, inspect it and revert unrelated changes where practical instead of accepting it wholesale.

Validation follows `validation-policy.md` and the applicable domain routes; final diff inspection follows `git-worktree-and-commits.md`. Reporting follows `completion-and-reporting.md`. These checks do not replace the owning workflow's actual acceptance or completion conditions.
