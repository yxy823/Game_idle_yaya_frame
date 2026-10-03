# 12 · Independent review

This document is the common contract for every formal review. Review methods live in Skills:

- `plan-review-godot` inspects design documents and proposals, including its GDD method;
- `review-code`, `review-ux`, `review-art`, `review-audio`, `review-assets`, `review-localization` and `review-balance` cover the other subjects.

Select only the methods relevant to the user's requested scope; one independent instance can combine several. Reviews happen only when requested; they are never a mandatory pipeline.

## Trigger and independence

The user chooses the timing and scope: one Feature, several Features, a commit range, a source or design document, or named files. Follow explicit static-only or other restrictions. Stage 6 coordinates a review requested during delivery; a separate review may happen before or after that stage. A completed review does not itself authorize repair, source changes or human acceptance.

Use a fresh instance that did not author the reviewed work. Loading a review Skill in the author's context is an author self-check, not independent review.

To start the reviewer:

1. Select the `independent-reviewer` role defined in `.codex/agents/independent-reviewer.toml`. It is one reusable role for every specialty.
2. Confirm that the current client supports the role and actually started the instance with it.
3. Check the instance's context and effective permissions. Permission overrides from the parent session may apply to it again, so a TOML setting alone never proves isolation.
4. If the client cannot provide a fresh review context, report that limit. Do not relabel the author's own pass as independent review.

When delegating, start without the full author conversation when the client supports that choice. Hand off only what the reviewer needs:

| Input | Content |
| --- | --- |
| Scope and decision | User request, questions to decide, applicable methods and exclusions |
| Authoritative requirements | Exact source/rule paths, approved decisions and unresolved proposals distinguished |
| Snapshot | Project directory, commit or range, and relevant uncommitted differences included in the reviewed result |
| Raw evidence | Original test/measurement files, reproduction steps and environment; summaries labeled as claims |
| Allowed validation | Permitted commands/run scope, isolated output location and effective permission limits |

Do not include a persuasive “why this must be correct” narrative or the verdict the author wants. Summaries help navigation but remain claims to verify against sources and artifacts. The reviewer chooses relevant files beyond the initial list when dependencies require it, without expanding the user's task scope.

## Read-only outcomes and isolated validation

Reviewed source, assets, specifications, original acceptance records and original evidence are read-only to the reviewer. Do not fix, reformat, update requirements, replace evidence, record human acceptance, mark Features done or commit changes. These boundaries apply even if the actual sandbox grants broader writes.

Necessary targeted verification is allowed within the user's review scope unless the user restricted it. Before running a command:

- Inspect its side effects. Direct all logs, caches, imports, test data and outputs away from the reviewed files.
- Use an isolated copy or an authorized validation environment, under `reports/scratch/<task>/` where that is safe. A separate report path alone does not isolate a Godot import or a test that writes into source or user data.
- Copy the exact reviewed snapshot, including relevant uncommitted files. A copy of HEAD alone misses those changes.
- Do not run the command when its side effects cannot be contained or the permission is unavailable. Report the claim as unverified instead of bypassing the limit.

Conversation output is normally enough. A saved review report goes under `reports/features/<ID>/` or `reports/maintenance/<task>/`, following [Reports and cleanup](09-records-reports-and-handoff.md#reports-and-cleanup). Never overwrite another run or the author's evidence, and do not add a review registry.

## Evidence and verdict

Determine whether each important claim has current, relevant evidence. Inspect what tests assert, which scenarios actually ran, raw failures, skipped or missing checks, and whether the environment and version apply. For measurements, check workload, sampling, comparable conditions and actual duration; separate diagnostic and delivery builds. Textual audio descriptions cannot replace listening evidence, and a resource filename cannot replace a displayed visual. Do not invent observed results when tools cannot expose them.

Report actionable findings with severity, source location, concrete trigger and consequence. Distinguish:

- contract violations from unapproved design suggestions;
- uncertainty from a demonstrated defect;
- inherited issues from introduced ones, when reviewing a change.

Avoid speculative findings without a plausible supported trigger. Evidence sufficiency belongs to the applicable review method; there is no separate `test-evidence-review` handoff.

The result identifies the reviewed snapshot, methods and actual coverage, validation performed, findings, unverified requirements and limitations. “No findings” is bounded by that coverage. Returning a report completes the review task, but missing critical evidence cannot satisfy a required approval condition. Check whether reviewed artifacts changed during the review. If they did, narrow the conclusion to the inspected snapshot or re-review the affected changes; never apply an old verdict silently to new work.

Delivery can pass a requested review condition only when the agreed scope is adequately covered and the responsible task or the user has resolved blocking findings and limits. Repairs go back to the authorized author task for verification and any affected human acceptance. Further review follows the user's stated condition, not an automatic new cycle for every edit. Art, audio and UX review support, but never replace, the user's actual experience acceptance.
