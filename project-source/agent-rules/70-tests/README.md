# 70 Test Rules

Testing levels are defined by how much real Godot runtime semantics are needed:

```text
L0 Static/File Validation
L1 Unit Test
L2 Godot Integration Test
L3 Runtime Scene Test
Manual Visual Acceptance
```

v1 intentionally does **not** create `visual-regression.md`, screenshot golden baselines, pixel-diff tolerance, coverage-percentage gates, or generic performance thresholds.

Read the matching sections below; combine domains when the test actually uses them.

| Document | Read when |
| --- | --- |
| `testing-strategy.md` | Selecting test levels or reviewing their distribution and visual boundary |
| `gdunit4-profile.md` | Authoring/running gdunit4 tests or changing its runner, result handling, cleanup or version |
| `unit-tests.md` | Writing or reviewing L1 tests, doubles or refactor characterization |
| `integration-tests.md` | Writing or reviewing L2 tests with real Godot semantics |
| `scene-runtime-tests.md` | Writing or reviewing L3 runtime scene tests |
| `fixtures-and-isolation.md` | Creating or changing fixtures, shared/global state, resources, files or cleanup |
| `time-randomness-and-async.md` | Testing time, frames, tweens, randomness or asynchronous behavior |
| `input-and-command-testing.md` | Testing input, UI interaction or command behavior |
| `errors-logs-and-diagnostics.md` | Running tests and assessing results, or testing expected errors/logs and suppression |
| `production-isolation.md` | Changing test roots, exports, autoloads, production/test dependencies or generated/vendor test assets |
| `test-selection-and-gates.md` | Selecting verification scope or interpreting discovery and completion gates |
| `feature-test-integration.md` | Creating/changing Feature test mappings or executing tests in the Feature workflow |
| `validation.md` | Any test-system change: determine its applicable validation |
