# Design document structure and rule ownership

Use this reference when creating a GDD entry or topic, revising organization or deciding where a design rule belongs. [Design coverage](gdd-fields.md) describes the design questions; this page organizes their answers.

## Use a navigable structure

For a new GDD, use `docs/gdd/README.md` and the fixed topic paths and naming patterns defined by **GDD document names** in `methodology/01-product-doc-structure.md`. That section owns the content-to-location mapping, system keys and reference rules. The entry introduces the game and reading path; topics hold their assigned rules and decisions and link relevant open questions. Use the same structure throughout development, without choosing file placement by size or complexity.

Preserve existing structure outside an authorized restructuring scope, including an existing single-file GDD. Standardization uses the naming contract above and updates affected references; a local change does not require reorganizing unrelated design or saving a separate copy. Establishing the scope and open-questions documents follows their own creation contracts.

Use the configured `document_language` for titles and prose while keeping standard filenames unchanged. System and model instances follow the owning contract's fixed patterns. Do not add numeric prefixes, translated filename variants, ad hoc topic locations, a version-number scheme or role/owner fields.

The standard names are:

```text
docs/gdd/
  README.md
  concept-and-experience.md
  gameplay.md
  systems/<system-key>.md
  balance/<system-key>.md
  balance/cross-system.md
  progression.md
  presentation.md
  design-scope-and-boundaries.md
  open-questions.md
```

These locations are fixed for their stated responsibilities. Create a body when its content is written, including system rules from the first system in a draft; the gameplay overview links them. Do not create empty topics or duplicate decision histories to fill the list.

## Give each rule one owner

Keep a rule's definition, meaningful exceptions and relevant decision or evidence limits together. Other pages link to that location and explain how they consume it. A short navigational summary is useful; maintaining another full rule body is not.

When changing a rule, inspect its affected systems, numeric assumptions, presentation requirements and validation scenarios. Update necessary references within authorization. Moving a file or renaming a heading also requires fixing affected paths and anchors. For planned consumers, follow the existing source-impact route in the Skill entry; document restructuring does not silently change implementation scope.

GDD owns the game's intended behavior. Product selects a deliverable scope and references GDD. Professional sources refine presentation or production requirements. Feature design and architecture explain implementation. Use these distinct purposes when deciding where content belongs instead of copying the same design into all four.

## Write an implementable topic at the right depth

A useful system topic explains its purpose, player process, rules and relevant dependencies. Add sections only when they help answer the current design question:

- Intended experience and current scope.
- Triggers, player inputs, states, results, limits and recovery paths.
- Specifications and existing numeric rules, with units and sources. Use `design-balance` for derived formulas or related parameter sets.
- Interactions with other systems and visible feedback, linking their owning passages.
- Observable rule scenarios and experience questions, keeping actual evidence separate from plans.
- Working assumptions that still affect interpretation, with links to their unresolved choices in the open-questions document rather than a second question body.

For example, a candidate light-board design could say that clicking a cell toggles that cell only; the flow topic defines whether input remains available after all cells are lit. The display topic references that completion state for its message rather than redefining it. A sample play sequence can expose whether a mistaken click is recoverable. These are illustrative candidate rules, not adopted requirements or verified experience.

Ordinary dimensions and item counts can be specified directly when supported by the request. Do not treat every numeric field as a modeling project. Likewise, a written formula or time target is not evidence that its intended pacing has been observed.

## Make principles useful for decisions

A design principle should connect an experience to a real choice. For example, an adopted goal of unhurried experimentation might support reversible actions and clear recovery feedback; a candidate timer would then need a reason compatible with that goal. The example does not require every game to be forgiving.

Avoid principles that merely restate quality aspirations. Prefer a short explanation of what a principle changes or excludes. Use as many as the game needs to guide its current tradeoffs, without assigning a fixed count or score.

## Deliver the current source

Link the actual entry or changed topic and explain important revisions and remaining limits. Check that the reader can find the requested design and that links, terms and decision states agree. Preserve evidence as evidence and proposals as proposals; document completion alone does not establish adoption, implementation or human acceptance.
