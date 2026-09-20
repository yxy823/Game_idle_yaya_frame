---
name: project-clarifier
description: Clarify a project idea, design tradeoff, ambiguous requirement, or domain term through a focused discussion. Use when the user wants to think a proposal through, asks for clarification, or wants settled project vocabulary documented. Supports conversation only and authorized terminology documentation; does not require Product initialization or create Features for discussion.
---

# Project clarifier

## Choose the needed outcome

Read the request and existing authorization before choosing an outcome. Asking
depth and document output are independent decisions:

- **Discussion:** resolve the current question and summarize the useful result
  in the conversation. Do not write files merely because a decision was made.
- **Document settled vocabulary:** clarify only the remaining gaps, then pass
  confirmed definitions and the authorized write scope to
  `product-standardizer`. Follow the terminology contract in
  `methodology/01-product-doc-structure.md`.

An explicit request to write already authorizes the specified documentation;
do not ask again just to select a mode. A request to discuss alone does not.
If a clear action was requested, continue its existing authorized workflow
without inserting an interview. This Skill is not a mandatory stage before
every task.

## Shared questioning method

1. **Find facts first.** Read relevant existing Product, applicable project constraints in `docs/project-rules.md`, `docs/terminology.md` when
   present, and only the code, Feature design or architecture records needed for the question.
   Reuse explicit user decisions. Distinguish observed implementation,
   approved intent, assumptions and proposals; show conflicting sources instead
   of silently choosing a new meaning. Missing optional documents are normal.
2. **Ask the smallest useful question.** Clear request: no extra question. One
   material gap: ask about that gap. A broader design: work in small rounds,
   resolving prerequisites before dependent details. A few brief, independent
   questions can share a round. Offer concrete options and a reasoned
   recommendation when useful, leaving room for a custom answer.
3. **Spend questions on consequences.** Clarify uncertainty that would change
   the current goal, scope, observable behavior or a costly decision. State
   reasonable low-impact assumptions when they allow progress. Do not choose
   a material Product tradeoff for the user or treat silence as agreement.
4. **Use a concrete situation.** To distinguish similar concepts, walk through
   a relevant example and ask what differs. For inventory, an item definition,
   an owned item and a stack need separate names only when the distinction
   matters. A stacking rule belongs in Product; the short conceptual
   distinction may belong in terminology. Do not enumerate every possible case.
5. **Follow corrections locally.** When an earlier decision changes, revisit
   only the answers that depended on it. Preserve unaffected decisions and
   explain the consequence that now needs resolving.
6. **Stop at a useful result.** Once the current question is answered, or the
   goal, scope, key behavior and way to judge the outcome are clear enough for
   the requested next step, summarize them briefly. Surface any material open
   choice; do not demand an exhaustive design tree or a fixed final approval
   phrase. Previously confirmed scope and decisions remain valid.

Use the available question mechanism and the user's conversation language.
Do not create round counters, confidence scores, question ledgers, state files,
or formatting checks. Discussion in an empty project needs neither a ready
Godot environment nor a complete Product. Before preparing durable wording,
resolve `document_language` through `methodology/05-document-language.md`;
this is not a prerequisite for ordinary conversation.

## Finish in the right place

For discussion only, return the conclusion, its important reason and any
remaining decision in ordinary prose. No document or planning handoff is needed.

For authorized terminology documentation, read the terminology contract and
propose the smallest edit. Reuse a clear local Product definition where it is
sufficient; project vocabulary needed across modules or Features belongs in
the optional `docs/terminology.md`. Create it only for useful, confirmed content.
Keep one owning definition and link to it; do not collect chat history, pending
ideas, task status, detailed behavior or Godot implementation choices there.

Pass the proposed definitions, relevant source locations, confirmed decisions,
remaining uncertainty and whether meaning or behavior changes to
`product-standardizer`. It alone persists Product and terminology wording.
Terminology maintenance that preserves meaning and behavior does not require
Product initialization or Feature synchronization. A substantive Product change
uses the normal Product and planning route. Do not silently rename code or
migrate data to match a chosen term.

If the user instead authorizes formal requirements or technical work, return
to the appropriate entry in `methodology/00-overview.md` with the settled
answers. Technical structure and decision records follow
`methodology/10-architecture-overview.md` within that work's authorization.
Do not manufacture Product, Features or ADRs to conclude a conversation.

## Reuse inside Product elicitation

`product-init-elicitor`, `product-spec-elicitor` and `product-audio-sketcher` reuse the shared
questioning method above while retaining their Product-specific draft/patch
contracts. They return to their existing caller. Reading this method does not
start another clarification workflow or call the standardizer recursively.
