# 09 · Records, reports and handoff

This document defines where reports, research, project knowledge and Progress are kept, and how a task is handed off or continued in another conversation. Reusable tools and project decisions stay in the project source directories; reports contain only actual execution output.

## Reports and cleanup

Choose output locations before producing a run or temporary workspace. Keep the report root for fixed entry points; create the following directories only when needed:

| Artifact | Location and responsibility |
| --- | --- |
| Tool or workflow-defined reports | Keep their fixed paths, including `reports/gdunit-wrapper/<Feature-ID>/run-<id>/` (or `focused/run-<id>/` under the same root), `reports/manual-acceptance/` and `reports/initialization.md`. Their readers and evidence references depend on those contracts. |
| Custom Feature logs, results and screenshots | Use `reports/features/<Feature-ID>/`, including engineering Features. Keep results with their Feature rather than scattering files at the root or grouping several Features in a Product scratch directory. |
| Custom reports without a Feature | Use `reports/maintenance/<task>/`, with a descriptive maintenance or investigation key. |
| Temporary documents: drafts, interim plans, handoff copies and reference-source excerpts | Use `tmp/<task>/` at the project root, with topic or attempt subdirectories as useful. Do not mix temporary documents into normal source or documentation directories. |
| Temporary projects, probes and command-support files | Use `reports/scratch/<task>/`, with separate attempt directories as needed. Keep each copied project and its generated caches inside that workspace; copy only the inputs needed for the check. |

Temporary documents in `tmp/` are local and ignored by Git. Integrate lasting decisions into their owning maintained documents before removing drafts; retain any temporary material still needed by the current task or handoff.

### Saving results

- Where a tool supports output paths, save kept results in the task report directory, apart from scratch inputs.
- Use descriptive filenames. Add a run subdirectory when separate attempts must survive, and never overwrite a referenced original.
- Suffixes such as `final`, `verified` or `delivery` do not identify the applicable result; the Feature or Progress evidence link does.
- When evidence stays inside a scratch project, keep the needed workspace and link the actual evidence location. A scratch path alone does not make its contents disposable.
- Prefer the original tool output: gdUnit already keeps `result.json`, `engine.log` and its raw reports together. Save a console transcript only when it keeps useful information the originals lack.
- A custom report or screenshot is evidence. Probes and candidate inputs belong in scratch; temporary documents such as commit messages belong in `tmp/<task>/`. Reusable generators and fixtures belong in normal source directories, even when their outputs are temporary placeholders.

### Keeping scratch material

