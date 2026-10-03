# 04 · Project rules

This document defines what `docs/project-rules.md` holds, how the rule sources divide their work, and how project rules are added, changed or removed.

## Responsibilities

The repository uses these rule boundaries:

```text
docs/project-rules.md
  project-wide development constraints, collaboration and engineering principles

AGENTS.md
  root project router and repository execution instructions

agent-rules/00-core/
  global engineering invariants and rule precedence

agent-rules/<specialized module>/
  concrete Godot, GDScript, and domain semantics for that module
```

`methodology/` defines the Product and Feature workflow, Test Impact Review, traceability, human acceptance and completion gates. It does not become a second source for concrete engine or language behavior.

## `docs/project-rules.md`

`docs/project-rules.md` is the project-level entry for engineering rules. It applies to every relevant Product, Feature, design and implementation.

- It separates mandatory constraints from recommendations and review conditions, using the `[MUST]`, `[PREFER]` and `[REVIEW]` meanings from `agent-rules/00-core/rule-precedence-and-routing.md`.
- An ADR, Product or Feature design does not grant an exception by itself.
- Conflicts follow the Core conflict protocol and external instruction precedence. Do not invent a total ordering of all documents.

The file holds:

- confirmed development constraints that span Products or Features, including dependency restrictions and architecture invariants;
- collaboration expectations and human-control boundaries;
- workflow constraints that do not depend on the engine or language;
- general architecture, dependency, state, data, error-handling and performance principles;
- a short orientation to the repository rule sources.

Keep enough scope and rationale with each constraint to apply it. Do not turn a local Feature choice into a global restriction, and do not prefill a blank project with unconfirmed technical promises.

The file does not copy the current Environment Bootstrap status, executable paths, tool versions or concrete Godot and GDScript rules. Those facts stay in the configuration or the routed rule documents. Other content belongs elsewhere:

