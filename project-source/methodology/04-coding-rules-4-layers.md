# 04 - Project rules and engineering rule ownership

This document keeps its historical filename for workflow compatibility. The current architecture is responsibility-based; it is not an independent four-layer override system.

## Responsibilities

The repository uses these rule boundaries:

```text
docs/project-rules.md
  project-wide constraints, collaboration and general design principles

AGENTS.md
  root project router and repository execution instructions

agent-rules/00-core/
  global engineering invariants and rule precedence

agent-rules/<specialized module>/
  concrete Godot, GDScript, and domain semantics for that module
```

`methodology/` defines Product and Feature workflow, Test Impact Review, traceability, human acceptance, and completion gates. It does not become a second source for concrete engine or language behavior.

## `docs/project-rules.md`

The generated Project Rules document is the project-level rule entry for every Product, Feature, design and implementation. It separates mandatory constraints from recommendations and review conditions using the existing `[MUST]`, `[PREFER]` and `[REVIEW]` meanings. An ADR, Product or Feature design does not by itself grant an exception. Follow the Core conflict protocol and external instruction precedence rather than inventing a new total ordering of all documents.

It is the stable home for:

- confirmed long-lived constraints that span Products/Features, including product boundaries and architecture invariants;
- collaboration expectations and human-control boundaries;
- stack-independent workflow constraints;
- general architecture, dependency, state, data, error-handling, and performance principles;
- a short orientation to the repository rule sources.

It must not copy the current Environment Bootstrap status, executable paths, tool versions, or concrete Godot/GDScript rules. Those facts belong to the authoritative configuration or routed rule documents.

Keep enough scope and rationale to apply each project constraint. Domain terms belong in `docs/terminology.md`; game-design behavior belongs in `docs/gdd/`; delivery boundaries belong in Product; current structure belongs in architecture documentation; costly technical tradeoffs belong in ADRs when warranted. Do not turn local Feature choices into global restrictions or prefill a blank project with unconfirmed offline, platform or save-compatibility promises.

## Rule loading

An agent loads the applicable rules in this order:

1. Read the root `AGENTS.md` and identify the affected domains. Read applicable `docs/project-rules.md` constraints before defining Product intent, decomposing Features or choosing an implementation. Reuse unchanged reading; status-only questions need not load every engineering rule.
2. Use `agent-rules/00-core/README.md` to select the concrete documents and sections relevant to the current decision or change.
3. Read each affected specialized module README and follow its topic conditions. Load applicable sections, not every document in the module. A module's `validation.md` is applied whenever that module is affected.
4. Apply the core precedence protocol. A specialized rule may refine behavior inside its delegated scope, but may not silently weaken a core invariant.
5. Report a real contradiction instead of selecting one source silently.

The README files are the routing authority for concrete documents. Reuse already read, unchanged rules on continuation; load additional sections when scope or evidence changes. This limits reading, not the applicability of requirements. Status queries and terminology discussion do not automatically load engine rules.

### Implementing with prepared guidance

For an existing Feature using `implementation-guidance-godot`, the guidance preparer follows the routes above and explains the relevant constraints with source links in the existing Feature design contract. When an advisor was explicitly requested, the main Agent can reuse its background investigation without reproducing all of it. The implementing Agent still reads the guidance, the key applicable original rule sections governing its edits and validation, and the actual code, interfaces, callers and resource consumers needed for the change. Guidance narrows retrieval; it does not replace governing sources or remove an applicable obligation. Distinguish direct inspection from findings received from the advisor.

Before dependent implementation or resumption, compare the guidance with the actual checkout and relevant committed or uncommitted changes. Revisit affected sources when the goal, rules, code, interfaces, consumers or target-version facts change, when actual behavior contradicts the guidance, or when a missing dependency appears. Load additional routed rules where those facts require them; do not repeat unrelated background reading. Governing-source changes affecting the Feature's contract still follow the existing synchronization route before dependent work.

The main Agent handles ordinary implementation choices within the approved design. For a material deviation, check the original sources and resolve any missing decision; consult the advisor only within the explicit delegation authorization. A proposed design cannot waive a rule, change AC or establish verification or human acceptance. Final scope checks and evidence freshness remain governed by the execution loop, including the Feature design's existing snapshot participation.

## Stack-independent architecture

Use the logic/presentation responsibility model and document relationships in `docs/game-organization.md` to interpret the game's organization; the model does not prescribe physical directories or a communication mechanism.

The following principles belong in `docs/project-rules.md` because they do not depend on a particular engine or programming language:

- distinguish ownership of game rules and business state from presentation and its local display state, choosing communication mechanisms to fit the actual collaboration;
- make meaningful state transitions explicit with a model appropriate to their complexity;
- keep gameplay orchestration within logic responsibilities and feedback sequencing within presentation responsibilities, and explain their actual assembly and connections without requiring a separate control layer;
- prefer composition and explicit dependency passing over hidden global access;
- drive adjustable behavior from data or focused configuration;
- keep core rules as independent and testable as the project allows;
- define serializable data for confirmed saving, replay, transfer or diagnostic needs;
- distinguish expected failure from exceptional failure and do not silently swallow errors;
- measure before introducing performance complexity.

