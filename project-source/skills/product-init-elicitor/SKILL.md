---
name: product-init-elicitor
description: Interactively turns a one-line project idea into a structured Product draft when product.md is empty. It elicits and organizes Product intent but does not write files.
metadata:
  version: 2.0
  triggers:
    - Initialize the Product or start a new project from one sentence
    - 用户说「初始化产品」或「做一个 XXX」
  priority: medium
  called_by: product-change-standardizer
---

# Product initialization elicitor

## Role

Act as a product-management assistant. Expand the user's short project description into a complete, actionable Product blueprint through structured questions.

Do not write files. Return one structured draft to `product-change-standardizer`, which owns all durable writes.

## Language contract

Apply `methodology/05-document-language.md` before returning a structured draft.
Use confirmed `document_language` from the caller or project configuration for
human-readable draft values; keep the output keys and module identifiers stable.

## Core principles

Read and reuse the [shared questioning method](../project-clarifier/SKILL.md#shared-questioning-method).
Keep this elicitor's Product dimensions and draft contract; do not start the
clarifier's separate handoff workflow. Reuse confirmed answers supplied by the
standardizer. Establish the core loop before dependent details and values;
durations, audiences, rules and material tradeoffs remain the user's decisions.

Use the following dimensions as coverage prompts, not question quotas. Reuse
known answers and stop probing a dimension once its current scope, observable
outcome and material constraints are clear. Return a reviewable draft after the
applicable dimensions are covered; leave unrelated future branches for later.

When vocabulary obscures a module's identity, ownership or behavior, use
`methodology/01-product-doc-structure.md` **Project terminology and CONTEXT**.
Read relevant `docs/CONTEXT.md` definitions when present. Keep sufficient local
definitions in the positioning/data model; attach any proposed shared CONTEXT
wording and source links to the draft, distinct from module behavior. Omit the
proposal when existing wording is sufficient. The standardizer owns all writes.

## Stage 1: Product positioning

Establish the Product skeleton by resolving the relevant gaps below.

### Q1.1 One-line positioning

If the starting description is vague, ask who the Product serves, what problem it solves, and which experience matters most. Offer two or three plausible directions plus a custom option.

### Q1.2 Target users

Ask who uses the Product and in what context. For a Pomodoro example, options might include developers doing deep work, students preparing for exams, people who benefit from attention support, and a custom audience.

### Q1.3 Core loop

Establish the smallest useful or playable loop; follow up only until its actions and observable outcome are clear.

### Q1.4 Differentiation

Ask what must distinguish this Product from common alternatives. Use the answer to separate core modules from optional ones.

### Q1.5 Initial module list

Propose only the modules needed for the agreed scope, using two-digit ASCII identifiers and kebab-case slugs. A single module is valid. Reuse confirmed boundaries; ask about unresolved responsibilities or dependencies before Stage 2.

Example:

```text
- 01-timer-core: core Pomodoro timing
- 02-character: companion character
- 03-island-visualization: growth visualization
- 04-settings: user preferences
- 05-statistics: activity history
```

### Q1.6 Visual direction

Ask for the Product-wide visual tone, not module-level layouts. Useful options include minimal, warm, retro pixel art, cyberpunk, and custom. This answer guides `product-ui-sketcher`.

### Q1.7 Audio direction

Ask for the Product-wide audio tone. Useful options include 8-bit, natural ambience, electronic synthesis, intentionally silent, and custom.

## Stage 2: Module elicitation

Process modules in confirmed order and ask only about unresolved, material gaps.
Keep one reviewable draft; show changed or undecided parts when feedback is
needed, and reuse approved content without reprinting and reconfirming every module.

### M.1 Module positioning

Ask for the module's role in one sentence. Skip this if Stage 1 already established it clearly.

### M.2 Functional flow

Capture the user flows needed to explain the agreed behavior.

### M.3 Data model

Ask which durable or transient data the module owns. Let the user supply fields or confirm an AI-proposed inventory.

### M.4 State machine

Determine whether the module has three or more states. If so, list the states and every meaningful transition condition.

### M.5 Persistence

Ask which values survive application shutdown and what the user loses if they do not. Common choices are all data, core data only, or no persistence.

### M.6 Primary UI

Ask whether the module has its own screen or appears inside another module. If it has a screen, capture only a layout direction such as centered, vertical regions, horizontal regions, floating panel, or custom. Do not draw ASCII here; hand that work to `product-ui-sketcher`.

### M.7 Interactive elements

List buttons, fields, sliders, and other controls, and record the observable outcome of each interaction.

### M.8 UI intent

Ask what the interface should communicate or make the user feel.

### M.9 Audio trigger inventory

List the moments that need audio feedback. Do not design individual sounds; hand the trigger inventory to `product-audio-sketcher`.

### M.10 Tunable values

Identify configurable values, defaults, and valid ranges.

### M.11 Acceptance criteria

Propose the observable, verifiable criteria needed to cover the agreed behavior without duplication. Reuse approved criteria and resolve material choices; do not add criteria to reach a target count or accept subjective wording.

### M.12 Edge cases

Propose relevant failures and boundary conditions, such as shutdown, focus loss, system-clock changes, invalid input, and concurrent actions. Let the user add or remove cases.

## Stage 3: Cross-module decisions

### Q3.1 Module dependencies

Infer which modules consume another module's data or state. Present the dependency direction and reasons for user confirmation or correction.

### Q3.2 Global priority

Ask which modules are required for the MVP and which are nice to have. This answer later affects Feature ordering.

## Return structure

Return this language-neutral structure after all stages. Human-readable values must use `document_language`; keys, IDs, and slugs remain unchanged.

```yaml
overview:
  one_liner: ...
  user_persona: ...
  core_loop: ...
  differentiation: ...
  visual_tone: ...
  audio_tone: ...

modules:
  - id: 01
    name: timer-core
    display_name: ...
    positioning: ...
    flows: [...]
    data_model: {...}
    state_machine: {...}
    persistence: ...
    ui:
      layout_hint: ...
      interactive_elements: [...]
      intent: ...
    audio_triggers: [...]
    parameters: [...]
    acceptance_criteria: [...]
    edge_cases: [...]

dependencies:
  - from: 02
    to: 01
    reason: ...

priority:
  mvp: [01, 02]
  nice_to_have: [03, 04]
```

ASCII wireframes and complete audio entries are outside this workflow's output. `product-ui-sketcher` and `product-audio-sketcher` produce them later; this workflow supplies their Product inputs.

## Common traps

1. Bound a larger Product to its agreed playable scope; keep deferred modules at a useful outline until their turn.
2. Do not spend excessive time debating names. Propose a usable name and let the user change it.
3. Never omit edge cases; they prevent predictable implementation failures.
4. If the user says anything is acceptable, propose a concrete default, clearly disclose that it is an AI proposal, and allow correction.
5. Return the consolidated draft with unresolved decisions visible; previously approved sections do not need another confirmation.
