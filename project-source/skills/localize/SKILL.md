---
name: localize
description: "Define localization conventions or implement translations and locale support in an authorized Godot task. Use for language coverage, translation resources and locale-sensitive presentation; review is separate."
---

# Localization

Follow `methodology/11-specialist-workflows.md`. Resolve requested target locales,
source language and intended coverage from existing decisions; do not infer them
from `document_language`, which governs project documentation.

For specification work, maintain needed conventions in
`docs/localization/localization-spec.md`: terminology, tone, variable/plural
meaning, locale fallback and formatting expectations. Reuse domain definitions;
localization wording does not redefine game rules. Unconfirmed translations or
meaning choices remain drafts.

For implementation, work in the owning authorized Feature/experiment. Inspect
the project's existing Godot translation mechanism and version-specific API before
choosing file formats or changing it. Preserve stable keys and placeholders,
separate translatable text from code, and cover runtime-created text and error/
empty states in scope. Keep actual translations in runtime resources, not a
second Markdown copy. Check character/font coverage, fallback, long strings,
numbers/dates, input labels and RTL only for applicable locales.

Validate extraction/import and representative locale switching in actual display
conditions; describe locale and screen coverage. Mechanical completeness does not
prove natural wording or cultural suitability. Escalate material ambiguities to
the source owner. Finalize source/translation changes before final verification.

Return changed sources/resources and gaps to the owning task. A separate
`localization-review` instance audits the result; human language/experience
acceptance is not supplied by this implementation Skill.
