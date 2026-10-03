---
name: feedback-triage-godot
description: Verify a Godot project feedback report against confirmed intent and current behavior, then identify its classification and next owner. Use when a reported missing capability or unexpected result needs checking; established defects proceed to diagnosis or their existing task.
---

# Verify and route project feedback

Return what the report means for this project: a supported defect, a changed requirement, an existing capability with a discovery/explanation problem, or an unresolved evidence gap. Apply **Feedback assessment**, **Classification boundary** and **Bug ownership and routing** in `methodology/07-engineering-change.md`; these own the assessment rules and subsequent work. Respect the existing GDD prerequisite there.

## Establish the report

Use the conversation and relevant current sources to identify the actual observation, expected result, entry/trigger and affected version. Read only the GDD, Product, professional or project-tool contract and implementation needed to resolve this report. Inspect relevant Feature/Progress history when it determines ownership or prior evidence. Reuse answered questions and current evidence; labels such as "Bug" or "missing feature" are claims to examine, not conclusions.

A read-only request permits inspection and analysis, not running Godot or writing probes. When the task authorizes reproduction, use the relevant existing verification method and preserve its real result. If reproduction is unavailable, distinguish source evidence from unverified runtime behavior rather than declaring the report false.

## Return the next useful action

Explain the classification, supporting source/observation, significant uncertainty and next owner. Where the capability already exists, give its actual entry and limits. Where evidence conflicts, show the disagreement rather than selecting the source that makes a convenient answer. A short answer may be sufficient; no report file, issue state or new Feature is required by this Skill.

For a confirmed defect whose cause needs investigation, use [bug-diagnosis-godot](../bug-diagnosis-godot/SKILL.md) within the same task. For actual changes, follow the canonical ownership table in methodology 07: current-Feature defects stay with that Feature; independent engineering work uses [engineering-change-plan](../engineering-change-plan/SKILL.md); design/professional questions return to their existing owner. Documentation-only corrections retain their normal writing scope.

This assessment does not amend intent, create a plan, mark a Feature complete or supply human acceptance. A report-checking-only request ends with the assessment and any real gap. Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
