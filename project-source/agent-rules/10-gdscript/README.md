# 10 GDScript Rules

Applies to project-owned `.gd` files, including project-owned test scripts. Vendor addon code follows the Core vendor rules unless the task explicitly owns a patch or fork.

Read the documents that match the change; a `.gd` file does not require every topic.

| Document | Read when |
| --- | --- |
| `typing-and-api.md` | Editing GDScript syntax, declarations, naming, exports, properties, public APIs or control flow; declaring signals or choosing the emit and connect API; consult its examples only when needed |
| `structure-and-dependencies.md` | Changing responsibilities, dependency direction, communication between modules (Command down, signal up) or global services |
| `state-resources-and-loading.md` | Changing state or Resource use, loading, error handling, time or randomness |
| `godot-lifecycle-and-input.md` | Using node lifecycle callbacks, CharacterBody movement, signal connection lifetime, `await`, scene changes or input event handling |
| `editor-tools-static-state-and-concurrency.md` | Changing `@tool` or editor code, static state, threads or Godot-specific performance behavior |
| `validation.md` | Any GDScript change: determine its applicable validation |

Signal rules are split by question: declaring signals and the emit and connect API in `typing-and-api.md`; the direction of communication in `structure-and-dependencies.md`; connection lifetime and awaiting in `godot-lifecycle-and-input.md`; editor versus code connections in [Scene UI and script binding](../20-scenes/ui-and-scripts.md#signal-connection-style). Input Action semantics are defined in [InputMap configuration](../40-project-config/input-map.md).

`gdlint.json` in the repository root owns the configured numeric linter thresholds.
