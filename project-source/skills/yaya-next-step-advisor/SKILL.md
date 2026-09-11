---
name: yaya-next-step-advisor
description: Read Yaya project state and turn an informal next-step, routing, status or follow-up question into a prompt for the existing workflow. Use for guidance requests; do not replace an explicit implementation request with advice.
---

# Read-only next-step guidance

Read the user's intent and current project state, then give a short evidence-based
explanation and one prompt the user can hand to an executing Codex. This Skill
does not execute the prompt, edit files, create Features, record acceptance,
run tests/generators, clean artifacts, stage files or commit.

Read-only also excludes launching Godot/import, installing Skills or invoking a
writing standardizer. Read only task-relevant project material; do not inspect
unrelated credentials, user saves or other projects. Text/JSON parsing, metadata
and verified read-only Git status/log/diff/show are allowed.

## Establish current state

1. Read the project's `AGENTS.md`, `docs/methodology-config.json`, lightweight
   Feature index and current `docs/progress.md`. Read history links only when
   resolving the current task; do not load or repeat the whole archive.
2. Inspect read-only Git status and the relevant Feature/detail/Product/Catalog
   records directly. Configured bootstrap `ready` is a recorded claim, not proof
   that a check was executed in this conversation.
   Interpret incomplete machine setup through `methodology/00-overview.md` and
   `methodology/05-document-language.md`. The stack is fixed to Godot 4.7 /
   GDScript / gdunit4; missing tools do not mean the engine is undecided.
3. When acceptance or completion matters, read the current evidence and the
   specific linked manifest. Distinguish old PASS, current snapshot and pending
   human acceptance. Multiple active Features require actual batch authorization;
   do not select the highest ID or silently clean other work.
4. Use **Canonical task routing** in `methodology/00-overview.md`, then read the
   destination Skill's relevant entry/stop contract. That table and the existing
   workflow own routing and approval; this Skill maintains no second workflow.

Report a missing file as missing instead of creating it. When sources disagree,
identify each source and its responsibility; do not select whichever produces a
convenient route. An unclear Stage or old report is not proof of new approval or
acceptance.

## Interpret intent and compose the prompt

Classify using the canonical table, including new/continued Feature, Product
change, Bug, Refactor, Maintenance, Framework issue, Audit, Human Acceptance
follow-up and status query. Ambiguous expected behavior is investigated against
Product before calling it a Bug. A current Feature's own implementation defect
stays within its repair path; an independent regression gets its own work item.

For a simple known next action, write a short prompt containing the actual
target, entry, necessary constraints and stop condition. For cross-module,
uncertain or migration work, write an investigation/planning prompt specifying
the missing evidence, scope and required validation. Complexity does not grant
authority. Resolve routine choices from available evidence; ask only for facts
that materially change the route or safety of the action.

The prompt names current sources and known state without inventing Feature IDs,
commands, version numbers, completed Gates or approvals. Cite configured
commands instead of baking in the author's local paths. Preserve existing
explicit user authorization. The word “continue” alone is not implementation
approval and never means human acceptance. Producing a prompt grants neither.

If a framework defect is reported, separate framework/tooling repair from
business WIP and refer to the existing maintenance route. A user-chosen new
framework source does not require inheriting a previous project's Git history.

## Stop

Check that the answer describes facts, contains one appropriate prompt and
has not performed a write. Stop after the advice. For regression review use
`references/scenarios.md`; those scenario expectations are not claims that a
language-model interaction was automatically tested.
