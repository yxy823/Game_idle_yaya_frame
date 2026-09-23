# Test / Production Isolation

Development tests remain loadable by Godot while production export remains independent of all test-only code and state.

## Test roots and export

- **[MUST]** Do not put `.gdignore` in active test root/ancestor merely to exclude tests from production; runner/Godot must still load test fixtures.
- **[MUST]** Production export has explicit exclusion policy for test roots, test fixtures, test-only generated artifacts, and test framework/editor addon.
- **[MUST]** Production code/resources/configuration do not depend on test root or test-framework implementation.
- **[MUST]** Production startup/export must succeed when test runtime is completely absent.

## Autoload/ProjectSettings

- **[MUST]** Test-only/editor-only Autoloads do not become production runtime dependencies.
- **[MUST]** Excluding addon files from export does not remove persisted Autoload entry; plugin-owned test Autoloads need symmetric unregister/export stripping.
- **[MUST]** Ordinary tests do not permanently add test-only InputMap/Group/ShaderGlobal/ProjectSettings/MainScene state to production `project.godot`.

## Generated files and vendor

- **[PREFER]** Test-created mutable files go to test-owned `user://`/temporary paths.
- **[MUST]** Tests that must write `res://` use test-owned scratch subtree or isolated fixture project, not production asset/data directories.
- **[MUST]** Clean only test-owned scratch/import/UID artifacts.
- **[MUST]** Third-party test frameworks are vendor dependencies; do not modify implementation for project style/lint/test convenience.
- **[MUST]** Project-owned test GDScript still follows applicable project GDScript/static rules; framework-specific exceptions are scoped, not blanket lint exemptions.

## Coverage/visual/performance policy

- **[MUST]** v1 has no project-wide coverage-percentage gate. Coverage may be auxiliary evidence but never substitutes for behavioral assertions/integration/runtime tests.
- **[MUST]** v1 has no generic performance threshold without project-specific budget/target hardware contract.
- Visual evidence and acceptance follow the [visual boundary](testing-strategy.md#visual-boundary).
