# 00 Core Rules

Core rules apply across file types. Use this router for modifications and related engineering decisions, then read only the documents and sections that match the task. Ordinary status or vocabulary discussion does not require loading engineering rules.

| Document | Read when |
|---|---|
| `rule-precedence-and-routing.md` | Several rule modules apply, or a rule's strength or a conflict between rules must be resolved |
| `godot-version-and-authority.md` | Godot or tool behavior is version-sensitive or uncertain; assessing an upgrade or a discrepancy between documentation and runtime |
| `godot-resource-references.md` | Choosing or changing business IDs, Resource UIDs, resource paths, NodePaths or scene references |
| `change-scope-and-ownership.md` | Preparing a modification: locating the implementation and its impact, choosing scope, preserving APIs, dependencies, style and existing work, or assessing dependent changes, deletion or refactoring |
| `git-worktree-and-commits.md` | Every modifying task: choosing the target checkout, inspecting and preserving current changes, continuing a task, staging, local commits and prohibited Git operations |
| `third-party-generated-and-temporary-files.md` | Vendor, generated, `.import`, cache, backup, scratch or temporary files are involved |
| `validation-policy.md` | Combining validation gates, deciding whether evidence is sufficient, or running Godot editor checks |
| `completion-and-reporting.md` | Preparing the final task report |
| [technical-documentation-writing-godot](../../.agents/skills/technical-documentation-writing-godot/SKILL.md) | Writing, updating or organizing project documentation. Read the Skill's references that match the document type. Its writing guidance does not change the field rules of `docs/` files or the workflow steps defined in `methodology/`. |

Core rules define cross-cutting invariants. Specialized modules refine them for a narrower domain; they do not silently remove unrelated Core obligations.