Use a Command or another focused abstraction when it removes real complexity from a non-trivial action. Do not impose a pattern where a small pure function, an existing project convention, or a direct implementation is clearer.

Organize code around cohesive responsibilities and domain boundaries. File length, complexity, and other numeric limits belong to the project's machine-readable validation configuration. They are evidence for review, not a universal line-count rule or an automatic split authorization.

## Contextual project knowledge

`docs/knowledge/` stores contextual evidence from actual project tasks, not another source of mandatory engineering rules. Use the [knowledge README](../docs/knowledge/README.md) for lookup and entry maintenance.

An experience may be useful only in this project's particular conditions and still deserve a note. Stable prescriptive guidance requires the existing authority under [incremental rule maintenance](#incremental-rule-maintenance); recording knowledge does not authorize rule promotion.

## Evolution and rule promotion

Keep concrete framework and language learnings in the appropriate `agent-rules/<module>/` source after explicit approval. Keep incident-specific learning in Feature notes or design, and reusable explanatory knowledge in its own topic. Promote only reusable, prescriptive guidance under the incremental maintenance contract below; Project Rules is not an incident log.

When a change would move a rule between these boundaries, inspect ownership and report the boundary change before editing. Do not create a parallel concrete rule authority to avoid the existing router.

## Incremental rule maintenance

The Agent actively checks for useful additions, amendments and removals during Product/design work and at the Stage 3 documentation checkpoint. Stage 1 surfaces rules affecting the proposal; Stage 2 records already approved changes; Stage 3 resolves newly discovered material issues before dependent implementation and final verification. Bug Guardrails from Stage 5.5 use the same contract. If no change is proposed, do not produce a report or placeholder. This is workflow judgment, not a Hook or automatic rule generator.

Before writing any project-rule addition, deletion or edit, output a self-check report in the conversation. The same contract applies when a candidate belongs in `agent-rules` rather than `project-rules.md`; moving it does not bypass review. One report may cover a batch but must account for every changed rule. Even wording/link-only edits get a brief report stating unchanged meaning, strength and scope.

| Report item | Required explanation |
| --- | --- |
| Rule and operation | Identify the rule/source and whether it is added, amended or removed. |
| Before and after | Show the original and proposed wording; identify an absent original or deleted text explicitly. |
| Reason and evidence | State the actual need, confirmed decision and available evidence; separate facts from inference. |
| Project-level value and owner | Explain reuse beyond this Feature and why this belongs in Project Rules, a specialized rule, architecture, ADR or local design. |
| Scope and strength | State applicability, MUST/PREFER/REVIEW and any explicit exception; expose semantic changes. |
| Duplication and conflicts | Check existing coverage and conflicts with rules, Product and accepted decisions. |
| Impact and handling | Identify affected Product, Features, implementation and verification, or explain why none needs changing. |
| Conclusion and authority | Recommend adoption, revision or rejection; distinguish decisions already authorized from those still required. |

For deletion, explain why the protected concern no longer applies or what now protects it. Reuse explicit decisions and documentation authority: persisting an already agreed constraint or a meaning-preserving edit needs no repeated approval. New restrictions, removals and changes of meaning, strength, scope or exceptions require an explicit decision covering that change. A general Feature implementation request does not authorize constitutional changes. Cost, existing style or a local implementation convenience cannot alone waive a MUST. Stop only affected work when a real conflict is unresolved.

After approval, update the owning rule and affected references incrementally; merge duplicates instead of only appending. Assess existing GDD, Product and planned/completed Features through `feature-sync` where rule changes affect their contracts. During an active Feature, retain its task context and record necessary follow-up scope; supporting synchronization remains part of that authorized work and preserves its unfinished changes. Resolve current conflicts and committed-source prerequisites before dependent plan writes, and complete authorized downstream synchronization before the next affected Feature.

Workflow changes do not retroactively rewrite historical approvals or evidence. State when an approved change applies, preserve completed history, and reassess current design/tests where applicable; a blanket 'next Feature only' policy cannot silently exempt current work from a newly confirmed project hard constraint. Final rule/design edits precede Stage 4 when possible. Later changes must satisfy the existing source-freshness, verification and applicable acceptance requirements.

Keep the full self-check in the conversation by default. Keep durable local rationale in Feature design, important cross-Feature tradeoffs in an ADR, necessary rule interpretation with the rule and exact change history in Git. Progress holds only pending decisions/links. An independent rule-maintenance task needs no artificial Feature. Save a separate report file only when explicitly requested or needed for an agreed handoff; do not create a rule registry or duplicate history. After writing, compare the actual diff with the report and state real validation and remaining work. This is author self-check, not independent review or execution evidence.
