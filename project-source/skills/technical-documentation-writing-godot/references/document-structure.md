# Document structure and ownership

Use this reference when readers cannot find an explanation, a document serves unrelated purposes, or several pages maintain the same facts. First identify the lookup problem and the actual consumers of the affected files.

## Organize around project questions

Keep the project's prescribed locations for GDD, Product, Feature records, architecture, knowledge and evidence. Within the area open to organization, group pages by what readers need to understand or do. A navigation-only grouping is insufficient when a growing directory still hides unrelated material in one flat collection; a small coherent topic needs no extra hierarchy.

For example, a growing knowledge topic about scene lifecycle may benefit from separate entries for reconnecting signals and restoring a reopened interface. Each entry should answer a real recurring question and link its evidence. A short note about one incident may be better served by the existing entry. These are possible groupings, not mandatory file names or proof that this project has those defects.

Compare reusing the current page, improving its headings, splitting independent explanations, merging duplicates and moving files. Choose a directory change when its concrete navigation benefit justifies updating readers and references. A request to clarify one Feature description does not authorize moving the Feature ledger.

Before an authorized move or rename, inspect links, template references, source fields, identifiers and any tool that consumes the path. Preserve historical meaning and stable IDs. Update the affected references in the same task; use the project's actual compatibility policy instead of introducing redirects or a second path map.

## Give each explanation an owner

Follow the local contracts identified in [Writing guide](writing-guide.md#establish-the-document-contract). Those contracts decide which document owns a rule, a delivery boundary, a technical choice or a result; this reference does not define a second schema.

A useful distinction in a Godot project is:

- The governing design explains a gameplay rule, such as what limits inventory capacity.
- Delivery and Feature documents explain the adopted scope and how it will be verified, linking that rule instead of keeping another copy of its formula.
- A relevant architecture page explains the implemented responsibility or dependency, with links to an accepted decision when its rationale matters.
- A knowledge entry explains a reusable lesson from actual work and links the original incident or evidence.

Use this distinction only where it matches the current owning sources. Do not create every document in order to explain a small change, move binding requirements into knowledge, or use a documentation rewrite to adopt a new technical design.

Keep live task state in its existing record. Historical verification and decisions retain their original version and limits. When a later source supersedes them, add the appropriate current reference or correction without rewriting history as though the newer behavior had always existed.

## Make navigation useful

An entry page answers who it serves, what is available and where to continue. Topic indexes provide links and concise purposes; the linked pages carry the full explanations. Avoid duplicating an entire setup procedure in the project README and the tool guide merely to make both pages appear complete.

Name a page for its object or task. "Inventory persistence contract" and "Reproduce an inventory restore failure" serve different questions; use such a distinction only when both documents are actually needed. Preserve conventional Feature file names and other identifiers required by project tools. Document titles and ordinary prose follow `document_language`.

For a reader who must perform one step, point to the relevant preparation, check or recovery section. A broad link to all project methodology makes the reader rediscover the route. Verify both that the target exists and that the linked section contains the needed information.

## Remove duplicate bodies, retain useful context

Keep a full rule, method or tool contract at its owning source. Elsewhere retain the local action, trigger, ordering dependency or warning needed to use it, plus an accurate link.

For example, a save/load verification guide may need to state which local scene and test data the current check uses. It can link the test runner's documented options instead of maintaining a second command reference. A Feature explanation may summarize the outcome of an acceptance criterion, but must not maintain a second editable set of criterion IDs or passing results.

Repeated words alone do not establish unnecessary duplication. A brief reminder beside a destructive tool option or before a dependent step can prevent a real mistake. Remove repeated definitions and full procedures when they add maintenance burden; do not shorten a pointer until its triggering condition or destination becomes unclear.

Check the revised reading path from the original user question to its answer. A successful reorganization preserves the relevant contract, makes the answer easier to locate and leaves no abandoned authoritative copy or broken consumer within scope.
