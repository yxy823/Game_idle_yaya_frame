# GDScript Linter - Command Line Interface

Run GDScript code analysis from the terminal using Godot's headless mode.

## Quick Start

```bash
# Analyze current project
godot --headless --script res://addons/gdscript-linter/analyzer/analyze-cli.gd

# Analyze specific directories
godot --headless --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- src/ scripts/

# Output as JSON
godot --headless --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --json
```

## Usage

```
godot --headless --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- [options] [paths...]
```

**Note:** The `--` separator is required before any linter options to distinguish them from Godot's own arguments.

## Arguments

| Argument | Description |
|----------|-------------|
| `[paths...]` | `.gd` files or directories to analyze (default: `res://`); repeated files are deduplicated |

## Options

| Option | Description |
|--------|-------------|
| `--config <path>` | Required config file (default: `res://gdlint.json`); missing, unreadable or invalid configuration fails |
| `--format <type>` | Output format: `console`, `json`, `clickable`, `html`, `github` |
| `--severity <level>` | Minimum severity to report: `info`, `warning`, `critical` |
| `--check <checks>` | Comma-separated known check IDs to run; an unknown ID fails before changing the enabled checks |
| `--top <N>` | Show only top N issues sorted by priority |
| `--json` | Shorthand for `--format json` |
| `--clickable` | Shorthand for `--format clickable` (Godot Output panel format) |
| `--html` | Shorthand for `--format html` |
| `--github` | Shorthand for `--format github` (GitHub Actions annotations) |
| `--output, -o <file>` | JSON or HTML output file; HTML defaults to `code_quality_report.html` |
| `--no-ignore` | Bypass all `gdlint:ignore` directives |
| `--help, -h` | Show help message |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No issues or Info-only findings |
| 1 | Warnings found (no critical issues) |
| 2 | Critical issues found |
| 3 | Invalid/empty input, configuration error (including an unknown check ID), or JSON output failure |

`--severity` and `--top` affect the displayed findings only. They do not change
the exit code calculated from the full analysis. Check the process exit code even
when the filtered report looks clean. Input paths that do not exist or discover no
eligible GDScript files fail with exit 3.

## Configuration

### Project Configuration and Editor Preferences

Analysis thresholds, checks, metrics and scan scope come from the project's
`gdlint.json`. Existing machine-level analysis settings are ignored. The dock
stores personal display, export, filter and Claude preferences in `EditorSettings`.

Opening or rebuilding the dock does not save the config. Changing an analysis
setting writes the project configuration while retaining untouched analysis values
and unknown JSON fields. It does not write a machine-level analysis override.
An invalid loaded configuration cannot be saved over by the dock. The bundled
project enables gdUnit4 by default; the linter dock is an optional editor plugin.

### Config File Format

The CLI requires `gdlint.json` in the Godot project root unless `--config` selects
another file. It does not silently fall back to built-in defaults when that file
is missing or unreadable. The generic configuration loader retains optional-file
behavior for other callers. Partial valid configs still use built-in defaults for
omitted fields; use the generated project's complete config to retain its policy.

Example `gdlint.json`:

```json
{
	"metrics": {
		"file_length": "physical",
		"function_length": "physical"
	},
	"limits": {
		"file_lines_soft": 400,
		"file_lines_hard": 600,
		"function_lines": 40,
		"function_lines_critical": 70,
		"max_parameters": 5,
		"max_nesting": 3,
		"max_line_length": 100,
		"cyclomatic_warning": 10,
		"cyclomatic_critical": 15
	},
	"checks": {
		"file_length": true,
		"function_length": true,
		"parameters": true,
		"nesting": true,
		"todo_comments": true,
		"long_lines": true,
		"print_statements": true,
		"empty_functions": true,
		"magic_numbers": true,
		"commented_code": true,
		"missing_types": true,
		"cyclomatic_complexity": true,
		"god_class": true,
		"naming_conventions": true,
		"unused_variables": true,
		"unused_parameters": true,
		"missing_return_type": true
	},
	"scanning": {
		"respect_gdignore": true,
		"scan_addons": false,
		"included_addons": [],
		"excluded_addons": []
	},
	"exclude": {
		"paths": ["addons/", ".godot/", "tests/mocks/"]
	}
}
```

### Custom Configs

Use the "Export Config..." button in the editor to save custom configs (e.g., `gdlint-strict.json` for CI, `gdlint-lenient.json` for development).

```bash
# Use a strict config for CI
godot --headless --script ... -- --config gdlint-strict.json
```

## Output Formats

### Console (default)

Human-readable report with summary, top files, and categorized issues.

### JSON

Write a JSON file directly for integration with other tools:

```bash
godot --headless --script ... -- --json --output report.json
```

The report is also printed to standard output. Prefer `--output` for the artifact
because Godot startup diagnostics can accompany the console output. The destination
directory must already exist. JSON includes `exit_code`, `input_errors`, summary
counts, per-file metrics and findings; `presentation_filtered` indicates whether
`--severity` or `--top` was requested. Early configuration errors go to stderr and
do not produce a JSON report.

### Clickable

Godot Output panel format with clickable file:line links:

```
res://scripts/player.gd:42: [warning] Function 'update_physics' exceeds 30 lines (45)
```

