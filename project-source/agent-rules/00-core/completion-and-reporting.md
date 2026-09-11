# Completion and Reporting

Completion reports state outcomes and evidence, not private step-by-step reasoning.

## Commit eligibility boundary

- **[MUST]** The applicable completion workflow and Completion Gate determine
  **when** the current task has satisfied its required approval, validation,
  acceptance, and completion conditions and is therefore eligible to commit.
- **[MUST]** An unresolved completion blocker means no commit is permitted. The
  completion layer must not describe a blocked task as commit-eligible.
- **[MUST]** After eligibility is established, delegate staging, commit
  construction, message format, prohibited operations, and post-commit checks
  to `git-worktree-and-commits.md`; do not duplicate those mechanics here.

## Required report content

- **[PREFER]** Summarize outcomes and evidence rather than the Agent's internal process.
- **[MUST]** Report material behavior/architecture/configuration changes, including significant necessary dependent migrations.
- **[MUST]** Report the material validation gates actually executed and their results.
- **[MUST]** Do not say 'all tests passed', 'fully validated', or equivalent unless that exact scope was actually executed.
- **[MUST]** Report any applicable required gate not executed, with reason and concrete residual risk.
- **[MUST]** Surface remaining validation failures/blockers clearly; do not summarize a mixed/failing run as successful overall.

## Precision

- **[PREFER]** Do not enumerate every unrelated validation category just to mark it not applicable.
- **[PREFER]** Report residual risk only when there is a concrete unverified condition, limitation, compatibility concern, or deferred issue.
- **[PREFER]** Report useful incidental issues separately from current-task failures so they are not mistaken for regressions caused by the task.
- **[MUST]** Do not claim unmeasured performance, platform compatibility, leak-freedom, visual quality, or other properties that were not actually evaluated.
- **[PREFER]** For visual changes in v1, state when composition/layout/animation feel still requires manual acceptance.
- **[PREFER]** Include exact Godot/tool version when materially version-sensitive, and summarize logs instead of pasting them unless needed to explain failure.
- **[MUST]** Report current completion state only; do not describe unperformed future work as if it will happen automatically.
