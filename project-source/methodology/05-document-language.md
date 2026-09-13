# 05 · Document language contract

> This document defines how Yaya Loop chooses the language of durable project knowledge without localizing its machine protocols or duplicating its canonical workflow sources.

## 1. Two language contexts

Yaya Loop separates two concepts:

- **Conversation language** is the language currently used between the user and the AI. It is session-level interaction state and is not persisted by Yaya Loop.
- **Document language** is the language used for durable, human-readable project knowledge. It is persisted in the project and remains stable across sessions.

Changing the language of a conversation must not change the language of project documents.

## 2. Configuration contract

Every newly initialized project must store `document_language` in `docs/methodology-config.json` before Yaya Loop generates Product or Feature content.

The current file contains the complete configuration. Keep its actual machine
paths and command values there rather than copying a second example here.
The project stack is Godot 4.7 / GDScript / gdunit4.


The value of `document_language` must be a [BCP 47 language tag](https://www.rfc-editor.org/rfc/rfc5646.html#section-2.1). Initial verified values are:

- `en` for English
- `zh-CN` for Simplified Chinese

Other well-formed BCP 47 tags may be used on a best-effort basis, but the agent must disclose that they are not covered by the existing language examples. Yaya Loop's existing `language` field continues to identify the programming language and must not be reused for document language.

Yaya Loop recommends conventional BCP 47 casing: lowercase language, title-case script, and uppercase region. Bootstrap preserves the exact value explicitly confirmed by the user and does not silently normalize it. Empty values, whitespace, and underscore forms such as `zh_CN` are invalid and must be confirmed again in a hyphenated form. Private-use, grandfathered, and other unusual tags require explicit confirmation and remain best-effort rather than verified.

The environment checker performs basic lexical screening: an ASCII alphabetic
primary subtag of two to eight letters, or an `i`/`x` prefix followed by subtags;
hyphen-separated subtags contain one to eight ASCII letters or digits. It rejects
whitespace, underscores and empty/overlong subtags without normalizing the value.
This does not validate complete BCP 47 subtag ordering, registry membership or user
confirmation. The Agent still resolves tag validity and the confirmation requirements
above before generating durable content; a configuration check does not grant them.

### Verification command fields

`docs/methodology-config.json` also owns the stable entrypoints used by `execute-next-feature`:

- `test_cmd`: default automated test command or test-runner entrypoint. The agent may select a narrower test target supported by the project, but must not invent unsupported commands.
- `test_framework`: stable identifier for the configured runner. Workflow selection semantics remain separate from runner details, but readiness and evidence import require an implemented adapter. This project uses `gdunit4`; incomplete setup means machine tools remain unconfirmed.
- `test_unit_root`, `test_feature_root`, `test_invariant_root`: project test-layout roots. These are project conventions consumed by test planning; a test framework may store its own plugin/runtime files elsewhere.
- `python_executable`: Complete Python executable path or name used by project tools. It contains no script path or appended arguments; no automatic Hook is registered.
- `environment_bootstrap`: setup status, actual Godot executable and observed version, as described below.

These values are machine-facing command strings and must not be translated when `document_language` changes. A document-language migration preserves them byte-for-byte unless the user separately changes the project's verification setup.

The Test Registry always lives at `docs/test-registry.json`, relative to the project root.
Its location is shared by the merger, checker, test selector and completion check;
it is not a configuration field or duplicated Feature-index metadata.

### Project Environment Bootstrap

Bootstrap means the Agent prepares this project's environment in response to an
explicit setup request. Use the configuration contract below; there is no
separate setup program.

The `environment_bootstrap` object stores only:
- `status`: `incomplete` or `ready`;
- `engine_executable`: complete Godot executable file path, absolute or relative to the project root, without shell quotes or arguments; no PATH lookup;
- `engine_version`: the exact output observed from `Godot --version`.

Use the user-configured `engine_executable` directly without rediscovering it.
If that path is unavailable, report the reason; change it only when the user
requests a new tool location. Keep `engine_version` empty and status incomplete
until actual setup confirms the environment; a prefilled path is not readiness.
The top-level stack remains Godot 4.7 / GDScript / gdunit4. Store the Python
executable in `python_executable` and commands in `test_cmd`.
Script parsing and lint use Godot/addon entrypoints directly as described in `gdscript-lint.md`. The plan-aware test runner
accepts scope arguments; focused and affected scopes do not need separate
configuration copies. No plugin source/hash inventory, timestamp, working-directory
field or stored blocker list is needed; commands run from the project root.

The Agent confirms the tools and dependencies. Before the first CLI run that needs
project scripts in a newly copied project, let the configured Godot editor finish
its normal resource import and global class scan if this project has not already
been opened. Follow the [first scan instructions](../tools/README.md#首次-godot-扫描).
Configuration-only setup may defer this to the authorized first run and must
report that it was not executed. Reuse completed preparation on later Features;
do not add an import wrapper or a per-Feature import phase.
Record the actual setup process and findings in `reports/initialization.md`.
Append a new entry when that report already exists; preserve earlier failures.
This is a human-readable task report, not a machine gate or another state file.
Progress keeps the current result, blockers, next step and report link.
Set status ready
after confirming configuration, then run:

```powershell
python -B tools/checks/check-project-environment.py --require-ready
```

Without the flag, the checker accepts valid incomplete configuration. With it,
the checker requires ready status, available Python/Godot paths and command
entrypoints, and a live Godot 4.7.x version matching the recorded value.
It does not prepare editor caches, install dependencies, execute tests, script
parsing or lint, initialize Git or claim those checks passed. If setup fails, leave status
incomplete and report the actual reason in Progress rather than duplicating
errors into configuration arrays.

The same runner uses `--scope full` for the configured full test roots.
A required full suite still needs an actual successful full run. Ready
configuration proves environment availability only; Stage 4 proves actual
test and static results. Subsequent Features reuse the configured commands
rather than rediscovering installations.

## 3. Language selection

For a new project:

1. Infer a reasonable proposed default from the language currently used by the user.
2. Ask the user to confirm the proposed document language once.
3. Persist the confirmed BCP 47 tag before generating durable Product or Feature content.
4. Use the persisted value as the authority in every later workflow.

If the user's preference cannot be inferred, propose `en` and ask for confirmation. Inference is only a default; country, IP address, timezone, operating-system locale, and account location must not silently select the language.

Every inferred value is non-binding until the user confirms it. If the evidence is mixed or weak, report that uncertainty instead of presenting a dominant language as fact.

## 4. Content governed by document_language

The following generated, human-readable project knowledge must use `document_language`:

- Product headings, prose, tables, diagrams, UI labels, and audio descriptions
- Feature titles, descriptions, acceptance criteria, and human-readable source annotations
- Feature notes and revision-log explanations
- Current Progress, linked execution archives, implementation decisions, and durable handoff records
- Project-specific natural-language additions written into generated documents

Transient questions, explanations, reports, and verification instructions shown to the user follow the current conversation language. They do not need to match `document_language` unless they are also persisted into the project.

Read `docs/progress.md` as the current state and history index, then load only the
linked Feature/batch archive relevant to the task. New archives under `docs/progress/`
use `document_language`; existing history remains in its original language. A pure
history move preserves the original text and evidence links. Do not translate or
duplicate historical bodies in both Progress and Feature notes during archival.

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

Yaya Loop's executable workflow sources use one canonical English version. This includes Methodology specifications, Skills, templates, Coding Rules sources, explicit tools, and default examples.

Task prompts sent by a user may use the conversation language. Their language does
not by itself change the canonical workflow sources or the configured
`document_language` for durable project output.

Do not create parallel trees such as `methodology.zh-CN/`, localized Skill bodies, or translated Coding Rules libraries. Human-facing entry documents may have explicitly approved translations, such as `README.zh-CN.md`, but those translations are not executable workflow sources.

When rendering an English canonical template into another document language, preserve every required section and its semantics. Rendering must not weaken, omit, or reinterpret workflow requirements.

## 7. Projects missing document_language

An existing initialized project may predate this contract. If `docs/methodology-config.json` exists without `document_language`:

1. Inspect the apparent dominant language of `docs/product.md` and the active Product modules. Active modules are files linked from the module list in `docs/product.md`, excluding entries explicitly marked obsolete or archived; if no usable list exists, inspect current files under `docs/product/` as a fallback.
2. Present that language only as a non-binding migration proposal and ask the user to confirm it. If no language clearly dominates, report the uncertainty and ask the user to choose.
3. Persist the confirmed tag without translating existing files.
4. Record the migration once in the appropriate execution/upgrade archive and link
   it from the Progress history index; keep only a current unresolved decision in
   the main Progress file.
5. Apply the confirmed language to new durable content from that point forward.

Do not select a language from Feature titles alone when Product documents are available, because historical Feature data may contain mixed or imported content.

## 8. Existing mixed-language projects

If existing durable documents already contain multiple languages:

1. Report the mixture and identify the dominant Product language.
2. Ask the user to choose the authoritative `document_language`.
3. Persist the choice without silently translating historical content.
4. Write new standalone content in the configured language.
5. Before substantively editing an existing section written in another language, ask whether to localize that section now or preserve it for a later migration.

Historical completed Features and revision records may remain in their original language. Active Product requirements, pending Features, and current Progress should converge only through explicit, reviewable edits.

## 9. Changing an established document language

Editing the configuration field alone is not a supported language migration. A user who explicitly requests a different document language must receive a scoped migration plan covering at least:

- active Product documents and headings
- pending and in-progress Feature natural-language fields
- current Progress state and links; historical archives are excluded unless explicitly approved
- source anchors or links affected by translated headings
- verification that machine protocol values remain unchanged

Yaya Loop must not start this migration because the user merely changes conversation language. The initial international release does not automatically translate established projects.

## 10. Workflow obligations

Every workflow that creates or updates durable project knowledge must:

1. Read `docs/methodology-config.json` before writing.
2. Resolve missing configuration through the compatibility rules above.
3. Produce human-readable durable content in `document_language`.
4. Preserve the stable protocol elements in section 5.
5. Stop and ask when an edit would create an unapproved language migration.

These obligations apply equally to native agent integrations and agent-agnostic Prompts.

## 11. Initial release boundaries

The first international release verifies English and Simplified Chinese project knowledge. It does not require:

- a runtime localization framework or translation service
- localized copies of canonical workflow sources
- localized tool error registries
- automatic translation of an existing project
- region-specific variants of English
- verified output for every BCP 47 language tag

Support claims in public documentation must not exceed behavior covered by Bootstrap checks, repository tests, and documented smoke scenarios.

Run the canonical English, Simplified Chinese and conversation/document-language mismatch scenarios in [06-document-language-smoke-scenarios.md](./06-document-language-smoke-scenarios.md) before expanding public support claims.
