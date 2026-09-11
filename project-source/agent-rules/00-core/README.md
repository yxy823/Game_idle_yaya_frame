# 00 Core Rules

Core rules apply across file types. Read this README for every task, then load the concrete Core documents that match the change.

| Document | Read when |
|---|---|
| `rule-precedence-and-routing.md` | Multiple rule modules apply; rule strength or conflict must be resolved |
| `change-scope-and-ownership.md` | Deciding task scope, dependent changes, deletion, refactor, or preservation of existing work |
| `git-worktree-and-commits.md` | Every modifying task: clean-worktree preflight, task ownership, staging, local commit, or prohibited Git operations |
| `third-party-generated-and-temporary-files.md` | Vendor, generated, `.import`, cache, backup, scratch, or temporary files are involved |
| `validation-policy.md` | Combining validation gates or determining whether evidence is sufficient |
| `completion-and-reporting.md` | Preparing the final task report |

Core rules define cross-cutting invariants. Specialized modules refine them for a narrower domain; they do not silently erase unrelated Core obligations.
