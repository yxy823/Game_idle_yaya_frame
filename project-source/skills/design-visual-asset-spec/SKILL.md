---
name: design-visual-asset-spec
description: "Specify concrete visual resources in their owning presentation, interface or shared design sections. Use for preparation requirements and file specifications; excludes artwork production, import and art review."
---

# Visual asset specification

Follow `methodology/11-specialist-workflows.md` and **Resource requirements and handoff** in `methodology/01-product-doc-structure.md`. Read relevant GDD requirements and applicable Art Bible, presentation alternative, UI layout, target viewport/scaling and inspected existing assets.

Select the owning presentation, UI or extracted component section using methodology 01's resource contract. Visual resources shared outside a single such owner use **Shared resource specifications** in `docs/art/art-bible.md` (`共享资源规格` in Chinese). Move specifications and preparation state together when their use changes the owner, replacing consumer copies with links. Reuse existing resource identity and references; do not create a separate preparation list. Specify purpose and states, preparation status, source/actual and target paths, expected on-screen/subject size versus source pixel dimensions, aspect ratio, transparent padding, cropping, format and required variants. For animation, identify actual frame/timing/loop needs; for fonts or models, record their relevant character or geometry constraints rather than fictional pixel sizes. Reference GDD-owned details and shared art rules instead of copying them.

Separate required values, suggestions and measurements. Prefer existing assets, themes or procedural presentation that already meet the need. Do not multiply files for states the implementation can express without them. Identify available reference samples and missing deliverables; a filename is not a produced asset. Expand complex per-resource details within the owning section and link shared requirements once. A candidate's dependency is not an adopted preparation commitment.

Return actionable specifications, unknowns and destinations. Production is still reserved; `content-asset-integration` handles available files and `review-art` / `review-assets` independently assess appearance or technical fit. Keep local specifications out of duplicate Product tables.
