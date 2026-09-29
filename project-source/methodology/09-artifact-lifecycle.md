# Reports and Progress

Keep reusable source in the project source directories. Reports contain actual execution output; they are not the only copy of reusable tools or project decisions.

## Reports and cleanup

Choose output locations before producing a run or temporary workspace. Keep the report root for fixed entry points; create the following directories only when needed:

| Artifact | Location and responsibility |
| --- | --- |
| Tool or workflow-defined reports | Keep their existing paths, including `reports/gdunit-wrapper/<Feature-ID>/run-<id>/` (or `focused/run-<id>/` under the same root), `reports/manual-acceptance/` and `reports/initialization.md`. Their readers and evidence references depend on those contracts. |
| Custom Feature logs, results and screenshots | Use `reports/features/<Feature-ID>/`, including engineering Features. Keep results with their Feature rather than scattering files at the root or grouping several Features in a Product scratch directory. |
| Custom reports without a Feature | Use `reports/maintenance/<task>/`, with a descriptive maintenance or investigation key. |
| Temporary projects, probes, reference-source excerpts and command-support files | Use `reports/scratch/<task>/`, with separate attempt directories as needed. Keep each copied project and its generated caches inside that workspace; copy only the inputs needed for the check. |

Where a tool supports output paths, save retained results in the task report directory separately from scratch inputs. Use descriptive filenames; add a run subdirectory when distinct attempts need to survive, and never overwrite a referenced original. Repeated `final`, `verified` or `delivery` suffixes do not identify the applicable result; the existing Feature/Progress evidence link does. When evidence remains embedded in a scratch project, retain the required workspace and link the actual evidence location. A scratch path alone does not establish that its contents are disposable.

Prefer the original tool output: gdUnit already keeps `result.json`, `engine.log` and its raw reports together. Save an additional console transcript only when it preserves useful information missing from those originals. A custom report or screenshot is evidence; the probe, candidate input or commit-message file used to produce a result belongs in scratch. Reusable generators and fixtures belong in normal source directories, even when their outputs are temporary placeholders.

