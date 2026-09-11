# Errors, Logs, and Diagnostics in Tests

A test is not healthy when assertions pass but unanticipated runtime errors, leaks, or diagnostics occurred.

## Unexpected diagnostics

- **[MUST]** Unanticipated GDScript/runtime/script errors are hard test failures.
- **[MUST]** Unexpected `push_error()` is a failure under project test profile.
- **[MUST]** Configure primary runner to monitor runtime/script errors rather than relying only on assertion results.
- **[MUST]** `push_warning()` follows explicit project policy; do not mechanically make every Warning hard failure.
- **[PREFER]** Ordinary tests remain warning-clean; investigate new warnings rather than reflexively suppressing them.

## Expected diagnostics

- **[MUST]** If Error/Warning is itself tested contract, declare it with scoped runner expected-diagnostic assertion rather than globally disabling monitoring.
- **[MUST]** Expected diagnostic tests also assert structured failure/result/post-state represented by diagnostic.
- **[MUST]** Do not broaden global allowlists/suppressions to make one negative test pass.
- **[PREFER]** Match stable diagnostic type/code/core message rather than entire Godot engine text, absolute path, or line number unless location text itself is contract.

## Logs and error handling

- **[MUST]** Ordinary business tests do not use stdout/log text as sole success/failure contract.
- **[REVIEW]** Direct message-text assertions are appropriate for stable developer/tool diagnostics where message quality is itself product contract.
- **[MUST]** Prefer structured Godot/test-runner error monitoring to grepping stderr for word ERROR.
- **[PREFER]** CI preserves useful full logs as diagnostic artifacts, but logs do not replace structured test result/exit status.
- **[MUST]** `push_error`/`push_warning` does not replace real failure control flow.
- **[PREFER]** Project validators/tooling expose stable diagnostic code + structured context + human message.

## Leaks and suppression

- **[MUST]** A test-owned orphan Node is an isolation failure.
- **[REVIEW]** Framework-owned baseline orphans may be explicitly understood, but do not globally disable orphan detection to hide test-created leaks.
- **[MUST]** Node orphan detection does not prove files/signals/threads/timers/resources are all cleaned.
- **[MUST]** Do not remove/downgrade valid production diagnostics merely to make runner green.
- **[MUST]** A fallback path that catches failure must test original failure recognition, allowed fallback behavior, result, and required diagnostics.
