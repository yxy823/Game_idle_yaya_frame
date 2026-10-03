---
name: review-assets
description: "Independently audit scoped game assets for technical fit, references, imports and provenance records. Use for requested asset inspection; art/audio experience review is separate."
---

# Asset audit

Apply `methodology/12-independent-review.md`. Locate resource specifications through **Resource requirements and handoff** in `methodology/01-product-doc-structure.md`, including component-owned resources and the Bibles' shared-resource sections. Read those specifications, the current adopted combination where relevant, concrete asset rules, actual files/import settings and their runtime consumers. Candidate dependencies alone are not missing required assets; check the adopted and reviewed scope.

Check missing or stale paths/UIDs, unused or duplicate assets where relevant, format and dimensions/channels/duration, transparency/cropping, animation data, import/compression settings and memory/storage implications against actual requirements. A large file is not automatically a defect; establish its use and cost. Check provenance and license records for the requested scope, marking unknown rights as unknown rather than giving invented legal clearance.

Inspect replacements across all relevant consumers. File presence and successful import do not establish visual/sound fitness, actual usage or human acceptance. Use `review-art` or `review-audio` within the same independent instance when that experience review was requested.

Report source locations, affected consumers, concrete impact and unverified checks. Do not reimport, delete, deduplicate, rewrite provenance or repair references in the reviewed project; any necessary executable validation uses isolated artifacts.
