---
name: project-grill-me
description: Resolve material uncertainties in game ideas, GDD drafts, delivery scope, design tradeoffs or domain terms. Settled terminology uses project-terminology; clear requests continue their authorized workflow.
---

# Project grill-me

## Scope

Resolve material uncertainties within the requested discussion scope and return a useful conclusion or reviewable choice. Read relevant facts and existing decisions before asking. Do not write files merely because a decision was made, and do not insert an interview before a clear authorized action. Settled vocabulary goes directly to `project-terminology`; this Skill is not a mandatory entry to its documentation workflow.

Follow source ownership in `methodology/01-product-doc-structure.md`. This questioning method may support initial game design or GDD drafts before Product and Features exist. Use the user's idea and constraints as inputs and keep proposals distinct from adopted design. Durable GDD authoring belongs to `design-gdd`; discussion does not bypass the design prerequisites of later planning or implementation.

## Shared questioning method

Apply this method to the user's current discussion goal, including its remaining material questions. Callers reuse question grouping, proportional depth, continuation and completion here while retaining their own scope and authority.

### Establish facts and group the current questions

Read the supplied idea or relevant GDD topics, including applicable **Design scope and boundaries** under `methodology/01-product-doc-structure.md` for game-design or delivery questions. Read applicable Product delivery scope, engineering constraints in `docs/project-rules.md`, `docs/terminology.md` when present, and only the code, Feature design or architecture records needed for the question. Reuse explicit user decisions, including confirmed constraints not yet saved. Distinguish observed implementation, approved intent, assumptions and proposals; show conflicting sources instead of silently choosing a new meaning. Missing documents that have not yet been designed are normal; follow the scope contract for reading and persistence rather than inventing exclusions.

For a discussion with several material choices, start with a brief overview of what is settled, which questions are currently known and which depend on earlier answers. This is the current picture, not a promised final question count or an exhaustive design tree. A single clear gap needs no extra overview.

Clear request: no extra question. One material gap: ask about that gap. Group related independent decisions that can already be answered into one understandable set with concrete options and recommendations. Resolve prerequisites before their dependent details, briefly identifying the topics waiting on them. Do not split a related set into repeated one- or two-question turns or impose a fixed question quota. Leave room for a custom answer without demanding unrelated choices.

Use the available question mechanism and the user's conversation language, following actual tool limits without turning them into a fixed quota for the discussion. Keep each question visibly numbered and its selectable options labeled with letters, preserving the question text so the user can answer by number and letter; allow a custom answer. An open question need not have artificial options.

### Keep discussion depth proportionate

Clarify uncertainty that would change the current goal, scope, observable behavior or a costly decision. State reasonable low-impact assumptions when they allow progress. Do not choose a material user tradeoff or treat silence as agreement. Ordinary implementation details remain Agent decisions.

Check a proposed unusual case against the confirmed scope and constraints before asking about it:

- A case excluded by those constraints needs no question. Explain the exclusion briefly only when relevant; reopen it only if the constraints change or concrete evidence contradicts them.
- A possible case that does not materially affect the current decision can be left out or briefly noted with a bounded assumption. Do not turn speculative combinations or future capabilities into a mandatory discussion branch.
- A rare but consequential case may need discussion. State its concrete trigger, the requirement or result it affects, and why resolving it now matters; recommend the smallest adequate handling. Rarity alone does not justify ignoring a credible failure of an essential requirement or an irreversible loss.

When discussing a rare or extreme case, explicitly label it as such in the user's language and distinguish evidence from a hypothetical possibility. Say when its likelihood is unknown instead of inventing a probability. Ordinary boundaries such as an empty inventory, full capacity or insufficient funds are not rare merely because they are outside the happy path. If the user explicitly requests edge-case analysis, cover that scope while preserving these distinctions.

Use a relevant concrete situation to distinguish similar concepts, without enumerating every possible case. For inventory, an item definition, an owned item and a stack need separate names only when the distinction matters. A stacking rule belongs in GDD; the short conceptual distinction may belong in terminology.

### Continue from answers and show progress

Evaluate the user's answer against the relevant facts and constraints, state what it settles and identify any material gap it leaves. Then ask the next related set of unresolved questions whose prerequisites are ready in the same response. Do not stop at an acknowledgement or wait for the user to say "continue" while useful discussion remains within the original scope.

Answer an explanation request first, then return to the remaining discussion; asking for an explanation is not acceptance of a proposal. When an earlier decision changes, revisit only the answers that depended on it and preserve unaffected decisions. Respect an explicit request to explain only, pause, finish or narrow the scope.

After substantive progress, briefly say what is settled, what remains and what the next questions will resolve. Explain newly discovered questions or changed dependencies. Known remaining items may be counted, but do not invent a fixed total or a completion percentage. Keep this orientation in the conversation; do not create round counters, confidence scores, question ledgers, state files or formatting checks.

### Finish against the discussion goal

An answered subquestion does not complete the whole discussion. Finish when the current scope is clear enough for the requested result or next step, with material choices resolved, explicitly deferred by the user or identified as needing evidence that discussion cannot supply. Do not manufacture further questions or require a fixed final approval phrase.

State whether the requested discussion is complete, still awaiting a user choice, or limited by missing facts or validation. Summarize the useful conclusion and any remaining dependency; do not present a missing decision or untested hypothesis as resolved. Continue independent work still authorized, and return to the owning task when its next step is ready.

Game-design discussion needs neither a ready Godot environment nor a detailed Product. Before preparing durable wording, resolve `document_language` through `methodology/05-document-language.md`; this is not a prerequisite for ordinary conversation.

## Finish in the right place

For discussion only, return the conclusion, its important reason and any remaining decision in ordinary prose. Identify useful confirmed conclusions that remain unsaved so they are not mistaken for project source content. Do not create a document or planning handoff merely to close the discussion.

When the current request already authorizes subsequent work, return settled answers, relevant sources and remaining uncertainty to its coordinator so that work continues. Use `design-gdd` for initial game design and GDD rule changes, `design-balance` for numeric design within its boundary, `product-author` for Product delivery scope, `project-terminology` for meaning-preserving definitions, or the appropriate entry in `methodology/00-overview.md` for other work. The destination owns durable writing and its completion rules; do not ask again merely because the Skill changes. Technical structure and decision records follow `methodology/10-architecture-overview.md` within that work's authorization. Do not manufacture Product, Features or ADRs to conclude a conversation.

## Reuse inside scoped design work

`design-gdd`, `design-balance`, `product-spec-elicitor` and `design-audio-asset-spec` may reuse the shared questioning method above while retaining their own ownership and writing contracts. They return to their existing caller. Reading this method does not start another clarification workflow or call the standardizer recursively.

Inspired by Matt Pocock's `grill-me` questioning approach; adapted for this Godot project's source ownership and authorization boundaries.
