---
name: product-ui-sketcher
description: Design and maintain interface layout, states and interaction presentation in a UI specification. Use for wireframes and Godot prototype inputs; excludes art direction, implementation and UX review.
metadata:
  version: 3.0
  priority: medium
---

# Product UI sketcher

Follow `methodology/11-specialist-workflows.md` for professional ownership,
authorization and source impacts. Maintain `docs/ui/<interface>-design.md`
directly within the authorized scope, using the configured `document_language`.
Discussion-only work returns a proposal. Product owns player behavior and links
to this specification; `product-standardizer` is not its saving intermediary.

Read the relevant Product goal/actions, existing interface, applicable Art Bible,
display/input conditions and supplied representative resources. Reuse settled
choices; ask only about gaps that materially change layout or interaction.
Shared visual style belongs to `art-bible`, file-level requirements to
`visual-asset-spec`, and behavior changes to Product.

## Useful specification

Explain how hierarchy, grouping and feedback serve the current user goal.
Provide an ASCII wireframe with realistic content, key actions and state
differences. Draw separate states only when layouts differ substantially.

Use existing conventions: `[button]`, `[[primary action]]`,
`< input >`, `[option ▾]`, `[ ]` / `[x]`, image/icon labels and
`↕` for scrolling. Keep the primary action clear for each state. Mark focus,
disabled/error/empty/dense states and input navigation where relevant; no
requirement to design every possible future screen.

Distinguish confirmed display/readability constraints from trial values. Include
surrounding screen context, viewport/scaling conditions, representative text and
resource references, source versus visible-subject scale, and unresolved questions
for runtime evaluation. Node properties and incidental tuning stay in implementation.

## Handoff

Apply **Visual prototype before dependent implementation** in
`methodology/01-product-doc-structure.md`. The spec supplies questions and
inputs for an independently runnable Godot scene; it does not create that scene
or prove usability. A requested HTML exploration is separate authorized experiment
work and cannot substitute for Godot validation.

Coordinate resource entries with `visual-asset-spec` and audio requirements with
`product-audio-sketcher`, keeping one shared preparation list rather than copying
rows. Adopt actual prototype observations only with the applicable user decision,
updating the owning UI specification and routing any behavior changes to Product.

Return the source path, confirmed decisions, unresolved questions and relevant
planning/prototype inputs. Continue the owning authorized task. Formal UX review
uses `ux-review` in a different instance; this Skill cannot grant human acceptance.
