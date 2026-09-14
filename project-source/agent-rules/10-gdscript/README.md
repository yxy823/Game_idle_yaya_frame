# 10 GDScript Rules

Applies to project-owned `.gd` files, including project-owned test scripts.
Vendor addon code follows Core vendor rules unless the task explicitly owns a
patch/fork.

Read the matching sections below; a `.gd` file does not require every topic.

| Document | Read when |
| --- | --- |
| `typing-and-api.md` | Editing GDScript syntax, declarations, naming, APIs, properties, signals or control flow; consult examples only when needed |
| `structure-and-dependencies.md` | Changing responsibilities, dependency direction, communication or global services |
| `state-resources-and-loading.md` | Changing state/resources, loading, error handling, time or randomness |
| `godot-lifecycle-and-input.md` | Using node lifecycle, movement, signals/async, scene changes, input or groups |
| `tools-exports-static-and-concurrency.md` | Changing editor/tool code, static state, concurrency or Godot-specific performance behavior |
| `validation.md` | Any GDScript change: determine its applicable validation |

`gdlint.json` in the repository root owns configured numeric linter thresholds.
