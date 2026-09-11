# Unit Tests (L1)

L1 tests verify a small rule/state unit without requiring full real SceneTree lifecycle.

## Boundary

- **[PREFER]** Stable business rules are testable without booting Main Scene or unrelated Autoload infrastructure.
- **[MUST]** Do not start whole application merely to test a pure calculation, validator, state transition, or command rule.
- **[MUST]** A Node type does not automatically make a test L2; deciding factor is whether tested contract requires real SceneTree lifecycle.

## Parameterized/property tests

- **[PREFER]** Use parameterized/table-driven tests for one shared contract with multiple inputs/expected outcomes.
- **[MUST]** Do not combine unrelated business contracts into one giant parameter matrix.
- **[PREFER]** Give parameter cases semantic names/context so failures identify business scenario.
- **[PREFER]** Combine representative examples, boundary cases, and invariant/property tests for complex rules.

## Doubles

- **[PREFER]** Stub/Mock/Fake/Spy only dependencies outside current test target.
- **[MUST]** Do not mock core behavior being tested.
- **[MUST]** Do not mock Godot lifecycle/Signal/Resource/Input semantics and then claim real Godot integration is verified.
- **[REVIEW]** Spy/interaction assertions are appropriate only when collaboration itself is part of contract; do not verify every internal helper call.
- **[PREFER]** A small in-memory Fake may be more maintainable than complex mock choreography for simple stateful ports.
- **[MUST]** Do not create a test that mirrors production topology with every dependency stubbed and every internal call verified.

## Refactor characterization

- **[PREFER]** Before refactoring stable legacy behavior with weak coverage, add minimal characterization tests.
- **[MUST]** Do not freeze a known bug as correct behavior merely because a characterization test captured it.