Apply the [temporary-file lifecycle rule](../agent-rules/00-core/third-party-generated-and-temporary-files.md#temporary-backup-and-scratch) when creating scratch material. If it must survive the task or handoff, record its purpose and release condition in existing Feature notes or Progress, such as completion of a pending acceptance or investigation. At normal task close, check the task's actual output locations and evidence links, and identify any scratch material still needed. Use existing Progress/Feature records as the reading entry; do not create a second report index or retention ledger.

Organizing existing reports requires checking producers, readers and evidence links together, including historical Progress and Knowledge references. Preserve tool-managed run bundles and acceptance originals at their contracted paths. Grouping files and repairing references does not itself authorize deleting them or rewriting the contents of historical evidence.

Retain reports needed by current verification, acceptance, unresolved failures or follow-up work, including evidence linked by retained history and Knowledge. Link the relevant paths from the Feature or Progress record; do not maintain a separate ownership ledger, hold file or retention state.

Cleanup is an explicit maintenance action. Inspect the proposed paths, current references and contents first. Remove only understood, authorized output; leave unknown files and unresolved evidence for a later decision. Age, directory name and a later successful run do not by themselves authorize removal of a failure record. No test runner automatically cleans old reports.

## External research

Retained external findings belong in `docs/research/<descriptive-topic>.md`, created only when useful research is saved; the initial directory README is navigation only. The `researcher` role at `.codex/agents/researcher.toml` owns the minimum report content and search guidance; the coordinating agent assigns report writing and evaluates adoption. Use existing Feature design/notes or Progress links for navigation, expanding the directory README with report links only when actual volume warrants it. Reports are ordinary version-controlled Markdown; `reports/` remains the location for local execution evidence and scratch.

Research is cited reference material, not approved intent or proof of local runtime behavior. Accepted game-design decisions update the existing GDD; delivery boundaries, professional specifications and technical decisions update their Product, specialist, Feature design or ADR owner with a reference to the research. Useful lessons established through project work may enter `docs/knowledge/`, linking the research and actual evidence without copying the report. Preserve referenced historical conclusions when revising research; do not create a second task ledger.

Pure research Markdown does not invalidate business-test evidence, just like knowledge prose. Requirements cannot live solely there; scripts, fixtures and other non-Markdown files still participate in content binding and belong in normal source or report locations. A research-only assignment does not authorize experiments, implementation, requirement changes or marking a Feature complete.

## Project knowledge

`docs/knowledge/` owns reusable explanations from project work; Feature notes retain the original incident and local decisions. These notes are contextual evidence, not Product requirements, engineering rules or executable inputs. Follow the knowledge README for [organization](../docs/knowledge/README.md#organize-entries) and [entry maintenance](../docs/knowledge/README.md#maintain-during-authorized-work).

Pure knowledge Markdown and index edits do not invalidate business-test evidence; source, tests, configuration and governing contracts remain semantic inputs. Runnable scripts, fixtures and data belong in their normal project directories.

Finalize task-owned entries and index changes before the normal task commit; the handoff reports links. Updating project knowledge does not authorize rule promotion or changing another project or the framework.

## Progress

`docs/progress.md` contains current state, blockers, pending decisions, next legal action and a history index. It links approved plans and evidence instead of copying their bodies. Ordinary Markdown headings are sufficient; no machine markers or prescribed parser layout are required.

The initial `docs/progress/README.md` explains the directory and links back to current Progress; it is not an archive or another history index.

The Agent archives completed Feature or approved batch history once under `docs/progress/<key>.md`, keeping a link in the current Progress document. Preserve remaining blockers, pending decisions, original history and evidence links; do not infer approval, overwrite an existing archive or duplicate older history. Use `document_language` for new prose; moving history does not require translating it.

Feature notes own brief local decisions, regression links, TODOs and links to detailed `docs/features/F0XX-design.md` when needed. Feature design explains that change, while architecture documents describe the current system. Preserve completed designs as history and link later replacements; do not grow JSON notes into a second design document. Important cross-Feature technical choices may use an ADR under [the architecture convention](10-architecture-overview.md#architecture-decision-records); Feature notes link that rationale instead of repeating it. The archive owns execution history; Progress owns the present. Link the authoritative records without pasting the same narrative into them. A pure Progress/archive Markdown edit does not invalidate business-test evidence; AC, verification, Registry and source changes still do under the semantic snapshot contract.

## Task handoff

Prepare a handoff from the current request, relevant files, actual Git state and existing task records. Preserve the original goal, confirmed decisions, still-valid authorization, actual stop point, unresolved obligations and the next legal action. Identify the next conversation's concrete purpose when one is planned, not merely "continue the project". Separate completed work, evidence for the observed version, unverified claims, blockers and pending human acceptance.

Use the existing Progress and Feature notes for information that must survive the conversation. Link authoritative designs and original evidence instead of copying their bodies; work without a Feature uses Progress and its existing task artifacts. Update only necessary task-owned records within authorization. A summary-only request does not require file writes, a pause record does not require a continuation prompt, and preparing a handoff does not require rerunning completed checks or finishing the paused implementation.

Follow `agent-rules/00-core/git-worktree-and-commits.md` for state preservation in the task's target checkout and any authorized record commit. A handoff does not establish human acceptance or completion, reset Feature state, discard WIP, create a second handoff ledger or require an operating-system temporary file. Preserve the user's explicit pause or narrower current scope; old implementation authorization cannot override it. Generating text does not open a new conversation, send a message or start its proposed action.

`task-handoff-godot` organizes this work as a direct entry. A request only to understand status or choose a workflow may instead use `project-next-step-advisor`; that read-only method does not update records. When a prompt is requested, follow the format below using project-local sources; generated projects do not need the framework's full prompt library.

## Continuation prompts

Every drafted task/continuation prompt uses explicit level-two headings in this order: `目标`, `范围`, `输入与事实来源`, `决策边界与授权`, `约束`, `输出与交付`, `验证要求`, `完成条件`. Keep each field substantive and specific to the current task, regardless of prompt length. Cite the destination's actual rules for shared requirements rather than copying them. Add explicitly labeled background/entry, conflict handling, environment, risk/recovery or other conditional fields beside the related fields only when relevant. This is prompt presentation, not a new workflow or approval gate.

State the destination task's purpose and first useful action, real current sources and remaining obligations. Preserve effective authorization and explicit limits; do not invent IDs, paths, command availability, completed checks, decisions or acceptance. Missing facts remain identified gaps. Separate blocked or pending-human states from successful completion; neither a field nor a Skill boundary ends broader valid authorization, and the word "continue" supplies no missing authorization.

Produce task-specific copyable text when requested, rather than another maintained template file or parallel prompt collection. This format is shared by handoff and advisor; their different read/write responsibilities still apply.
