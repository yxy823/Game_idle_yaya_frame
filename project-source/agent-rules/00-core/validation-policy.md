# Validation Policy

Defines evidence rules shared by all specialized validation modules.

## Evidence composition

- **[MUST]** Every changed artifact and affected behavior satisfies every applicable validation route. The requirements of several modules add together.
- **[MUST]** Include the relevant tests and the project's supported lint, parsing and type checks when they apply to the changed artifacts. Use the configured entrypoints. Do not invent an unsupported checker or install a new toolchain solely to fill a generic checklist.
- **[MUST]** A higher-level PASS does not override a lower-level failure.
- **[MUST]** A gate is PASS only if the applicable check was actually executed and completed successfully.
- **[MUST]** Do not substitute one validation class for another unless project rules explicitly define that check as equivalent for the affected contract.
- **[PREFER]** Use repository-provided validation scripts and entrypoints when they encode the supported workflow, instead of rebuilding an ad-hoc alternative.
- **[MUST]** A validation wrapper preserves the failure semantics of the checks it runs; a wrapper exit code of 0 cannot erase a known underlying failure.
- **[PREFER]** Use the tool's supported exit status or structured result instead of guessing from console text.

## Failure handling

- **[MUST]** Do not obtain a green status by weakening lint thresholds, expanding ignores, skipping failing tests, disabling error monitoring, lowering schema severity, removing gates or rewriting rules.
- **[MUST]** Treat a validation failure as evidence that requires classification. Do not assume that the checker is wrong merely because it blocks completion.
- **[MUST]** After fixing a gate failure, rerun that gate and any additional checks that the fix makes necessary.
- **[MUST]** Run all validation routes that apply to the change, not every imaginable expensive gate.
- **[PREFER]** When the material impact scope is uncertain, choose a slightly broader relevant validation scope rather than claiming an unjustifiably precise minimum.

## Environment and reporting

- **[MUST]** Environment-specific evidence proves only the environment semantics that it actually exercises.
- **[MUST]** When a specialized rule requires fresh evidence from a new process, import, export or target runtime, an existing editor or session result is not a substitute.
- **[MUST]** If an applicable required gate cannot run, report it as not executed or blocked, with the reason and the unresolved risk. Never assume PASS.
- **[MUST]** Manual acceptance and automated validation are distinct evidence types. Do not report one as the other.
- **[MUST]** Validation artifacts such as logs, JUnit reports and temporary exports follow the generated and temporary file ownership rules. They must not silently become production source.

## Windows editor checks

These rules apply only to Godot editor checks on the local Windows machine inside the Codex restricted sandbox. On another machine, first check the actual permissions and directory behavior. They do not require launching the editor for every Feature.

- **[MUST]** Run editor checks, including `--headless --editor`, outside the sandbox through the `require_escalated` approval path. If approval is denied or unavailable, report the check as not executed or blocked; do not bypass approval.
- **[MUST]** When the output contains `Could not create editor data directory` or `Could not create editor config directory`, or access to `AppData/Roaming/Godot` fails, investigate the environment permissions. Stop later validation that depends on that run's success. Do not report a pass, and do not change business code or weaken gates because of it.
- **[MUST]** Before and after an editor check, compare the listing of the project root, including empty directories that Git does not track. When unexpected directories such as `export_templates`, `feature_profiles`, `script_templates` or `text_editor_themes` appear, check their origin first. Apply the [temporary-file rules](third-party-generated-and-temporary-files.md#temporary-backup-and-scratch) only to empty directories confirmed as created by this run, and keep pre-existing directories with the same name.
