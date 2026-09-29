---
name: manual-acceptance-godot
description: Prepare a Godot Feature's pending manual checklist or record its actual user acceptance from a submitted result or explicit conversation. Does not perform the user's experience, infer acceptance or mark the Feature done.
---

# Prepare or record manual acceptance

Identify the actual Feature, current scope and requested operation. Apply **GDD prerequisite and authority** in `methodology/01-product-doc-structure.md`. Use the existing approved acceptance mode and manual obligations; do not invent a Feature, new requirements or an empty checklist to make a request fit this method. Invocation depends on the needed capability and its inputs, not on starting the execution loop again.

## Use the matching part of the acceptance contract

`methodology/manual-acceptance-files.md` owns the checklist, original files, snapshot binding, commands and result semantics. Read only the sections needed for the operation, plus the relevant Feature and actual source/result files.

| Requested operation | Read and apply |
| --- | --- |
| Prepare material for the user to try | **Definitions and preparation**: expand approved obligations into concrete pending checks, bind them to final implementation and provide the actual checklist path and return instructions |
| Import the user's submitted JSON | **Receive actual user results**: read the submitted original and comments, verify its correspondence with the unchanged checklist and record the actual outcome |
| Record an explicit conversational result | **Conversation and subsequent work**: tie the user's real decision to current scope and use the conversation route without fabricating a file submission |

A valid fully passed user submission already accepts that checklist's scope; do not request another acceptance phrase. Resolve a contradictory comment or an unclear decision locally. Agent-generated results, silence and a request to continue do not supply human acceptance. Do not use a conversation entry to bypass an invalid file; follow the contract for an explicit resolution or a new clear user decision.

Keep the original checklist and user result distinct. A source or acceptance-contract change uses the existing freshness and renewal rules; do not rebind a prepared checklist or rewrite the user's observations. Automatic checks and screenshots can support the material but cannot perform the user's experience.

## Return the recorded outcome

Use the existing record helper and report what was prepared or actually recorded, its scope and the remaining uncertainty. A successful import may record `pending` or `rejected`; it is not evidence that acceptance passed or the Feature is done. Follow the acceptance contract for failures and subsequent work, returning implementation changes to their existing owner.

Durable wording follows `methodology/05-document-language.md`; writes and commits follow `agent-rules/00-core/git-worktree-and-commits.md`. Preserve a task-specific requirement for explicit permission to commit: an accepted result does not itself grant that permission, and commit permission does not supply acceptance. Reuse either when already explicit.

Return to the coordinating task with the actual result and evidence. Continue its remaining concrete authorization through the existing owner without asking again merely because this method returned; recording-only work does not independently advance Stage or declare delivery complete.