Apply the [temporary-file lifecycle rule](../agent-rules/00-core/third-party-generated-and-temporary-files.md#temporary-backup-and-scratch) when creating scratch material. If it must survive the task or a handoff, record its purpose and release condition in the Feature notes or Progress, for example the completion of a pending acceptance or investigation. At normal task close, check the task's actual output locations and evidence links, and identify scratch material still needed. Progress and Feature records are the reading entry; do not create a second report index or retention ledger.

### Organizing and cleaning reports

- Keep reports needed by current verification, acceptance, unresolved failures or follow-up work, including evidence linked from kept history and knowledge entries. Link their paths from the Feature or Progress record. Do not keep a separate ownership ledger, hold file or retention state.
- Before organizing reports, check their producers, readers and evidence links together, including earlier Progress and knowledge references. Keep tool-managed run directories and acceptance originals at their fixed paths. Grouping files and repairing references does not authorize deleting them or rewriting earlier evidence.
- Cleanup is an explicit maintenance action. Inspect the proposed paths, current references and contents first. Remove only understood, authorized output; leave unknown files and unresolved evidence for a later decision.
- Age, directory name or a later successful run alone does not authorize removing a failure record. No test runner cleans old reports automatically.

## External research

### Deciding and delegating research

The coordinating Agent decides whether current evidence is enough, whether a direct lookup helps, or whether a bounded investigation should go to the `researcher` role. No Stage, topic or Feature requires research.

- **Delegating:** pass the question, concrete target versions, project constraints, useful evidence already found, and whether and where to save a report. Keep independent work moving; only decisions that depend on the findings wait for them.
- **Direct lookups:** follow the role's source and version guidance without starting a subagent or writing a full report.
- **Role unavailable:** if the client cannot select the role, give an available agent the role's instructions or research directly, and say which was used.
- **Prefer `anysearch`:** use the user-installed `anysearch` Skill when available. It is an external tool and is not copied into the project; the role may fall back to other search methods on its own.
- **After the result:** the coordinating Agent checks whether the findings apply, adopts decisions within current authorization, finishes the task's documentation and commits, and continues the task. Neither a result nor a failed search changes that authority.

### Saving research

Saved external findings go in `docs/research/<descriptive-topic>.md`, created only when useful research is saved. The initial directory README is navigation only.

- The `researcher` role in `.codex/agents/researcher.toml` defines the minimum report content and search guidance. The coordinating Agent assigns the report and decides what to adopt.
- Navigate through the Feature design, notes or Progress links. Add report links to the directory README only when the number of reports warrants it.
- Reports are ordinary version-controlled Markdown. `reports/` stays the location for local execution evidence and scratch.

Research is cited reference material. It is not approved intent or proof of local runtime behavior.

- Accepted game-design decisions update the GDD. Delivery boundaries, professional specifications and technical decisions update the Product, specialist document, Feature design or ADR, with a reference to the research.
- Lessons confirmed through project work may enter `docs/knowledge/`, linking the research and actual evidence without copying the report.
- When revising research, keep conclusions that other documents reference. Do not create a second task ledger.

Research Markdown does not affect test evidence ([content fingerprint](08-test-traceability-and-evidence.md#content-fingerprint)), so requirements cannot live only there. Scripts, fixtures and other non-Markdown files belong in normal source or report locations. A research-only assignment does not authorize experiments, implementation, requirement changes or marking a Feature complete.

## Project knowledge

`docs/knowledge/` holds reusable explanations from project work. Feature notes keep brief incident learning and links to local decisions in the Feature design. Incident notes are contextual evidence, not Product requirements, engineering rules or executable inputs. Follow the knowledge README for [organization](../docs/knowledge/README.md#organize-entries) and [entry maintenance](../docs/knowledge/README.md#maintain-during-authorized-work).

Knowledge Markdown and its index do not affect test evidence; see [content fingerprint](08-test-traceability-and-evidence.md#content-fingerprint). Runnable scripts, fixtures and data belong in their normal project directories.

Finalize task-owned entries and index changes before the normal task commit; the handoff reports links. Updating project knowledge does not authorize rule promotion or changing another project or the framework.

## Progress

`docs/progress.md` contains the current state, blockers, pending decisions, the next allowed action and a history index. It links approved plans and evidence instead of copying their bodies. Ordinary Markdown headings are sufficient; no machine markers or prescribed parser layout are required.

The initial `docs/progress/README.md` explains the directory and links back to current Progress; it is not an archive or another history index.

The Agent archives the history of a completed Feature or approved batch once, under `docs/progress/<key>.md`, and keeps a link in the current Progress document. Keep remaining blockers, pending decisions, original history and evidence links. Do not infer approval, overwrite an archive or duplicate earlier history. Write new prose in `document_language`; moving history does not require translating it.

The archive holds execution history and Progress holds the present. Feature notes hold task reminders, regression links, TODOs and navigation. Implementation design and local decisions live in `docs/features/F0XX-design.md` under the [Feature design contract](02-feature-list-schema.md#feature-design-and-implementation-notes); ADRs and standalone technical decisions follow [10 · Architecture overview](10-architecture-overview.md#architecture-decision-records). Link those records instead of pasting the same narrative into Progress or notes.

## Task handoff

Prepare a handoff from the current request, relevant files, actual Git state and the task records. Preserve the original goal, confirmed decisions, still-valid authorization, actual stop point, unresolved obligations and the next allowed action. Identify the next conversation's concrete purpose when one is planned, not merely "continue the project". Separate completed work, evidence for the observed version, unverified claims, blockers and pending human acceptance.

Information that must survive the conversation goes in Progress and the Feature notes; work without a Feature uses Progress and its task files. Link designs and original evidence instead of copying them. Update only the records this task needs, within authorization.

- A summary-only request needs no file writes.
- A pause record needs no continuation prompt.
- Preparing a handoff does not require rerunning completed checks or finishing the paused implementation.

Follow `agent-rules/00-core/git-worktree-and-commits.md` to preserve state in the task's checkout and for any authorized record commit. A handoff does not:

- establish human acceptance or completion;
- reset Feature state or discard work in progress;
- create a second handoff ledger or require an operating-system temporary file;
- open a new conversation, send a message or start the proposed action.

Respect the user's explicit pause or narrower current scope; earlier implementation authorization cannot override it.

`task-handoff-godot` is the direct entry for this work. A request only to understand status or choose a workflow may use `project-next-step-advisor` instead; it is read-only and does not update records. When a prompt is requested, follow the format below with current project facts. The advisor takes scenario material from its declared shared Godot catalog; task handoff uses the owning task's sources.

## Continuation prompts

Every drafted task or continuation prompt uses level-two headings for these fields, in this order:

1. Goal
2. Scope
3. Inputs and sources of truth
4. Decision boundaries and authorization
5. Constraints
6. Output and delivery
7. Verification requirements
8. Completion conditions

Write the headings in the current conversation language, like the rest of the prompt; for example, a Chinese conversation uses `目标`, `范围`, `输入与事实来源`, `决策边界与授权`, `约束`, `输出与交付`, `验证要求`, `完成条件`. Fill every field with content specific to the task, however short the prompt.

- Cite the destination's actual rules for shared requirements instead of copying them.
- Add clearly labeled fields for background or entry point, conflict handling, environment, or risk and recovery beside the related fields, only when relevant.
- The format is presentation only; it adds no workflow step or approval gate.

State the destination task's purpose and first useful action, its real current sources and the remaining obligations.

- Keep effective authorization and explicit limits. Do not invent IDs, paths, command availability, completed checks, decisions or acceptance; name missing facts as gaps.
- Separate blocked or pending-human states from successful completion.
- Neither a field nor a Skill boundary ends broader valid authorization, and the word "continue" supplies no missing authorization.

Produce task-specific copyable text when requested, not a maintained template file or a parallel prompt collection. Handoff and the advisor share this format; their different read and write responsibilities still apply.
