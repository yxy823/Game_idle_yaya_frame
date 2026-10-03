# GdUnit4 Runner Profile

This file records the behavior of the project's fixed gdUnit4 runner that matters when writing and running tests. `docs/methodology-config.json` supplies the Godot executable and its observed version. Test selection, run records and completion evidence are defined in [methodology 08](../../methodology/08-test-traceability-and-evidence.md).

## Launch and process limits

The project-owned wrapper invokes the configured Godot executable directly:

```text
<godot> --path <project> --debug --ignore-error-breaks --script res://tools/testing/gdunit_evidence_runner.gd -rd <unique-run-directory> -a <target> [-c]
```

Godot options precede the script path. This launch does not use the vendor batch launcher, `--remote-debug` or a default `--headless` switch.

- Each run has a finite wall-time limit, set with `--timeout-seconds` (120 seconds by default). A test that waits longer fails the run.
- Standard input is closed, so tests cannot wait for console input.
- stdout and stderr are written to one ordered log.
- Each run keeps its engine log, discovery, JUnit and diagnostic reports in its own directory under `reports/gdunit-wrapper/`. Read them there when diagnosing a failure. Missing, ambiguous or stale JUnit cannot satisfy a run. The layout of run directories, `result.json` and the process and timeout handling are described in [Artifact-backed completion](../../methodology/08-test-traceability-and-evidence.md#artifact-backed-completion-and-semantic-freshness).

## Discovery and verdict

- **[MUST]** A GDScript test suite extends `GdUnitTestSuite`, and each test case uses the `test_` prefix that the runner requires for discovery.
- **[MUST]** Focused execution confirms through the project's verdict wrapper that the required suite and test case were discovered and executed. A runner exit code alone does not prove this.
- **[MUST]** Project test commands use the configured lookup root under `tests/` and the project-owned wrapper `tools/testing/run-gdunit-tests.py`, invoked as described in [Runtime Test Impact selection](../../methodology/08-test-traceability-and-evidence.md#runtime-test-impact-selection).
- **[MUST]** The current runner profile monitors script errors, unexpected `push_error()`, unexpected `push_warning()`, orphans and flaky results. A run that executes zero tests is not PASS, as defined in [Runner and discovery](test-selection-and-gates.md#runner-and-discovery).
- **[MUST]** The push-error monitor of the pinned runner also captures warnings. Declare expected errors or warnings with a scoped GdUnit expected-diagnostic assertion, and `await` it only when that assertion is a coroutine. Do not disable monitoring globally.

### Diagnostics outside test bodies

In the pinned runner, `STARTED` precedes `before_test()`, and the monitor start that follows clears the diagnostics of that hook. Suite `after()` and exit cleanup also lack reliable JUnit diagnostic coverage. The wrapper therefore recognizes native Godot header, message and source-location records throughout the lifecycle, and test banners never disable these checks. This is not a search for error words in arbitrary output.

- The project-owned session hook `tools/testing/gdunit_diagnostic_session.gd` records diagnostics and positively matched scoped assertions in the current report's `diagnostics.jsonl`. It observes public execution contexts, signals and monitor entries without modifying vendor state.
- Individual diagnostic IDs and source records bind each exemption to this run. An additional unmatched occurrence still fails.
- Missing, incomplete or mismatched diagnostic evidence fails closed. Native records before the hook starts and after it shuts down are subject to the same check.
- JUnit, a nonzero process exit and a timeout remain independent failure sources. The pinned JUnit writer omits orphan records, but the runner's orphan exit code 101 still makes the wrapper fail.

## Coroutine assertions

- **[MUST]** Await GdUnit coroutine assertions. In particular, `assert_signal(...).is_emitted(...)` and `is_not_emitted(...)` require `await`; omitting it can silently bypass the assertion.
- **[MUST]** Coroutine assertions also follow the bounded-wait and observer-order rules in `time-randomness-and-async.md`.

## Cleanup and ProjectSettings

- **[PREFER]** Register test-owned objects with `auto_free()`, or perform explicit teardown that completes before the test boundary.
- **[MUST]** The pinned runner reports a false-positive orphan for a pending `queue_free()`. Wait for the real idle or deletion condition when needed; do not disable orphan detection as a workaround.
- **[MUST]** Treat the runner's `ProjectSettings` snapshot as reliable only for restoring the value of a key that existed when the snapshot was taken and still exists at restore time.
- **[MUST]** Tests that add or delete a `ProjectSettings` key use explicit cleanup or process isolation; they do not rely on the runner snapshot to restore the set of keys.
- **[MUST]** A test that exercises persistence through `ProjectSettings.save()` runs in an explicitly isolated process with its own cleanup contract. Other tests follow the [Autoload and ProjectSettings rules](production-isolation.md#autoload-and-projectsettings).

## Runner version changes

- **[MUST]** When the configured runner version changes, revalidate discovery, diagnostic monitoring, report fields, coroutine behavior, orphan handling and `ProjectSettings` restoration. Remove version-specific workarounds only after that verification.
