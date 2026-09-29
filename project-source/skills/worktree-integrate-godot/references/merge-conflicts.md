# Resolve the existing integration conflict

Read when the selected integration reports conflicts or the user asks to take over an interrupted merge or other conflicted integration. The parent Skill owns result selection, verification, adoption and cleanup boundaries. Git preservation, allowed operations and commit conditions remain in `agent-rules/00-core/git-worktree-and-commits.md`, relative to the actual project root.

## Understand the operation already in progress

Identify the target directory, current branch/HEAD, operation type, source revisions, unresolved paths and existing staged or manual resolutions. Read the relevant history and current differences. Establish how this state relates to the authorized task before dependent writes; a conflict request does not authorize restarting an unrelated operation or discarding prior work.

Distinguish permission to diagnose, permission to resolve files and permission to finalize the operation. Reuse concrete authority already given. An existing rebase is not a reason to start or continue rewriting history automatically; handle it only under the applicable explicit authorization and Core Git restrictions. If the user's intended operation or result is materially unclear, explain that specific gap while preserving the current state.

An abort is neither mandatory nor universally forbidden. Before an authorized abort or other recovery, establish its effects on pre-existing changes and partial resolutions; Git does not guarantee that abort can reconstruct all local work. Do not use abort, reset, stash or cleanup merely to obtain a clean starting point. A requested stop can leave the operation preserved with a clear recovery point.

## Reconcile intent, not just conflict markers

Use the common ancestor and both revisions, relevant commit messages, current GDD/Product or Feature decisions, tests and affected implementation to understand why each change exists. Read only the sources needed for the conflicting behavior; do not require issue/PR records or invent a new conflict ledger.

- Preserve compatible intentions and real dependencies rather than selecting an entire side for convenience. Interpret “ours” and “theirs” according to the actual operation; their labels alone do not identify the desired behavior.
- For incompatible behavior, use the already agreed integration goal and authoritative decisions. If those do not determine the result, explain the concrete alternatives and leave that dependent resolution pending. Do not invent a third game rule or quietly change the selected outcome.
- In Godot scenes, resources and configuration, inspect the affected paths, `.uid` / `.import` references, node relationships and values together. A file with markers removed can still refer to a missing resource or combine incompatible states. Preserve required metadata; do not regenerate identifiers or edit binary assets as text merely to silence a conflict.
- Preserve unrelated local edits and prior valid resolutions. Stage only the inspected resolution scope under the Core Git contract. Resolving one file does not make every existing staged change eligible for the same commit.

If a required behavior change extends beyond reconciling the selected results, return that scope decision to its existing owner. Continue unaffected authorized resolutions; do not turn the conflict into a general refactor or automatically broaden acceptance criteria.

## Return a verified candidate or the exact remaining block

Inspect the resulting combined changes and unresolved Git state. Run the checks selected by the parent Skill for the actual affected result, retaining real failures and missing evidence. Restore coherent behavior within the authorized integration scope before finalization; do not weaken tests or relabel a failure to complete the operation.

Before a commit or a `--continue` operation, determine its actual effects and apply the parent Skill's verification, acceptance and explicit commit conditions. Do not automatically loop through all remaining rebase/cherry-pick steps or finish a merge just because the current text conflicts are gone. When conditions allow finalization, continue the already authorized integration; do not ask again only because resolution finished.

Report what was reconciled, the evidence supporting the result and any unresolved decision, failed check or pending operation. Use existing Feature/Progress records only when needed for continuation, under `methodology/09-artifact-lifecycle.md`; do not create a second status system.

Inspired by Matt Pocock's `resolving-merge-conflicts`: understand both changes and preserve their intended behavior. Rewritten for this project's Git, Godot, validation and authorization boundaries; no external Skill installation is required.
