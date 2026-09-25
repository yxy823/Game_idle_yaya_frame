# Git Changes and Commits

Defines Git change preservation, staging and local commits for a single-user project in one project directory. These rules apply to every task that may modify repository files; they do not establish multi-user change attribution or worktree workflows.

## Responsibility boundary

- **[MUST]** The owning workflow defines required approval and validation; its Completion Gate determines task completion. A local commit does not establish completion or human acceptance. Feature execution follows `methodology/03-execute-loop.md`, including its incremental commit boundary.
- **[MUST]** This document defines logical commit boundaries, staging, message format and post-commit checks for authorized changes.

## Inspect and preserve current changes

- **[MUST]** Before the first repository write for a task, run `git status --porcelain` and inspect every entry, including staged, unstaged, untracked, deleted, renamed, and conflicted paths.
- **[MUST]** Read relevant diffs before editing and preserve pre-existing work. A non-empty Git status alone does not block an authorized task. Do not stash, restore, delete, overwrite or include unrelated changes merely to obtain a clean directory or a convenient commit.
- **[MUST]** Pause, switch and resume work in the same project directory using the requested task, existing Feature/Progress records, current HEAD and relevant actual differences. Reuse valid work, decisions and authorization; a new conversation does not start the task over. Do not require per-file authorship proof or create an attribution ledger.
- **[MUST]** If the requested edit conflicts with existing content, the intended result is materially ambiguous, or a coherent validated commit cannot be separated from unrelated changes, explain the concrete overlap and stop only the dependent mutation until resolved. Continue unaffected authorized work and read-only analysis. Do not resolve a conflict by discarding existing work.
- **[MUST]** Project writes require Git. Environment setup follows the same preservation, validation and local commit rules as other modifying tasks.

## Staging

- **[MUST]** Stage only paths or individual hunks produced by the current logical task. Use explicit path arguments or an inspected hunk-selection mechanism.
- **[MUST]** Do not use `git add .`, `git add -A`, broad globs, or another staging command that can silently include unrelated work.
- **[MUST]** Before committing, run `git diff --cached --check`, inspect `git diff --cached --stat`, and inspect the complete `git diff --cached`. Correct an accidental inclusion made by this task; preserve pre-existing staged work and resolve a conflicting commit boundary rather than silently unstaging or committing it.
- **[MUST]** Confirm every applicable validation route covers the final staged change. Reuse still-valid results under the owning workflow's evidence rules; run missing or invalidated checks. The committed snapshot must be usable and include its required dependencies; success that relies on excluded working-tree changes does not validate that snapshot. Do not commit broken or incomplete logical changes, failing RED tests, or claim that an unexecuted Gate passed.

## Local commits

- **[MUST]** Execute Features and create their eligible local commits on the current Git branch, including `main` or `master`. The branch name does not waive change preservation, approval, acceptance, validation or Completion Gates.
- **[MUST]** During an authorized modifying task, automatically commit each complete logical change once its applicable validation passes, without another confirmation; an explicit no-commit request or user-defined commit condition takes precedence. At task completion, commit any remaining validated changes.
- **[MUST]** One commit represents one independently understandable logical change. Separate independent Features, Bugs, and Refactors. Changes sharing one root cause may stay together only when they must be implemented and verified together. One Feature may have several commits; each later commit may depend on earlier committed work. Choose boundaries by coherent behavior and validation, not time, file count or a fixed number of commits. A small task may need only one commit.
- **[MUST]** Use the subject format `<type>(<scope>): <Chinese behavior summary>`. The summary must identify the actual behavior or workflow change; do not use vague summaries such as "修复问题", "更新代码", "优化逻辑", or "调整内容".
- **[PREFER]** Use an established concise type such as `feat`, `fix`, `refactor`, `test`, `perf`, `build`, `docs`, or `chore`, and choose the narrowest stable scope. For an executed Feature, the Feature ID is the preferred scope.
- **[MUST]** For a non-trivial change, use a concise body that states what changed, why it was needed, meaningful implementation decisions, and the principal validation actually run. Do not mechanically enumerate files.
- **[MUST]** A Feature implementation or Engineering Feature commit, including incremental implementation and completion records, includes `Feature: <current Feature title>` in the body, using the matching entry's `title` in `docs/feature-list.json`, and exactly one `Work item: <relative-path>` pointing to its Feature detail record, for example `Work item: docs/features/F012.json`. Keep the subject specific to this commit's change instead of repeating only the overall Feature title. Remaining work belongs in Feature/Progress records, not a required commit-body section. Mention a limitation only when it affects understanding or using this change; do not describe a partial delivery as the whole Feature being complete. Tasks without a single owning Feature omit these fields rather than inventing a name/path or pointing at implementation artifacts.
- **[MUST]** After committing, run `git status --short` and confirm there are no accidentally committed, omitted, or newly generated changes. If a committed change needs correction, create a new correction commit; do not rewrite the existing commit.

### Message example

Illustrative incremental commit; replace the name, change and verification with actual facts. Body labels other than `Feature:` and `Work item:` are optional; omit redundant sections for simple changes.

```text
feat(F012): 增加背包容量检查并拒绝超量入库

Feature: 增加背包物品管理

内容：入库前检查剩余容量，超量时返回失败并保持原有物品数量。
原因：避免容量不足时部分写入，导致调用方无法判断实际入库结果。
验证：容量边界与失败后数量不变的测试通过；相关解析和 lint 通过。

Work item: docs/features/F012.json
```

## Forbidden operations

- **[MUST]** Do not automatically push, tag, amend, rebase, reset, modify Git remotes, bypass hooks with `--no-verify`, force-update history, or use a destructive checkout/clean operation.
- **[MUST]** Do not automatically create, switch, merge, or delete branches.
