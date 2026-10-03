# Runtime Scene Tests (L3)

L3 tests verify critical runtime flows across several systems, starting from a legal scenario and using production-facing operations.

## Scope

- **[PREFER]** Cover critical, high-value gameplay flows that cross systems, not every local function.
- **[MUST]** Drive the behavior under test through a real production-facing Command, API or input path.
- **[MUST]** Fixture and scenario setup may establish legal preconditions quickly, but must not directly produce the result of the operation being tested.
- **[PREFER]** Start from the legal scenario or checkpoint closest to the flow. Starting from the main scene is required only when application startup itself is the contract.

## Reality and doubles

- **[MUST]** Core systems that belong to the tested runtime flow use their real production implementation.
- **[REVIEW]** External, platform, network and telemetry boundaries outside the tested contract may use controlled Fakes that preserve the production interface.
- **[PREFER]** Assert the authoritative final state and domain events, plus a small number of meaningful milestones that help locate failures.
- **[MUST]** Do not lock down the order of all internal method calls unless that order is itself a business contract.

## Visual boundary

- **[MUST]** L3 behavior tests use deterministic assertions on runtime state, events, lifecycle and input. Supplemental rendering checks and manual visual acceptance follow the [visual boundary](testing-strategy.md#visual-boundary).
