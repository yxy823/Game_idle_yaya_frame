# Git Worktree and Commits

Defines repository-wide Git safety, task ownership, staging, and local commit
rules. These rules apply to every task that may modify repository files.

## Responsibility boundary

- **[MUST]** The applicable completion workflow and Completion Gate decide
  **when** a task is eligible to commit. This document must not reinterpret,
  waive, or replace that eligibility decision.
- **[MUST]** Once commit eligibility is established, this document defines
  **how** the task-owned changes are staged, committed, and checked afterward.

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
  initial/imported files and create an authorized initial local commit.
  This exception cannot absorb existing business work or unknown files.
  Only after this setup may a new Feature start. See README environment instructions.

## Staging

- **[MUST]** Stage only paths or individual hunks produced by the current
  logical task. Use explicit path arguments or an inspected hunk-selection
  mechanism.
- **[MUST]** Do not use `git add .`, `git add -A`, broad globs, or another
  staging command that can silently include unrelated work.
- **[MUST]** Before committing, run `git diff --cached --check`, inspect
  `git diff --cached --stat`, and inspect the complete `git diff --cached`.
  Remove unrelated staged paths or hunks before continuing.
- **[MUST]** Run every validation applicable to the final staged change. Do
  not commit an obvious intermediate state or claim that an unexecuted Gate
  passed.

## Local commits

- **[MUST]** Execute Features and create their eligible local commits on the
  current Git branch, including `main` or `master`. The branch name does not
  waive clean-worktree, approval, acceptance, validation, or Completion Gates.
- **[MUST]** Once the completion workflow declares the task commit-eligible,
  create one local commit without requesting another confirmation. The
  exception is an explicit user request not to commit.
- **[MUST]** One commit represents one independently understandable logical
  change. Separate independent Features, Bugs, and Refactors. Changes sharing
  one root cause may stay together only when they must be implemented and
  verified together.
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
- **[MUST]** A Feature implementation or Engineering Feature commit includes
  exactly one stable body field `Work item: <relative-path>` pointing to its
  Feature detail record, for example `Work item: docs/features/F012.json`.
  Never point this field at `.gd`, `.tscn`, `.tres`, or another implementation
  artifact. A maintenance/infrastructure task without a work-item document
  omits the field rather than inventing one.
- **[MUST]** After committing, run `git status --short` and confirm there are no
  accidentally committed, omitted, or newly generated changes. If a committed
  change needs correction, create a new correction commit; do not rewrite the
  existing commit.

## Forbidden operations

- **[MUST]** Do not automatically push, tag, amend, rebase, reset, modify Git
  remotes, bypass hooks with `--no-verify`, force-update history, or use a
  destructive checkout/clean operation.
- **[MUST]** Do not automatically create, switch, merge, or delete branches.
