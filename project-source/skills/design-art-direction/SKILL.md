---
name: design-art-direction
description: "Define or revise a game's shared visual direction, including choosing its art style. Use for art standards; individual asset specifications and art review have separate Skills."
---

# Art Bible

Use `methodology/11-specialist-workflows.md` for ownership, authorization, source
impacts and finalization. Read the relevant Product experience, existing visual
direction, UI constraints and supplied references, not every game module.

Choose a direction that supports the actual camera, target display size, player
attention and available production constraints. Compare alternatives only when
a material choice is unresolved. Distinguish a reference's useful properties
from permission or ability to reproduce it.

Maintain the applicable shared decisions in `docs/art/art-bible.md`:
- visual language and intended mood, with practical inclusion/exclusion examples;
- silhouette, shape, palette, contrast, typography and material/detail treatment
  where relevant to the current game;
- perspective, scale, animation language and visual priority across asset families;
- applicability and observable constraints needed by UI and resource specifications.

Only settle needed decisions; no full-game art catalog or mandatory variant count.
Identify confirmed requirements and open choices. Existing references are not
produced sample assets. Actual visual-art production is reserved, not implemented.

Hand concrete files to `design-visual-asset-spec`, interface presentation to
`design-ui-spec`, and source impacts to existing planning. Formal evaluation
uses a separate `review-art` instance; this Skill does not approve its own design.
Return the maintained source, decisions and gaps, then continue the owning task.
