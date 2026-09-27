---
name: design-visual-asset-spec
description: "Specify concrete visual assets or prepare their resource list from approved visual and interface requirements. Does not create artwork, import resources or conduct art review."
---

# Visual asset specification

Follow `methodology/11-specialist-workflows.md` and the resource preparation list contract in `methodology/01-product-doc-structure.md`. Read relevant GDD requirements and applicable Art Bible, UI layout, target viewport/scaling and inspected existing assets.

Maintain the relevant entries in `docs/resource-requirements/<scope>.md`, reusing the current list and stable resource IDs. Specify purpose and states, source and target paths, expected on-screen/subject size versus source pixel dimensions, aspect ratio, transparent padding, cropping, format and required variants. For animation, identify actual frame/timing/loop needs; for fonts or models, record their relevant character or geometry constraints rather than fictional pixel sizes. Reference GDD-owned details and shared art rules instead of copying them.

Separate required values, suggestions and measurements. Prefer existing assets, themes or procedural presentation that already meet the need. Do not multiply files for states the implementation can express without them. Identify available reference samples and missing deliverables; a filename is not a produced asset. Link complex per-resource details only when the list is insufficient.

Return actionable specifications, unknowns and destinations. Production is still reserved; `content-asset-integration` handles available files and `review-art` / `review-assets` independently assess appearance or technical fit. Keep local specifications out of duplicate Product tables.
