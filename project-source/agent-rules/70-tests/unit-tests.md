# Unit Tests (L1)

L1 tests verify a small rule or state unit without requiring the full real SceneTree lifecycle.

## Boundary

- **[PREFER]** Keep stable business rules testable without booting the main scene or unrelated Autoload infrastructure.
- **[MUST]** Do not start the whole application merely to test a pure calculation, validator, state transition or command rule.
- **[MUST]** A Node type does not automatically make a test L2. The deciding factor is whether the tested contract requires the real SceneTree lifecycle.

## Parameterized and property tests

- **[PREFER]** Use parameterized or table-driven tests for one shared contract with several inputs and expected outcomes.
- **[MUST]** Do not combine unrelated business contracts into one giant parameter matrix.
- **[PREFER]** Give parameter cases semantic names or context so that failures identify the business scenario.
- **[PREFER]** Combine representative examples, boundary cases and invariant or property tests for complex rules.

## Doubles

- **[PREFER]** Use Stubs, Mocks, Fakes or Spies only for dependencies outside the current test target.
- **[MUST]** Do not mock the core behavior being tested.
- **[MUST]** Do not mock Godot lifecycle, Signal, Resource or Input semantics and then claim that real Godot integration is verified.
- **[REVIEW]** Spy and interaction assertions are appropriate only when the collaboration itself is part of the contract; do not verify every internal helper call.
- **[PREFER]** A small in-memory Fake may be easier to maintain than complex mock choreography for simple stateful ports.
- **[MUST]** Do not create a test that mirrors the production topology with every dependency stubbed and every internal call verified.

## Characterization before refactoring

- **[PREFER]** Before refactoring stable legacy behavior with weak coverage, add minimal characterization tests.
- **[MUST]** Do not freeze a known bug as correct behavior merely because a characterization test captured it.
