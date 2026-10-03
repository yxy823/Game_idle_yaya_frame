---
name: loop-me-godot
description: Design a reusable way to handle recurring or anticipated Godot project work identified by the user. Clarifies triggers, inputs, decisions and delivery, and compares existing entries, Skills, documentation and tools. Historical task lessons belong to retro-godot; this entry does not automatically implement or schedule a workflow.
---

# Design recurring Godot project work

Help the user decide how a named kind of repeated work should be handled next time. The work may already recur or be anticipated; no history of failure is required. Use at any relevant point in project development, under the existing GDD prerequisite and authority in `methodology/01-product-doc-structure.md`. This is not a new Stage or a mandatory planning step.

Use [retro-godot](../retro-godot/SKILL.md) for explaining what happened in actual development and identifying lessons. This Skill instead designs future handling of the user's specified recurring activity; do not widen it into reviewing all tasks or personal habits.

## Understand the repeated activity

Reuse the current goal, scope and decisions. For observed repetition, inspect relevant examples to separate stable inputs and judgments from per-run variation. For anticipated work, reason from expected inputs and usage, label assumptions, and do not invent past frequency or savings.

Check the project-owned Skills, relevant workflow or domain rules, documentation and commands already covering the activity. Read only materials that affect this design. Compare clearer routing, reuse, a small extension and ordinary Agent judgment before proposing a new Skill or script.

## Describe one useful run

Explain the parts needed for this activity:

- The condition that starts it, its target and the existing materials and variable inputs it needs.
- Decisions the Agent can make from evidence and choices that require the user; prepare independent work before asking, and preserve valid decisions.
- The reusable method, the owner of its detailed rules, and the conditions for reading that source.
- The result delivered and how to judge success; address interruption, recovery and side effects when they are relevant.

When a missing choice changes the method, use the discussion approach in [project-grill-me](../project-grill-me/SKILL.md). Group related choices and give grounded recommendations. Do not restart GDD/Product elicitation merely to design a working method or require every possible question to be settled. Ordinary implementation details remain Agent decisions.

## Choose the smallest useful home

Keep repeatable task selection and judgment in a focused Skill, detailed rules in their project-owned authoritative source, and deterministic repeated operations in a tool only when its maintenance cost is justified. A short invocation or a clearer reference may be enough. Different situations can reuse the same ability without sharing one task's authorization or completion conditions.

For a proposed project-tool implementation, return to `methodology/07-engineering-change.md` and its existing task owner. For knowledge or stable constraints, use the applicable ownership rules in `methodology/04-project-rules.md` and `docs/knowledge/README.md`. Changed game intent belongs to the existing Product owner. A need to improve distributed framework materials is a recommendation for the framework-maintenance task, not permission to fetch or edit another repository.

Deliver the proposed method in the conversation: concrete need, entry, inputs and outputs, key decisions, ownership of details, and remaining adoption choices. No additional mechanism may be the best result. Walk through a relevant example or a clearly labelled future case; static reasoning is not execution evidence.

Do not automatically create workflow directories, personal profiles, reports, state ledgers, schedules or approval checkpoints. A design-only request ends with the proposal. Already authorized implementation continues through its existing owner with the task's validation, human acceptance and Git requirements. Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).

Inspired by Matt Pocock's `loop-me` idea of designing reusable handling for recurring activities; rewritten for Godot project work and its existing ownership and authorization boundaries.
