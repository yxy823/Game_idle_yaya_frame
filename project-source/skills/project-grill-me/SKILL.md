---
name: project-grill-me
description: Resolve material uncertainties in game ideas, GDD drafts, delivery scope, design tradeoffs or domain terms. Settled terminology uses project-terminology; clear requests continue their authorized workflow.
---

# Project grill-me

## Scope

Resolve the unresolved question and return a useful conclusion or reviewable choice. Read relevant facts and existing decisions before asking. Do not write files merely because a decision was made, and do not insert an interview before a clear authorized action. Settled vocabulary goes directly to `project-terminology`; this Skill is not a mandatory entry to its documentation workflow.

Follow source ownership in `methodology/01-product-doc-structure.md`. This questioning method may support initial game design or GDD drafts before Product and Features exist. Use the user's idea and constraints as inputs and keep proposals distinct from adopted design. Durable GDD authoring belongs to `design-gdd`; discussion does not bypass the design prerequisites of later planning or implementation.

## Shared questioning method

1. **Find facts first.** Read the supplied idea or relevant GDD topics, any applicable Product delivery scope, project constraints in `docs/project-rules.md`, `docs/terminology.md` when present, and only the code, Feature design or architecture records needed for the question. Reuse explicit user decisions. Distinguish observed implementation, approved intent, assumptions and proposals; show conflicting sources instead of silently choosing a new meaning. Missing documents that have not yet been designed are normal.
2. **Group useful questions.** Clear request: no extra question. One material gap: ask about that gap. For a broader design, collect the related independent decisions into one understandable round with concrete options and recommendations; resolve prerequisites before their dependent details. Avoid repeatedly asking one or two questions from the same topic. Leave room for a custom answer without demanding unrelated choices.
3. **Spend questions on consequences.** Clarify uncertainty that would change the current goal, scope, observable behavior or a costly decision. State reasonable low-impact assumptions when they allow progress. Do not choose a material Product tradeoff for the user or treat silence as agreement.
4. **Use a concrete situation.** To distinguish similar concepts, walk through a relevant example and ask what differs. For inventory, an item definition, an owned item and a stack need separate names only when the distinction matters. A stacking rule belongs in GDD; the short conceptual distinction may belong in terminology. Do not enumerate every possible case.
5. **Follow corrections locally.** When an earlier decision changes, revisit only the answers that depended on it. Preserve unaffected decisions and explain the consequence that now needs resolving.
6. **Stop at a useful result.** Once the current question is answered, or the goal, scope, key behavior and way to judge the outcome are clear enough for the requested next step, summarize them briefly. Surface any material open choice; do not demand an exhaustive design tree or a fixed final approval phrase. Previously confirmed scope and decisions remain valid.

Use the available question mechanism and the user's conversation language. Keep each question visibly numbered and its selectable options labeled with letters, preserving the question text so the user can answer by number and letter; allow a custom answer. Do not create round counters, confidence scores, question ledgers, state files, or formatting checks. Game-design discussion needs neither a ready Godot environment nor a detailed Product. Before preparing durable wording, resolve `document_language` through `methodology/05-document-language.md`; this is not a prerequisite for ordinary conversation.

## Finish in the right place

For discussion only, return the conclusion, its important reason and any remaining decision in ordinary prose. No document or planning handoff is needed.

When the current request already authorizes subsequent work, return settled answers, relevant sources and remaining uncertainty to its coordinator so that work continues. Use `design-gdd` for initial game design and GDD rule changes, `design-balance` for numeric design within its boundary, `product-author` for Product delivery scope, `project-terminology` for meaning-preserving definitions, or the appropriate entry in `methodology/00-overview.md` for other work. The destination owns durable writing and its completion rules; do not ask again merely because the Skill changes. Technical structure and decision records follow `methodology/10-architecture-overview.md` within that work's authorization. Do not manufacture Product, Features or ADRs to conclude a conversation.

## Reuse inside scoped design work

`design-gdd`, `design-balance`, `product-spec-elicitor` and `design-audio-asset-spec` may reuse the shared questioning method above while retaining their own ownership and writing contracts. They return to their existing caller. Reading this method does not start another clarification workflow or call the standardizer recursively.

Inspired by Matt Pocock's `grill-me` questioning approach; adapted for this Godot project's source ownership and authorization boundaries.
