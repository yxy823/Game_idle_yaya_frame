# Reports and Progress

Keep reusable source in the project source directories. Reports contain actual
execution output; they are not the only copy of reusable tools or project decisions.

## Reports and cleanup

Retain reports needed by current verification, acceptance, unresolved failures
or follow-up work. Link the relevant paths from the Feature or Progress record;
do not maintain a separate ownership ledger, hold file or retention state.

Cleanup is an explicit maintenance action. Inspect the proposed paths, current
references and contents first. Remove only understood, authorized output; leave
unknown files and unresolved evidence for a later decision. Age, directory name
and a later successful run do not by themselves authorize removal of a failure
record. No test runner automatically cleans old reports.

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

Feature notes own durable design decisions, regression links and TODOs. The
archive owns execution history; Progress owns the present. Link between them,
and do not paste the same narrative into all three. A pure Progress/archive
Markdown edit does not invalidate business-test evidence; AC, verification,
Catalog and source changes still do under the semantic snapshot contract.
