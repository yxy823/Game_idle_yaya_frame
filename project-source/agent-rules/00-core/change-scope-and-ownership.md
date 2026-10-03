# Change Scope and Ownership

Control how far a task may modify the repository while preserving existing work.

## Locate the change before editing

- **[MUST]** Read the relevant current implementation and its actual callers or resource consumers. Locate the code or data that owns the behavior; do not infer the change site from a filename, a symptom or a copied example.
- **[MUST]** Identify the affected contracts, modules, data and validation routes before choosing the change. Trace the necessary dependencies; an unrelated whole-repository reading pass is not required.
- **[PREFER]** Before implementation, briefly state the intended change, its material impact and the relevant validation. Reuse an approved plan that is still valid. This explanation is not an additional approval gate or a mandatory separate plan file.

## Task scope

- **[MUST]** Make the smallest coherent change that completely satisfies the requested behavior. Minimal means minimal complete impact, not the smallest file count.
- **[MUST]** Classify each change as a Requested Change, a Necessary Dependent Change or an Incidental Issue.
- **[MUST]** Treat a dependent migration required for correctness as implicit task scope when the causal relationship is clear and the change is minimal. Expand validation to cover it.
- **[MUST]** Do not modify Incidental Issues by default. Modify one only when it blocks the task, creates an immediate correctness or safety risk, or the user explicitly expands the scope. Otherwise, report it separately when it is useful.
- **[MUST]** Already touching a file or directory is not a sufficient reason to expand scope.
- **[MUST]** Do not perform unrelated renaming, formatting, directory reorganization, warning cleanup, dead-code cleanup, API modernization, scene normalization or refactoring.

## Existing work and shared contracts

- **[MUST]** Do not overwrite, reset, revert or delete unrelated existing project changes. Patch against the current state.
- **[MUST]** Unknown or unrelated existing modifications are work to preserve, not garbage.
- **[MUST]** Preserve existing public APIs, dependencies and local code style unless a concrete requirement makes a change necessary. Explain any necessary contract or dependency change and its consumers. Do not add a dependency merely for convenience when the existing stack is sufficient.
- **[MUST]** A change to a shared or public contract migrates all known necessary consumers, or uses an explicitly designed staged compatibility mechanism.
- **[MUST]** Lint or metric thresholds alone do not authorize structural refactoring. A split or refactor must improve a real responsibility, dependency or maintainability boundary.
- **[MUST]** Do not build speculative general-purpose frameworks for hypothetical future consumers.

## Deletion and derived outputs

- **[MUST]** Before deleting an artifact, confirm where relevant its owner, inbound consumers, dynamic references and registries, its generated or source relationship, and save, mod and data compatibility.
- **[MUST]** A result such as `unused` or `unreferenced` only creates a deletion candidate; it does not grant permission to delete.
- **[MUST]** When an authoritative source changes and project policy requires committed derived outputs, regenerate them through the formal pipeline and check that they are deterministic and not stale.
- **[MUST]** If a tool produces a large unrelated serialization or formatting diff, inspect it and revert the unrelated changes where practical instead of accepting it wholesale.

Validation follows `validation-policy.md` and the applicable domain routes; final diff inspection follows `git-worktree-and-commits.md`. Reporting follows `completion-and-reporting.md`. These checks do not replace the acceptance or completion conditions of the workflow that governs the task.
