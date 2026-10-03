# Time, Randomness, and Async Testing

Tests control the same clock, RNG and asynchronous semantics that the production behavior actually uses.

## Time domains

- **[MUST]** Declare whether the behavior uses scaled gameplay time, physics time, unscaled monotonic elapsed time or wall-clock and calendar time. These are not interchangeable.
- **[MUST]** Elapsed-time tests do not accidentally hard-code the render FPS unless the frame count itself is the contract.
- **[MUST]** Physics behavior uses the real physics-tick path. Do not change the physics tick rate as a routine trick to speed up tests.
- **[MUST]** Timer and SceneTreeTimer tests cover the process domain, pause behavior, time-scale behavior and the timeout result when those are part of the contract.
- **[MUST]** Pause and `Engine.time_scale` are separate test dimensions.
- **[MUST]** Duration and timeout correctness does not use an adjustable wall clock, and calendar or date behavior does not use monotonic ticks.
- **[PREFER]** Use injected or controlled clocks, the runner's frame and time simulation, or controlled Timers instead of waiting real seconds.

## Tween and frame synchronization

- **[MUST]** Tween tests advance controlled time or frames and assert the state or completion; do not sleep until a Tween finishes.
- **[PREFER]** Assert intermediate Tween values only when they are a business contract, and use an appropriate float tolerance.
- **[MUST]** A fixed `await` of N frames needs a lifecycle or processing reason; do not use a magic "two-frame" synchronization ritual.
- **[MUST]** Do not fix a flaky test simply by increasing an arbitrary wall-clock sleep.

## RNG and probability

- **[MUST]** Tests that assert concrete random outcomes use an explicit deterministic seed or an injected RNG.
- **[PREFER]** Use a `RandomNumberGenerator` per domain rather than uncontrolled global RNG for reproducible rules.
- **[MUST]** Use the RNG's `seed` to initialize it, and use a captured `state` only to restore a previously captured RNG state.
- **[MUST]** Do not freeze a long output sequence of the current Godot RNG as a permanent business API across versions, unless the project explicitly owns that RNG algorithm contract.
- **[MUST]** Probability tests distinguish deterministic mapping and boundary checks from statistical or property checks; finite samples need not match theoretical probabilities exactly.
- **[MUST]** Fuzz and property failures record enough of the seed and input to reproduce the case. Rerunning until green does not erase a flaky failure.

## Async

- **[MUST]** Signal and async waits have a finite timeout or an equivalent runner failure mechanism.
- **[MUST]** If a signal may emit synchronously, start observing before triggering it, or use a runner mechanism that cannot miss the event.
- **[PREFER]** After receiving a signal, assert the required payload and post-state rather than treating its receipt as proof of the entire workflow.
- **[MUST]** Threaded ResourceLoader tests wait on the official status or completion; do not guess completion with a sleep.
- **[MUST]** Do not use `load_threaded_get()` as a polling API, because it may block.
- **[MUST]** The test runner's timeout and a production or domain timeout are separate configuration with separate semantics.
