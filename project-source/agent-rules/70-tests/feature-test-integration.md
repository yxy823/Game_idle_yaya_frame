# Feature Workflow and Godot Test Integration

This document only connects the responsibilities of two rule sets. It does not replace the Godot test implementation rules in this directory, and it does not copy `methodology/08-test-traceability-and-evidence.md`.

## Authority boundary

- **[MUST]** The project workflow (methodology 03 and 08) decides what to test, why to test it, which tests to select and when to run them. It also decides how tests relate to Features, Acceptance Criteria, Bugs and manual acceptance.
- **[MUST]** This directory governs the concrete Godot test implementation: the L0 to L3 levels, runner behavior, fixtures, isolation, mocks and spies, the SceneTree, input, signals, asynchronous behavior and diagnostics.
- **[MUST]** The Required Test Set produced by the Test Impact Review is a minimum. The Godot impact gates in `test-selection-and-gates.md` may expand or escalate it, but they never silently remove tests from it.

## Traceability and physical organization

- **[MUST]** Logical IDs, test directories and the mapping to actual paths and test cases follow the [test taxonomy](../../methodology/08-test-traceability-and-evidence.md#test-taxonomy) and the [Registry rules](../../methodology/08-test-traceability-and-evidence.md#registry-rules).
- **[MUST]** The Godot levels L1 Unit, L2 Integration and L3 Runtime Scene are technical test levels, not physical directories that compete with the three Yaya test roots. Place each test in the Yaya directory that matches the contract it protects.

## Execution lifecycle

- **[MUST]** Implementation approval, the baseline and the RED, GREEN and refactor steps follow the [TDD execution contract](../../methodology/08-test-traceability-and-evidence.md#tdd-execution-contract). Acceptance, optional independent review and completion conditions are governed by the [execution loop](../../methodology/03-execute-loop.md).
- **[MUST]** Runner, selector and full-suite behavior follow the [Runner boundary](../../methodology/08-test-traceability-and-evidence.md#runner-boundary) and the actual project configuration. The project uses gdUnit4 as its fixed runner; see [GdUnit4 runner profile](gdunit4-profile.md).
- **[MUST]** The invocation, arguments and tool boundary of script parsing and lint follow the [direct static check contract](../../methodology/contracts/gdscript-lint.md).

If two applicable `[MUST]` rules still cannot be satisfied together, report a real rule conflict under [Rule precedence and routing](../00-core/rule-precedence-and-routing.md#rule-conflict-protocol). Do not weaken either gate to make tests pass.
