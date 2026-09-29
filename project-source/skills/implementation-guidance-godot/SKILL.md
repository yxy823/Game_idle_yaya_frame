---
name: implementation-guidance-godot
description: Prepare or update source-linked implementation guidance for an existing Godot Feature, including engineering Features. Covers constraints, design, necessary dependency order and verification reasoning; does not implement the Feature or create one for work without a Feature.
---

# Prepare Godot Feature implementation guidance

Use this method when implementation guidance is needed for an existing Feature. Apply the GDD prerequisite and the Feature's current scope, decisions and authorization. Work without a Feature is outside this entry; return to its existing task rather than creating a Feature to obtain guidance. A simple implementation can continue through its normal owner without this method.

Paths in code spans are relative to the target project root. Read **Feature design and implementation notes (optional)** in `methodology/02-feature-list-schema.md` for the guidance content, relative source links, proposal/approval lifecycle and sole durable location. Read **Implementing with prepared guidance** in `methodology/04-coding-rules-4-layers.md` for source reading and freshness. These contracts own the details; do not create another guide, draft file, ledger or status format.

## Choose who prepares the guidance

The main Agent may use this method itself. Delegate only when the current task prompt or still-valid session authorization explicitly requests an implementation advisor. Loading this Skill, a complex Feature or a request for detailed guidance does not by itself request delegation. Otherwise the main Agent prepares the needed design through the existing Feature workflow.

When delegation is explicitly requested, use `.codex/agents/implementation-advisor.toml` with its configured model and reasoning effort. Verify that the host can actually select that role and those settings; a role file alone does not prove they took effect. Provide the actual project/checkout, existing Feature, goal, known source paths, relevant Git state and uncommitted changes, approved decisions, unresolved questions and the assignment's permissions. Let the advisor inspect the necessary background instead of reading it all twice to prepare the handoff.

If the advisor cannot start, its configured model or reasoning effort is unavailable, or its execution fails, stop this guidance assignment and the implementation or other work that depends on it. Preserve existing materials and report the actual cause, completed work and what remains. Do not switch models, silently retry with different settings or let the main Agent take over the failed assignment. A later user decision may change that scope; existing implementation authorization is not a fallback authorization.

## Prepare the proposal and resolve material questions

Follow the project's rule routes and the existing design contract. Establish the current implementation, interfaces and real consumers, then explain how applicable constraints shape this Feature's design and validation. Use the [shared questioning method](../project-grill-me/SKILL.md#shared-questioning-method) only for material missing decisions. Keep ordinary implementation details open to the implementing Agent rather than prescribing every function or edit.

A delegated advisor returns numbered questions with A/B-style choices, a recommendation and relevant tradeoffs, allowing a custom answer. The main Agent presents these questions in the current conversation's visible message body, not only in a question widget, and passes the user's answers back to the same advisor. Do not depend on direct interaction in a child-thread UI or start a new advisor for every answer. Reuse confirmed decisions; do not ask when the existing facts and authority already settle the question.

During the guidance assignment, inspect files, permitted read-only Git state and relevant external sources; plan verification without running Godot, imports, tests, prototypes or other experiments. The advisor does not edit business code, game requirements, Feature JSON, Registry, task state or acceptance, and does not commit or delegate again. Its only write exception is the assigned, approved Feature design under the lifecycle below. Missing runtime evidence remains a named verification need, not a fabricated observation.

## Return guidance to the existing Feature

Return the reviewable proposal and genuinely missing decisions to the main Agent. After the existing approval covers the design, the same delegated advisor may save only the assigned `docs/features/F0XX-design.md` under the design lifecycle in methodology 02, including its guidance-only boundary. The main Agent checks the result and owns any authorized Feature notes link, record updates and commits. Do not request the same approval again or use a saved file as proof of approval.

The main Agent reads the guidance, key applicable original rules and current code/interfaces/consumers under methodology 04. It handles ordinary implementation choices. Material deviations require checking their sources and resolving any missing decision; consult the advisor again only within the existing explicit delegation scope. Guidance does not replace authoritative requirements, verification, human acceptance or the final combined-change check.

Return to [feature-execute](../feature-execute/SKILL.md) and its current Stage when the owning task already authorizes further work; guidance-only work ends with its requested result. The advisor's check of a design it helped author is not independent review. A requested formal review keeps the separate fresh-instance contract in `methodology/12-independent-review.md`.
