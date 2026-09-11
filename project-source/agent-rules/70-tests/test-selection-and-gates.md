# Test Selection and Gates

Choose validation by behavior/dependency impact. Focused tests are fast feedback, not automatically final evidence.

## Gate ladder

- **[MUST]** Use impact analysis, not only file extension, to select final tests.
- **[MUST]** Non-document changes run changed-artifact L0 validation plus tests covering affected behavior.
- **[MUST]** Do not declare completion after running only newly added/modified TestCase; run relevant existing affected suite as final task evidence.
- **[PREFER]** During iteration, run a direct focused test for fast feedback.
- **[MUST]** Use escalation ladder: G0 Static/File -> G1 Focused -> G2 Affected Suite -> G3 Integration/Runtime/Fresh/Export -> G4 Full Automated Suite.
- **[MUST]** Risk/impact triggers can escalate required gate; do not downgrade simply for speed.

## Impact triggers

- **[MUST]** Shared/public API, signal/event payload/timing, Resource schema/default, stable ID, enum, Command type, Autoload API, or similar contract changes validate known consumers.
- **[MUST]** Signal/Event changes validate producer and consumers; cross-scene lifecycle/wiring usually requires L2 or L3 evidence.
- **[MUST]** SceneTree lifecycle changes require real L2 SceneTree validation.
- **[MUST]** Input/UI wiring changes require corresponding real input route; no screenshot is required.
- **[PREFER]** Command/domain changes run Command/domain suites; add UI/input runtime testing only when adapter/wiring also changed.
- **[MUST]** Autoload registration/startup/public-state changes include affected suites plus fresh-process startup.
- **[MUST]** `project.godot` behavior changes include fresh target Godot process.
- **[MUST]** Import-pipeline changes include reimport/fresh-import evidence.
- **[MUST]** Data parser/schema/normalizer/generator infrastructure changes validate full managed dataset, deterministic regeneration, reload, and affected runtime consumers.
- **[MUST]** Shared base Scene/Resource default/schema changes validate representative instances/consumers.
- **[MUST]** Shared test infrastructure changes run all suites depending on it; use full suite when impact is global/uncertain.
- **[MUST]** Isolation/flaky fixes run affected tests in combination and repeatedly; use full suite when cross-suite/global contamination is plausible.
- **[MUST]** Export/packaging changes use `41-export-config` actual export/package gate.
- **[MUST]** Renderer/platform-specific behavior uses target/equivalent environment; headless does not prove renderer/window/platform semantics.

## Full-suite triggers

- **[MUST]** Default to full automated suite for shared core/domain primitives, global Event/Command infrastructure, primary Autoload core behavior, test isolation framework, base schema/serialization infrastructure, broad generator infrastructure, large cross-module refactors, known global contamination, or broad consumers that cannot be bounded confidently.
- **[MUST]** Full suite means all project automated tests, not every platform/export matrix unless those target gates are separately triggered.

## Runner/discovery

- **[MUST]** Check primary runner's official exit/result; do not infer PASS from last console line.
- **[MUST]** Do not add ignore/skip/filter exclusions to bypass current failures.
- **[MUST]** A targeted run confirms intended Suite/TestCase was discovered and executed. Zero tests is not PASS.
- **[MUST]** Test-source changes validate parse, discovery, modified tests, and relevant existing suite.
- **[MUST]** Impact analysis includes inheritance, signals/events, Resource/Scene references, registries, generated data, Autoload/global APIs, and dynamic resolution; textual grep alone is not sufficient proof.
- **[PREFER]** When exact impact is uncertain, run a slightly broader subsystem suite.

## Workflow/report

- **[MUST]** Agent-local required checks are not skipped merely because CI may run later.
- **[MUST]** Do not rerun every expensive CI matrix on every local edit when unrelated to change.
- **[MUST]** After fixing gate-discovered failure, rerun that gate plus newly affected checks.
- **[MUST]** Final reporting states tests added/updated, gates executed, results, required gates not run, and concrete residual risk.
