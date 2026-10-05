# Yaya integration patch: source-contracts-v1

The upstream dependency is **graydwarf/godot-gdscript-linter v3.3.0**, revision `aeeae7d9af260f5e17f7c95ab5e77790d48e46e2`. Its original MIT license and attribution remain in `LICENSE`. `plugin.cfg` reports the upstream version; this document identifies the additional Yaya-maintained patch, not a new upstream release.

On 2026-09-10 the [upstream release list](https://github.com/graydwarf/godot-gdscript-linter/releases) still listed v3.3.0 as latest, and its main-branch function checker still recognized only lines beginning with `func `. A released upgrade did not address these defects.

Yaya owns `analyzer/source-map.gd` and the integration edits in `analysis-config.gd`, `analysis-result.gd`, `file-result.gd`, `code-analyzer.gd`, `analyze-cli.gd`, `strict-handler.gd`, `ignore-handler.gd`, `checkers/function-checker.gd`, `checkers/unused-checker.gd`, and `checkers/style-checker.gd` under `analyzer/`, plus `dock.gd`, `dock.tscn`, `ui/settings-manager.gd`, `ui/settings-card-builder.gd`, and the local contract corrections in `docs/CLI.md`. Icons, third-party licenses, and unrelated checker implementations are not patched.

`dock.tscn` references `icons/settings.svg` by its existing path without an external-resource UID: the upstream UID has no definition in the distributed files. The icon itself and the scene's resource ID remain unchanged.

The patch shares lexical function boundaries across normal/static/private methods, multiline signatures, metrics, strict/ignore ranges, and unused-name scope. It distinguishes code and physical lines, excludes phantom EOF lines, and exports function metrics. CLI file/directory inputs are deduplicated; invalid/empty discovery fails with exit 3. JSON output can be written to a supplied output path. Filters change display only and cannot turn an existing failure into exit 0. CLI help documents this verdict behavior, exit 3 for invalid/empty input, configuration or JSON output errors, and the JSON/HTML output-path option.

The r1 engine-interface metric treatment covers only a top-level, non-static `_log_error` in a script directly extending `Logger`, with eight explicitly typed parameters and `-> void` matching the running Godot 4.7 `ClassDB` virtual method. Godot 4.7.1 official `a13da4feb` exposes the types `String, String, int, String, String, bool, int, Array[ScriptBacktrace]`, no default arguments, and a void return. The report keeps the real `params: 8`, adds its `parameter_contract` provenance, and emits `engine-parameter-contract` Info when the project arity limit is lower. Only that parameter-count limit is inapplicable to the fixed engine interface; body length, nesting, complexity and other checks remain active. Unresolved or indirect inheritance, inner classes, static methods, other names and mismatched types/return signatures retain ordinary arity checks. No filename exemption, ignore directive, callback signature edit or global threshold change is used. Recheck this narrow treatment when the target engine's interface changes.

## Magic-number correction (2026-09-12)

The pinned upstream style checker can match the trailing `56` in `get_sha256`: its left boundary excludes letters/underscore but not a preceding digit. It also scans string contents and only attempts to ignore a number immediately following a double quote. This produces false Info diagnostics for identifiers and text such as `"invocation_sha256"`.

Changed files:
- `analyzer/code-analyzer.gd`: reuse the existing SourceMap lexical code lines for both line metrics and the style checker.
- `analyzer/checkers/style-checker.gd`: scan lexed code for magic numbers and exclude preceding digits at the identifier boundary; remove the inadequate immediate-quote workaround.

The existing lexer masks single/double/triple-quoted strings, escapes and comments. No SHA-specific exemption, disabled rule, allowlist expansion or severity change is introduced. Actual decimal literals (including negative/fractional values) still produce diagnostics with their original value and line. Existing constant, enum/export and allowed-number handling stays unchanged. This remains a lexical check, not a complete Godot parser or a proof that every number needs a constant.

Regression cases cover numeric suffixes in names, quoted and multiline text, comments, allowed values, real numeric literals, and the existing Logger/metric contracts. Run engine-dependent contracts in an external validation project using the configured Godot. A Python fixture alone does not establish runtime behavior. Direct project checks are described in `yaya/methodology/contracts/gdscript-lint.md`; there is no separate static wrapper or static manifest.

## Configuration and editor consistency (2026-09-22)

The CLI requires the default project `gdlint.json` or the explicit `--config` file to load successfully. Missing/unreadable files fail with exit 3, as existing JSON/metric configuration errors do. Other callers retain the generic loader's optional-file behavior. Unknown `--check` IDs are rejected before changing any check switches, including mixed valid/invalid lists. `--help` exits without loading a project configuration or starting analysis.

The dock reads analysis thresholds, checks and scan scope from the project config, ignoring old machine-level analysis overrides. `EditorSettings` continues to hold personal display/export/filter/Claude preferences. Applying settings to controls does not emit change signals, and rebuilding the dock keeps its settings manager and analyzer on the same newly loaded config. Only explicit analysis-setting changes save `gdlint.json`; they do not write global analysis overrides. The existing panel header and CLI note identify that project-config write behavior.

Config saving retains all supported analysis fields, including metrics and fields without dock controls, and preserves unknown fields in an existing JSON object. Invalid loaded configurations and unreadable/non-object destination configs are not overwritten. CLI documentation now covers single-file inputs, direct JSON output, Info-only success, failure exit 3 and display-filter verdict preservation.

## Updating upstream

Compare the pinned upstream base, these local changes, and the proposed new upstream version. Preserve licensing and inspect each listed changed file. If upstream fixes the same defect, use its implementation after the same positive/negative regressions pass and remove the redundant local patch. If the defect remains, carry only the still-needed change; if upstream APIs or lexing change, review the integration rather than overwriting or blindly applying old edits. Update this file with the new base and retained changes. Do not add a patch manager, upgrade state machine, or compatibility layer.
