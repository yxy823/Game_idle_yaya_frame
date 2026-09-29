# 12 · Independent review

This is the common contract for all formal reviews. Design-document and proposal inspection uses `plan-review-godot`, including its conditional GDD method; other review methods live in `review-code`, `review-ux`, `review-art`, `review-audio`, `review-assets`, `review-localization` and `review-balance`. Select only methods relevant to the user's requested scope; one independent instance can combine several methods. Reviews are requested work, never a mandatory pipeline.

## Trigger and independence

The user chooses the timing and scope: one Feature, several Features, a commit range, a source/design document or named artifacts. Follow explicit static-only or other restrictions. Stage 6 coordinates a review requested during delivery; a separate review may happen before or after that stage. A completed review does not itself authorize repair, source changes or human acceptance.

Use a fresh instance that has not authored the reviewed work. Loading a review Skill in the author context is author self-checking, not independent review. The supplied `.codex/agents/independent-reviewer.toml` defines a reusable role, not a separate role per specialty or proof that it was loaded. Verify the current client supports and actually selects the role, and inspect the instance's context and effective permissions. Parent runtime permission overrides may apply again. Never infer isolation from a TOML setting alone. If the client cannot provide a fresh review context, report that limit; do not relabel the author's pass.

When delegating, start without the full author conversation when the client supports that choice. Hand off only what the reviewer needs:

| Input | Content |
| --- | --- |
| Scope and decision | User request, questions to decide, applicable methods and exclusions |
| Authoritative requirements | Exact source/rule paths, approved decisions and unresolved proposals distinguished |
| Snapshot | Project directory, commit or range, and relevant uncommitted differences included in the reviewed result |
| Raw evidence | Original test/measurement files, reproduction steps and environment; summaries labeled as claims |
| Allowed validation | Permitted commands/run scope, isolated output location and effective permission limits |

Do not include a persuasive “why this must be correct” narrative or the author's desired verdict. Summaries help navigation but remain claims to verify against sources and artifacts. The reviewer chooses relevant files beyond the initial list when dependencies require it, without expanding the user's task scope.

## Read-only outcomes and isolated validation

Reviewed source, assets, specifications, original acceptance records and original evidence are read-only to the reviewer. Do not fix, reformat, update requirements, replace evidence, record human acceptance, mark Features done or commit changes. These boundaries apply even if the actual sandbox grants broader writes.

Necessary targeted verification is allowed within the user's review scope unless restricted. Before running it, inspect side effects and direct all logs, caches, imports, test data and outputs away from the reviewed artifacts. Use an isolated safe copy or an existing authorized validation environment, and the existing `reports/scratch/<task>/` convention where safe. A separate report path alone does not isolate a Godot import or test that writes into source/user data. Preserve the exact reviewed snapshot when copying, including relevant uncommitted files; a copy of HEAD alone omits those changes. Do not run a command when its side effects cannot be contained or its permission is unavailable. Report the resulting unverified claim instead of bypassing limits.

Keep retained review reports under the existing `reports/features/<ID>/` or `reports/maintenance/<task>/` locations; conversation output is normally sufficient. Never overwrite another run or the author's evidence. Follow [artifact lifecycle](09-artifact-lifecycle.md) without adding a review registry.

## Evidence and verdict

Determine whether each important claim has current, relevant evidence. Inspect what tests assert, which scenarios actually ran, raw failures, skipped/missing checks, and applicability of environment and version. For measurements, check workload, sampling, comparable conditions and actual duration; separate diagnostic and delivery builds. Textual audio descriptions cannot replace listening evidence, and a resource filename cannot replace a displayed visual. Do not invent observed results when tools cannot expose them.

Report actionable findings with severity, source location, concrete trigger and consequence. Distinguish contract violations from unapproved design suggestions; uncertainty from a demonstrated defect; and inherited issues from introduced ones when reviewing a change. Avoid speculative findings without a plausible supported trigger. Evidence sufficiency belongs to the applicable review method; there is no separate `test-evidence-review` handoff.

The result identifies the reviewed snapshot, methods and actual coverage, validation performed, findings, unverified requirements and limitations. “No findings” is bounded by that coverage. Returning a report completes the review task, but missing critical evidence cannot satisfy a required approval condition. Check whether reviewed artifacts changed during the review. If they did, narrow the conclusion to the inspected snapshot or re-review the affected changes; never apply an old verdict silently to new work.

Delivery can proceed past a requested review condition only when its agreed scope is adequately covered and blocking findings or limits have been resolved by the responsible task/user. Repairs return to the authorized author task for verification and any affected human acceptance. Additional review follows the user's existing condition, not an automatic new cycle for every edit. Art, audio and UX review support, but never replace, the user's actual experience acceptance.
