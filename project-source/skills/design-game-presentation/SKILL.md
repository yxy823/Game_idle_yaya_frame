---
name: design-game-presentation
description: "Plan an observable game moment from experience goals or informal descriptions, define its component requirements and compare implementation approaches in presentation documents. Use for game-moment design and approach selection, including early GDD exploration. Not for writing runtime code or producing image and audio files."
---

# Game presentation planning

Turn an intended experience into an actionable presentation design: what the player perceives, which parts communicate it, which techniques fit and which approach is currently adopted. This Skill plans game moments within the wider presentation layer; it does not own all UI or game logic.

**Game presentation documents** in `methodology/11-specialist-workflows.md` defines authority, document identity, component extraction, UI and GDD links, source impacts and acceptance entries. It also separates a business result, a current-state display and one-time feedback. Resource details follow **Resource requirements and handoff** in the same file. Write authorized documents in `document_language`; discussion-only work returns the proposal without saving it.

Read the relevant experience goal, GDD and UI context, current presentation documents and suitable project implementations. Begin with the observable trigger, sequence and end state. When the user has only an experience goal, propose a concrete presentation before choosing technology; this can support initial GDD exploration. Preserve confirmed requirements and keep proposals separate from adopted decisions. Ask only about gaps that would change the present decision.

## From a moment to implementable requirements

Decompose by meaningful behavior and independent control, not by asset file count. For a reward, icon flight, amount change and destination feedback may be separate parts that share a trigger. Describe what the player perceives and the relevant timing, space, repeat or cancel behavior and control relationships. Keep useful qualitative ranges until exact values are required or accepted; do not turn a colloquial adjective into an invented numeric specification.

Compare techniques only where there is a real choice. Prefer suitable existing implementations and simple property animation when they meet the requirement. A hybrid approach is normal. Alternatives may belong to the whole presentation or a component; record the chosen combination by reference, and do not imply that every candidate must be implemented. Separate a technique's limitations from a design decision that still needs the user.

| Current question | Read when needed |
| --- | --- |
| Which implementation family fits the behavior, or whether to combine them | [Technique selection](references/technique-selection.md) |
| A component needs surface, color, UV, mask, dissolve or screen-space behavior | [Shader requirements](references/shader-requirements.md) |
| A component has many independently moving or evolving visual elements | [Particle requirements](references/particle-requirements.md) |
| How to record component alternatives, mixed adoption and downstream links | [Item arrival example](references/presentation-example.md) |

These references help normalize requirements, not mandate algorithms, node trees or source code. Do not require a custom particle Shader when existing materials can satisfy the effect. Detailed engineering guidance belongs to the owning implementation task and can be linked from its alternative.

## Documents and continuation

- Check `docs/presentation/README.md`, then select the `docs/presentation/<scope>.md` body by trigger moment and player-perceived result. When methodology 11 requires extraction to `docs/presentation/components/<component-key>.md`, move the component body and update all affected references.
- Keep alternative-specific resources inside that alternative unless the resource rules assign a shared owner. Coordinate visual and audio specifications with `design-visual-asset-spec` and `design-audio-asset-spec`. Missing files can stay explicit while planning continues.
- Link each use as methodology 11 describes: a UI use at its interaction and in the UI's related-presentations section, a non-UI use from its GDD topic.
- Only adopted requirements and the authorized approach enter Feature source, AC or design references. Presentations and Features need not correspond one-to-one.

This Skill neither produces image or audio files nor searches local asset libraries.

Return decisions, source links, concrete uncertainties and the next action the current task allows. A specific feasibility question can use `prototype-godot`. Actual integration uses the development task, with `content-asset-integration` for supplied files. Before final verification, the implementing task updates the adopted combination and the file and consumer links. Human acceptance stays in the linked report or completion record; planning or available code does not establish it.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
