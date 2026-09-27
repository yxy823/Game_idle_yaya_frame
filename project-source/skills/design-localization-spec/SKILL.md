---
name: design-localization-spec
description: Define or update the approved language coverage and locale conventions in a localization specification. Use for localization design decisions; translation resources and runtime locale support use content-localization.
---

# Localization specification

Follow `methodology/11-specialist-workflows.md` for source ownership, authorization and requirement impacts. Maintain `docs/localization/localization-spec.md` within the requested design scope; discussion-only work returns a proposal. Use the configured `document_language` for the specification, not as evidence of the game's source or target languages.

Read the relevant GDD and Product delivery scope, existing localization specification, shared terminology and affected interface constraints. Reuse settled decisions; ask only for material gaps in source language, target locales, intended content coverage, fallback, tone, variable/plural meanings or locale-sensitive presentation. Include formatting, fonts, long text and RTL requirements only where applicable. Separate confirmed requirements from unresolved choices and translation drafts.

Reference domain definitions rather than copying or redefining gameplay concepts. This specification owns locale expressions and language conventions; actual translations belong in runtime resources. Reference existing GDD-owned requirements instead of copying them. Changed player behavior returns to `product-author` for GDD maintenance, and meaning-preserving domain definitions to `project-terminology`.

Make the approved requirements concrete enough for implementation and verification, with their applicability stated. Validate affected source links and return the specification path, confirmed coverage and unresolved decisions. Handle effects on existing plans through the source-impact route in methodology 11 within the existing authorization. Standalone specification work needs no runnable implementation or invented Feature. Runtime changes, translation import and locale testing belong to `content-localization` inside an authorized Feature or scoped experiment; independent language review belongs to `review-localization`.
