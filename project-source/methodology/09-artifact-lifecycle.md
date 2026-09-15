# Reports and Progress

Keep reusable source in the project source directories. Reports contain actual
execution output; they are not the only copy of reusable tools or project decisions.

## Reports and cleanup

Choose output locations when preparing a run or temporary workspace:

| Artifact | Location and responsibility |
| --- | --- |
| Tool or workflow-defined reports | Keep their existing paths, including `reports/gdunit-wrapper/run-<id>/`, `reports/manual-acceptance/` and `reports/initialization.md`. Their readers and evidence references depend on those contracts. |
| Custom logs, results and screenshots | Group under `reports/<task>/`, using the Feature ID or a descriptive maintenance key. Add run subdirectories when needed to preserve distinct attempts; avoid scattering custom files or per-run directories at the report root. |
| Temporary projects, probes, reference-source excerpts and command-support files | Use `reports/scratch/<task>/`, with separate attempt directories as needed. Keep each copied project and its generated caches inside that workspace; copy only the inputs needed for the check. |

Create these directories only when needed. Where a tool supports output paths,
save retained results in the task report directory separately from scratch inputs.
When evidence remains embedded in a scratch project, retain the required workspace
and link the actual evidence location. A scratch path alone does not establish
that its contents are disposable.

Apply the [temporary-file lifecycle rule](../agent-rules/00-core/third-party-generated-and-temporary-files.md#temporary-backup-and-scratch)
when creating scratch material. If it must survive the task or handoff, record its
purpose and release condition in existing Feature notes or Progress, such as
completion of a pending acceptance or investigation. Keep reusable tools and
fixtures in their normal source directories. Changing an existing output layout
requires checking its producers, readers and current evidence links together.

Retain reports needed by current verification, acceptance, unresolved failures
or follow-up work. Link the relevant paths from the Feature or Progress record;
do not maintain a separate ownership ledger, hold file or retention state.

Cleanup is an explicit maintenance action. Inspect the proposed paths, current
references and contents first. Remove only understood, authorized output; leave
unknown files and unresolved evidence for a later decision. Age, directory name
and a later successful run do not by themselves authorize removal of a failure
record. No test runner automatically cleans old reports.

## Project knowledge

`docs/knowledge/README.md` owns the knowledge organization and entry guidance.
Start with Godot runtime, GDScript, debugging/testing and tools/pipelines topics,
with indexes and separate Markdown entries for successful approaches and failure
lessons. Add project-module subtopics when actual content benefits from them.
These notes are contextual evidence,
not Product requirements, engineering rules or executable inputs.

Task documentation may extract a useful reusable explanation here, linking its
Feature, commit, report, test or reference evidence. Feature notes retain the
original incident and local decisions; avoid copying the full history. Check
existing coverage before adding an entry, and keep its nearest index useful.
Pure knowledge Markdown and index edits do not invalidate business-test evidence;
source, tests, configuration and governing contracts remain semantic inputs.
Runnable scripts, fixtures and data belong in their normal project directories.

Finalize task-owned entries and index changes before the normal task commit;
the handoff reports links. A read-only task does not write entries. Missing new
learning requires no placeholder note. Updating project knowledge does not
authorize rule promotion or changing another project or the framework.

## Progress

`docs/progress.md` contains current state, blockers, pending decisions, next
legal action and a history index. It links approved plans and evidence instead
of copying their bodies. Ordinary Markdown headings are sufficient; no machine
markers or prescribed parser layout are required.

The Agent archives completed Feature or approved batch history once under
`docs/progress/<key>.md`, keeping a link in the current Progress document.
Preserve remaining blockers, pending decisions, original history and evidence
links; do not infer approval, overwrite an existing archive or duplicate older
history. Use `document_language` for new prose; moving history does not require
translating it.

Feature notes own durable local decisions, regression links and TODOs. Important
cross-Feature technical choices may use an ADR under
[the architecture convention](10-architecture-overview.md#architecture-decision-records);
Feature notes link that rationale instead of repeating it. The archive owns
execution history; Progress owns the present. Link the authoritative records
without pasting the same narrative into them. A pure Progress/archive Markdown
edit does not invalidate business-test evidence; AC, verification, Registry and
source changes still do under the semantic snapshot contract.
