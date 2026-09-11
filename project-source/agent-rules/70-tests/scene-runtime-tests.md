# Runtime Scene Tests (L3)

L3 tests verify critical multi-system runtime flows from a legal scenario using production-facing operations.

## Scope

- **[PREFER]** Cover critical/high-value cross-system gameplay flows, not every local function.
- **[MUST]** Drive behavior under test through a real production-facing Command/API/Input path.
- **[MUST]** Fixture/scenario setup may establish legal preconditions quickly but must not directly manufacture result of operation being tested.
- **[PREFER]** Start from closest legal scenario/checkpoint to flow; Main Scene from zero is required only when application startup itself is contract.

## Reality and doubles

- **[MUST]** Core systems belonging to tested runtime flow use real production implementation.
- **[REVIEW]** External/platform/network/telemetry boundaries outside tested contract may use controlled Fakes preserving production interface.
- **[PREFER]** Assert authoritative final state and domain events, plus small number of meaningful milestones for failure localization.
- **[MUST]** Do not lock down all internal method-call ordering unless ordering itself is business contract.

## Visual boundary

- **[MUST]** L3 automated assertions remain deterministic runtime state/event/lifecycle/input checks. Do not add screenshot/golden/pixel-diff visual gates in v1.
