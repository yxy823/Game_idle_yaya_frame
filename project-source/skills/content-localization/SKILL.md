---
name: content-localization
description: "Implement translation resources and locale support against the approved localization specification in an authorized Godot task. Use for runtime translation and locale work. Not for language coverage or convention design (design-localization-spec) or independent review (review-localization)."
---

# Localization implementation

Follow `methodology/11-specialist-workflows.md`. Read the approved `docs/localization/localization-spec.md`, including its **Term translations** section (methodology 11 **Localization term translations**). Also read relevant domain definitions, supplied translations and the current implementation.

Take target locales, source language and intended coverage from those confirmed decisions. `document_language` governs project documentation and does not set them.

Missing or changed language requirements return to `design-localization-spec` before dependent implementation. Preserve approved domain meanings and game rules. Unconfirmed translations remain drafts; implementation authorization does not decide disputed wording or language experience.

## Implement

Work in the owning authorized Feature or experiment.

- Inspect the project's Godot translation mechanism and its version-specific API before choosing file formats or changing it.
- Preserve stable keys and placeholders, and keep translatable text separate from code.
- Cover runtime-created text and the in-scope error and empty states.
- Keep complete translated strings in runtime resources, applying the approved term wording. Do not create a second Markdown catalog of sentences or dialogue.
- Check character and font coverage, fallback, long strings, numbers and dates, input labels and RTL only for applicable locales.

## Validate and return

Validate extraction or import and representative locale switching in actual display conditions. Describe the covered locales and screens. Mechanical completeness does not prove natural wording or cultural suitability. Escalate material ambiguities to the source owner.

Before final verification, finalize implementation and translation changes, and obtain any required specification changes from their owner. Return changed sources, resources and gaps. A separate `review-localization` instance audits the result; this Skill does not supply human acceptance of language or experience.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
