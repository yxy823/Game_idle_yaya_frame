# 00 Core Rules

Core rules apply across file types. Use this router for modifications or relevant engineering decisions, then read only the concrete documents and sections that match the task. Reuse already loaded, unchanged rules during continuation; ordinary status or vocabulary discussion does not require loading engineering rules.

| Document | Read when |
|---|---|
| `rule-precedence-and-routing.md` | Multiple rule modules apply; rule strength or conflict must be resolved |
| `godot-version-and-authority.md` | Godot/tool behavior is version-sensitive or uncertain; assessing an upgrade or a documentation/runtime discrepancy |
| `change-scope-and-ownership.md` | Deciding task scope, dependent changes, deletion, refactor, or preservation of existing work |
| `git-worktree-and-commits.md` | Every modifying task: inspect/preserve current changes, same-directory continuation, staging, local commits or prohibited Git operations |
| `third-party-generated-and-temporary-files.md` | Vendor, generated, `.import`, cache, backup, scratch, or temporary files are involved |
| `validation-policy.md` | Combining validation gates or determining whether evidence is sufficient |
| `completion-and-reporting.md` | Preparing the final task report |

Core rules define cross-cutting invariants. Specialized modules refine them for a narrower domain; they do not silently erase unrelated Core obligations.
