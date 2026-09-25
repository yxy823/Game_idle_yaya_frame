---
name: content-localization
description: "Implement translation resources and locale support against an approved localization specification in an authorized Godot task. Language coverage and convention design use design-localization-spec; independent review uses review-localization."
---

# Localization implementation

Follow `methodology/11-specialist-workflows.md`. Read the approved `docs/localization/localization-spec.md`, relevant domain definitions, supplied translations and current implementation. Resolve target locales, source language and intended coverage from those confirmed decisions; do not infer them from `document_language`, which governs project documentation.

Missing or changed language requirements return to `design-localization-spec` before dependent implementation. Preserve approved domain meanings and game rules. Unconfirmed translations remain drafts; implementation authorization does not decide disputed wording or language experience.

Work in the owning authorized Feature/experiment. Inspect the project's existing Godot translation mechanism and version-specific API before choosing file formats or changing it. Preserve stable keys and placeholders, separate translatable text from code, and cover runtime-created text and error/empty states in scope. Keep actual translations in runtime resources, not a second Markdown copy. Check character/font coverage, fallback, long strings, numbers/dates, input labels and RTL only for applicable locales.

Validate extraction/import and representative locale switching in actual display conditions; describe locale and screen coverage. Mechanical completeness does not prove natural wording or cultural suitability. Escalate material ambiguities to the source owner. Finalize implementation and translation changes, and obtain any required specification changes from their owner, before final verification.

Return changed sources/resources and gaps to the owning task. A separate `review-localization` instance audits the result; human language/experience acceptance is not supplied by this implementation Skill.
