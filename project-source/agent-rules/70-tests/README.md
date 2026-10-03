# 70 Test Rules

Test levels are defined by how much real Godot runtime semantics a test needs:

```text
L0 Static/File Validation
L1 Unit Test
L2 Godot Integration Test
L3 Runtime Scene Test
Manual Visual Acceptance
```

The [visual boundary](testing-strategy.md#visual-boundary) and the [coverage and performance policy](production-isolation.md#coverage-and-performance-policy) define which image and numeric gates the project does not use.

Read the documents that match the change, and combine domains when a test actually uses them.

| Document | Read when |
| --- | --- |
| `testing-strategy.md` | Selecting test levels, reviewing their distribution or applying the visual boundary |
| `gdunit4-profile.md` | Writing or running gdUnit4 tests, or changing the runner, result handling, cleanup or runner version |
| `unit-tests.md` | Writing or reviewing L1 tests, test doubles or characterization tests before a refactor |
| `integration-tests.md` | Writing or reviewing L2 tests with real Godot semantics |
| `scene-runtime-tests.md` | Writing or reviewing L3 runtime scene tests |
| `fixtures-and-isolation.md` | Creating or changing fixtures, shared or global state, test Resources or files, or cleanup |
| `time-randomness-and-async.md` | Testing time, frames, Tweens, randomness or asynchronous behavior |
| `input-and-command-testing.md` | Testing input, UI interaction or Command behavior |
| `errors-logs-and-diagnostics.md` | Running tests and assessing results, or testing expected errors, logs and their suppression |
| `production-isolation.md` | Changing test roots, exports, Autoloads, dependencies between production and test code, or generated and vendor test assets |
| `test-selection-and-gates.md` | Selecting the verification scope, or interpreting discovery and completion gates |
| `feature-test-integration.md` | Creating or changing Feature test mappings, or executing tests in the Feature workflow |

This module has no separate `validation.md`: each document above states the evidence that its own rules require.
