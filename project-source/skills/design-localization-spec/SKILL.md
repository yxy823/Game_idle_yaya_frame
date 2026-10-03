---
name: design-localization-spec
description: "Define or update the approved language coverage and locale conventions in the localization specification. Use for localization design decisions, including approved term translations. Not for translation resources or runtime locale support (content-localization)."
---

# Localization specification

Follow `methodology/11-specialist-workflows.md` for source ownership, authorization and requirement impacts. **What stays in the GDD** in that file covers moving localization specifications out of GDD. Maintain `docs/localization/localization-spec.md` within the requested design scope; discussion-only work returns a proposal. Write the specification in the configured `document_language`, which says nothing about the game's source or target languages.

## Read and clarify

Read the relevant GDD and Product delivery scope, the current localization specification, shared terminology and affected interface constraints. Reuse settled decisions. Ask only about material gaps in:

- source language, target locales and intended content coverage;
- fallback and tone;
- the meaning of variables and plurals;
- locale-sensitive presentation, including formatting, fonts, long text and RTL where applicable.

Separate confirmed requirements from unresolved choices and translation drafts.

## Maintain the specification

This file is the fixed owner of locale coverage, locale expressions and language conventions. Reference domain definitions instead of copying or redefining gameplay concepts.

Maintain the **Term translations** section as described in methodology 11 **Localization term translations**. Target-language names are not project-terminology aliases, and full translated strings stay in runtime resources.

GDD keeps game rules and experience goals. Changed player behavior returns to `design-gdd`, and meaning-preserving domain definitions go to `project-terminology`.

Make the approved requirements concrete enough for implementation and verification, and state where each applies.

## Return

Validate affected source links. Return the specification path, confirmed coverage and unresolved decisions. Handle effects on planned work through the change routes under **Writing and adoption** in methodology 11 within the current authorization. Standalone specification work needs no runnable implementation or invented Feature.

Runtime changes, translation import and locale testing belong to `content-localization` inside an authorized Feature or scoped experiment. Independent language review belongs to `review-localization`.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
