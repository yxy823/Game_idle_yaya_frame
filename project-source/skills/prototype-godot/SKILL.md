---
name: prototype-godot
description: "Build or refine a scoped Godot visual or logic prototype that answers a concrete layout, interaction, state-transition or feasibility question. Use for a requested experiment or a visual prototype needed before dependent implementation. Not for Features that have no such open question."
---

# Answer a question with a Godot prototype

Identify the question to settle, the current task's authorization and the evidence that would answer it. Apply **GDD prerequisite and authority** in `methodology/01-product-doc-structure.md`; an experiment does not create missing game design or approve a proposed rule. Discussion-only work can define the experiment without building it.

## Read the matching prototype method

Use the matching section and keep its source ownership, validation and adoption rules:

| Question | Read |
| --- | --- |
| Layout, scale, content density, representative assets or visual and interaction feedback | **Visual prototype before dependent implementation** in `methodology/13-prototypes.md`, including its scope, resources, validation and adoption |
| Logic, state transitions or technical feasibility | **Scoped logic prototypes** in `methodology/13-prototypes.md`; read the visual section as well only when judging visual or perceptual qualities |
| Resources must be prepared or supplied before the experiment can answer its question | **Resource requirements and handoff** in `methodology/11-specialist-workflows.md` |

Default to the project's own Godot environment and a small runnable scene. Follow the selected method to choose between isolated sample state and a necessary real engine path. HTML is not a default prototype format or a step before Godot verification. Read relevant professional sources and the affected engineering domains through the project `AGENTS.md`, without loading unrelated specifications.

## Build and report within the task

Reuse a prototype that still answers the question. Build only the state, controls and observations the authorized experiment needs, and keep assumptions visible. Standalone work uses the scoped-experiment route in `methodology/00-overview.md`; delivery work uses the owning Feature's current plan. Runtime checks and changes stay within that task's actual permissions.

Return:

- the runnable entry;
- the question answered and the actual observations;
- unresolved limits;
- the source owner that must adopt any decision.

When comparing a presentation alternative, link the experiment from that section. Adopted choices and actual file and consumer relationships return to the owning document before final verification. State what was not run or still needs human experience; a screenshot, static check or simulated state change covers only what it actually shows. Follow `methodology/13-prototypes.md` for notes or Progress, source updates and prototype disposition, without creating a second plan or status ledger.

A prototype's acceptance covers its agreed scope, not production readiness or later game behavior. Preserve necessary human feedback and do not infer it from successful execution.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
