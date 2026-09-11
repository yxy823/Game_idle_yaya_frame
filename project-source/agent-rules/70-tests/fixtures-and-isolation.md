# Fixtures and Isolation

Every test should be runnable alone, in arbitrary order, repeatedly, without leaking mutable state.

## Fresh state

- **[MUST]** Mutable fixtures are per-test by default.
- **[PREFER]** Suite-level shared fixtures are immutable/read-only or use a proven complete reset protocol.
- **[MUST]** Tests do not depend on declaration/runner order or another test already/not-yet running.

## Nodes/resources

- **[MUST]** Test-created Nodes/Scenes have clear cleanup owner. `remove_child()` is not free; `queue_free()` is deferred.
- **[MUST]** When correctness depends on deletion completion, wait for real lifecycle condition rather than assuming `queue_free()` is immediate.
- **[MUST]** Do not mutate cached Definition/Config Resource loaded through normal ResourceLoader and assume next test reloads clean copy.
- **[REVIEW]** ResourceLoader cache overrides require explicit understanding of whether only main Resource or dependency graph needs isolation.

## Global state

- **[MUST]** Autoload mutable state, `static var`, registries, caches, InputMap, ProjectSettings, Engine time scale, pause, and similar process-global state must be restored or process-isolated.
- **[MUST]** Do not create arbitrary reflection/reset backdoors in production solely for tests.
- **[MUST]** If chosen runner provides verified snapshot/restore guarantee for a global facility, project may rely on it; otherwise snapshot/restore explicitly.
- **[MUST]** Ordinary tests do not persist ProjectSettings changes back into production `project.godot`.

## Files and signals

- **[MUST]** Tests writing `user://` use a test-owned namespace and never recursively clear real entire `user://`.
- **[MUST]** Tests clean only paths/files they own.
- **[MUST]** Signal/subscription/observer registrations crossing TestCase lifetime are restored/disconnected.

## Input/async/RNG cleanup

- **[MUST]** Every injected pressed Input action is released even when assertions fail; use teardown/owned helpers rather than only normal success path.
- **[MUST]** A TestCase ends without uncontrolled Timer/async work that can later mutate another test's state.
- **[MUST]** Critical cleanup lives in runner teardown/ownership paths that execute after assertion failure.
- **[MUST]** If critical cleanup cannot restore trustworthy baseline, fail/abort affected test/suite rather than continuing with trustworthy-looking greens.
- **[PREFER]** Use runner orphan/leak diagnostics for scene-heavy suites, but do not claim Node orphan detection proves every file/thread/signal/resource is cleaned.
