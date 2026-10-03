# Writing guide

Improve the explanation of the current Godot project without changing what its documents mean or authorize. Use the reader's task to decide the necessary context and detail.

## Establish the document contract

Identify the requested result and affected files from the current task. Read the relevant existing text and its factual sources before editing. Reuse settled decisions; ask only about a gap that changes the requested result. A code observation describes current behavior, not approval to change an intended game rule.

The following paths belong to the target project, not to the source framework or another Skill package. Read only the contracts relevant to the documents being written, reusing current context:

| Document being written | Source of its content and constraints |
| --- | --- |
| Project README or tool instructions | The existing entry page, actual command or editor interface, and the project's local configuration and usage contract |
| Existing GDD or Product explanation | `methodology/01-product-doc-structure.md`; for Product output, its current templates under `methodology/templates/` |
| Feature records or design explanation | `methodology/02-feature-list-schema.md` and the affected Feature's actual sources and records |
| Architecture or a technical decision record | `methodology/10-architecture-overview.md` and the relevant implemented responsibilities and accepted decisions |
| Reusable project knowledge | `docs/knowledge/README.md`, the relevant topic and original task evidence |
| Research or verification records | `methodology/09-records-reports-and-handoff.md`, the actual evidence and the owning task's research or verification contract |

Apply the target project's `AGENTS.md` and write durable output in its configured `document_language`. Use `methodology/05-document-language.md` when resolving language or rendering a template. Project identifiers and machine-readable structures keep their form whatever the language; reuse the project's terminology and templates. Missing design, approval or evidence remains a gap for the owning task; this writing method cannot supply it. In particular, it does not create a GDD from an idea or reconstruct approved game design from code.

Preserve required template sections, fixed paths, IDs, field names, machine-readable structures and historical facts. An optional outline may omit irrelevant sections; a required Product section remains even when its answer is that it does not apply. Decide from the owning contract, not a general preference for shorter pages.

## Read additional guidance only when needed

- For several documents, unclear ownership, naming, navigation or repeated explanations, use [Document structure](document-structure.md).
- For operational instructions, reproduction steps or a verification guide, use [Procedure writing](procedure-writing.md).
- For a local wording correction, work in the current page and its necessary references. It does not imply a directory migration or repository-wide rewrite.

## Explain the project clearly

Open with the reader's immediate purpose or conclusion where the document's structure permits it. Keep a rule's explanation, applicability and important caveat together. Put a prerequisite or side effect next to the action it changes.

Use the project's established names for scenes, resources, signals, features and domain concepts. Distinguish a packed scene, an instantiated node and its owner when that distinction matters to the explanation; do not invent a new term system for ordinary prose. Changes to gameplay meanings return to their design owner.

Choose the form that makes the relationship visible:

- Use paragraphs for reasoning and consequences, lists for independent conditions, and numbered steps for real ordering dependencies.
- Use tables when rows answer the same questions, such as a tool option's purpose and effect. Keep long rationale outside a cell.
- Use diagrams when they clarify a relevant runtime flow or responsibility boundary. A diagram explains inspected relationships; it is not authority to redesign them.

Apply these sentence-level rules:

- **One sentence, one job.** Give each sentence one action, condition or fact. When a sentence of about 40 words or more combines actions, conditions and exceptions, split it into short sentences or a list. Commands, paths and identifiers do not count toward the length.
- **Explain a shared reminder once.** A general reminder gets its full explanation at its owning source. Elsewhere, keep one sentence and a link only where it prevents a real mistake, such as beside a destructive tool option or before a dependent step. [Document structure](document-structure.md#remove-duplicate-bodies-retain-useful-context) decides which repeated bodies to remove.
- **Prefer concrete wording to officialese and compressed terms.** Name the actual file, field, Skill, section or action instead of abstract nouns such as "the owning contract", "durable" or "the work". Write full sentences with articles rather than telegraphic notes, and write three or more alternatives as "A, B or C" rather than a slash chain.
- **Nest lists only for a real category-to-item relationship.** Keep lists one level deep by default. Nest only when each parent item is a category and its children are members of it; otherwise use paragraphs, numbered steps or a table.

Write concrete statements with their conditions. For example, "the panel works" is insufficient in a verification note. If actually observed, describe which panel was opened, the input used, the displayed result and any uncovered state. Do not turn illustrative wording into a claim that the interaction ran.

Keep natural Markdown paragraphs without fixed-width wrapping. Preserve meaningful structure in lists, tables, code, diagrams and machine-readable templates. The language of these examples does not choose the project's output language.

## Verify and finish the writing task

Compare the changed explanation with its sources: requirements stay requirements, proposals stay proposals, and a result states only what its evidence supports. Preserve the difference between expected behavior, current implementation and observed execution.

Check affected links, section anchors, identifiers and command examples. When an authorized move changes a path, account for its actual readers and tool consumers before completing the edit. Use existing applicable link, format or build checks under the target project's rules; do not import a framework command or claim a check that did not run.

Documentation about a runtime result needs the relevant evidence. Pure wording or navigation work does not itself require launching Godot, regenerating a project or replaying unchanged tests. The owning workflow decides whether a source or contract change invalidates earlier verification. Leave unavailable checks explicit.

Return the edited documents, why the changes help, actual verification and material gaps. For analysis-only work, return the findings without writing. Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
