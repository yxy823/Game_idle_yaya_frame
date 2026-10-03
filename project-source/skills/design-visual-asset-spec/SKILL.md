---
name: design-visual-asset-spec
description: "Specify concrete visual resources in their owning presentation, interface or shared design sections. Use for preparation requirements and file specifications. Not for artwork production, import or art review."
---

# Visual asset specification

Follow `methodology/11-specialist-workflows.md` for ownership, authorization and source impacts. Its **Resource requirements and handoff** section selects the owning section (a presentation, UI or extracted component section, or **Shared resource specifications** in `docs/art/art-bible.md`), lists the common resource fields and explains how specifications move when the owner changes. Do not create a separate preparation list.

Read the relevant GDD requirements, the applicable Art Bible, the presentation alternative, the UI layout, the target viewport and scaling, and the inspected current assets. Reuse current resource identities and references. Reference GDD-owned details and shared art rules instead of copying them.

## Visual fields

For each resource, specify:

- purpose and states;
- preparation status, the source or actual path and the target path;
- expected on-screen or subject size, separate from source pixel dimensions;
- aspect ratio, transparent padding, cropping, format and required variants.

For animation, identify the actual frame, timing and loop needs. For fonts or models, record their relevant character or geometry constraints instead of fictional pixel sizes.

## Keep the specification minimal

Separate required values, suggestions and measurements. Prefer assets, themes or procedural presentation that already meet the need. Do not add files for states the implementation can express without them. Identify available reference samples and missing deliverables; a filename is not a produced asset. A candidate's dependency is not an adopted preparation commitment.

Return actionable specifications, unknowns and destinations. Do not copy these specifications into Product tables. Visual-art production is a reserved capability with no Skill (methodology 11 **Design, production, integration and review**). `content-asset-integration` handles available files, and `review-art` or `review-assets` independently assesses appearance or technical fit.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
