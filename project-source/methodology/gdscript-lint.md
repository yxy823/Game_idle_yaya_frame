# GDScript lint contracts and evidence

The native target Godot parser/compiler and the configured linter establish
different contracts. The Agent calls the Godot parser and bundled lint CLI directly.
Project setup records the actual Python and Godot executable paths. The project uses the addon
under `addons/gdscript-linter` and the root `gdlint.json` configuration.
Never run a Godot editor/import check inside a restricted Windows sandbox when the
project requires the external approval route.

Magic-number checks operate on numeric literals after string/comment masking.
Digits inside identifiers such as `get_sha256` and text such as `"sha256"` are
not numeric literals. The existing allowlist and constant treatment remain.

## Metrics

| Field | Exact interpretation |
| --- | --- |
| `physical_lines` | Physical source lines, including blank lines and comments. Empty text has zero lines; an ending newline does not add a phantom line. CRLF and LF are equivalent. |
| `code_lines` | Physical lines containing non-comment code or literal content after lexical masking; blank and comment-only lines do not count. It is not a statement count. |
| Function range | Named declaration through its own body. Multiline signature lines count; following dedented members and the next function's documentation do not. A multiline string/expression can contain dedented physical lines without ending its function. |
| `complexity` | Lexical decision indicator: one baseline plus `if`, `elif`, `for`, `while`, `match`, `and`, `or`, `&&`, `\|\|`. Ternary `if` counts once. Comments and string contents do not contribute. This is not a control-flow-graph cyclomatic proof; individual match arms and lambda ownership are not separately modeled. |
| `max_nesting` | Relative indentation of non-continuation body lines, excluding comments and signature/expression continuations. This remains an indentation indicator, not an AST depth proof. |

`metrics.file_length` and `metrics.function_length` explicitly select `physical`
or `code`; missing fields in old configurations keep `physical`. Both metrics are
always reported, and functions report the selected `length_metric` and `line_count`.
The new template makes the selection explicit without raising thresholds. A project
may intentionally adopt `code` through its engineering-change configuration review;
do not silently reinterpret an old threshold.

Line counts are review signals. Read the reported code/physical difference and the
function responsibility before choosing a fix. Necessary comments must be preserved;
deleting explanation or splitting coherent work into forwarding functions is not a
quality improvement. A physical-length warning can expose a review decision, while
the report still retains the complete code metric and failure verdict.

Ordinary/static/private and multiline named declarations share the same model.
Private method names do not exempt metrics or return-type checking. Engine virtual
return-type exemptions remain an explicit name list. Unused-name checks are scoped
to the containing named function; they remain a lexical heuristic for local block
shadowing/lambda captures, with native compiler diagnostics still authoritative.
Anonymous lambdas are not independently counted as named methods.

### Fixed engine interface arity

Godot 4.7.1's `Logger._log_error` virtual callback requires eight parameters. Its
interface is owned by the engine, so changing that signature to fit an ordinary
project function limit would break the callback contract. The linter recognizes
only a top-level instance method in a script directly extending `Logger`, with
the exact explicit parameter types and void return matching the running Godot
4.7 `ClassDB` metadata. The actual parameter names may differ, including an
underscore prefix for unused callback inputs.

The function still reports `params: 8`. Its `parameter_contract` records the
owner, method, engine version, ClassDB authority, fixed arity and matched types.
When the project limit is lower, `engine-parameter-contract` Info explains why
that single arity metric belongs to the engine interface. This is no exemption
from length, complexity, nesting or native signature validation. Ordinary
eight-parameter methods, wrong bases/types/returns, static lookalikes and inner
classes remain subject to normal arity checks. Indirect/path-based inheritance
is conservatively unresolved; it does not receive this treatment.

The real-engine regression records `Engine.get_version_info()` and the complete
`Logger._log_error` metadata in `contracts.json`, then checks both the legitimate
callback and the negative cases. No repository filename, ignore directive or
global threshold authorizes this engine-owned metric treatment.

## Direct execution

Use the Godot executable recorded in `docs/methodology-config.json`.
The Agent runs the existing engine and addon commands directly; there is no
Python static wrapper, static manifest, or static-result registration command.

```powershell
# $godot is the configured executable path; run from the project directory.
& $godot --headless --path . --check-only --script res://path/to/changed_script.gd | Out-Host
$LASTEXITCODE
& $godot --headless --path . --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --json --output reports/lint.json res:// | Out-Host
$LASTEXITCODE
```

For PowerShell with the Windows GUI executable, the pipeline waits for the process;
read `$LASTEXITCODE` immediately. An empty exit value is not a successful check.

Parse changed project scripts and necessary dependants according to the actual
impact. Run the bundled lint CLI on the full `res://` project scope, respecting
`gdlint.json`. Existing dependency exclusions do not waive regression checks
when the task itself changes that dependency.

Check each command's exit code and original output immediately. Keep failures;
do not overwrite a report still needed for an unresolved task. Choose a distinct
report filename when preserving an earlier run. Report actual checked scope,
Critical/Warning/Info counts and any unexecuted checks. Unknown counts are not zero.
An unresolved required parse or lint failure prevents completion even when the
test-evidence helper passes. This is an Agent responsibility, not another state file.

The lint CLI returns 3 for invalid/empty input, 2 for Critical, 1 for Warning,
and 0 for clean or Info-only results. Display filters cannot erase the real verdict.
Magic-number Info is a review signal: inspect whether a named constant improves
the code; do not rename identifiers or change thresholds to silence a false positive.

Resource import belongs to Godot's normal editor/resource handling. It is not a
Feature stage or a prelude built into static checking. If project preparation is
incomplete, report the actual dependency/cache problem; script parsing and lint
do not themselves prove that resources were imported.

## Dependency maintenance

`addons/gdscript-linter/YAYA_PATCH.md` records local changes and upstream attribution.
Preserve licensing. Test changed dependency behavior in the actual configured
engine; a version label or old report does not establish that a new edit works.
