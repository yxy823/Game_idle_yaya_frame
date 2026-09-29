---
name: project-environment-godot
description: Configure, update or recover a Godot project's tool environment, or complete its needed first resource scan. Does not create a project, repair game behavior or run a general verification suite.
---

# Maintain the project environment

Identify the requested environment change or preparation and reuse the actual configuration and prior results. Apply **GDD prerequisite and authority** in `methodology/01-product-doc-structure.md`. This capability can support an existing task or an explicit setup request; it creates no Feature or new Stage.

## Read only the applicable contract

Paths below are relative to the project root. `methodology/05-document-language.md` owns configuration and **Project Environment Bootstrap**; this Skill does not define another setup procedure.

| Current need | Read and apply |
| --- | --- |
| Initial environment configuration | **Configuration contract**, **Verification configuration** and **Project Environment Bootstrap**; use **Language selection** only when the document language is not already confirmed |
| A tool location or version changed | **Verification configuration** and the affected Bootstrap checks; preserve unrelated settings and valid preparation |
| A configured tool cannot be invoked | **Project Environment Bootstrap** for using the configured path, reporting its actual failure and changing a tool location only within the requested scope |
| A newly copied project needs its first import/class scan | **Project Environment Bootstrap** and **首次 Godot 扫描** in `tools/README.md`; apply the project's actual process and permission constraints |

Use configured executables and the existing environment checker. Check its real output rather than treating a prefilled path or file presence as readiness. Do not recreate the project, install dependencies or replace a tool choice merely because a check fails. Reuse a completed first scan; do not add a recurring import phase or clear caches to hide a failure.

## Return the actual preparation result

Make only the authorized configuration or preparation changes and perform the matching checks. Configuration-only work can leave the first scan for the authorized first run under the Bootstrap contract; report that distinction. A successful probe or scan proves only its own result, not passing tests or game behavior.

Use the existing initialization report and Progress responsibilities in methodology 05, preserving prior evidence without adding a readiness flag or another state file. Durable writes follow its language contract and `agent-rules/00-core/git-worktree-and-commits.md`, including the current task's commit conditions.

Return what changed, what was actually checked and any remaining blocker to the owning task. Continue already authorized work through its existing owner without another confirmation merely because this method returned; setup success does not declare that task complete.
