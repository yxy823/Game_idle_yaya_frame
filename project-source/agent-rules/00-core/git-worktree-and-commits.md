# Git Changes and Commits

Defines Git change preservation, staging and local commits for a single-user project. These rules apply to every task that may modify repository files; they do not establish multi-user change attribution.

## Responsibility boundary

- **[MUST]** The workflow that governs the task defines the required approval and validation, and its Completion Gate determines task completion. A local commit does not establish completion or human acceptance. Feature execution follows `methodology/03-execute-loop.md`, including its incremental commit boundary.
- **[MUST]** This document defines logical commit boundaries, staging, message format and delivery reporting for authorized changes.

## Inspect and preserve current changes

- **[MUST]** When the task designates a checkout, including an authorized worktree, work in it. Verify its actual path and Git state, then read, modify and validate project files there; do not substitute another checkout.
- **[MUST]** Use a worktree only when the current scope and authorization call for one; do not create one by default.
- **[MUST]** A separate checkout alone does not isolate tools, running processes, caches or runtime data. Assess the side effects that matter for the requested operation.
- **[MUST]** At the start of a modifying task, inspect Git status and the relevant differences to understand existing work and the staging state.
- **[MUST]** Preserve pre-existing unrelated content and its staging state. A non-empty Git status alone does not block an authorized task. Do not stash, restore, delete, overwrite or include unrelated changes merely to obtain a clean directory or a convenient commit.
- **[MUST]** To pause, switch or resume work, use the task's designated checkout, the Feature and Progress records, the current HEAD and the relevant actual differences. Ordinary continuation in the same directory needs no new checkout.
- **[MUST]** Reuse valid work, decisions and authorization; a new conversation does not start the task over. After verifying their scope, changes that belong to the same authorized task may be completed, validated and committed.
- **[MUST]** Do not require per-file authorship proof or create an attribution ledger.
- **[MUST]** Stop only the dependent mutation and explain the concrete overlap when the requested edit conflicts with existing content, the intended result is materially ambiguous, or a coherent validated commit cannot be separated from unrelated changes. Continue unaffected authorized work and read-only analysis until the overlap is resolved. Do not resolve a conflict by discarding existing work.
- **[MUST]** If an unfinished merge or rebase, or a change of HEAD or branch, cannot be explained by the authorized task's operations, preserve the state and report it. Resolve the uncertainty before dependent writes or commits; do not automatically abort, reset or clean it up.
- **[MUST]** Project writes require Git. Environment setup follows the same preservation, validation and local commit rules as other modifying tasks.

## Staging

- **[MUST]** Stage only paths or individual hunks that belong to the current logical change, including verified work resumed from the same task. Use explicit path arguments or an inspected hunk-selection mechanism.
- **[MUST]** Do not use `git add .`, `git add -A`, `git commit -a`, broad globs or another command that can silently include unrelated work.
- **[MUST]** Perform the validation required by the task and reuse results that still cover the current change. Committing adds no separate review gate: do not reread the complete staged diff or rerun passed checks for every commit. Check again only for new changes, failures, invalidated evidence or a concrete concern. Include the dependencies that the committed change needs.
- **[MUST]** Report unresolved validation failures or missing evidence under the governing workflow. Do not claim that unexecuted checks passed, and do not delete valid tests, weaken assertions or bypass checks to obtain a pass.

## Local commits

- **[MUST]** Execute Features and create their eligible local commits in the task's target checkout. A branch named `main` or `master` does not by itself require switching branches. The branch name also does not waive change preservation, approval, acceptance, validation or Completion Gates.
- **[MUST]** Automatically commit complete logical changes within the authorized task, without another confirmation. Choose boundaries as the work develops; a separate commit plan or review is not required.
- **[MUST]** An explicit no-commit request or a user-defined commit condition takes precedence within its scope and continues across Skills and resumed conversations. When a task separately requires actual acceptance and explicit permission to commit, satisfy both: an accepted result alone grants no commit permission, and permission to commit alone supplies no acceptance. Reuse permission that is already explicit without asking again.

### Commit boundaries

- **[MUST]** One commit represents one independently understandable logical change, together with its necessary implementation, tests, references and documentation.
- **[MUST]** Separate independent Features, Bugs and Refactors. Changes that share one root cause may stay together only when they must be implemented and verified together.
- **[MUST]** One Feature may have several commits, and each later commit may depend on earlier committed work.
- **[MUST]** Choose boundaries by coherent behavior and validation, not by time, file count, a fixed number of commits or separate "code", "test" and "docs" phases. A small task may need only one commit.

### Commit messages

- **[MUST]** Use the subject format `<type>(<scope>): <Chinese behavior summary>`. The summary identifies the actual behavior or workflow change; do not use vague summaries such as "修复问题", "更新代码", "优化逻辑" or "调整内容".
- **[PREFER]** Use an established concise type such as `feat`, `fix`, `refactor`, `test`, `perf`, `build`, `docs` or `chore`, and choose the narrowest stable scope. For an executed Feature, the Feature ID is the preferred scope.
- **[MUST]** For a non-trivial change, write a concise body that states what changed, why it was needed, meaningful implementation decisions and the principal validation actually run. Do not mechanically enumerate files.
- **[MUST]** Every commit for a Feature or an Engineering Feature, including incremental implementation and completion records, includes these two body lines:
  - `Feature: <current Feature title>`, using the `title` of the matching entry in `docs/feature-list.json`;
  - exactly one `Work item: <relative-path>` that points to the Feature detail record, for example `Work item: docs/features/F012.json`.
- **[MUST]** Keep the subject specific to this commit's change instead of repeating only the overall Feature title.
- **[MUST]** Record remaining work in the Feature and Progress records; a commit body has no required section for it. Mention a limitation only when it affects understanding or using this change, and do not describe a partial delivery as the whole Feature being complete.
- **[MUST]** A task without a single Feature that owns it omits the `Feature:` and `Work item:` lines. Do not invent a name or path, and do not point them at implementation files.

### Correction and delivery

- **[MUST]** If a committed change needs correction, fix and validate it, then create a new correction commit; do not rewrite the existing commit.
- **[MUST]** At task delivery, report this task's commit hashes or verified range, the validation actually run and any remaining uncommitted task changes. A logical commit does not mean that the whole task is complete.
- **[MUST]** If repository state, permissions, identity, signing or hooks prevent a commit, preserve the work and report the actual failure and the uncommitted scope. Do not silently initialize a repository, change Git configuration or bypass checks to make committing succeed. Explicitly authorized project creation keeps its own repository-initialization contract.

### Message example

An illustrative incremental commit; replace the name, change and verification with actual facts. Body labels other than `Feature:` and `Work item:` are optional; omit redundant sections for simple changes.

```text
feat(F012): 增加背包容量检查并拒绝超量入库

Feature: 增加背包物品管理

内容：入库前检查剩余容量，超量时返回失败并保持原有物品数量。
原因：避免容量不足时部分写入，导致调用方无法判断实际入库结果。
验证：容量边界与失败后数量不变的测试通过；相关解析和 lint 通过。

Work item: docs/features/F012.json
```

## Forbidden operations

- **[MUST]** Do not automatically push, tag, amend, rebase, reset, modify Git remotes, bypass hooks with `--no-verify`, force-update history or use a destructive checkout or clean operation.
- **[MUST]** Do not create, switch, merge or delete branches outside the current task's concrete authorization. Using a worktree alone does not authorize changes to another checkout or the removal of existing work.
