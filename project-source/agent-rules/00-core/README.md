# 00 Core Rules

Core rules apply across file types. Use this router for modifications or relevant engineering decisions, then read only the concrete documents and sections that match the task. Reuse already loaded, unchanged rules during continuation; ordinary status or vocabulary discussion does not require loading engineering rules.

| Document | Read when |
|---|---|
| `rule-precedence-and-routing.md` | Multiple rule modules apply; rule strength or conflict must be resolved |
| `godot-version-and-authority.md` | Godot/tool behavior is version-sensitive or uncertain; assessing an upgrade or a documentation/runtime discrepancy |
| `change-scope-and-ownership.md` | Preparing a modification: locate the implementation and impact, choose scope, preserve APIs/dependencies/style and existing work; assess dependent changes, deletion or refactor |
| `git-worktree-and-commits.md` | Every modifying task: inspect/preserve current changes, same-directory continuation, staging, local commits or prohibited Git operations |
| `third-party-generated-and-temporary-files.md` | Vendor, generated, `.import`, cache, backup, scratch, or temporary files are involved |
| `validation-policy.md` | Combining validation gates or determining whether evidence is sufficient |
| `completion-and-reporting.md` | Preparing the final task report |
| [technical-documentation-writing-godot](../../.agents/skills/technical-documentation-writing-godot/SKILL.md) | Writing, updating or organizing project documentation; use its relevant references while preserving the owning schemas and workflow contracts |

Core rules define cross-cutting invariants. Specialized modules refine them for a narrower domain; they do not silently erase unrelated Core obligations.
