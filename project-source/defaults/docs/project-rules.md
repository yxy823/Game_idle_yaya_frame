# Project rules

> Read applicable engineering constraints before revising GDD design, defining Product delivery scope, planning Features or choosing an implementation. Game-design scope and exclusions are in [Design scope and boundaries](../methodology/01-product-doc-structure.md#design-scope-and-boundaries).
>
> This file holds project-wide development constraints, collaboration expectations and general engineering principles. Concrete engine and language rules live under `agent-rules/`; see [Part 3](#part-3--project-rule-sources).

## Project-wide engineering constraints

Use the existing `[MUST]`, `[PREFER]` and `[REVIEW]` meanings from `agent-rules/00-core/rule-precedence-and-routing.md`. MUST constraints apply to every relevant Product, Feature, design and implementation. A Product, Feature design or ADR cannot silently override them. Keep each constraint's scope and necessary rationale clear; technical details remain at their owning source.

No project-specific engineering constraints have been confirmed yet. Add confirmed development constraints here when needed; do not invent technical commitments from examples. GDD owns game-design boundaries and exclusions, including long-lived ones; reference its owning passages rather than duplicating them here. Definitions belong in `docs/terminology.md`, delivery boundaries in Product and current architecture in its own documents.

Rule additions, deletions and edits follow `methodology/04-project-rules.md` **Incremental rule maintenance**, including the mandatory conversational self-check before every proposed write. Preserve existing authorization; obtain the missing decision for substantive changes. The Stage 3 documentation checkpoint checks for useful incremental updates before final verification. If no useful change is identified, do not produce a report or new rule.

---

# Part 1 · Collaboration contract

> This part defines mandatory collaboration requirements. Rule authority and conflicts follow `methodology/04-project-rules.md` and the Core precedence protocol. These requirements do not override system, developer or user instructions.

## 1.1 Collaboration discipline

1. **Avoid over-design.** Use the smallest complexity that satisfies current requirements. Do not add unused interfaces, unneeded patterns, or speculative extension points unless the user explicitly requests extensibility.
2. **Confirm before acting on ambiguity.** When requirements are unclear or have multiple reasonable interpretations, state the current understanding and ask focused questions before writing substantial code.
3. **Work in small steps.** Keep one change focused on one objective. Do not mix opportunistic refactoring into a bug fix or add behavior during a refactor.
4. **Prefer consistency over personal improvement.** Existing naming, directory structure, and established patterns are the project standard. Do not replace them merely because another approach appears more elegant.
5. **Disclose uncertainty honestly.** Mark uncertain APIs, version differences, and platform behavior as needing verification. Never invent an answer.
6. **A rejected decision stays rejected.** Do not reintroduce a design or code approach the user rejected in a slightly different form.
7. **Do not expand scope without approval.** Change only what the user and current Feature require. Report unrelated problems and let the user decide whether to address them.

## 1.2 Workflow constraints

Feature implementation uses `feature-execute` and the canonical `methodology/03-execute-loop.md`. That specification owns the Context / Rules Snapshot, authorization and continuation, acceptance, optional independent review, verification and completion. Environment preparation follows `methodology/06-project-environment.md`; test semantics follow `methodology/08-test-traceability-and-evidence.md`. Do not maintain competing Stage instructions here.

Inspect and preserve existing changes, continue work in the task's designated checkout, stage the intended scope and create eligible logical commits under `agent-rules/00-core/git-worktree-and-commits.md`.

When rules change, state their approved applicability to current and later work under the incremental maintenance contract. Do not retroactively rewrite historical approvals, and do not assume current work is exempt from a newly confirmed hard constraint.

Every placeholder file uses the `_placeholder_` prefix. Record its replacement need in the owning resource section of the UI, presentation or shared design document, and link it from the Feature AC or design that uses it; Feature notes only provide navigation.

## 1.3 Reporting requirements

Follow `agent-rules/00-core/completion-and-reporting.md` and the owning workflow's handoff. Explain material changes, actual verification and expected work left outside scope; include manual instructions only when applicable.

## 1.4 Deviating from these rules

Identify the exact rule, proposed deviation, reason and impact. Project style, migration cost or a mandatory platform convention may justify departing from a PREFER recommendation; they do not automatically waive a MUST. Unresolved mandatory conflicts follow the Core conflict protocol. A substantive rule change or exception requires explicit authority covering that choice and the self-check report above; reuse a decision already made instead of asking again.

---

# Part 2 · General design and architecture

> These are stack-independent design defaults (`PREFER`), unless a separately identified project or specialized rule makes a specific constraint mandatory. Choose patterns for an actual need; do not automatically promote a local design choice into a project hard constraint.

## 2.1 Start with a focused function or existing method

Represent an ordinary operation with clear inputs, local intermediate values and an explicit result. Split only when responsibility, reuse or readability warrants it. Doing one thing does not itself justify a new class.

Player and AI callers can reuse the same behavior API; the caller type alone does not justify a Command. Use a Command object when the current requirement needs an operation to be queued, undone, replayed, recorded or managed with an independent lifecycle. Keep only state that this lifecycle actually needs; do not promote all local variables into object fields.

## 2.2 Core architecture principles

- **Separate game authority from presentation.** Game logic owns rules, business state and valid results; presentation translates them into player feedback and may own view-local state. Apply the responsibility model and examples in `docs/game-organization.md`; concrete state-mutation and dependency rules remain in `agent-rules/10-gdscript/structure-and-dependencies.md`.
- **Make meaningful state transitions explicit.** Choose the simplest model that captures mutually exclusive states, valid transitions and entry/exit or cancellation responsibilities. An enum and a central transition function may suffice; separate state objects or nodes are useful when lifecycle, reuse or transition complexity warrants them.
- **Make collaboration explicit.** Distinguish requests, current state and one-time events/results. Gameplay orchestration belongs with game rules; feedback orchestration belongs with presentation. Connect them through suitable existing APIs, signals or a coordinator according to ownership and lifetime, without requiring a fixed control layer or event bus.
- **Prefer composition over inheritance.** Build behavior from focused components instead of a large all-purpose base-class hierarchy.
- **Drive adjustable behavior from data.** Levels, skill values, and entity parameters belong in configuration or data when changing them should not require code changes.
- **Isolate independent rules where useful.** Keep suitable calculations and rule decisions testable without the UI or engine. Preserve real Godot physics and lifecycle dependencies where the behavior needs them; engine objects do not by themselves make a responsibility presentational.
- **Pass dependencies explicitly.** Constructor or function parameters make dependencies visible and replaceable in tests.
- **Reduce what callers must know.** Keep related validation, ordering, failure handling and state coordination with a cohesive owner. Assess an interface by all the knowledge needed to use it correctly, including configuration and lifetime constraints; fewer files or public methods alone do not establish a better design.
- **Serialize state for confirmed uses.** When saving, replay, transfer or diagnostics requires serialization, define a representation for the data that use needs. Other runtime state follows its ownership and lifecycle; keep core data clear and rules independently testable.

## 2.3 Pattern guide

Choose a pattern only when it solves a present problem more simply than an ordinary function or the existing project structure.

| Situation | Preferred pattern |
| --- | --- |
| An ordinary action transforms inputs into an output | Focused function or existing method |
| Several systems react to one event | Observer or event bus |
| Behavior depends on legal state transitions or entry/exit responsibilities | Simplest explicit state model |
| Operations need queuing, undo, replay, recording or an independent lifecycle | Command |
| Measured allocation cost causes a performance problem | Consider an object pool |
| An entity combines independent capabilities | Components; use ECS only when its added complexity is justified |
| Presentation mirrors data | Read the model directly or subscribe to existing signals; snapshots only when needed |
| Cross-module communication chains become too long | Event bus, used sparingly because pervasive events weaken type visibility |

## 2.4 Anti-patterns

- **God Object:** one manager accumulates unrelated systems and responsibilities.
- **Business logic in UI callbacks:** button handlers directly mutate domain rules that cannot be tested without the UI.
- **Raw singletons everywhere:** global access hides dependencies and makes tests difficult.
- **Scattered state:** many booleans replace an explicit state model.
- **Premature abstraction:** an interface or extension point exists only for an imagined future implementation.
- **Magic values in logic:** thresholds and tunable values are embedded instead of named or configured.
- **Unclear operations:** mixed responsibilities or hidden inputs obscure a function; clarify its data flow and split coherent responsibilities without automatically introducing a Command.

## 2.5 General code organization

1. Organize by stable game domain rather than file type or delivery Feature ID. A `player/` area containing its data, view, and control code is preferable to distant `models/`, `views/`, and `controllers/` trees. Use `docs/game-organization.md` when choosing a module location or expanding the starter skeleton.
2. Keep one core concept per file. Split when cohesion, responsibility, readability, or testability justify it; numeric thresholds such as file length limits belong to the linter configuration in the project-root `gdlint.json` and do not by themselves require a split.
3. Keep entry points limited to assembly, dependency injection, and startup.
4. Keep adjustable configuration in a focused config or data area owned by its module; shared use alone does not remove domain ownership.
5. Do not create miscellaneous dumping grounds such as `utils.gd` or `helpers.gd`; name utilities by domain or responsibility.

## 2.6 Error handling

- Distinguish expected failures from exceptional failures. A temporarily unavailable user action may be ignored or explained; corrupted persistent data should produce an explicit error and diagnostic record.
- Never swallow an exception silently. Log it and explain why continuation is safe when it is intentionally tolerated.
- Provide a recognizable fallback resource or an actionable error when an image, audio file, or configuration fails to load.
- Use assertions during development to protect invariants that should never be violated.

## 2.7 Performance defaults

- Measure before optimizing. Do not optimize from intuition alone.
- Use object pools only for genuinely high-frequency allocation and destruction.
- Do not sacrifice readability unless measurement identifies the code as a meaningful hotspot.

---

# Part 3 · Project rule sources

The root `AGENTS.md` routes each task to `agent-rules/00-core/` and the affected domain modules. Concrete engine and language rules stay there; do not copy them into this file. `methodology/` defines the Product and Feature workflow, test traceability, human acceptance and completion. Tool paths and the Project Environment Bootstrap are defined in [Project environment](../methodology/06-project-environment.md); do not record environment state here.
