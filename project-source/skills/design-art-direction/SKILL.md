---
name: design-art-direction
description: "Define or revise a game's shared visual direction, including its art style, in the Art Bible. Use for shared art standards. Not for individual asset specifications (design-visual-asset-spec) or art review (review-art)."
---

# Art direction (Art Bible)

Follow `methodology/11-specialist-workflows.md` for ownership, authorization, source impacts and finalization. **What stays in the GDD** in that file covers moving art standards out of GDD. Read the relevant GDD experience goals, Product delivery scope, current visual direction, UI constraints and supplied references, not every game module.

## Choose the direction

Choose a direction that supports the actual camera, target display size, player attention and available production constraints. Compare alternatives only when a material choice is unresolved. A reference's useful properties are separate from permission or ability to reproduce it.

## Maintain the Art Bible

Keep detailed shared art standards only in `docs/art/art-bible.md`. GDD keeps intended player feelings and recognition goals and links these standards. Coordinate a change to the game's adopted overall direction with `design-gdd`. Useful topics include:

- visual language and the style choices that serve the GDD's experience goals, with practical inclusion and exclusion examples;
- silhouette, shape, palette, contrast, typography and material or detail treatment where relevant to the current game;
- perspective, scale, animation language and visual priority across asset families;
- applicability and observable constraints that UI and resource specifications need.

Settle only the needed decisions; there is no full-game art catalog or required variant count. Mark confirmed requirements and open choices. Reference images are not produced sample assets. Visual-art production is a reserved capability with no Skill (methodology 11 **Design, production, integration and review**).

## Hand off

- Concrete file specifications go to `design-visual-asset-spec`. When **Resource requirements and handoff** in `methodology/11-specialist-workflows.md` selects the Art Bible, that Skill maintains the Bible's **Shared resource specifications** section; this Skill maintains the style standards those entries reference.
- Interface presentation goes to `design-ui-spec`. Effects on planned work use the change routes under **Writing and adoption** in methodology 11.
- Formal evaluation uses a separate `review-art` instance; this Skill does not approve its own design.

Return the maintained source, decisions and gaps.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
