# Testing Strategy

Static validation and behavioral tests are separate evidence. Use the lowest test level that proves the contract.

## Levels

- **[MUST]** Do not use Godot Engine's own internal `--test` infrastructure as normal project GDScript test framework.
- **[MUST]** Project declares one primary Godot test runner. Do not add a second framework merely because one test seems easier in it.
- **[PREFER]** Use a mature CLI/headless-capable framework with scene-testing support; gdUnit4 is reference choice for this Godot 4.x ruleset when adopted.
- **[MUST]** Static validation and behavioral tests are reported separately and do not substitute for each other.
- **[PREFER]** Use the lowest test level that proves the required contract.

## Distribution

- **[PREFER]** Keep many L1 tests for pure/domain rules, appropriate L2 tests for real Godot collaboration, and smaller high-value L3 flows.
- **[MUST]** Do not upgrade every test to Main-scene E2E for perceived realism.
- **[MUST]** A TestCase must have a real observable verification result; silent early return/zero-verification cannot count as PASS.
- **[MUST]** A reliably automatable business bug fix adds/updates regression evidence; purely visual/artistic defects default to manual visual acceptance.
- **[MUST]** Expected values do not copy production algorithm by default; use known examples, tables, independent invariants, or explicitly maintained reference implementation.
- **[MUST]** Tests primarily verify observable contracts rather than meaningless private implementation steps.

## Visual boundary

- **[MUST]** v1 does not require screenshots, golden images, pixel diffs, animation similarity, or subjective layout scoring.
- **[MUST]** Visual composition, artistic consistency, layout appearance, and animation feel use manual acceptance.
