# 70 Test Rules

Testing levels are defined by how much real Godot runtime semantics are needed:

```text
L0 Static/File Validation
L1 Unit Test
L2 Godot Integration Test
L3 Runtime Scene Test
Manual Visual Acceptance
```

v1 intentionally does **not** create `visual-regression.md`, screenshot golden
baselines, pixel-diff tolerance, coverage-percentage gates, or generic
performance thresholds.

Read:

- `testing-strategy.md`
- `gdunit4-profile.md`
- `unit-tests.md`
- `integration-tests.md`
- `scene-runtime-tests.md`
- `fixtures-and-isolation.md`
- `time-randomness-and-async.md`
- `input-and-command-testing.md`
- `errors-logs-and-diagnostics.md`
- `production-isolation.md`
- `test-selection-and-gates.md`
- `feature-test-integration.md`
- `validation.md`
