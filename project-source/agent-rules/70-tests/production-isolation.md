# Test and Production Isolation

Development tests remain loadable by Godot, while the production export stays independent of all test-only code and state.

## Test roots and export

- **[MUST]** Do not put `.gdignore` in an active test root or one of its ancestors merely to exclude tests from production; the runner and Godot must still load test fixtures.
- **[MUST]** The production export has an explicit exclusion policy for test roots, test fixtures, test-only generated artifacts and the test framework's editor addon.
- **[MUST]** Production code, Resources and configuration do not depend on a test root or on the test framework's implementation.
- **[MUST]** Production startup and export succeed when the test runtime is completely absent.
- **[MUST]** When test roots, the test framework, export filters, test Autoloads or the project's test integration change, validate the isolation rules in this document.

## Autoload and ProjectSettings

- **[MUST]** Test-only and editor-only Autoloads do not become production runtime dependencies. Plugin-owned test Autoloads follow the cleanup and export rules in [Editor plugins](../40-project-config/editor-plugins.md#plugins).
- **[MUST]** Ordinary tests do not permanently add test-only Input Map entries, groups, shader globals, ProjectSettings or main-scene settings to the production `project.godot`.

## Generated files and vendor code

- **[PREFER]** Tests write the mutable files they create to test-owned `user://` or temporary paths.
- **[MUST]** Tests that must write under `res://` use a test-owned scratch subtree or an isolated fixture project, not production asset or data directories.
- **[MUST]** Clean only scratch, import and UID artifacts that the tests own.
- **[MUST]** Third-party test frameworks are vendor dependencies; do not modify their implementation for project style, lint or test convenience.
- **[MUST]** Project-owned test GDScript still follows the applicable project GDScript and static-check rules. Framework-specific exceptions are scoped, not blanket lint exemptions.

## Coverage and performance policy

- **[MUST]** The project has no project-wide coverage-percentage gate. Coverage may serve as auxiliary evidence but never substitutes for behavioral assertions, integration tests or runtime tests.
- **[MUST]** The project has no generic performance threshold without a project-specific budget and target-hardware contract.

Visual evidence and acceptance follow the [visual boundary](testing-strategy.md#visual-boundary).
