# Godot preparation in a separate checkout

Read this page before an authorized editor, import, test, game or other writing operation in a worktree, including verification during result integration. Reuse still-valid observations; inspect only the data and tools that the operation can affect. Pure read-only source comparison does not require running Godot.

Paths in code spans are relative to the target project root unless they are Godot resource paths or settings. Generic configuration and first-scan procedures remain in [project-environment-godot](../../project-environment-godot/SKILL.md), backed by `methodology/05-document-language.md` and `tools/README.md`.

## Identify the actual resources and side effects

| Area touched by this operation | What to establish |
| --- | --- |
| Versioned project content | The selected checkout contains the intended scripts, scenes, assets and required `.uid` / `.import` metadata. Its `res://` resolves from its own `project.godot`; shared Git storage does not mean both checkouts edit the same resource files. Inspect actual external links or paths when used. |
| Local files and imports | Uncommitted, untracked and ignored files are not supplied by the selected commit. Check only required local dependencies. `.godot/` is ignored by this project; another checkout's import cache is not proof that this one is prepared. Use the existing scan contract when needed instead of copying or clearing caches by default. |
| Executables and local configuration | Resolve the actual target paths and configured tools. Reuse a valid machine environment; do not copy an entire machine configuration, reinstall dependencies or change shared tool settings merely because the checkout is new. |
| `user://` and test scratch data | Determine the actual directory and relevant file/cleanup operations. The same project settings can make multiple checkouts use the same user-data directory. Separate save slots do not isolate settings, caches or test cleanup. |
| Project-external paths and services | Check absolute paths, report/log destinations, databases, ports or services only when the operation uses them. Identify existing processes that might write there before starting a conflicting run. |

The bundled gdUnit4 uses `user://tmp`: inspect `addons/gdUnit4/src/core/GdUnitFileAccess.gd` and the suite cleanup in `addons/gdUnit4/src/core/execution/stages/GdUnitTestSuiteAfterStage.gd` when this runner is involved. Running only tests can therefore still affect another checkout's scratch files. Apply `agent-rules/70-tests/fixtures-and-isolation.md` to test-owned namespaces and cleanup; do not alter bundled runner code merely to make a worktree appear isolated.

## Choose a preparation method for the actual write

Prefer an existing project setting, save/test namespace or tool output option that covers the requested operation. Confirm both the write destination and any cleanup scope; serial execution alone does not protect saved data from a later destructive write. No single change proves that every other side effect is isolated.

For Godot-managed user data, the [official file-path documentation](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#accessing-persistent-user-data-user) describes `application/config/use_custom_user_dir` and `application/config/custom_user_dir_name`. Within authorized experiment configuration, a distinct custom user directory is one available option; verify support and the actual result in the project's Godot version. It does not redirect arbitrary absolute paths or external services. Do not invent a universal command-line isolation flag or change the game's public name just to assume separation.

Use the existing diagnostics or an authorized minimal probe to observe relevant resolved paths; `ProjectSettings.globalize_path("user://")` can expose Godot's user-data location. Account for the probe's own startup/import effects before running it. Where the operation may erase or overwrite data and a safe destination cannot yet be established, report the specific blocker and continue unaffected read-only or code work instead of testing against valuable shared data.

Keep any temporary configuration within the current task's allowed write scope. Preserve existing settings, explain what was changed and why, and exclude experiment-only settings from adopted game behavior unless their adoption is itself intended and verified. Do not create a general isolation subsystem, extra state file or blanket environment-copy procedure.

## Report only demonstrated preparation

Separate inspected configuration from observed runtime paths, successful imports, actual test results and human acceptance. Record the relevant target and real evidence through existing task records and [verification-evidence-godot](../../verification-evidence-godot/SKILL.md) when evidence maintenance is needed. An unrun checkout is not validated isolation; a passing environment probe is not passing gameplay or test behavior.

When preparation is sufficient, return to the authorized operation. Broader delivery checks remain with its workflow and [project-verification-godot](../../project-verification-godot/SKILL.md); this reference does not require a full project run for every directory preparation.
