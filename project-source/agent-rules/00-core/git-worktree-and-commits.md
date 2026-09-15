# Git Worktree and Commits

Defines repository-wide Git safety, task ownership, staging, and local commit
rules. These rules apply to every task that may modify repository files.

## Responsibility boundary

- **[MUST]** The owning workflow defines required approval and validation;
  its Completion Gate determines task completion. A local commit does not
  establish completion or human acceptance. Feature execution follows
  `methodology/03-execute-loop.md`, including its incremental commit boundary.
- **[MUST]** This document defines logical commit boundaries, staging, message
  format and post-commit checks for authorized changes.

## Clean worktree and task ownership

- **[MUST]** Before the first repository write for a task, run
  `git status --porcelain` and inspect every entry, including staged,
  unstaged, untracked, deleted, renamed, and conflicted paths.
- **[MUST]** A new modifying task starts only from a clean worktree. If any
  pre-existing change is present, stop and report it; do not add, stash,
  restore, delete, overwrite, or otherwise absorb it into the new task.
- **[MUST]** A resumed multi-turn task may continue with a dirty worktree only
  when every existing change is demonstrably owned by that same task. Stop if
  ownership is unknown, mixed, or contradicted by the durable Feature/Progress
  record.
- **[MUST]** Read actual Git status and the relevant diff before writes;
  no automatic event establishes task ownership.

- **[MUST]** Cross-session continuation uses the user's explicit resumed task,
  its Progress/Feature history, current HEAD and all staged/unstaged/untracked
  diffs. Match every dirty path to that task before writing; a changed HEAD or
  session ID alone neither proves nor disproves ownership. If any path remains
  unexplained, report it and stop writes. Read-only review, clarification,
  cancellation and acceptance discussion can continue. Do not create a new
  owner record or clean the workspace to manufacture proof.
- **[MUST]** Ordinary project writes require Git. The one first-use exception
  is an explicitly requested fresh-project initialization: inspect the exact
  project files, configure tools, initialize independent Git, review
  initial/imported files and create an initial local commit within the user's
  authorization. If the request explicitly excludes a commit, finish the
  authorized environment preparation with the initial baseline uncommitted.
  When that commit is authorized, continue the same initialization and review
  only its known initial files and setup changes before committing.
  This exception cannot absorb existing business work or unknown files.
  Before a new modifying task starts, the initial baseline must be committed
  and the worktree clean. See README environment instructions.

## Staging

- **[MUST]** Stage only paths or individual hunks produced by the current
  logical task. Use explicit path arguments or an inspected hunk-selection
  mechanism.
- **[MUST]** Do not use `git add .`, `git add -A`, broad globs, or another
  staging command that can silently include unrelated work.
- **[MUST]** Before committing, run `git diff --cached --check`, inspect
  `git diff --cached --stat`, and inspect the complete `git diff --cached`.
  Remove unrelated staged paths or hunks before continuing.
- **[MUST]** Confirm every applicable validation route covers the final staged
  change. Reuse still-valid results under the owning workflow's evidence rules;
  run missing or invalidated checks. The committed snapshot must be usable and
  include its required dependencies; success that relies on excluded working-tree
  changes does not validate that snapshot. Do not commit broken or incomplete
  logical changes, failing RED tests, or claim that an unexecuted Gate passed.

## Local commits

- **[MUST]** Execute Features and create their eligible local commits on the
  current Git branch, including `main` or `master`. The branch name does not
  waive clean-worktree, approval, acceptance, validation, or Completion Gates.
- **[MUST]** During an authorized modifying task, automatically commit each
  complete logical change once its applicable validation passes, without another
  confirmation; an explicit no-commit request or user-defined commit condition
  takes precedence. At task completion, commit any remaining validated changes.
- **[MUST]** One commit represents one independently understandable logical
  change. Separate independent Features, Bugs, and Refactors. Changes sharing
  one root cause may stay together only when they must be implemented and
  verified together. One Feature may have several commits; each later commit
  may depend on earlier committed work. Choose boundaries by coherent behavior
  and validation, not time, file count or a fixed number of commits. A small
  task may need only one commit.
- **[MUST]** Use the subject format
  `<type>(<scope>): <Chinese behavior summary>`. The summary must identify the
  actual behavior or workflow change; do not use vague summaries such as
  "修复问题", "更新代码", "优化逻辑", or "调整内容".
- **[PREFER]** Use an established concise type such as `feat`, `fix`,
  `refactor`, `test`, `perf`, `build`, `docs`, or `chore`, and choose the
  narrowest stable scope. For an executed Feature, the Feature ID is the
  preferred scope.
- **[MUST]** For a non-trivial change, use a concise body that states what
  changed, why it was needed, meaningful implementation decisions, and the
  principal validation actually run. Do not mechanically enumerate files.
- **[MUST]** A Feature implementation or Engineering Feature commit, including
  incremental implementation and completion records, includes
  `Feature: <current Feature title>` in the body, using the matching entry's
  `title` in `docs/feature-list.json`, and exactly one
  `Work item: <relative-path>` pointing to its Feature detail record,
  for example `Work item: docs/features/F012.json`. Keep the subject specific to
  this commit's change instead of repeating only the overall Feature title.
  Remaining work belongs in Feature/Progress records, not a required commit-body
  section. Mention a limitation only when it affects understanding or using this
  change; do not describe a partial delivery as the whole Feature being complete.
  Tasks without a single owning Feature omit these fields rather than inventing
  a name/path or pointing at implementation artifacts.
- **[MUST]** After committing, run `git status --short` and confirm there are no
  accidentally committed, omitted, or newly generated changes. If a committed
  change needs correction, create a new correction commit; do not rewrite the
  existing commit.

### Message example

Illustrative incremental commit; replace the name, change and verification with
actual facts. Body labels other than `Feature:` and `Work item:` are optional;
omit redundant sections for simple changes.

```text
feat(F012): 增加背包容量检查并拒绝超量入库

Feature: 增加背包物品管理

内容：入库前检查剩余容量，超量时返回失败并保持原有物品数量。
原因：避免容量不足时部分写入，导致调用方无法判断实际入库结果。
验证：容量边界与失败后数量不变的测试通过；相关解析和 lint 通过。

Work item: docs/features/F012.json
```

## Forbidden operations

- **[MUST]** Do not automatically push, tag, amend, rebase, reset, modify Git
  remotes, bypass hooks with `--no-verify`, force-update history, or use a
  destructive checkout/clean operation.
- **[MUST]** Do not automatically create, switch, merge, or delete branches.