| Content | Owner |
| --- | --- |
| Game-design scope, exclusions and version boundaries, even long-lived or cross-system ones | GDD [Design scope and boundaries](01-product-doc-structure.md#design-scope-and-boundaries); link it instead of copying it |
| Domain terms | `docs/terminology.md` |
| Local game rules | Their GDD topics |
| Delivery boundaries | Product |
| Current structure | Architecture documents under [10 · Architecture overview](10-architecture-overview.md) |
| Costly technical tradeoffs | ADRs, when the [ADR conditions](10-architecture-overview.md#architecture-decision-records) hold |

The stack-independent design defaults, such as separating game authority from presentation, explicit state transitions, composition, explicit dependencies, data-driven tuning, error handling and measuring before optimizing, are maintained in [`docs/project-rules.md`](../docs/project-rules.md) Part 2. Use `docs/game-organization.md` to interpret the logic and presentation responsibilities; that model does not prescribe directories or a communication mechanism.

## Rule loading

Load rules through the root `AGENTS.md` (**Engineering rule routing**) and [`agent-rules/00-core/README.md`](../agent-rules/00-core/README.md), reading only the matching sections and each affected module's `validation.md`. Resolve real conflicts with the Core precedence protocol in `agent-rules/00-core/rule-precedence-and-routing.md`.

## Implementing with prepared guidance

When an approved Feature uses `implementation-guidance-godot`, the guidance follows the rule routes above and cites its sources in the Feature design. Guidance narrows what to read; it does not replace the sources or remove an obligation.

- **The implementing Agent still reads** the guidance, the key original rule sections for its edits and validation, and the actual code, interfaces, callers and resource consumers involved. It distinguishes what it inspected directly from what the advisor reported.
- **Before dependent implementation or resumption,** compare the guidance with the actual checkout and relevant changes. Revisit the affected sources when the goal, rules, code, interfaces, consumers or target-version facts change, when actual behavior contradicts the guidance, or when a dependency is missing. Source changes that affect the Feature's contract go through `feature-sync` first.
- **Deviations:** the main Agent makes ordinary implementation choices within the approved design. For a material deviation, check the original sources and resolve the missing decision; consult the advisor again only within the explicit delegation. A proposed design cannot waive a rule, change AC, or establish verification or human acceptance.

Final scope checks and evidence freshness follow [03 · Execute loop](03-execute-loop.md).

## Contextual project knowledge

`docs/knowledge/` stores contextual evidence from actual project tasks. It is not a source of mandatory engineering rules. Use the [knowledge README](../docs/knowledge/README.md) for lookup and entry maintenance.

An experience may be useful only under this project's particular conditions and still deserve a note. Recording knowledge does not authorize rule promotion; stable prescriptive guidance goes through [incremental rule maintenance](#incremental-rule-maintenance).

## Evolution and rule promotion

Each kind of learning has one place:

- concrete framework and language learning: the matching `agent-rules/<module>/` source, after explicit approval;
- brief incident learning: Feature notes;
- implementation decisions and their rationale: the Feature design;
- reusable explanatory knowledge: its own topic under `docs/knowledge/`.

Promote only reusable, prescriptive guidance, under the contract below. Project Rules is not an incident log.

When a change would move a rule between these boundaries, check ownership and report the boundary change before editing. Do not create a parallel rule source to avoid the router.

## Incremental rule maintenance

This section is the single source for when rule changes are proposed and how they are approved and written.

### When to check

The Agent looks for useful additions, amendments and removals at these points:

- during Product and design work;
- Stage 1 of `feature-execute`: surface rules that affect the proposal;
- Stage 2: record changes that are already approved;
- Stage 3 documentation checkpoint: resolve newly discovered material issues before dependent implementation and final verification;
- Stage 5.5 for a Bug: assess the Guardrail under [Bug-learning promotion](07-engineering-change.md#bug-learning-promotion);
- task completion: check whether reusable prescriptive learning is already covered by `agent-rules/`, and propose one generalized rule with its target module only when valuable guidance is missing.

Do not create a rule for every defect, duplicate an existing rule or promote Product detail. If no change is proposed, do not produce a report or placeholder. This is workflow judgment, not a Hook or an automatic rule generator.

### Self-check report

Before writing any project-rule addition, deletion or edit, output a self-check report in the conversation.

- The same report applies when a candidate belongs in `agent-rules` instead of `project-rules.md`; moving it does not bypass review.
- One report may cover a batch but accounts for every changed rule.
- A wording-only or link-only edit still gets a brief report stating that meaning, strength and scope are unchanged.

| Report item | Required explanation |
| --- | --- |
| Rule and operation | Identify the rule or source and whether it is added, amended or removed. |
| Before and after | Show the original and proposed wording; state explicitly when there is no original or the text is deleted. |
| Reason and evidence | State the actual need, confirmed decision and available evidence; separate facts from inference. |
| Project-level value and owner | Explain reuse beyond this Feature and why this belongs in Project Rules, a specialized rule, architecture, an ADR or local design. |
| Scope and strength | State applicability, MUST, PREFER or REVIEW, and any explicit exception; expose semantic changes. |
| Duplication and conflicts | Check current coverage and conflicts with rules, Product and accepted decisions. |
| Impact and handling | Identify affected Product, Features, implementation and verification, or explain why none needs changing. |
| Conclusion and authority | Recommend adoption, revision or rejection; distinguish decisions already authorized from those still required. |

For a deletion, explain why the protected concern no longer applies or what now protects it.

### Approval

- Persisting an already agreed constraint or making a meaning-preserving edit needs no repeated approval.
- New restrictions, removals and changes of meaning, strength, scope or exceptions require an explicit decision covering that change.
- A general Feature implementation request does not authorize rule changes.
- Cost, current style or local implementation convenience cannot alone waive a MUST.
- When a real conflict is unresolved, stop only the affected work.

### Writing and follow-up

After approval, update the owning rule and the affected references. Merge duplicates instead of appending.

- Assess the GDD, Product and planned or completed Features through `feature-sync` where the rule change affects their contracts.
- During an active Feature, keep its task context and record the needed follow-up scope. The supporting synchronization is part of that authorized work and preserves its unfinished changes.
- Resolve current conflicts and committed-source prerequisites before dependent plan writes. Complete authorized downstream synchronization before the next affected Feature.

Workflow changes do not retroactively rewrite earlier approvals or evidence. State when an approved change applies, keep completed history, and reassess current design and tests where applicable. A blanket "next Feature only" policy cannot exempt current work from a newly confirmed hard constraint. Make final rule and design edits before Stage 4 when possible; later changes meet the normal source-freshness, verification and acceptance requirements.

### Where records go

- The full self-check stays in the conversation by default.
- Local rationale goes in the Feature design, important cross-Feature tradeoffs in an ADR, and necessary rule interpretation with the rule. Git holds the exact change history.
- Progress holds only pending decisions and links.
- An independent rule-maintenance task needs no artificial Feature.
- Save a separate report file only when explicitly requested or needed for an agreed handoff. Do not create a rule registry or a duplicate history.

After writing, compare the actual diff with the report and state the real validation and remaining work. This is an author self-check, not independent review or execution evidence.
