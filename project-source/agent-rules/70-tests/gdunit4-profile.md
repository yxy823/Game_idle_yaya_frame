# GdUnit4 Runner Profile

This file records behavior specific to the primary runner configured in
`docs/methodology-config.json`. That configuration remains the authority for
the installed runner version and executable commands.

## Project-owned launch and process protection

The wrapper invokes the configured Godot executable directly:

```text
<godot> --path <project> --debug --ignore-error-breaks --script res://tools/testing/gdunit_evidence_runner.gd -rd <unique-run-directory> -a <target> [-c]
```

Godot options precede the script path. This launch does not use the vendor
batch launcher, `--remote-debug`, or a default `--headless` switch. Existing
wrapper target, continue, and required-test selectors remain unchanged.

`--timeout-seconds` configures a finite positive wall-time limit (default 120
seconds). Standard input is closed; stdout and stderr share one ordered log.
The project-owned process guard confines timeout termination to this invocation
and its descendants, including the Windows console launcher's engine child.

Each invocation retains one `result.json` plus the original engine log,
discovery, JUnit and diagnostic reports under `reports/gdunit-wrapper/run-*`. Missing, ambiguous, or stale JUnit cannot satisfy a run.

## Discovery and verdict

- **[MUST]** A GDScript test suite extends `GdUnitTestSuite`, and each discovered
  test case uses the `test_` prefix required by the runner.
- **[MUST]** Focused execution confirms through the project test verdict wrapper
  that the required suite and test case were discovered and executed. A runner
  exit code alone does not prove this contract.
- **[MUST]** Project test commands use the configured lookup root under `tests/`
  and the project-owned verdict wrapper from the methodology command authority.
- **[MUST]** The current runner profile monitors script errors, unexpected
  `push_error()`, unexpected `push_warning()`, orphans, and flaky results. Zero
  executed tests is not a passing verdict.
- **[MUST]** Because the current pinned runner's push-error monitor also captures
  warnings, expected errors or warnings use a scoped GdUnit
  expected-diagnostic assertion; await only when that assertion is a coroutine.
  Do not disable monitoring globally.

For the pinned runner, `STARTED` precedes `before_test()`, and the following
monitor start clears that hook's diagnostics. Suite `after()` and exit cleanup
also lack reliable JUnit diagnostic coverage. The wrapper therefore recognizes
native Godot header/message/source-location records throughout the lifecycle;
test banners never disable diagnostic checks. This is not a search for error
words in arbitrary output.

The project-owned `tools/testing/gdunit_diagnostic_session.gd` session hook records
diagnostics and positively matched scoped assertions in the current report's
`diagnostics.jsonl`. It observes public execution contexts, signals and monitor
entries without modifying vendor state. Individual diagnostic IDs and source
records bind exemptions to this run; an additional unmatched occurrence still
fails. Missing, incomplete or mismatched evidence fails closed. Native records
before hook startup and after hook shutdown remain subject to the same check.
JUnit, nonzero process exit and timeout remain independent failure sources. In
particular, this pinned JUnit writer omits orphan records, while the runner's
orphan exit code 101 still makes the wrapper fail.

## Coroutine assertions

- **[MUST]** Await GdUnit coroutine assertions. In particular,
  `assert_signal(...).is_emitted(...)` and `is_not_emitted(...)` require
  `await`; omitting it can silently bypass the assertion.
- **[MUST]** Coroutine assertions also follow the bounded-wait and observer-order
  rules in `time-randomness-and-async.md`.

## Cleanup and ProjectSettings

- **[PREFER]** Register test-owned objects with `auto_free()` or perform explicit
  teardown that completes before the test boundary.
- **[MUST]** For the current pinned runner's pending-`queue_free()` orphan
  false-positive, wait for the real idle/deletion condition when needed. Do not
  disable orphan detection as a workaround.
- **[MUST]** Treat the current runner's `ProjectSettings` snapshot as reliable
  only for restoring the value of a key that existed at snapshot time and still
  exists at restore time.
- **[MUST]** Tests that add or delete a `ProjectSettings` key use explicit cleanup
  or process isolation; they do not assume the runner snapshot will restore the
  key set.
- **[MUST]** Ordinary tests do not call `ProjectSettings.save()`. A test that
  exercises persistence requires an explicitly isolated process and cleanup
  contract.

## Version changes

- **[MUST]** Revalidate discovery, diagnostic monitoring, report fields,
  coroutine behavior, orphan handling, and `ProjectSettings` restoration when
  the configured runner version changes. Remove version-specific workarounds
  only after that verification.
