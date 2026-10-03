---
name: design-ui-spec
description: "Design and maintain interface layout, states and interaction presentation in a UI specification. Use for wireframes and Godot prototype inputs. Not for art direction, implementation or UX review."
---

# UI specification

Follow `methodology/11-specialist-workflows.md` for ownership, authorization and source impacts. Its **UI document boundaries** section fixes the interface and component files and how a shared control moves to `docs/ui/components/<component-key>-design.md`. **What stays in the GDD** in that file covers moving interface specifications out of GDD. Write directly within the authorized scope in the configured `document_language`; discussion-only work returns a proposal.

GDD owns player behavior, and Product links adopted requirements for delivery. Reference GDD rules and goals instead of copying them. Keep protected source inputs intact. `product-author` does not save this specification on its behalf.

Read the relevant GDD goals and actions, Product delivery scope, the current interface, the applicable Art Bible, display and input conditions and supplied representative resources. Reuse settled choices; ask only about gaps that materially change layout or interaction. Shared visual style belongs to `design-art-direction`, file-level requirements to `design-visual-asset-spec`, and behavior changes to GDD through `design-gdd`.

Select the interface or shared-control document under **UI document boundaries** before naming the output. When creating, renaming or removing an interface or component specification, or changing the purpose, Product association or component consumers shown in its navigation, read `docs/ui/README.md` and update the affected entry in the same authorized change. Do not turn this update into a directory-wide review.

## Useful specification

Explain how hierarchy, grouping and feedback serve the current user goal. Provide an ASCII wireframe with realistic content, key actions and state differences. Draw separate states only when layouts differ substantially.

When an interaction affects game rules or business state, use the responsibility model in `docs/game-organization.md`. Link the governing game rule, distinguish the requested action from its accepted or rejected result, and describe the corresponding display. Hover, focus, panel expansion and display transitions may remain UI-local state. A displayed affordability hint does not replace the logic's purchase decision; actual wiring belongs to implementation.

Use these conventions: `[button]`, `[[primary action]]`, `< input >`, `[option ▾]`, `[ ]` / `[x]`, image and icon labels, and `↕` for scrolling. Keep the primary action clear for each state. Mark focus, disabled, error, empty and dense states and input navigation where relevant; there is no requirement to design every possible future screen.

Distinguish confirmed display and readability constraints from trial values. Include the surrounding screen context, viewport and scaling conditions, representative text and resource references, source versus visible-subject scale, and unresolved questions for runtime evaluation. Node properties and incidental tuning stay in implementation.

Ordinary control states stay here. A complete game moment, such as collecting a reward, belongs to `design-game-presentation`. Link it from the UI document as **Game presentation documents** in methodology 11 describes; the UI document does not replace the presentation's adoption or implementation references.

## Handoff

Apply **Visual prototype before dependent implementation** in `methodology/13-prototypes.md`. The specification supplies questions and inputs for an independently runnable Godot scene; it does not create that scene or prove usability. A requested HTML exploration is separate authorized experiment work and cannot replace Godot validation.

Coordinate visual resource sections with `design-visual-asset-spec` and audio requirements with `design-audio-asset-spec`. **Resource requirements and handoff** in `methodology/11-specialist-workflows.md` selects the owning section; do not create a separate resource list. Adopt actual prototype observations only with the applicable user decision, updating the UI specification and routing any behavior change to GDD through `design-gdd`.

Return the source path, confirmed decisions, unresolved questions and relevant planning and prototype inputs. Formal UX review uses `review-ux` in a different instance; this Skill cannot grant human acceptance.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
