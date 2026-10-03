---
name: project-environment-godot
description: Configure, update or recover a Godot project's tool paths, or run its first Godot resource scan. Use when the user asks for environment setup, a tool moved or changed version, or a configured tool cannot be started. Not for creating a project, fixing game behavior or running a general verification suite.
---

# Maintain the project environment

Prepare or repair the tools this project runs with. [Project environment](../../../methodology/06-project-environment.md) defines the configuration and the Bootstrap steps; this Skill applies them and adds no other setup procedure. Environment work does not need a GDD, and it creates no Feature or Stage.

## Read the section for the current need

| Current need | Read and apply |
| --- | --- |
| First setup of a new project | **Tool configuration** and **Project Environment Bootstrap**. The default document language is already set; read [language selection](../../../methodology/05-document-language.md#3-language-selection) only if the user asks for another language |
| A tool moved or changed version | **Tool configuration**, then rerun the affected Bootstrap checks. Keep unrelated settings and preparation that is still valid |
| A configured tool cannot be started | **Tool configuration**: report the actual failure; change the path only within the user's request |
| The first import and class scan is needed | **Project Environment Bootstrap** step 2 and [首次 Godot 扫描](../../../tools/README.md#首次-godot-扫描) |

If an editor or import run will write inside a worktree and you do not know where it writes or cleans up, read [Godot worktree runtime preparation](../worktree-create-godot/references/godot-worktree-runtime.md) first. Reading it does not create a worktree.

## Check with real output

- Use the configured executables and `tools/checks/check-project-environment.py`. Judge readiness from the checker's actual output, not from a filled-in path or an existing file.
- When a check fails, do not recreate the project, install dependencies or switch tools on your own. Report the failure.
- Reuse a completed first scan. Do not add a recurring import step, and do not clear caches to hide a failure.

## Report and return

Make only the configuration or preparation changes the user asked for, and run the matching checks. If you configured paths but left the first scan for later, say so.

Record the outcome in `reports/initialization.md` and Progress as described in **Project Environment Bootstrap**. Commit under `agent-rules/00-core/git-worktree-and-commits.md`, including any commit conditions the user set.

Return what changed, what was actually checked and any remaining blocker. A successful check shows only that the tools are available, not that tests pass or the game works. If this Skill was called from another authorized task, continue that task; setup success does not complete it.
