# Consolidate game-design material

Use this reference to combine scattered notes, GDD topics, supplied documents or adopted discussion results into a maintainable design. Consolidation remains authoring; a separate findings-only review uses `plan-review-godot`.

## Establish what each source supports

Read the relevant material and open questions, and identify each source's topic, current status and actual references. Distinguish adopted rules, candidate designs, implementation observations and measured evidence. User-designated authority and explicit decisions matter; a file's date, size or position in the directory does not settle a design conflict.

When implementation differs from adopted design, preserve that distinction rather than automatically rewriting the design to match it. For a material conflict, identify both claims, their locations, available adoption evidence and what depends on resolving it. Keep an unresolved choice visible and continue independent consolidation work.

A small comparison in the conversation or affected topic is sufficient when needed. Do not create a new source ledger or record every file's metadata merely to organize the task.

## Consolidate without losing design

Use [Design document structure](design-docs.md) for the output and its standard naming contract. New GDD outputs and authorized standardization use the fixed names; preserve existing paths outside that scope and update affected file/heading references when moving content. Consolidate unresolved design conflicts into the existing open-questions document with their sources and effects, replacing duplicated question bodies with links. When authorized consolidation concerns overall scope, move that content and update its references; preserve unrelated existing structure. A single-file GDD does not require another copy or conversion of all its topics merely for a local consolidation.

Give each retained rule an owning location. Preserve its exceptions, assumptions, numeric meaning, decision state and useful evidence even when the surrounding wording is compressed. Place system rules and numerical models under their fixed paths in methodology 01, and confirmed professional specifications under their owners in methodology 11; neither complexity nor their original location changes that assignment. Collect confirmed term definitions and aliases from the supplied material into `docs/terminology.md` through `project-terminology`, following **Project terminology** in methodology 01. Replace migrated active bodies with references while retaining the task's protected original inputs as source material. Resolve unsettled meanings before recording them as confirmed definitions.

Keep enough source-to-result information to verify that substantive content was retained or deliberately changed. A brief explanation is enough for a small consolidation; a larger migration may need a mapping table in the response or an existing task record. This does not require another artifact.

Check the new or updated entry, affected links and anchors, and cross-topic agreement in rules, terms and numbers. Only replace, archive or remove old material within the actual task's authorized scope. An explicit separate-copy request preserves the inputs; ordinary local editing has no separate-copy requirement.

## Deliver the consolidated design

Provide the resulting entry or edited topics, explain material structural changes and adoption reasoning, and identify any unresolved conflict and its consequence. A proposal introduced during consolidation remains a proposal until adopted. State actual coverage and evidence limits rather than claiming that organized documentation proves gameplay or implementation.
