# Time, Randomness, and Async Testing

Tests must control same clock/RNG/async semantics production behavior actually uses.

## Time domains

- **[MUST]** Declare whether behavior uses scaled gameplay time, physics time, unscaled monotonic elapsed time, or wall-clock/calendar time. These are not interchangeable.
- **[MUST]** Elapsed-time tests do not accidentally hard-code render FPS unless frame count itself is contract.
- **[MUST]** Physics behavior uses real physics-tick path; do not change physics tick rate as normal test acceleration trick.
- **[MUST]** Timer/SceneTreeTimer tests cover process domain, pause behavior, time-scale behavior, and timeout result when those are contract.
- **[MUST]** Pause and `Engine.time_scale` are separate test dimensions.
- **[MUST]** Duration/timeout correctness does not use adjustable wall clock; calendar/date behavior does not use monotonic ticks.
- **[PREFER]** Use injected/controlled clocks, runner frame/time simulation, or controlled Timers instead of waiting real seconds.

## Tween/frame synchronization

- **[MUST]** Tween tests advance controlled time/frames and assert state/completion; do not sleep for Tween to finish.
- **[PREFER]** Only assert Tween intermediate values when they are business contract and use appropriate float tolerance.
- **[MUST]** Fixed `await N frames` needs lifecycle/process reason; do not use magic 'two-frame' synchronization ritual.
- **[MUST]** Do not fix flaky test by simply increasing arbitrary wall-clock sleep.

## RNG and probability

- **[MUST]** Tests asserting concrete random outcomes use explicit deterministic seed or injected RNG.
- **[PREFER]** Use per-domain `RandomNumberGenerator` rather than uncontrolled global RNG for reproducible rules.
- **[MUST]** Use RNG `seed` to initialize; use captured `state` only to restore previously captured RNG state.
- **[MUST]** Do not freeze current Godot RNG long output sequence as forever cross-version business API unless project explicitly owns that RNG algorithm contract.
- **[MUST]** Probability tests distinguish deterministic mapping/boundary checks from statistical/property checks; finite samples need not equal theoretical probabilities exactly.
- **[MUST]** Fuzz/property failures record enough seed/input to reproduce case; rerunning until green does not erase flaky failure.

## Async

- **[MUST]** Signal/async waits have finite timeout or equivalent runner failure mechanism.
- **[MUST]** If signal may emit synchronously, establish observation before triggering or use runner mechanism that cannot miss event.
- **[PREFER]** After receiving signal, assert required payload/post-state rather than treating receipt as proof of entire workflow.
- **[MUST]** Threaded ResourceLoader tests wait on official status/completion; do not guess completion with sleep.
- **[MUST]** `load_threaded_get()` is not used as polling API because it may block.
- **[MUST]** Test-runner timeout and production/domain timeout are separate configuration/semantics.
