---
name: localization-review
description: "Independently review locale coverage, translation fidelity and locale-sensitive presentation. Use for requested localization review; translation and implementation use localize."
---

# Localization review

Apply `methodology/12-independent-review.md`. Read intended locales, source text,
domain definitions and localization specification, then compare actual resources
and displayed flows for the selected coverage.

Check omissions/fallback, mistranslation and consistency, variable/plural integrity,
formatting, font coverage, line wrapping/truncation, locale switching and
applicable direction/input conventions. Separate mechanically checked completeness
from linguistic judgment and actual visual inspection. Scope language confidence;
do not label untranslated meaning as correct merely because keys match.

Source-language ambiguity goes back to its owner rather than being resolved by
inventing translated behavior. Proposed terminology is not an approved glossary.
A screenshot of one locale cannot validate other locale layouts.

Return locale/flow coverage, concrete key/text or screen references, findings and
remaining human-language checks. Do not edit translations or independently approve
the experience on the user's behalf.
