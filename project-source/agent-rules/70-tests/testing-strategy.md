# Testing Strategy

Static validation and behavioral tests are separate evidence. Use the lowest test level that proves the contract.

## Levels

- **[MUST]** Do not use Godot Engine's internal `--test` infrastructure as the project's GDScript test framework.
- **[MUST]** The project uses gdUnit4 as its fixed test runner; see [GdUnit4 runner profile](gdunit4-profile.md). Do not add a second framework merely because one test seems easier to write in it.
- **[MUST]** Report static validation and behavioral tests separately; neither substitutes for the other.
- **[PREFER]** Use the lowest test level that proves the required contract.

## Distribution

- **[PREFER]** Keep many L1 tests for pure and domain rules, appropriate L2 tests for real Godot collaboration, and a smaller number of high-value L3 flows.
- **[MUST]** Do not upgrade every test to an end-to-end test from the main scene for perceived realism.
- **[MUST]** A TestCase has a real observable verification result. A silent early return or a test that verifies nothing cannot count as PASS.
- **[MUST]** A business bug fix that can be reliably automated adds or updates regression evidence. Purely visual or artistic defects default to manual visual acceptance.
- **[MUST]** Expected values do not copy the production algorithm by default. Use known examples, tables, independent invariants or an explicitly maintained reference implementation.
- **[MUST]** Tests primarily verify observable contracts rather than meaningless private implementation steps.

## Visual boundary

- **[MUST]** The framework does not impose a general screenshot, golden-image, pixel-diff, animation-similarity or subjective-layout gate. Do not introduce one as an implicit requirement of ordinary delivery.
- **[REVIEW]** A task with an explicitly agreed objective rendering contract may use scoped screenshot or pixel checks as supplemental evidence. State the observable contract and the environment limits; such checks do not establish subjective visual acceptance or become a project-wide gate.
- **[MUST]** Visual composition, artistic consistency, layout appearance and animation feel use manual acceptance.
