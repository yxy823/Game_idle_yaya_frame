# Integration Tests (L2)

L2 tests keep the real collaborator or engine boundary that is the subject of the test.

## Boundary

- **[MUST]** An integration test preserves the real collaboration being validated: real components, real Godot Node, Resource, Signal and SceneTree semantics, or both.
- **[MUST]** If every collaborator is mocked, the test is still a unit test.
- **[PREFER]** Use the smallest representative fixture or scene that carries the real collaboration; do not boot the main scene automatically.
- **[PREFER]** Test one clear integration boundary per TestCase where possible.

## Fixture scenes

- **[PREFER]** Create test-only fixture scenes that compose real production subscenes and components with known dependencies.
- **[MUST]** Do not maintain a copy of a full production scene as a parallel test scene that must be synchronized by hand.
- **[MUST]** Fixture scenes provide composition and a known state; they do not reimplement production behavior.
- **[PREFER]** Use the primary runner's Scene ownership, frame simulation, input synchronization and signal waiting rather than inventing another runtime for Scene tests.
- **[REVIEW]** Direct property access or method invocation through the SceneRunner is for fixture setup, explicit white-box component tests or diagnostics. Do not use it to bypass production Commands and then claim that the business operation works.

## Doubles and assertions

- **[PREFER]** Replace external, platform and nondeterministic dependencies outside the current integration target with controlled Fakes or Stubs.
- **[MUST]** Keep the core collaborators under test real.
- **[PREFER]** L2 tests focus on representative cases of boundaries, wiring, lifecycle and serialization rather than duplicating the entire L1 input matrix.
- **[REVIEW]** A heavily mocked module has representative L2 evidence proving that the production wiring still matches the mocked contract.
