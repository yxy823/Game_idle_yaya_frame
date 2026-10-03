# 06 · Project environment

This page covers the tool paths stored in `docs/methodology-config.json` and how the Agent prepares a newly created project to run them. Document language, the other setting in that file, is covered in [document language](05-document-language.md).

## Tool configuration

`docs/methodology-config.json` stores two machine settings used by project tools:

| Field | Value |
| --- | --- |
| `python_executable` | The Python executable path or command name used to run project tools. No script path or arguments. |
| `engine_executable` | The full path of the Godot executable, absolute or relative to the project root. No shell quotes or arguments; it is not looked up on `PATH`. |

The file stores tool choices only. It does not store whether the environment is ready, the observed Godot version, a blocker list or a plugin inventory. These values are never translated. A document-language change keeps them byte-for-byte.

Use the configured `engine_executable` as given; do not search for another Godot installation. If the path does not work, report why. When the user asks the Agent to set up the environment, the Agent may write the Python and Godot paths it finds into this file. During any other task, change the paths only when the user asks for a new tool location. A filled-in path does not mean the tools are ready.

Commands run from the project root. The test entry is fixed at `tools/testing/run-gdunit-tests.py`; it reads the configured Godot path, and `--godot-binary` overrides it for one run only. Script parsing and lint call Godot and the linter addon directly, as described in [GDScript lint](contracts/gdscript-lint.md).

## Project Environment Bootstrap

Bootstrap is the Agent preparing this project's environment when the user asks for setup. It is a task the Agent performs, not a separate setup program. It does not depend on a GDD.

1. **Confirm the tools.** Check the Python and Godot paths and any dependencies, and write the paths into the configuration.
2. **Run the first Godot scan.** If the project has never been opened, let the configured Godot editor finish importing resources and scanning global classes before the first command that needs project scripts. Follow the [first scan instructions](../tools/README.md#首次-godot-扫描). A setup request that only asks for configuration may leave the scan to the first authorized run; say that it has not run yet. Later Features reuse the finished scan; there is no import wrapper or per-Feature import step.
3. **Check readiness.** Run:

   ```powershell
   python -B tools/checks/check-project-environment.py --require-ready
   ```

4. **Record the result.** Write what you did and what you found in `reports/initialization.md`. If the file already exists, add a new entry and keep earlier failures. Progress records the current result, blockers, next step and a link to the report.

`reports/initialization.md` is a report for people; no tool treats it as a gate. The default project `.gitignore` keeps it local, so committing Progress does not include it. Commit the report only when the user asks.

## What the readiness check proves

| Mode | Checks |
| --- | --- |
| Without `--require-ready` | The configuration structure. An empty Godot path is allowed, and tool availability is not claimed. |
| With `--require-ready` | The Python and Godot executables exist, the test runner file exists, and a live Godot version probe reports 4.7.x. It prints the observed version. |

The check does not prepare editor caches, install dependencies, run tests, parse scripts, run lint or initialize Git. Passing it shows only that the tools are available; Stage 4 test, parse and lint runs prove the actual results. If setup fails, record the reason in Progress and the initialization report, not in the configuration file.
