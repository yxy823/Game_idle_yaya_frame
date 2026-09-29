---
name: verification-evidence-godot
description: Inspect, import or recover existing Godot test evidence when references, originals, freshness or interrupted runs need attention. Routes necessary reruns and manual acceptance to their owners; does not fabricate results or complete the Feature.
---

# Maintain actual verification evidence

Identify the requested evidence operation, actual Feature or diagnostic scope, current source state and referenced originals. Apply **GDD prerequisite and authority** in `methodology/01-product-doc-structure.md`. Reuse existing records and task authorization; evidence maintenance creates no Feature, new Stage or parallel result ledger.

## Distinguish the evidence problem

Read **Artifact-backed completion and semantic freshness** in `methodology/08-testing-strategy.md` and the matching operation under **调用** or **结果如何使用** in `tools/README.md`. These project-relative sources own evidence identity, coverage, import and recovery; do not reproduce their structure or edit verdicts by hand.

| Actual situation | Response within the existing contract |
| --- | --- |
| A real completed run needs importing, or its reference path was wrong | Read the actual originals and check current applicability; use the existing importer with valid references. A reference-only correction does not justify rerunning valid evidence |
| A summary exists but an original is missing or damaged | Locate and inspect the actual original first. If it cannot support the result, report the gap and arrange only the verification needed to replace it; do not reconstruct passing evidence from prose |
| Source or verification obligations changed | Apply the canonical content/freshness rules to determine what is invalid. Reuse still-valid evidence and renew affected obligations; commit time or a familiar filename does not establish freshness |
| A run was interrupted, failed or may still be running | Inspect its real record, logs and process state before a new run or stop action. Preserve the attempt and respect process ownership and stop authorization; apply the canonical failure/recovery coverage instead of hiding it with an older or narrower success |

Displaying a saved record and checking its current support for completion are different operations under `tools/README.md`. Select the operation the task needs and report its actual meaning. Focused/baseline results, static output and specialist measurements retain their own evidence limits; do not convert them into final gdUnit evidence or fabricate a report for `not_required`.

## Obtain only the missing evidence

Use [project-verification-godot](../project-verification-godot/SKILL.md) when authorized recovery requires another static check, existing test run or scene check. Choose the scope required by the original failure or current obligations; do not default to a full rerun. Diagnosis or implementation changes return to their existing owner rather than becoming an evidence edit.

If actual human results need preparing, recording or renewing, use [manual-acceptance-godot](../manual-acceptance-godot/SKILL.md). An automated rerun cannot renew human acceptance. Preserve failures and referenced originals under **Reports and cleanup** in `methodology/09-artifact-lifecycle.md`; no cleanup or reconstructed artifact may conceal a required failure.

## Return the supported result

Report which originals and references were checked or updated, what remains valid, and what failed, is stale or is still missing. Successful recording or evidence validation does not establish direct static checks, user acceptance or whole-Feature completion beyond its actual coverage.

Durable wording follows `methodology/05-document-language.md`; any repository writes follow `agent-rules/00-core/git-worktree-and-commits.md`, including the current task's acceptance and commit conditions. Return the result to the owning task and continue already authorized follow-up there without a new approval merely because this method returned. A narrow evidence-maintenance request does not authorize business changes or a completion transition.
