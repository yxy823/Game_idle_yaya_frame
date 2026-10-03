# Test Selection and Gates

Choose validation by the impact on behavior and dependencies. Focused tests give fast feedback; they are not automatically final evidence. The general evidence rules in [Validation policy](../00-core/validation-policy.md) also apply.

## Gate ladder

- **[MUST]** Select final tests by impact analysis, not only by file extension.
- **[MUST]** Changes other than documentation run L0 validation of the changed artifacts plus the tests that cover the affected behavior.
- **[MUST]** Do not declare completion after running only the new or modified TestCases; run the relevant existing affected suite as final task evidence.
- **[PREFER]** During iteration, run a directly focused test for fast feedback.
- **[MUST]** Use this escalation ladder: G0 Static/File -> G1 Focused -> G2 Affected Suite -> G3 Integration/Runtime/Fresh/Export -> G4 Full Automated Suite.
- **[MUST]** Risk and impact triggers can escalate the required gate; do not downgrade it simply for speed.

## Impact triggers

- **[MUST]** Changes to a shared or public API, a signal or event payload or its timing, a Resource schema or default, a stable ID, an enum, a Command type, an Autoload API or a similar contract validate the known consumers.
- **[MUST]** Signal and event changes validate the producer and its consumers; lifecycle or wiring across scenes usually requires L2 or L3 evidence.
- **[MUST]** SceneTree lifecycle changes require real L2 SceneTree validation.
- **[MUST]** Input and UI wiring changes require the corresponding real input route; no screenshot is required.
- **[PREFER]** Command and domain changes run the Command and domain suites. Add UI or input runtime testing only when the adapter or wiring also changed.
- **[MUST]** Changes to Autoload registration, startup or public state include the affected suites plus fresh-process startup.
- **[MUST]** Behavior changes in `project.godot` include a fresh target Godot process.
- **[MUST]** Import-pipeline changes include reimport or fresh-import evidence.
- **[MUST]** Changes to data parser, schema, normalizer or generator infrastructure validate the full managed dataset, deterministic regeneration, reload and the affected runtime consumers.
- **[MUST]** Changes to the defaults or schema of a shared base Scene or Resource validate representative instances and consumers.
- **[MUST]** Changes to shared test infrastructure run all suites that depend on it; use the full suite when the impact is global or uncertain.
- **[MUST]** Fixes for isolation or flaky behavior run the affected tests together and repeatedly; use the full suite when contamination across suites or global state is plausible.
- **[MUST]** Export and packaging changes use the actual export and package gate of `41-export-config`.
- **[MUST]** Renderer- or platform-specific behavior uses the target environment or an equivalent; a headless run does not prove renderer, window or platform semantics.

## Full-suite triggers

- **[MUST]** Default to the full automated suite for changes to any of the following, or when consumers cannot be bounded confidently:
  - shared core or domain primitives;
  - global Event or Command infrastructure;
  - the core behavior of the primary Autoloads;
  - the test isolation framework;
  - base schema or serialization infrastructure;
  - broad generator infrastructure;
  - large refactors across modules;
  - known global contamination.
- **[MUST]** The full suite means all automated tests of the project, not every platform or export matrix unless those target gates are separately triggered.

## Runner and discovery

- **[MUST]** Check the official exit status or result of the primary runner; do not infer PASS from the last console line.
- **[MUST]** Do not add ignore, skip or filter exclusions to bypass current failures.
- **[MUST]** A targeted run confirms that the intended suite and TestCase were discovered and executed. A run that executes zero tests is not PASS.
- **[MUST]** Changes to test sources validate parsing, discovery, the modified tests and the relevant existing suite.
- **[MUST]** Impact analysis includes inheritance, signals and events, Resource and Scene references, registries, generated data, Autoload and global APIs, and dynamic resolution. A textual search alone is not sufficient proof.
- **[PREFER]** When the exact impact is uncertain, apply [Failure handling](../00-core/validation-policy.md#failure-handling) and run a slightly broader subsystem suite.

## Workflow and reporting

- **[MUST]** Do not skip required local checks merely because CI may run them later.
- **[MUST]** Do not rerun every expensive CI matrix on each local edit when it is unrelated to the change.
- **[MUST]** After fixing a failure that a gate found, rerun under [Failure handling](../00-core/validation-policy.md#failure-handling).
- **[MUST]** The final report also states the tests added or updated, in addition to the content required by [Completion and reporting](../00-core/completion-and-reporting.md#required-report-content).
