# 05 · Document language contract

> This document defines how Yaya Loop chooses the language of durable project knowledge without localizing its machine protocols or duplicating its canonical workflow sources.

## 1. Two language contexts

Yaya Loop separates two concepts:

- **Conversation language** is the language currently used between the user and the AI. It is session-level interaction state and is not persisted by Yaya Loop.
- **Document language** is the language used for durable, human-readable project knowledge. It is persisted in the project and remains stable across sessions.

Changing the language of a conversation must not change the language of project documents.

## 2. Configuration contract

New projects use Simplified Chinese (`zh-CN`) for durable documents by default. The creator supplies this value in `docs/methodology-config.json`; use it without asking the user to confirm the default. An explicit user choice of another document language overrides the default under **Language selection**. This also applies to an initial GDD draft and does not require environment Bootstrap, a Godot run or an existing GDD. Preserve unrelated tool settings when saving a requested language change.

Copied purpose/pending-state notices and directory navigation do not establish Product content. When replacing a notice with actual project content, use the configured `document_language`; copying performs no translation.

The current file contains the complete configuration. Keep its actual machine tool paths there rather than copying a second example here. The project stack is Godot 4.7 / GDScript / gdunit4.


The value of `document_language` must be a [BCP 47 language tag](https://www.rfc-editor.org/rfc/rfc5646.html#section-2.1). Initial verified values are:

- `en` for English
- `zh-CN` for Simplified Chinese

Other well-formed BCP 47 tags may be used on a best-effort basis, but the agent must disclose that they are not covered by the existing language examples.

Yaya Loop recommends conventional BCP 47 casing: lowercase language, title-case script, and uppercase region. Preserve the configured value without silently normalizing it. Empty values, whitespace, and underscore forms such as `zh_CN` are invalid; report the configuration error and resolve the intended valid tag before writing. Private-use, grandfathered, and other unusual tags remain best-effort rather than verified; ask only if the user's intended language is unclear.

The environment checker performs basic lexical screening: an ASCII alphabetic primary subtag of two to eight letters, or an `i`/`x` prefix followed by subtags; hyphen-separated subtags contain one to eight ASCII letters or digits. It rejects whitespace, underscores and empty/overlong subtags without normalizing the value. This does not validate complete BCP 47 subtag ordering or registry membership. The Agent resolves unusual-tag validity and applies the configured language; the checker does not decide language preferences.

Tool paths in the same file are covered in [project environment](06-project-environment.md).

## 3. Language selection

Read `document_language` before generating durable GDD, Product or Feature content. For a new project, keep the supplied `zh-CN` and proceed without a language-confirmation question.

If the user explicitly requests another document language before substantive content exists, save its valid BCP 47 tag and use it directly; that request needs no second confirmation. For an established project, preserve its configured language and apply **Changing an established document language** when a migration is requested. Reuse still-valid explicit decisions across Skills and sessions.

Conversation language, country, IP address, timezone, operating-system locale and account location do not override the configured value. Ask only when an explicit request is ambiguous or conflicts with the existing document scope; do not turn the default into a recurring approval step.

## 4. Content governed by document_language

The following generated, human-readable project knowledge must use `document_language`:

- Authorized initial GDD drafts, additions or edits to GDD prose, Product delivery headings/prose, and professional specifications
- Feature titles, descriptions, acceptance criteria, and human-readable source annotations
- Feature notes and revision-log explanations
- Current Progress, linked execution archives, implementation decisions, and durable handoff records
- Project-specific natural-language additions written into generated documents

Transient questions, explanations, reports, and verification instructions shown to the user follow the current conversation language. They do not need to match `document_language` unless they are also persisted into the project.

Read `docs/progress.md` as the current state and history index, then load only the linked Feature/batch archive relevant to the task. New archives under `docs/progress/` use `document_language`; existing history remains in its original language. A pure history move preserves the original text and evidence links. Do not translate or duplicate historical bodies in both Progress and Feature notes during archival.

Quoted user-interface text, proper nouns, code samples, and external references may legitimately contain another language. Language checks must not reject content solely because individual characters or examples use a different script.

## 5. Stable protocol elements

The following elements must remain stable English or language-neutral protocol values in every project:

- JSON keys and schema structure
- Feature IDs such as `F009`
- Status values such as `pending`, `in_progress`, and `done`
- Scope values such as `small`, `medium`, and `large`
- Repository paths, structural filenames, and ASCII slugs
- Skill names and public command names
- Conventional Commit types such as `feat`, `fix`, and `docs`
- Placeholder prefixes such as `_placeholder_`
- Review severity values `must_fix`, `suggest`, and `acceptable`
- Structured feature-completion-evidence keys/status values; human-readable summaries follow the conversation language
- Test IDs (`F0XX-ACyy`, `F0XX-RTyy`, `INV-<DOMAIN>-NN`), component IDs, test kinds/status values, and test registry keys
- ISO 8601 timestamps and programming-language identifiers

An agent must translate meaning-bearing prose, not keys, enums, IDs, evidence strings, paths, or identifiers.

## 6. Canonical-source policy

Yaya Loop's executable workflow sources use one canonical English version. This includes Methodology specifications, Skills, templates, Project Rules sources, explicit tools, and default examples.

Task prompts sent by a user may use the conversation language. Their language does not by itself change the canonical workflow sources or the configured `document_language` for durable project output.

Do not create parallel trees such as `methodology.zh-CN/`, localized Skill bodies, or translated Project Rules libraries. Human-facing entry documents may have explicitly approved translations, such as `README.zh-CN.md`, but those translations are not executable workflow sources.

When rendering an English canonical template into another document language, preserve every required section and its semantics. Rendering must not weaken, omit, or reinterpret workflow requirements.

## 7. Missing configuration is an error

The creator supplies `docs/methodology-config.json` with `document_language`. A missing file or field is a project-file error, not an older-project mode. Report it and resolve the configuration before writing durable content; do not guess its value from Product files or create a migration record.

## 8. Content in another language

Use the configured `document_language` for new durable content. Existing text in another language does not change that setting. Translate existing sections only within an explicitly approved scope; preserve completed Features and revision records unless their translation is also authorized.

## 9. Changing an established document language

Editing the configuration field alone is not a supported language migration. A user who explicitly requests a different document language must receive a scoped migration plan covering at least:

- active GDD, Product and professional documents and headings
- pending and in-progress Feature natural-language fields
- current Progress state and links; historical archives are excluded unless explicitly approved
- source anchors or links affected by translated headings
- verification that machine protocol values remain unchanged

Yaya Loop must not start this migration because the user merely changes conversation language. The initial international release does not automatically translate established projects.

## 10. Workflow obligations

Every workflow that creates or updates durable project knowledge must:

1. Read `docs/methodology-config.json` before writing.
2. Treat a missing file or `document_language` as an error under section 7.
3. Produce human-readable durable content in `document_language`.
4. Preserve the stable protocol elements in section 5.
5. Stop and ask when an edit would create an unapproved language migration.

These obligations apply equally to native agent integrations and agent-agnostic Prompts.
