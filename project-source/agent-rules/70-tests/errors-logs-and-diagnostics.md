# Errors, Logs, and Diagnostics in Tests

A test is not healthy when its assertions pass but unanticipated runtime errors, leaks or diagnostics occurred.

## Unexpected diagnostics

- **[MUST]** Unanticipated GDScript, runtime and script errors are hard test failures.
- **[MUST]** An unexpected `push_error()` is a failure under the project's test profile.
- **[MUST]** Configure the primary runner to monitor runtime and script errors rather than relying only on assertion results.
- **[MUST]** `push_warning()` follows explicit project policy; do not mechanically make every Warning a hard failure.
- **[PREFER]** Keep ordinary tests free of warnings, and investigate new warnings rather than reflexively suppressing them.

## Expected diagnostics

- **[MUST]** If an Error or Warning is itself the tested contract, declare it with the runner's scoped expected-diagnostic assertion rather than globally disabling monitoring.
- **[MUST]** Expected-diagnostic tests also assert the structured failure, result or post-state that the diagnostic represents.
- **[MUST]** Do not broaden global allowlists or suppressions to make one negative test pass.
- **[PREFER]** Match a stable diagnostic type, code or core message rather than the entire Godot engine text, an absolute path or a line number, unless the location text itself is the contract.

## Logs and error handling

- **[MUST]** Ordinary business tests do not use stdout or log text as their only success or failure contract.
- **[REVIEW]** Direct assertions on message text are appropriate for stable developer and tool diagnostics where the message quality is itself part of the product contract.
- **[MUST]** Prefer structured error monitoring by Godot and the test runner to searching stderr for the word ERROR.
- **[PREFER]** CI keeps useful full logs as diagnostic artifacts, but logs do not replace a structured test result or exit status.
- **[MUST]** `push_error()` and `push_warning()` do not replace real failure control flow.
- **[PREFER]** Project validators and tooling expose a stable diagnostic code, structured context and a human-readable message.

## Leaks and suppression

- **[MUST]** An orphan Node owned by a test is an isolation failure.
- **[REVIEW]** Baseline orphans owned by the framework may be explicitly understood, but do not globally disable orphan detection to hide leaks that tests create.
- **[MUST]** Node orphan detection does not prove that files, signals, threads, timers and Resources are all cleaned.
- **[MUST]** Do not remove or downgrade valid production diagnostics merely to make the runner green.
- **[MUST]** A fallback path that catches a failure is tested for recognizing the original failure, the allowed fallback behavior, the result and the required diagnostics.
