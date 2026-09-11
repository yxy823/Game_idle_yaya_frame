# Integration Tests (L2)

L2 tests keep the real collaborator/engine boundary that is the subject of the test.

## Boundary

- **[MUST]** An Integration Test preserves the real collaboration being validated: real components and/or real Godot Node/Resource/Signal/SceneTree semantics.
- **[MUST]** If every collaborator is mocked, test is still a Unit Test.
- **[PREFER]** Use smallest representative fixture/scene carrying real collaboration; do not boot Main Scene automatically.
- **[PREFER]** Test one clear integration boundary per TestCase where possible.

## Fixture scenes

- **[PREFER]** Create test-only fixture scenes composing real production subscenes/components with known dependencies.
- **[MUST]** Do not maintain a copied full production scene as parallel test scene that must be manually synchronized.
- **[MUST]** Fixture scenes provide composition/known state; they do not reimplement production behavior.
- **[PREFER]** Use primary runner's Scene ownership, frame simulation, input synchronization, and signal waiting rather than inventing another Scene test runtime.
- **[REVIEW]** Direct SceneRunner property/invoke access is for fixture setup, explicit white-box component tests, or diagnostics; do not use it to bypass production Commands and claim business operation works.

## Doubles and assertions

- **[PREFER]** Replace external/platform/nondeterministic dependencies outside current integration target with controlled Fakes/Stubs.
- **[MUST]** Keep core collaborators under test real.
- **[PREFER]** L2 focuses on boundary/wiring/lifecycle/serialization representative cases rather than duplicating entire L1 input matrix.
- **[REVIEW]** A heavily mocked module should have representative L2 evidence proving production wiring still matches mocked contract.