### GitHub Actions

Annotations that appear directly in GitHub PR diffs:

```bash
godot --headless --script ... -- --github
```

Output format:
```
::error file=scripts/player.gd,line=42::[high-complexity] Function has complexity 25 (max 15)
::warning file=scripts/player.gd,line=100::[long-function] Function exceeds 30 lines (45)
```

### HTML

Self-contained HTML report with interactive filtering:

```bash
godot --headless --script ... -- --html -o report.html
```

## CI/CD Integration

### GitHub Actions

```yaml
name: GDScript Lint

on: [push, pull_request]

jobs:
  lint:
	runs-on: ubuntu-latest
	steps:
	  - uses: actions/checkout@v4

	  - name: Setup Godot
		uses: chickensoft-games/setup-godot@v1
		with:
		  version: 4.2.1

	  - name: Run GDScript Linter
		run: |
		  godot --headless --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --format github
```

### GitLab CI

```yaml
lint:
  image: barichello/godot-ci:4.2.1
  script:
    - godot --headless --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --format json --output lint-report.json
  artifacts:
    when: always
    paths:
      - lint-report.json
```

This publishes the native linter JSON as an artifact; it is not GitLab's separate
Code Quality report schema.

## Examples

### Analyze Multiple Directories

```bash
godot --headless --script ... -- src/ scripts/ autoload/
```

### Show Only Critical Issues

```bash
godot --headless --script ... -- --severity critical
```

### Show Top 10 Priority Issues

```bash
# Top 10 issues sorted by severity, then by "badness" (complexity, line count)
godot --headless --script ... -- --top 10

# Top 5 critical issues for quick CI summary
godot --headless --script ... -- --top 5 --severity critical --format github
```

### Run Specific Checks

```bash
# Only check for complexity and function length
godot --headless --script ... -- --check high-complexity,long-function
```

### Combine Options

```bash
# Run selected checks; display critical issues (warnings still return exit 1)
godot --headless --script ... -- \
	--config gdlint-ci.json \
	--severity critical \
	--check high-complexity,long-function,god-class \
	--format github \
	src/
```

## Available Check IDs

For use with `--check`:

| Check ID | Description |
|----------|-------------|
| `file-length` | Files exceeding line limits |
| `long-function` | Functions exceeding line limits |
| `long-line` | Lines exceeding max length |
| `todo-comment` | TODO, FIXME, HACK comments |
| `print-statement` | Debug print statements |
| `empty-function` | Functions with no implementation |
| `magic-number` | Hardcoded numeric values |
| `commented-code` | Commented-out code blocks |
| `missing-type-hint` | Variables without type hints |
| `missing-return-type` | Functions without return type |
| `too-many-params` | Functions with many parameters |
| `deep-nesting` | Excessive nesting depth |
| `high-complexity` | High cyclomatic complexity |
| `god-class` | Classes with too many members |
| `naming-class` | Class naming convention |
| `naming-function` | Function naming convention |
| `naming-signal` | Signal naming convention |
| `naming-const` | Constant naming convention |
| `naming-enum` | Enum naming convention |
| `unused-variable` | Local variables never used |
| `unused-parameter` | Function parameters never used |
| `ascii-violation` | ASCII-only file directives or project-wide setting |
| `strict-limit` | Strict-limit directives |
| `sealed-violation` | Sealed class protection |

The `naming-*` IDs share one naming-conventions switch, so selecting one enables
the naming group. Unknown IDs, including misspellings mixed with valid IDs, fail
with exit 3.

## Common Mistakes

### Files and Directories Are Both Supported
```bash
# Analyze one file and a directory; overlaps are deduplicated
godot --headless --script ... -- src/player.gd src/
```

### Wrong: Forgetting the `--` separator
```bash
# DON'T do this - Godot will consume --top as its own arg
godot --headless --script ... --top 5
```

### Right: Use `--` before linter options
```bash
# DO this - the -- tells Godot "everything after is for the script"
godot --headless --script ... -- --top 5
```

### Wrong: Running from wrong directory
```bash
# DON'T do this if gdscript-linter isn't in this project
cd /some/other/project
godot --headless --script res://addons/gdscript-linter/analyzer/analyze-cli.gd
```

### Right: Use --path for external projects
```bash
# DO this - run from the linter's project, use --path for target
cd /project-with-linter-installed
godot --headless --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --path /other/project
```

## For AI Assistants

When using this CLI:

1. **Always use `--` before any linter options** - required separator
2. **Pass `.gd` files, directories, or both** - directories are scanned recursively and repeated files are deduplicated
3. **The script path is relative to the project with the linter installed** - use `--path` for external projects
4. **Targeting a specific addon** - pass its path as a positional argument (e.g. `-- addons/myaddon`) and it is automatically added to `included_addons` for that run
5. **Require configuration and retain the real verdict** - use the project config or an explicit `--config`, write JSON with `--output`, and inspect the exit code even when display filters are used

Example for analyzing an external project:
```bash
godot --headless --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --path "C:/path/to/project" --top 10
```

## Performance Notes

- Godot headless mode has ~2-3 second startup overhead
- For interactive use, consider running analysis from within the editor
- For CI/CD, the startup overhead is negligible compared to build times
