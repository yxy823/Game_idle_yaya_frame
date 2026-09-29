---
name: worktree-integrate-godot
description: Integrate selected Godot worktree changes into the intended target, or resume an authorized integration that has conflicts. Checks the combined result; does not select an experiment's winner, create a worktree by default or automatically clean up branches.
---

# Integrate selected Godot worktree results

Identify the adopted result, source revisions or authorized local changes, intended target branch and actual target checkout. Reuse the task's decisions and current repository evidence. A new integration starts after the result to adopt is clear; a direct request to resolve an existing conflict starts by identifying that operation and its intended result, not by launching another merge.

Apply **GDD prerequisite and authority** in `methodology/01-product-doc-structure.md`. Paths in code spans are project-relative. Read `agent-rules/00-core/git-worktree-and-commits.md` for authorization, current-change preservation, staging, verification and commits; this method creates no new Stage or completion rule.

## Establish a coherent candidate

Inspect source and target history, actual status and the relevant changes before dependent writes. Work in the intended target checkout, preserving its unrelated content and staging state. An unexplained in-progress operation or changed HEAD is a state to investigate, not permission to abort or reset. Worktree creation does not authorize writing to a different target.

Bring over the selected result and its real dependencies: scripts, scenes, resources, required identifiers, tests and documentation may belong together. Exclude unrelated experiments and temporary runtime settings; explain an inseparable overlap instead of silently adopting the entire source. Git integrates revisions or selected changes, not two directory trees. Uncommitted or ignored source content needs separate inspection and authorized handling, not a transport commit to bypass its conditions.

Choose the integration method from the actual history and selected scope. A whole-branch merge and selected-commit application have different effects; neither is a universal default. Inspect whether the chosen command will generate commits, advance the target ref or include other changes before executing it. A merge can commit automatically; `--no-commit` alone does not stop a fast-forward update, as described in the [Git merge contract](https://git-scm.com/docs/git-merge#Documentation/git-merge.txt---no-commit).

Where validation or acceptance must precede committing or adopting the result, retain a reviewable candidate without prematurely advancing the target or recording commits. Choose a suitable method under the actual task authorization; do not add an unrequested worktree, squash history or relax a Gate to make the command convenient. Creating a separate candidate checkout, if needed and authorized, uses [worktree-create-godot](../worktree-create-godot/SKILL.md).

When conflicts occur, or the request is to resume an already conflicted integration, read [Resolve the existing integration conflict](references/merge-conflicts.md). It owns the conflict method; conflict-free integration does not require that reference.

## Validate and adopt the combined result

Use [project-verification-godot](../project-verification-godot/SKILL.md) for the owning task's applicable checks, including affected Godot scene/resource relationships. No text conflict does not prove that paths, node references, identifiers or behavior still work. Read the shared [Godot runtime preparation](../worktree-create-godot/references/godot-worktree-runtime.md) before relevant writing tools when target preparation or data destinations are missing or have changed.

The combined candidate needs evidence that applies to its actual content and obligations. Source-checkout success alone cannot stand in for target verification. Reuse still-valid results; renew only affected or missing checks. Use [verification-evidence-godot](../verification-evidence-godot/SKILL.md) for evidence applicability, reference/import recovery or interrupted runs, and [manual-acceptance-godot](../manual-acceptance-godot/SKILL.md) for actual user acceptance when the owning task requires it.

Preserve explicit no-commit conditions. The existing Bug tasks that require actual human acceptance and explicit permission to commit still require both before any local commit, including intermediate resolution or checkpoint commits. Acceptance alone grants no commit permission; permission alone provides no acceptance. Reuse prior explicit decisions, but do not treat a generic request to continue or integrate as replacing either special condition. When a condition is missing, complete permitted analysis or candidate preparation and report the blocked final action.

Adopt and commit eligible results according to the Core Git contract, checking the actual target and resulting scope afterward. A conflict resolution or integrated local commit does not complete a Feature or supply human acceptance by itself. Report the source and target, adopted scope, resulting commits or remaining candidate changes, real checks and unresolved conditions. Continue already authorized work through its owner without another confirmation merely because this method returned.

## Preserve the source until cleanup is authorized

Integration does not automatically authorize deleting the source worktree or branch. If cleanup is requested, account for remaining work, needed evidence and any task or process still using that checkout. For Codex-managed worktrees use the available host archive/recovery tools and their preservation contract; do not replace them with a deletion script. Do not promise that ignored local files are preserved without checking the actual tool contract.
