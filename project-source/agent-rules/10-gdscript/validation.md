# GDScript Validation

After a `.gd` change:

- **[MUST]** Validate with the parser, compiler and import path of the target Godot 4.7, not only with a third-party parser.
- **[MUST]** Run the configured `graydwarf/godot-gdscript-linter` checks on changed project-owned GDScript. `gdlint.json` owns the exact thresholds.
- **[MUST]** Do not add or expand `gdlint:ignore*`, `@warning_ignore`, exclusions or linter configuration merely to pass.
- **[MUST]** Run the affected behavioral tests that [test selection and gates](../70-tests/test-selection-and-gates.md) requires.
- **[MUST]** If lifecycle, Node, Resource, Input, Autoload, threading or other runtime semantics changed, include the corresponding real Godot integration or runtime gate.
