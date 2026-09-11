# GDScript Validation

After a `.gd` change:

- **[MUST]** Validate with target Godot 4.7 parser/compiler/import path, not only a third-party parser.
- **[MUST]** Run configured `graydwarf/godot-gdscript-linter` checks for project-owned changed GDScript. `gdlint.json` owns exact thresholds.
- **[MUST]** Do not add/expand `gdlint:ignore*`, `@warning_ignore`, exclusions, or linter configuration merely to pass.
- **[MUST]** Run affected behavioral tests required by `70-tests/test-selection-and-gates.md`.
- **[MUST]** If lifecycle, Node, Resource, Input, Autoload, threading, or other runtime semantics changed, include the corresponding real Godot integration/runtime gate.
- **[MUST]** A warning/critical metric is a review signal, not automatic authorization for meaningless splitting.

Recommended stack:

```text
Godot native parse/static typing
+ configured GDScript linter
+ target Godot real parse/import
+ affected project tests/runtime gates
```
