---
name: engineering-refactor-select
description: >-
  Compare unresolved code smells recorded in Feature notes, recommend one worthwhile refactor or explain why to defer, and return the user's choice to engineering-change-plan. This workflow never edits or commits. English triggers: pick a smell to refactor, scan suggestions, find refactor TODOs. 中文触发：挑一个坏味道重构、扫一下 suggest、看看 notes 里的重构待办。
---

# Pick one refactor smell

Use this three-stage workflow to find unresolved code smells in Feature notes, compare their current value and cost, and recommend one when action is worthwhile. Explain when deferring is more useful. A user-selected problem returns to [engineering-change-plan](../engineering-change-plan/SKILL.md), which owns refactor triage and Feature creation.

## Language contract

This read-only report uses the conversation language and preserves extracted note excerpts verbatim. It does not require document-language setup. The writer of any subsequently authorized durable note follows `methodology/05-document-language.md`.

## Scope

- Use this workflow when the user wants to refactor but does not know which recorded smell to choose.
- Use it with a Feature or category filter when the user asks to inspect only a subset, such as one Feature or cross-file smells.
- If the user already knows the exact smell, skip selection and route it directly to `engineering-change-plan` in `refactor` mode.
- If the problem comes from an external observation, route it to `engineering-change-plan`; use `bug`, `refactor`, or `maintenance` mode according to its semantics.

## Global rules

1. Discover and select only. Do not write code, modify files, or commit. Report the recommendation or reason to defer, and wait for the user's choice.
2. Explain relative priority using current evidence, expected benefit, and the cost of a safe change. Do not calculate numeric scores or create priority fields or a separate ledger.
3. Cover the requested scope without hiding important candidates merely to shorten the report; do not expand a filtered request into a whole-project scan.
4. Do not invoke another Skill, including [feature-plan](../feature-plan/SKILL.md), [feature-sync](../feature-sync/SKILL.md) or [feature-execute](../feature-execute/SKILL.md). After the user chooses, hand the selection back as **Response routing** describes; `engineering-change-plan` starts any further work, and `feature-execute` implements only after explicit Feature approval.

## Stage 1: scan

**Entry:** the user invokes this workflow.

**Output:** an unranked list of confirmed unresolved candidates and any material uncertainty.

1. Check `docs/features/`. If it is absent, report that there are no recorded Feature candidates and stop; selection does not require creating a plan.
2. Read `docs/feature-list.json` for titles, statuses and dependencies. Apply any requested Feature filter before loading details, then read the selected details' `notes`. A category filter selects matching findings within that scope; a project-wide category search may need all notes. Follow other details only to resolve a candidate's current validity or real dependency, not to broaden the scan.
3. Split notes by line or sentence and extract any paragraph containing at least one stable marker:
   - `TODO`
   - `suggest`
   - `Code smell` or the Chinese equivalent `代码气味`
   - `refactor` or `重构`
   - `future`, `defer`, `未来`, or `推到`
4. Read each finding in its full note context before counting or ranking it. Exclude findings explicitly resolved or superseded; follow linked later Features and named current files when needed to confirm the meaning. A completed source Feature alone does not resolve every TODO in its notes. If current validity cannot be established, report the uncertainty separately without ranking or recommending that finding. Preserve historical notes unchanged.
5. Record for every remaining candidate:
   - Feature ID;
   - concise Feature title from the index;
   - a verbatim excerpt of at most 200 characters;
   - code file paths named in the note, when any.
6. If no confirmed unresolved candidate remains, report that result and any unresolved uncertainty in the current conversation language; the user may describe an external observation directly. Stop before Stage 2 without forcing a recommendation or claiming unverified findings were resolved.

## Stage 2: compare value, impact, and cost

**Entry:** Stage 1 found at least one candidate.

**Output:** a reasoned relative order, including candidates better deferred and material evidence gaps.

Compare candidates against the user's current goals. Use the evidence needed to explain the order:

- **Current facts:** identify the problem in checked source, call relationships, or actual maintenance records. Distinguish static inference from observed execution; historical notes alone do not establish current runtime behavior.
- **Consequences of leaving it:** explain any obstruction to an agreed next task, repeated coordinated edits, or other concrete maintenance cost. State unknown frequency or impact honestly. A Feature dependency does not by itself prove that this smell blocks the dependent work.
- **Smallest complete remedy:** compare leaving the code as it is, a local correction or removal, and a larger structural change when relevant. Identify the expected improvement while preserving accepted behavior; file count and pattern preferences alone do not establish value.
- **Timing and verification cost:** consider existing tests, change and recovery risk, and actual dependencies. Explain whether acting now is worthwhile or whether the same cleanup fits better with a later related change.

File counts, `BUG` or pitfall keywords, dependency counts, and several notes naming the same file are investigation clues, not automatic priority rules. Do not convert these considerations into weights, thresholds, or a new scoring system.

Findings with the same confirmed cause may share one comparison and smallest remedy; preserve all source Feature IDs, excerpts, and paths. Keep unrelated causes distinct even when they share a file. Explain real dependencies between proposed remedies without treating them as a severity bonus.

If current evidence shows that accepted behavior is broken, separate that defect from behavior-preserving refactor candidates. Point to `engineering-change-plan` and the Bug ownership rules in `methodology/07-engineering-change.md`; an old `BUG` marker alone is insufficient. This report neither creates a Bug task nor starts its repair.

## Stage 3: report, recommend, and stop

**Entry:** Stage 2 compared the candidates.

**Output:** one transient report with a recommendation or a reason to defer, plus any material uncertainty or separate Bug finding.

Use a short table or paragraphs in the current conversation language. Give distinct candidates unambiguous references, especially when one Feature has several findings. Keep each candidate traceable to its source Feature, verbatim excerpt, and checked paths; identify all origins when findings were combined. Explain current impact, the smallest useful remedy, and why its timing differs from alternatives. Keep uncertain findings separate from the ordering and explain what evidence could change the judgment.

Recommend one candidate when its current benefit justifies the change and verification cost. Compare it with the alternatives. If none is worthwhile now, say so and explain why; an unresolved improvement can remain valid without becoming a current task. Do not invent a recommendation or mark deferred or uncertain findings as resolved.

After the report, wait for the user's choice under Global rules 1 and 4; do not start planning or delegate further investigation. Choosing a candidate alone is not implementation approval; retain any specific additional authorization the user actually supplies.

## Response routing

| User response | Action |
|---|---|
| Selects an ID, item number, or a refactor recommendation | Return the selected problem, evidence, proposed scope, and existing authorization to `engineering-change-plan` in `refactor` mode; implementation requires an explicitly approved scope |
| Chooses to address a separately reported behavior defect | Return it to `engineering-change-plan` for Bug ownership and scope triage; do not label the repair as refactor or start it here |
| Requests complete notes for F0YY | Read and show `docs/features/F0YY.json` notes verbatim, then ask whether to select it |
| Requests another scan filtered to category X | Re-run Stages 1–3 with X as the filter |
| Declines all candidates | Confirm that no refactor will be started and stop |
| Gives an ambiguous answer | Ask which candidate or scope the user means; do not assume a choice or manufacture a recommendation |

## Exception handling

| Condition | Required response |
|---|---|
| A record needed for the requested scan is invalid | Report its exact path, parse error and affected conclusion; do not repair it in this read-only workflow |
| Many candidates match | Lead with the comparative conclusion and summarize the remaining candidates; preserve their source references and material uncertainty without a fixed severity quota |
