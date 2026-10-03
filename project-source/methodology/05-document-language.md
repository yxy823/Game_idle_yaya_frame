# 05 · Document language

> This document defines which language each kind of project text uses. It keeps machine protocol values unlocalized and does not duplicate the workflow sources.

## 1. Two language contexts

The project separates two concepts:

- **Conversation language** is the language currently used between the user and the Agent. It belongs to the session and is not saved in the project.
- **Document language** is the language of human-readable project documents. It is saved in the project and stays the same across sessions.

Changing the conversation language does not change the language of project documents.

## 2. Configuration contract

`docs/methodology-config.json` stores the document language in `document_language`. The same file stores the tool paths described in [06 · Project environment](06-project-environment.md); a language change keeps those settings unchanged.

The value is a [BCP 47 language tag](https://www.rfc-editor.org/rfc/rfc5646.html#section-2.1). Verified values are:

- `en` for English
- `zh-CN` for Simplified Chinese

Other well-formed BCP 47 tags may be used on a best-effort basis. The Agent states that they are not covered by the verified language examples.

- Use conventional casing: lowercase language, title-case script and uppercase region.
- Preserve the configured value as written; do not normalize it.
- Empty values, whitespace and underscore forms such as `zh_CN` are invalid. Report the configuration error and resolve the intended valid tag before writing.
- Private-use, grandfathered and other unusual tags are best-effort, not verified. Ask only if the user's intended language is unclear.

The environment checker screens the form of the tag only:

- the primary subtag is two to eight ASCII letters, or an `i` or `x` prefix followed by subtags;
- hyphen-separated subtags contain one to eight ASCII letters or digits;
- whitespace, underscores and empty or overlong subtags are rejected, and the value is not normalized.

The checker does not validate full BCP 47 subtag ordering or registry membership, and it does not choose a language. The Agent judges unusual tags and applies the configured language.

## 3. Language selection

New projects use Simplified Chinese (`zh-CN`). The project creator writes this value into `docs/methodology-config.json`.

- Read `document_language` before writing GDD, Product or Feature content. For a new project, keep `zh-CN` without asking the user to confirm it.
- If the user explicitly asks for another document language before substantive content exists, save its valid BCP 47 tag and use it directly. That request needs no second confirmation. This also applies to an initial GDD draft and does not need Environment Bootstrap, a Godot run or a GDD.
- For an established project, keep its configured language. A requested change follows [§9](#9-changing-an-established-document-language).
- Reuse still-valid explicit decisions across Skills and sessions.

Conversation language, country, IP address, timezone, operating-system locale and account location do not override the configured value. Ask only when an explicit request is ambiguous or conflicts with the current document scope. Do not turn the default into a recurring approval step.

## 4. Content written in document_language

The following human-readable project content uses `document_language`:

- authorized initial GDD drafts, additions or edits to GDD prose, Product delivery headings and prose, and professional specifications;
- Feature titles, descriptions, acceptance criteria and human-readable source annotations;
- Feature notes and revision-log explanations;
- current Progress, linked execution archives, implementation decisions and saved handoff records;
- project-specific prose added to generated documents.

The initial files contain purpose notices, pending-state notices and directory navigation. They are not Product content. When replacing a notice with actual project content, write in `document_language`; copying a file translates nothing.

Read `docs/progress.md` as the current state and history index, then load only the linked Feature or batch archive the task needs. New archives under `docs/progress/` use `document_language`; earlier history keeps its original language. Moving history keeps the original text and evidence links. Do not translate history or copy it into both Progress and Feature notes during archiving.

Questions, explanations, reports and verification instructions shown to the user follow the current conversation language. This includes handoff and continuation prompts and their headings. Such text uses `document_language` only when it is also saved into a project document.

Quoted interface text, proper nouns, code samples and external references may contain another language. A language check does not reject content only because some characters or examples use a different script.

## 5. Stable protocol elements

The following elements stay English or language-neutral in every project:

- JSON keys and schema structure
- Feature IDs such as `F009`
- status values such as `pending`, `in_progress` and `done`
- scope values such as `small`, `medium` and `large`
- repository paths, structural filenames and ASCII slugs
- Skill names and public command names
- Conventional Commit types such as `feat`, `fix` and `docs`
- placeholder prefixes such as `_placeholder_`
- review severity values `must_fix`, `suggest` and `acceptable`
- keys and status values in `docs/feature-completion-evidence.json`; its human-readable summaries follow the conversation language
- test IDs (`F0XX-ACyy`, `F0XX-RTyy`, `INV-<DOMAIN>-NN`), component IDs, test kinds and status values, and Test Registry keys
- ISO 8601 timestamps and programming-language identifiers

Translate meaning-bearing prose only. Keys, enum values, IDs, evidence strings, paths and identifiers stay unchanged.

## 6. Language of project files

Each kind of file has one language:

| Files | Language |
| --- | --- |
| Agent-read sources: `methodology/` (including `methodology/templates/`), `agent-rules/`, `.agents/skills/` and `.codex/agents/*.toml` | English, one canonical version |
| Human-facing entries: `README.md`, `tools/README.md`, the `asset_workbench/` documents and component READMEs | Chinese |
| `AGENTS.md` | English, except the **沟通与交付** and **使用说明的可读性** sections shared with the framework, which are Chinese |
| Project documents under `docs/` | `document_language` |

Most initial files under `docs/` are written in the default `zh-CN`. `docs/progress.md`, `docs/project-rules.md` and the `docs/knowledge/` READMEs start as English sources. Translate them only within an approved scope under [§8](#8-content-in-another-language).

Task prompts written by the user may use the conversation language. Their language does not change the language of these sources or the configured `document_language`.

Do not create parallel trees such as `methodology.zh-CN/`, localized Skill bodies or translated rule libraries. A human-facing entry may have an explicitly approved translation, such as `README.zh-CN.md`; such a translation is not a workflow source.

When rendering an English template into another document language, keep every required section and its meaning. Rendering does not weaken, omit or reinterpret workflow requirements.

## 7. Missing configuration is an error

The project creator supplies `docs/methodology-config.json` with `document_language`. A missing file or field is a project-file error, not a separate project mode. Report it and fix the configuration before writing project documents. Do not guess the value from Product files or create a migration record.

## 8. Content in another language

New content uses the configured `document_language`. Text already written in another language does not change that setting. Translate existing sections only within an explicitly approved scope. Keep completed Features and revision records as they are unless their translation is also authorized.

## 9. Changing an established document language

Editing the configuration field alone does not migrate a project's language. When the user explicitly asks for a different document language, give a scoped migration plan covering at least:

- active GDD, Product and professional documents and their headings;
- natural-language fields of pending and in-progress Features;
- current Progress state and links; historical archives are excluded unless explicitly approved;
- source anchors and links affected by translated headings;
- verification that machine protocol values stay unchanged.

Do not start this migration only because the user changes the conversation language. Established projects are never translated automatically.

## 10. Workflow obligations

Every workflow that creates or updates project documents:

1. Reads `docs/methodology-config.json` before writing.
2. Treats a missing file or missing `document_language` as an error under [§7](#7-missing-configuration-is-an-error).
3. Writes human-readable content in `document_language`.
4. Keeps the stable protocol elements in [§5](#5-stable-protocol-elements) unchanged.
5. Stops and asks when an edit would start an unapproved language migration.

These obligations apply to every Skill and to prompts used without a Skill.
