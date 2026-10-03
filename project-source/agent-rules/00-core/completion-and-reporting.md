# Completion and Reporting

Completion reports state outcomes and evidence, not private step-by-step reasoning.

## Completion and local commits

- **[MUST]** The applicable completion workflow and its Completion Gate determine **when** the current task has satisfied its required approval, validation, acceptance and completion conditions and may be reported complete.
- **[MUST]** An unresolved completion blocker prevents marking the task complete. Validated logical changes may still be committed under the governing workflow; report the remaining work and any applicable human acceptance truthfully.
- **[MUST]** Leave logical commit boundaries, staging, message format, prohibited operations and commit delivery reporting to `git-worktree-and-commits.md`; do not duplicate those mechanics here.

## Required report content

- **[PREFER]** Summarize outcomes and evidence rather than the Agent's internal process.
- **[MUST]** Report material changes to behavior, architecture or configuration, including significant necessary dependent migrations.
- **[MUST]** Identify the key changed files or coherent file groups and explain why the changes were needed. Scale the detail to the task; do not dump an exhaustive file list or repeat the diff.
- **[MUST]** Report the material validation gates that were actually executed and their results.
- **[MUST]** Do not say "all tests passed", "fully validated" or an equivalent unless that exact scope was actually executed.
- **[MUST]** Report any applicable required gate that was not executed, with the reason and the concrete residual risk.
- **[MUST]** Surface remaining validation failures and blockers clearly. Do not summarize a mixed or failing run as successful overall.

## Precision

- **[PREFER]** Do not enumerate every unrelated validation category just to mark it not applicable.
- **[PREFER]** Report residual risk only when there is a concrete unverified condition, limitation, compatibility concern or deferred issue.
- **[PREFER]** Report useful incidental issues separately from current-task failures so that they are not mistaken for regressions caused by the task.
- **[MUST]** Do not claim unmeasured performance, platform compatibility, freedom from leaks, visual quality or other properties that were not actually evaluated.
- **[PREFER]** For a visual change, state which composition, layout or animation-feel aspects still require manual acceptance under the [visual boundary](../70-tests/testing-strategy.md#visual-boundary).
- **[PREFER]** Include the exact Godot or tool version when the result is materially version-sensitive.
- **[PREFER]** Summarize logs instead of pasting them, unless a log excerpt is needed to explain a failure.
- **[MUST]** Report the current completion state only. Do not describe unperformed future work as if it will happen automatically.
