---
name: design-ui-spec
description: Design and maintain interface layout, states and interaction presentation in a UI specification. Use for wireframes and Godot prototype inputs; excludes art direction, implementation and UX review.
metadata:
  version: 3.0
  priority: medium
---

# UI specification

Follow `methodology/11-specialist-workflows.md` for professional ownership, authorization and source impacts. Maintain `docs/ui/<interface>-design.md` directly within the authorized scope, using the configured `document_language`. Discussion-only work returns a proposal. GDD owns player behavior; Product links adopted requirements for delivery. Reuse GDD-owned details by reference; `product-author` is not this specification's saving intermediary.

Read the relevant GDD goals/actions and Product delivery scope, existing interface, applicable Art Bible, display/input conditions and supplied representative resources. Reuse settled choices; ask only about gaps that materially change layout or interaction. Shared visual style belongs to `design-art-direction`, file-level requirements to `design-visual-asset-spec`, and behavior changes to GDD through `design-gdd`.

## Useful specification

Explain how hierarchy, grouping and feedback serve the current user goal. Provide an ASCII wireframe with realistic content, key actions and state differences. Draw separate states only when layouts differ substantially.

When an interaction affects game rules or business state, use the responsibility model in `docs/game-organization.md`: link the governing game rule, distinguish the requested action from its accepted/rejected result, and describe the corresponding display. Hover, focus, panel expansion and display transitions may remain UI-local state. A displayed affordability hint does not replace the logic's purchase decision; actual wiring belongs to implementation.

Use existing conventions: `[button]`, `[[primary action]]`, `< input >`, `[option ▾]`, `[ ]` / `[x]`, image/icon labels and `↕` for scrolling. Keep the primary action clear for each state. Mark focus, disabled/error/empty/dense states and input navigation where relevant; no requirement to design every possible future screen.

Distinguish confirmed display/readability constraints from trial values. Include surrounding screen context, viewport/scaling conditions, representative text and resource references, source versus visible-subject scale, and unresolved questions for runtime evaluation. Node properties and incidental tuning stay in implementation.

Keep ordinary control states here. For a complete game moment such as collecting a reward, use `design-game-presentation` to maintain its observable process, component requirements and alternative approaches. Link it at the actual UI use and in an end-of-document related-game-presentations navigation section, localized through `document_language`. Several interfaces reference the same shared body while retaining their specific trigger and usage context. The UI document does not replace the presentation's current adoption or implementation references.

## Handoff

Apply **Visual prototype before dependent implementation** in `methodology/01-product-doc-structure.md`. The spec supplies questions and inputs for an independently runnable Godot scene; it does not create that scene or prove usability. A requested HTML exploration is separate authorized experiment work and cannot substitute for Godot validation.

Coordinate resource sections with `design-visual-asset-spec` and audio requirements with `design-audio-asset-spec`: interface-only resources stay here, presentation-alternative dependencies stay in that alternative, and shared resources link to their shared design owner. Use **Resource requirements and handoff** in methodology 01 without a separate resource list. Adopt actual prototype observations only with the applicable user decision, updating the owning UI specification and routing any behavior changes to GDD through `design-gdd`.

Return the source path, confirmed decisions, unresolved questions and relevant planning/prototype inputs. Continue the owning authorized task. Formal UX review uses `review-ux` in a different instance; this Skill cannot grant human acceptance.
