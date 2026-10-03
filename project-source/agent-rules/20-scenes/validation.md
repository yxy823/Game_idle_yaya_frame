# Scene Validation

```text
format and dependency parse
-> UID and resource consistency
-> NodePath and reference resolution
-> attached script compilation and base-type compatibility
-> dynamic instantiate, _enter_tree and _ready where relevant
-> affected integration and runtime behavior
```

- **[MUST]** Validate changed scenes with the target Godot 4.7.
- **[MUST]** For instancing or inheritance changes, validate representative source scenes and their derived or instance consumers.
- **[MUST]** If editor or automation tooling was used, inspect the resulting diff for unrelated scene pollution or normalization.
- **[MUST]** A scene that parses but fails during instantiation or `_ready` does not pass.
- **[PREFER]** For a sufficiently independent reusable Scene, use Play Current Scene (F6) or an equivalent isolated run as an additional validation path.
- **[MUST]** Classify an isolated-run failure as either a hidden, undeclared dependency or a declared public dependency that the isolated run did not provide. A reasonable dependency-injection contract is not an architecture defect merely because a bare F6 run cannot supply it.
- **[PREFER]** When a reusable Scene has a declared public dependency, validate it with the smallest harness or fixture that provides that dependency. Do not make the Scene falsely self-contained or add hidden `/root/...` paths merely to make isolated execution pass.
- **[PREFER]** Use the Remote Scene tree during runtime validation when ownership, instantiation, reparenting or orphan behavior is part of the change.
