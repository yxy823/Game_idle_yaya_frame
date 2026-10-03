# GDScript lint contracts and evidence

The Godot parser and the bundled linter check different things. The parser decides whether a script compiles on the target Godot version. The linter reports style and size signals under the project's `gdlint.json`. The Agent runs both directly; there is no wrapper script.

This page explains how the Agent reads their results. The linter's patched behavior and implementation details are recorded in [YAYA_PATCH.md](../../addons/gdscript-linter/YAYA_PATCH.md).

Before running a Godot editor or import check, follow [Windows editor checks](../../agent-rules/00-core/validation-policy.md#windows-editor-checks).

## Direct execution

Use the Godot executable recorded in `docs/methodology-config.json` and run from the project directory:

```powershell
# $godot is the configured executable path; run from the project directory.
& $godot --headless --path . --check-only --script res://path/to/changed_script.gd | Out-Host
$LASTEXITCODE
# Replace F001 with the actual Feature; use an unused run subdirectory if needed.
$reportDirectory = 'reports/features/F001'
New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
& $godot --headless --path . --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --json --output "$reportDirectory/lint.json" res:// | Out-Host
$LASTEXITCODE
```

- With the Windows GUI executable, the PowerShell pipeline waits for the process. Read `$LASTEXITCODE` immediately; an empty exit value is not a successful check.
- Parse the changed project scripts and the scripts that depend on them, according to the actual impact.
- Run the lint CLI on the full `res://` scope, which respects `gdlint.json`. Dependency exclusions in that file do not waive checks when the task itself changes that dependency.
- For work without a Feature, use `reports/maintenance/<task>/`. Saved parse output goes to the same task directory, not scratch. Choose paths and keep originals under [Reports and cleanup](../09-records-reports-and-handoff.md#reports-and-cleanup).

## Lint exit codes

| Exit code | Meaning |
| --- | --- |
| 0 | Clean, or Info findings only |
| 1 | Warning findings |
| 2 | Critical findings |
| 3 | Invalid or empty input, a missing or unreadable configuration file, an unknown `--check` ID, or a JSON output error |

Exit 3 never becomes a successful run with a fallback policy or disabled checks. Display filters cannot change the verdict.

## Reading the results

Check each command's exit code and original output immediately.

- Keep failures. Do not overwrite a report still needed for an unresolved task; use a distinct filename or run subdirectory to keep an earlier run.
- Report the actual checked scope, the Critical, Warning and Info counts, and any checks not run. An unknown count is not zero.
- An unresolved required parse or lint failure blocks completion, even when the test-evidence helper passes. Tracking this is the Agent's job; there is no state file for it.

### Metrics are signals

Line counts, complexity and nesting are review signals, not proofs. Read the reported numbers and the function's responsibility before choosing a fix.

| Field | Meaning |
| --- | --- |
| `physical_lines` | Physical source lines, including blank lines and comments. Empty text has zero lines, a final newline adds no line, and CRLF and LF count the same. |
| `code_lines` | Lines containing code or literal content after comments and strings are masked; blank and comment-only lines do not count. It is not a statement count. |
| Function range | From the named declaration through its own body, including multiline signature lines. Following dedented members and the next function's documentation are excluded; a multiline string or expression does not end the function. |
| `complexity` | One plus each `if`, `elif`, `for`, `while`, `match`, `and`, `or`, `&&` and `\|\|`; a ternary `if` counts once. Comments and strings do not count. It is a lexical indicator, not a control-flow proof; match arms and lambdas are not modeled separately. |
| `max_nesting` | Relative indentation of body lines, ignoring comments and continuation lines. It is an indentation indicator, not an AST depth. |

- `metrics.file_length` and `metrics.function_length` in `gdlint.json` select `physical` or `code`; a missing field means `physical`. Both values are always reported, and each function reports its selected `length_metric` and `line_count`.
- Switching a threshold to `code` is a configuration change made through an engineering-change review. Do not silently reinterpret a threshold.
- Keep necessary comments. Deleting explanation or splitting coherent work into forwarding functions is not a quality improvement.
- Private, static and multiline methods are measured the same way. A private name does not exempt metrics or return-type checks. Engine virtual methods are exempt from the return-type check only through an explicit name list. Anonymous lambdas are not counted as named methods.
- Unused-name checks are lexical heuristics. The native compiler's diagnostics stay authoritative.
- Magic-number Info is a review signal. Check whether a named constant would improve the code; do not rename identifiers or change thresholds to silence a false positive. Digits inside identifiers such as `get_sha256` and inside strings are not reported.

### `engine-parameter-contract` Info

Godot's `Logger._log_error` virtual callback requires eight parameters, so its arity is fixed by the engine. The linter still reports `params: 8` for that callback. When the project's parameter limit is lower, it adds `engine-parameter-contract` Info explaining that this one arity metric belongs to the engine interface.

- Leave the callback signature as the engine defines it.
- The Info covers only the parameter count. Length, complexity, nesting and native signature validation still apply.
- Any other eight-parameter method still gets the normal arity finding. Which declarations qualify is defined in [YAYA_PATCH.md](../../addons/gdscript-linter/YAYA_PATCH.md).
- No filename, ignore directive or global threshold may be used to obtain this treatment.

## Editor dock and resource import

The optional editor dock reads its analysis settings from the same `gdlint.json`. Personal display, export and filter preferences stay in editor settings. Opening the dock does not save the configuration; only explicit analysis-setting edits do. Generated projects do not enable the linter editor plugin by default.

Resource import is normal Godot editor work, not a Feature Stage or a step of static checking. If project preparation is incomplete, report the actual dependency or cache problem. Script parsing and lint do not prove that resources were imported.

## Dependency maintenance

`addons/gdscript-linter/YAYA_PATCH.md` records the local changes and the upstream attribution. Preserve licensing. Test changed linter behavior with the configured engine; a version label or an earlier report does not prove that a new edit works.
