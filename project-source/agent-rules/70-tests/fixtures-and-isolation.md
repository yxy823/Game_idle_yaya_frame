# Fixtures and Isolation

Every test can run alone, in any order and repeatedly, without leaking mutable state.

## Fresh state

- **[MUST]** Mutable fixtures are created per test by default.
- **[PREFER]** Suite-level shared fixtures are immutable or read-only, or use a proven complete reset protocol.
- **[MUST]** Tests do not depend on declaration or runner order, or on whether another test has already run.

## Nodes and Resources

- **[MUST]** Test-created Nodes and Scenes have a clear cleanup owner. `remove_child()` does not free a Node, and `queue_free()` is deferred.
- **[MUST]** When correctness depends on completed deletion, wait for the real lifecycle condition rather than assuming that `queue_free()` is immediate.
- **[MUST]** Do not mutate a cached definition or configuration Resource loaded through the normal ResourceLoader and assume that the next test reloads a clean copy.
- **[REVIEW]** Overriding the ResourceLoader cache requires an explicit understanding of whether only the main Resource or its whole dependency graph needs isolation.

## Global state

- **[MUST]** Restore or process-isolate mutable Autoload state, `static var` values, registries, caches, the InputMap, ProjectSettings, the Engine time scale, pause state and similar process-global state.
- **[MUST]** Do not create arbitrary reflection or reset backdoors in production code solely for tests.
- **[MUST]** If the chosen runner provides a verified snapshot and restore guarantee for a global facility, the project may rely on it; otherwise, take the snapshot and restore it explicitly.
- **[MUST]** Persisting test changes into the production `project.godot` is governed by [Autoload and ProjectSettings](production-isolation.md#autoload-and-projectsettings).

## Files and signals

- **[MUST]** Tests that write to `user://` use a test-owned namespace and never recursively clear the real `user://` directory.
- **[MUST]** Tests clean only the paths and files they own.
- **[MUST]** Signal, subscription and observer registrations that outlive a TestCase are restored or disconnected.

## Input, async, and RNG cleanup

- **[MUST]** Release every injected pressed Input action, even when assertions fail. Use teardown or owned helpers rather than only the normal success path.
- **[MUST]** A TestCase ends without uncontrolled Timer or async work that could later mutate another test's state.
- **[MUST]** Critical cleanup lives in runner teardown or ownership paths that execute after an assertion failure.
- **[MUST]** If critical cleanup cannot restore a trustworthy baseline, fail or abort the affected test or suite rather than continuing with greens that only look trustworthy.
- **[PREFER]** Use the runner's orphan and leak diagnostics for scene-heavy suites, but do not claim that Node orphan detection proves that every file, thread, signal and Resource is cleaned.
