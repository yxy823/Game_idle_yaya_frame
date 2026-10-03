---
name: review-localization
description: "Independently review locale coverage, translation fidelity and locale-sensitive presentation. Use for a requested localization review. Not for specification writing (design-localization-spec) or translation and runtime implementation (content-localization)."
---

# Localization review

Apply `methodology/12-independent-review.md`. Read intended locales, source text, domain definitions and localization specification, then compare actual resources and displayed flows for the selected coverage.

Check omissions/fallback, mistranslation and consistency, variable/plural integrity, formatting, font coverage, line wrapping/truncation, locale switching and applicable direction/input conventions. Separate mechanically checked completeness from linguistic judgment and actual visual inspection. Scope language confidence; do not label untranslated meaning as correct merely because keys match.

Source-language ambiguity goes back to its owner rather than being resolved by inventing translated behavior. Language coverage and convention changes belong to `design-localization-spec`; runtime fixes belong to `content-localization` under separate implementation authorization. Compare actual term usage with the **Term translations** section of `docs/localization/localization-spec.md` (methodology 11 **Localization term translations**) and the linked domain definitions. Proposed terminology is not an approved entry. A screenshot of one locale cannot validate other locale layouts.

Return locale and flow coverage, concrete key, text or screen references, findings and remaining human-language checks.
