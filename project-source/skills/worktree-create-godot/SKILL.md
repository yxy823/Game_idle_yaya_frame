---
name: worktree-create-godot
description: Prepare or reuse a Godot Git worktree for an authorized task, with the intended source version and required local preparation. Use when a separate checkout is needed; does not choose the winning solution or integrate results.
---

# Prepare a Godot worktree

Establish why this task needs another checkout, its intended base and the work to continue there. Reuse the current request, repository state and existing records instead of asking for known inputs. Apply **GDD prerequisite and authority** in `methodology/01-product-doc-structure.md`; a worktree does not create a Feature, new Stage or missing game design. A request to compare approaches without implementation can end with a proposed arrangement.

Paths in code spans below are relative to the actual project root. Read `agent-rules/00-core/git-worktree-and-commits.md` for authorization, existing changes, staging and commits; this Skill does not replace that contract.

## Establish the intended checkout

- Inspect the actual repository, relevant worktrees, branch/ref and current changes. Reuse a suitable active checkout when no ongoing task or process depends on it and its existing work has been accounted for. Ordinary task continuation does not itself require a new worktree.
- Distinguish the selected committed base from unstaged, staged, untracked and ignored content. A new worktree does not automatically carry those local changes. If this task needs any of them, inspect and carry only the authorized content while preserving the source and its staging state; do not commit merely to make transport convenient.
- Use available Codex managed-worktree tools before shell creation. Confirm the requested base against the tool's actual default, provide the intended ref where needed, and use the completed returned path. A pending operation or a registration failure with a usable returned checkout is not a reason to create another one. Use manual Git creation only when the managed capability is unavailable or the user explicitly requests it.
- Keep branch creation and changes to other checkouts within the task's concrete authorization. After creation or selection, verify the actual directory, branch or detached commit and relevant status. Perform subsequent project reads, edits and checks in that target rather than silently substituting the main checkout.

Explicit no-commit conditions continue here. In particular, the existing Bug tasks that require both actual human acceptance and explicit permission to commit permit no interim transport/checkpoint commit before both conditions are met. Neither requirement supplies the other; reuse either when already explicit.

## Prepare only what the requested work needs

Before an editor, import, test, game or other tool operation that may write, read [Godot worktree runtime preparation](references/godot-worktree-runtime.md). It owns the additional cross-checkout data considerations. A pure read-only source comparison needs no runtime preparation, and a separate directory alone proves no runtime isolation.

Use [project-environment-godot](../project-environment-godot/SKILL.md) for an actual configuration or first-scan dependency. Use [project-verification-godot](../project-verification-godot/SKILL.md) for checks required by the requested preparation or owning task. Reuse valid preparation, avoid a new readiness ledger, and do not expand directory creation into a full test suite or game launch.

## Return the usable location and real limits

Report the actual target path, base/branch or commit, any authorized local content carried over, completed preparation and the next operation that is ready. If checkout creation succeeded but running remains blocked, name that distinction and the missing condition; do not call an unexecuted runtime check passed.

Continue the existing authorized task in that checkout without another confirmation merely because this Skill returned. Preparation does not prove the experiment or Feature succeeded. Use existing Progress or Feature records only when durable continuation information is needed, under `methodology/09-records-reports-and-handoff.md`.

Integrating an adopted result belongs to [worktree-integrate-godot](../worktree-integrate-godot/SKILL.md). Creation or later integration does not automatically authorize deleting a worktree or branch; preserve the checkout for its current work and follow the host's managed lifecycle tools if cleanup is requested.
