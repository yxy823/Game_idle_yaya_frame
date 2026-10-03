---
name: task-handoff-godot
description: Preserve a Godot project's actual task stop point and prepare a scoped handoff for a pause, task switch or new conversation. Use for requested handoff records or continuation text; ordinary status questions do not require this workflow.
---

# Prepare a project task handoff

Use **Task handoff** in `methodology/09-records-reports-and-handoff.md` for shared content, record ownership and continuation boundaries. Match the requested result: a conversational summary, durable pause records, or records plus copyable text for a new conversation. Do not force all three outputs when only one is needed.

## Recover the real stop point

Identify the current goal, intended next purpose and requested pause/switch from the conversation. Inspect relevant actual files and read-only Git state, then the existing Progress, owning Feature notes/design and original evidence needed to distinguish completed work from remaining obligations. Read history only when it resolves a current uncertainty.

Preserve accepted decisions and concrete authorization without treating old plans, report text or prior passing results as current approval or verification. State the first useful resumption action and what would block it. For a Feature, retain its actual Stage and outstanding verification/acceptance conditions under `methodology/03-execute-loop.md`; for work without a Feature, retain its original task scope without inventing one.

## Deliver the requested handoff

When saving a stop point is authorized, update only necessary existing records under the **Progress** and **Task handoff** contracts in methodology 09. Follow the project Git contract for those edits, including any current no-commit restriction. Link original evidence and keep task-owned scratch material needed to resume. Do not clean, complete or restart the implementation merely to make the handoff appear tidy.

When the user wants to continue in another conversation, apply **Continuation prompts** in methodology 09 and return copyable task-specific text with the next purpose, scope, effective authorization, necessary project-local sources and first action. If the user only wants a summary or saved pause, a full prompt is unnecessary. No framework prompt library, operating-system temporary file or separate handoff document is required.

Check the output against the actual stop point and report any unresolved gap. A requested pause ends implementation at that boundary until the user resumes it; an ordinary summary does not revoke remaining authorization in a continuing task. This Skill does not send the handoff or create or switch conversations.
