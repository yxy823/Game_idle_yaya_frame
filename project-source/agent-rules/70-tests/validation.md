# Test-System Validation

Use concrete test-selection rules in `test-selection-and-gates.md`.

- **[MUST]** Static validation and behavioral tests are separate evidence.
- **[MUST]** Unexpected runtime/script errors invalidate a test run even when assertions are green.
- **[MUST]** Test discovery must find and execute intended tests.
- **[MUST]** Test-owned Node/file/Input/global state is cleaned or affected run is not trustworthy.
- **[MUST]** Required waits/time/randomness are deterministic and bounded.
- **[MUST]** Production/test isolation is validated when test roots/framework, export filters, test Autoloads, or project test integration change.
- **[MUST]** v1 automated validation does not include screenshots, golden images, pixel diffs, a generic coverage percentage, or generic performance thresholds.
