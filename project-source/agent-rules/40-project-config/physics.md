# Physics Configuration

Physics tick rate, interpolation, backend, and threading are whole-project simulation settings.

## Physics

- **[REVIEW]** `physics_ticks_per_second` is a whole-project timing/simulation change; do not modify it as a test speed hack.
- **[REVIEW]** Changing `physics_ticks_per_second` can change damping and gameplay feel; evaluate those effects instead of treating the change as pure precision or performance tuning.
- **[MUST]** When substantially increasing the physics tick rate, check `max_physics_steps_per_frame` under low rendering FPS so the simulation does not fall behind or slow down.
- **[REVIEW]** Evaluate physics interpolation together with the display refresh rate and render cadence for jitter at nonstandard tick rates.
- **[MUST]** Physics interpolation is a global simulation/rendering contract; validate movement/camera/physics consumers when changed.
- **[REVIEW]** Physics backend changes are migration-level behavior changes. Pin/validate backend when project correctness depends on backend-specific behavior.
- **[REVIEW]** Running physics on a separate thread changes API/threading constraints and requires review of crossing code.
