---
name: design-game-presentation
description: Plan an observable game moment from experience goals or informal descriptions, standardize component requirements and compare implementation approaches. Maintains presentation documents; excludes writing runtime code and producing image or audio files.
---

# Game presentation planning

Turn an intended experience into an actionable presentation design: what the player perceives, which parts communicate it, which techniques fit, and which approach is currently adopted. Use `methodology/11-specialist-workflows.md`, especially **Game presentation documents**, for authority, document relationships, source impacts and acceptance links, including the distinction between a business result, current-state display and one-time feedback. This Skill plans game moments within the broader presentation layer; it does not own all UI or game logic. Resource details follow **Resource requirements and handoff** in `methodology/01-product-doc-structure.md`. Write authorized documents in `document_language`; discussion-only work returns the proposal without saving it.

Read the relevant experience goal, GDD/UI context, existing presentation and suitable project implementations. Begin with the observable trigger, sequence and end state. When the user only has an experience goal, help propose a concrete presentation before choosing technology; this can support initial GDD exploration. Preserve confirmed requirements and distinguish proposed design from adopted decisions. Ask only about gaps that would change the present decision.

## From a moment to implementable requirements

Decompose by meaningful behavior and independent control, not by asset file count. For a reward, icon flight, amount change and button feedback may be separate parts while sharing a trigger. Describe what the player perceives and the relevant timing, space, repeat/cancel and control relationships. Keep useful qualitative ranges until exact values are required or accepted; do not turn a colloquial adjective into an invented numeric specification.

Compare techniques only where there is a real choice. Prefer suitable existing implementations and simple property animation when they meet the requirement. A hybrid approach is normal. Alternatives may belong to the whole presentation or a component; record the chosen combination by reference, and do not imply that every candidate must be implemented. Separate a technique's limitations from a design decision that still needs the user.

| Current question | Read when needed |
| --- | --- |
| Which implementation family fits the behavior, or whether to combine them | [Technique selection](references/technique-selection.md) |
| A component needs surface, color, UV, mask, dissolve or screen-space behavior | [Shader requirements](references/shader-requirements.md) |
| A component has many independently moving or evolving visual elements | [Particle requirements](references/particle-requirements.md) |
| How to record component alternatives, mixed adoption and downstream links | [Reward presentation example](references/presentation-example.md) |

These references help normalize requirements, not mandate algorithms, node trees or source code. Do not require a custom particle Shader when existing materials can satisfy the effect. Detailed engineering guidance belongs to the owning implementation task and can be linked from its alternative.

## Durable output and continuation

Select the `docs/presentation/<scope>.md` body by the trigger moment and player-perceived result under the canonical document contract, checking existing navigation first. Different sources of the same item-arrival moment share one body with source-specific contexts; a distinct process links that moment rather than copying it. When two distinct presentations use the same partial component contract, apply mandatory extraction to `docs/presentation/components/<component-key>.md`, migrating the body and updating all affected references. Put alternative-specific resources inside that alternative unless methodology 01's resource contract assigns them to a shared owner; coordinate visual/audio specifications with their specialist Skills. Missing files can remain explicit while planning continues. This Skill neither produces image/audio files nor searches local asset libraries.

Link a UI use at its actual interaction and in the UI's final related-presentations navigation; link a non-UI use from its relevant GDD topic. Preserve one shared body for multiple consumers. Only adopted requirements and the authorized approach enter Feature source/AC/design references; presentations and Features need not correspond one-to-one.

Return decisions, source links, concrete uncertainties and the next action allowed by the current task. A specific feasibility question can use `prototype-godot`; actual integration uses the existing development task and `content-asset-integration` where supplied files are involved. Continue existing authorization without a new handoff ceremony. Before final verification, the implementing task updates actual adoption and file/consumer links. Human acceptance remains in the existing linked report/completion record; planning or code availability does not establish it.
