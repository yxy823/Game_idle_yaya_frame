# 14 · Project terminology

This specification defines what the project terminology file contains, when terms are recorded and how term changes are handled.

## Project terminology

`docs/terminology.md` is the single authoritative file for confirmed project term definitions, canonical names, aliases and conceptual distinctions. `project-terminology` maintains it and the links to it. The location is fixed whether a term is used in one topic or across systems, Products, Features or conversations.

- GDD, Product, Feature and professional documents use these terms and link their definitions. They do not keep separate domain glossaries or local authoritative definitions.
- The terminology file explains what a project concept means and how its name differs from related names.
- GDD owns the concept's detailed gameplay rules, conditions, flows, values, state transitions and intended experience. Professional documents own their specifications; architecture and code own implementation choices. A short definition may identify a concept by its role and link to the design document for its full behavior.
- Target-locale wording belongs in the **Term translations** section of the localization specification, under [Localization term translations](11-specialist-workflows.md#localization-term-translations). A translated name is not a competing domain definition.
- Ordinary explanatory prose and examples stay with the topic they explain.

Do not create a second `UBIQUITOUS_LANGUAGE.md` or another parallel glossary. Do not turn the file into a general project-context document or a dictionary of ordinary words and engine APIs.

New projects include this file with only its purpose. If the file is missing, create it when saving confirmed definitions. While no terms are confirmed, leave it without entries; do not invent entries or block unrelated design work.

Read the relevant definitions during clarification, planning, implementation and review when the file exists. Write it in `document_language` and keep stable IDs. Do not rename code or migrate saved data only to match terminology. A known code identifier may be recorded as an alias; this does not authorize code or save-data migration.

## Clarify competing terms

Clarify vocabulary when competing names or meanings would change a design or delivery decision. Read the current definitions first.

- If one word describes different concepts, distinguish them with familiar names.
- If several words mean the same thing, propose one consistent name.
- Reuse an already clear definition instead of starting a glossary for every task.

Test a distinction with a concrete scenario. For example, when discussing inventory, distinguish an item definition, an owned item and a stack only if their identity or behavior differs. Asking whether two items with different modifiers can stack exposes a real decision; listing every possible item attribute does not. Record the accepted behavior in its GDD section, and derive delivery scope and AC from that section.

When implementation exists, compare the relevant code with the stated meaning. Report a conflict with both sources: code describes what happens today and cannot silently redefine approved intent. A new meaning stays a proposal until the user settles the design choice through `design-gdd`.

## Record terms during design work

Authorized GDD creation, revision and consolidation include recording the current scope's confirmed terms in `docs/terminology.md` through `project-terminology`, together with the affected links.

- Collect the definitions already present in the supplied design; do not wait for another system, Product or Feature to use them.
- Reuse the task's writing authorization unless the user explicitly limits the writable files. Discussion-only work writes nothing.
- Recording a term does not establish game design or authorize development.

Use a compact structure and expand only where a distinction needs explanation:

- Start with a short description of the covered domain when it helps the reader. Give each term a canonical name and a definition, normally one or two sentences. Include domain actions as well as nouns when their meanings matter. There is no word or term quota.
- Explain conceptual relationships, aliases or commonly confused neighbors only when they prevent a real misunderstanding.
- Link to the GDD section for detailed rules, flows, values and state transitions, and to Product and Feature records for delivery scope and AC. Keep implementation state ownership, Godot classes, storage formats and technical choices in architecture records or code.
- Keep pending ideas, chat logs, current progress and task-local notes out of the file.
- Move definitions from the authorized GDD or professional scope into this file and replace their bodies with links. Keep section anchors that Feature sources use, with a link at the old location. Original input materials that the task must preserve stay marked as source material; current definitions live only in the terminology file.

## Responsibilities

| Skill | Responsibility for terms |
| --- | --- |
| `project-terminology` | Meaning-preserving definitions in `docs/terminology.md` and the links to them |
| `design-gdd` | Overall game design, including any change to what a term means for gameplay |
| `design-balance` | Scoped numerical design |
| `product-author` | Product delivery documents |
| `project-grill-me` | Clarifies a term and returns the answer to the current task |
| `product-spec-elicitor` | Clarifies delivery choices |

Using `project-terminology` during GDD writing does not start Product planning. Pure terminology maintenance may clarify a name, record an already agreed distinction, or move and link a definition. It does not need a new Product, Feature or Feature synchronization.

If a definition change alters actual intent or exposes an unresolved behavior choice, settle that choice through `design-gdd` first and synchronize affected work with `feature-sync`. Then update the terminology.

## Incremental terminology maintenance

Check for new terms, renames, retirements and clarified meanings during GDD and Product writing and at the Stage 3 documentation checkpoint before final verification. Save confirmed additions or changes in `docs/terminology.md`. If nothing changed, do not write the file or produce an empty report. Settled, meaning-preserving changes reuse the task's documentation authorization; discovering a new design choice does not approve it.

- Add confirmed definitions, merge duplicates and repair links.
- For a rename, keep the old name only while it helps readers find the canonical term.
- For a retirement, keep a link to the replacement when historical references need it; otherwise remove the obsolete wording within scope.
- Settle semantic changes through `design-gdd` first, as described in [Responsibilities](#responsibilities).
- Keep only the current definitions here. Record the reason for a change in the GDD, Feature design or ADR where it belongs, or leave it to Git; do not keep a glossary change log.
