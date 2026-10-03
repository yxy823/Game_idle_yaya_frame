---
name: wayfinder-godot
description: Resolve linked uncertainties blocking an existing Godot project goal, following their actual dependencies. Choose discussion, factual research, scoped prototypes or comparable implementations as needed; clear tasks continue their existing owner without this entry.
---

# Find a workable path through linked Godot questions

Use this method when several material unknowns affect one another and solving one changes what can be decided next. It can support discussion, planning or implementation without adding a Stage or a mandatory entry before ordinary work. Apply **GDD prerequisite and authority** in `methodology/01-product-doc-structure.md` to the actual destination: initial game-design questions return to [design-gdd](../design-gdd/SKILL.md), while dependent planning, engineering exploration and implementation need the relevant actual GDD. This method does not fill missing design through technical assumptions.

## Establish the goal and the relevant unknowns

Reuse the current request, confirmed decisions, exclusions and concrete authorization. Identify what this effort should achieve and what kind of result the user requested: conclusions, a choice supported by evidence, a bounded experiment, or continued implementation. Read relevant existing sources and task records, not a fixed document bundle or every past discussion.

Separate approved intent, observed implementation, evidence, assumptions and unresolved choices. Describe the questions that currently change the result and which answers they depend on. Keep still-vague in-scope concerns tentative until their prerequisites make them useful; do not pre-plan every future branch or restore excluded work through exploration.

Work on questions whose prerequisites are available. Group related independent choices for the user, and advance independent factual investigation while an answer is pending. Do not answer a material user preference on the user's behalf or proceed with work that depends on a missing decision. Once evidence or a correction arrives, revisit only affected conclusions and dependencies; preserve unaffected decisions. There is no one-question-per-conversation rule or requirement to settle every possible question before progressing.

## Select the method that can resolve the gap

Use only the applicable row; these methods are not a sequence to invoke in full.

| Missing basis for the next decision | Method and boundary |
| --- | --- |
| User preference, design boundary or consequential tradeoff | Use the [shared questioning method](../project-grill-me/SKILL.md#shared-questioning-method). Bring facts and concrete alternatives; ask only the decisions that matter, without restarting general GDD/Product elicitation. |
| An API, third-party capability or the project's actual implementation | Read the relevant local sources first. When external facts are needed, follow **External research** in `methodology/09-records-reports-and-handoff.md` for lookups, delegation to `researcher` and saved sources. Research is not permission to experiment or adopt a requirement. |
| Layout, interaction, state behavior or feasibility that discussion cannot establish | Use [prototype-godot](../prototype-godot/SKILL.md) for an authorized bounded Godot experiment. Define the question and observation needed; preserve actual human judgment and distinguish simulated behavior from the required real engine path. Discussion-only work may describe the experiment without building it. |
| Several implementations need actual comparison and would overwrite each other or require separate working directories | Set comparable goals, representative inputs and observations before building alternatives. Use [worktree-create-godot](../worktree-create-godot/SKILL.md) only when the task needs and authorizes those directories; simpler experiments can use the existing checkout. A separate checkout does not prove runtime data isolation. |
| A concrete proposal now exists and its assumptions or omissions need inspection | Use [plan-review-godot](../plan-review-godot/SKILL.md) within the requested review scope. Findings support a decision; they do not approve the proposal, implement it or create a compulsory gate. |

Recheck the current scope before a method would write records, build an experiment, run a probe or create a worktree. Reuse authority that already covers the concrete action; a discussion-only or read-only limit remains binding. If a necessary action is not permitted or a prerequisite is unavailable, identify that specific gap and continue only independent work still in scope. Do not turn the limitation into an invented result or a blanket stop on unrelated authorized work.

For example, an inventory with many items may need a design choice about search before comparing list and grid layouts. Read existing item-count constraints and implementation facts first; only build comparable prototypes if they answer the remaining question. The task's size alone is not a reason to open several worktrees.

## Preserve findings in their existing home

Keep a one-off discussion in the conversation. When authorized continuity or durable work requires records, use the relevant sections of `methodology/09-records-reports-and-handoff.md`: Progress for current state, Feature notes for reminders and navigation, the fixed Feature design for local implementation decisions, research for retained external findings, and existing report locations for actual execution evidence. Link authoritative decisions and original evidence instead of copying them into a new exploration document.

Apply **Architecture Decision Records** in `methodology/10-architecture-overview.md` for a technical decision that meets its conditions; ordinary questions do not require an ADR. Adopted technical decisions without a Feature that do not qualify use **Standalone technical decisions** in the same specification when saving is authorized. Confirmed game intent, delivery scope and professional requirements still return to their GDD/Product or specialist owner. An exploration finding alone does not authorize those writes.

Do not create an issue/ticket map, question ledger, claim state, research-only branch or parallel backlog for this method. Work without a Feature can use its existing task records; it need not manufacture a Feature or a new conversation to resolve the next question.

## Return the result and continue the owning task

Explain the current conclusion or reviewable alternatives, supporting sources and actual observations, remaining material uncertainty, and the next action with its real prerequisites. A plausible answer is not a verified result. Missing evidence or a user decision remains an explicit gap, not a resolved question.

Finish discussion-only work at its requested analytical result. When enough uncertainty is resolved for already authorized planning or implementation, return the findings to its existing owner under **Canonical task routing** in `methodology/00-overview.md` and continue that work. Do not ask for a fixed final confirmation or widen the scope because an attractive alternative appeared. Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**). Any integration of selected worktree results follows the separate [worktree-integrate-godot](../worktree-integrate-godot/SKILL.md) contract and current authority; exploration does not authorize integration or cleanup by itself.

For a single ordinary unresolved question, use [project-grill-me](../project-grill-me/SKILL.md) directly. [project-next-step-advisor](../project-next-step-advisor/SKILL.md) explains status and entry selection without advancing exploration; [loop-me-godot](../loop-me-godot/SKILL.md) designs handling for a recurring activity; [retro-godot](../retro-godot/SKILL.md) examines actual past experience. Clear authorized work continues through its existing owner without a wayfinding detour.

Inspired by Matt Pocock's `wayfinder` method of resolving decisions along their dependencies; rewritten for this Godot project's source ownership, evidence and authorization boundaries.
