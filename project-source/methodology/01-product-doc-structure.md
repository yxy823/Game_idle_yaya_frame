# 01 · GDD and Product document structure

This specification defines the game design document (GDD) under `docs/gdd/` and the Product delivery documents `docs/product.md` and `docs/product/NN-<delivery>.md`. Related contracts:

- Professional specifications, UI and presentation documents, and resource handoff: [Specialist work and sources](11-specialist-workflows.md).
- Visual and logic prototypes: [Prototypes](13-prototypes.md).
- Project term definitions: [Project terminology](14-project-terminology.md).

Write headings and prose in the configured `document_language` under [document language](05-document-language.md). Filenames and section semantics stay the same in every language.

## GDD prerequisite and authority

Use `design-gdd` to develop a game idea into a GDD, or to deepen, revise or consolidate the current design.

### Work that can start before a complete GDD

The following work can proceed before a complete GDD, Product or Feature exists:

- initial design discussion and the clarification that supports it;
- numerical modeling and presentation exploration that support the initial design;
- review of an actual draft.

Use the known goals, constraints and available draft, and keep assumptions and unresolved choices visible. Discussion alone writes nothing. A request to save a draft does not adopt every proposal in it. Design work does not require a ready Godot environment.

During an authorized GDD authoring or consolidation task, supporting specialist work may save already confirmed specifications at their fixed locations under [Specialist work and sources](11-specialist-workflows.md), within the same writing scope. This exception does not cover unrelated specialist design or implementation.

### Work that requires a substantive GDD

Delivery planning, implementation, engineering repairs and runnable experiments require a substantive GDD under `docs/gdd/`. Other specialist work has the same prerequisite unless it is the early design support described above.

- Read the GDD entry and the sections relevant to the task.
- An empty directory, a directory-navigation README, a template or a pending-state notice is not a GDD.
- If the GDD is missing, explain the missing design and the `design-gdd` route. Stop dependent development; do not invent gameplay or start a design interview the user did not ask for.
- A status query may explain the current state without starting work.

### What the GDD owns

The GDD owns game positioning, intended player experience, core loops, system rules, states, numeric behavior, content progression and game-version design scope. Use the [standard document names](#gdd-document-names), including [Design scope and boundaries](#design-scope-and-boundaries) and [Open design questions](#open-design-questions). The GDD entry links the actual source files.

- Keep the current organization unless a restructuring is authorized. Do not create empty chapters or duplicate bodies.
- The GDD need not settle every future detail. The current delivery scope and its design dependencies must be clear before dependent planning or implementation.
- When a design gap affects the current work, resolve it in its GDD topic and update its open question. Do not invent the missing rule in Product or Feature text.

The GDD holds game rules and overall experience goals and links the professional documents for presentation, UI, art, audio, resources and localization. [Ownership and decisions](11-specialist-workflows.md#ownership-and-decisions) assigns those documents. Implementation design belongs in the Feature design, the current implemented structure in architecture, and executable behavior in code.

For example, for a shop purchase the GDD owns the purchase conditions, state effects and intended feedback. The shop UI specification and the item-arrival presentation describe how the player operates and perceives the purchase. Product selects a coherent delivery across those sources. Detailed collaboration and state ownership belong in architecture or the Feature design. `docs/game-organization.md` explains this split between logic and presentation; it does not make the GDD a logic-only document.

### Who writes the GDD

The GDD is a maintained project source. Within the user's concrete authorization:

- `design-gdd` owns overall game design and consistency across topics.
- `design-balance` directly maintains numerical models, formulas, parameters and calculation explanations at their fixed GDD location. Ordinary specification values do not require numerical modeling.
- `product-author` writes delivery documents, not game design.

The current task updates affected Product and professional documents and planned Features through their own Skills. No Skill has to relay another Skill's writes.

### Proposals and adoption

- A proposal is not accepted design. Adoption is also separate from calculation, runtime or experience verification.
- File presence or a saved edit does not by itself confirm a choice. Saving a candidate never replaces an adopted value.
- Changing an experience goal, adding a mechanic or altering another system to make a model work is an overall design decision for `design-gdd`.
- Numerical design does not authorize edits to runtime code or resources.
- When planned or completed work is affected, keep unrelated content and follow the source commit, synchronization and validation rules in [Specialist work and sources](11-specialist-workflows.md#ownership-and-decisions).
- An initial GDD draft does not need Products, Features or synchronization records. The GDD needs no separate permission, tracking ledger or synchronization system.

### Before revising design or delivery scope

Check the relevant GDD design boundaries, the engineering constraints in `docs/project-rules.md` and the relevant accepted architecture decisions. A design request does not silently change an engineering rule; resolve such a conflict through [incremental rule maintenance](04-project-rules.md#incremental-rule-maintenance).

## GDD document names

New GDDs and authorized standardization use these exact filenames for the matching content; do not substitute similar names. Filenames stay the same in every document language; titles and prose follow `document_language`.

| Filename under `docs/gdd/` | Content |
| --- | --- |
| `README.md` | GDD entry: a brief game introduction, the covered scope and links to the actual design files. |
| `concept-and-experience.md` | Game concept, player context, intended experience, design principles, world premise, character identities and relationships, and the authored story outline. Narrative mechanics belong in their system file. |
| `gameplay.md` | Core loop, representative play, relationships between systems and navigation to the game's systems. |
| `systems/<system-key>.md` | One game system's mechanics, inputs, states, transitions, limits, rule scenarios and content-definition catalog, including branching or stateful narrative rules. Reference numerical models instead of copying them. |
| `balance/<system-key>.md` | That system's numerical models: variables, formulas, parameter values, curves, calculation assumptions and derivations. |
| `balance/cross-system.md` | Numerical models whose relationships span several systems. System-specific models stay in their own files and are referenced. |
| `progression.md` | Content placement, teaching and challenge sequencing, progression goals and intended pacing. Reference content definitions and unlock rules in system files and curves in balance files. |
| `presentation.md` | Game-level interaction, understanding, intended player feelings, recognition needs and feedback goals. Link the UI and presentation specifications, and the Art and Sound Bibles for visual style and sound standards. |
| `design-scope-and-boundaries.md` | Overall design scope, confirmed exclusions and version boundaries, under [Design scope and boundaries](#design-scope-and-boundaries). |
| `open-questions.md` | Current unresolved design choices and missing evidence, under [Open design questions](#open-design-questions). |

Use this structure from the first draft onward, whatever the game size, document length or complexity:

- Create a file when its content is first written; do not prebuild empty topics. Keep the initial purpose notices and the first-write conditions of the scope document.
- A system's rules always go in its `systems/<system-key>.md` file, including the first system in a draft. `gameplay.md` keeps the cross-system view and the links.
- Numerical models always go in the `balance/` file that matches their system scope. An ordinary dimension or item count that is part of a rule stays with that rule. Named model variables, derived values and calculation explanations stay together in the balance file, and rules reference them.

System keys:

- Give each distinct game system one stable lowercase hyphenated `system-key`, recorded with its link in `gameplay.md`. Reuse the same key for its balance file.
- The key identifies the system, not its size, implementation module or writing session.
- `cross-system` is reserved for the cross-system balance file.
- Related models within one system share its balance file under separate headings. Do not split them into more files by complexity.
- When a new system is confirmed, add its link to the gameplay navigation; do not create a separate registry. The GDD entry links the standard topics and the actual system and balance files.

Content definitions follow the system that establishes their gameplay identity, even when another system consumes them. For example, ore types defined by mining stay in `systems/mining.md`; a shop references those definitions and owns its sale rules. Modeled prices and yields belong in the matching balance file, and their distribution across stages belongs in `progression.md`. Static world and character descriptions do not need an invented narrative system; choices, branches and story-state transitions do.

Before naming an output or drafting a prompt for another task, read the current GDD entry. Reference the actual file and heading; do not assume that a standard topic already has content.

For an imported or differently organized GDD:

- Edit a topic at its current location unless its migration is authorized.
- New topics and new systems always use the standard paths above. Link them from the GDD entry and, for systems, from `gameplay.md`. Extending a rule in a current topic does not create a new topic.
- This allows local additions without moving unrelated content or creating a second body.
- When standardization or restructuring is authorized, move the affected content to its standard location and update every affected reference, including Product and Feature sources and professional documents.
- Keep filenames and referenced headings while their meaning is unchanged. A necessary rename or move updates the affected paths and anchors in the same change.

## Design scope and boundaries

`docs/gdd/design-scope-and-boundaries.md` is the fixed GDD document for **Design scope and boundaries** (`设计范围与边界` in Chinese). Keep the path stable, write the title and prose in `document_language`, and link it directly from the GDD entry.

It owns the overall game-design scope, confirmed exclusions and version boundaries across game logic and presentation. Project Rules owns development constraints, collaboration and engineering principles; a long-lived or cross-system game-design boundary still belongs here.

Keep the conditions, exceptions and useful reason with each boundary. Distinguish three cases:

- an adopted exclusion;
- a deferral limited to a named game version;
- an unresolved choice or candidate.

Missing design does not imply an exclusion.

Game versions use the names and scope defined in the GDD; do not invent a release sequence. Product links the version scope it delivers. Splitting or reordering delivery units does not change a game version, and Product keeps no separate version sequence.

Local mechanism limits stay in their GDD topics. Local presentation or Shader constraints stay in the corresponding design or professional specification. Link them from this document only when that helps navigation. Do not collect every local rule here, and do not repeat a boundary's full body in Project Rules, Product, Feature or professional documents. When moving a boundary, update the affected references and replace the old body with a link within the authorized scope.

How work uses this document:

- For game-design discussion, delivery planning, implementation or review, read the relevant sections of this document and of the related GDD topics before proposing work or questions.
- Apply confirmed boundaries when ruling out cases. Read Project Rules when engineering constraints affect the task.
- Reuse unchanged context and explicit user decisions, including decisions not yet saved.
- Pure engineering or status work does not need to load unrelated game-design material.
- If this document has not been written yet, use the available design and confirmed constraints. A missing file does not invalidate substantive design or block discussion.

How the document is written:

- When authorized GDD drafting first saves the game's design, `design-gdd` creates this document from the actual known scope and links it from the entry.
- Authorized scope revisions maintain it and the necessary references as decisions settle. For a GDD that lacks this document, move only the affected scope content; do not reorganize unrelated topics.
- Do not prefill an empty project with invented exclusions, or create a placeholder as evidence of completed design.
- Settled decisions reuse the task's writing authorization. Changing an adopted boundary still needs the corresponding design decision.
- Discussion-only work writes no files. When wrapping up, it names the confirmed conclusions that remain unsaved.
- Supporting Skills return those conclusions to the current task; they do not start a separate rule-maintenance workflow.

## Open design questions

`docs/gdd/open-questions.md` is the fixed GDD document for **Open questions** (`开放问题` in Chinese). It owns the current unresolved game-design choices, and the missing facts or evidence that could change the design. Link it directly from the GDD entry, use descriptive question headings that other documents can reference, and write in `document_language`.

New projects include a purpose and pending-content notice. That notice is not substantive design, and it does not prove that all questions are settled. When authorized drafting starts from a GDD without this file, create it from the actual known questions without reorganizing unrelated topics.

For each question, keep together:

- the actual uncertainty;
- links to the relevant topics and sources;
- its effect on the design or on dependent work;
- the decision or evidence needed to resolve it;
- the compared alternatives or a working assumption, when known, following [Candidate and unadopted ideas](#candidate-and-unadopted-ideas).

Do not invent questions, or fixed IDs, scores, owners or workflow states to fill a template. Distinguish a user choice from a fact that needs investigation, calculation or play evidence. A question about a topic not yet written may describe that scope without linking a nonexistent file.

Each game-design question has one body here. The GDD topic keeps the rule context, clearly marked working assumptions and a short link to the question. Product, Feature, professional documents and Progress link the question and explain their own dependency instead of copying it. Local delivery choices, implementation tradeoffs, execution blockers and unadopted ideas stay where they already belong; this document is not a second task backlog.

Use the questions in the work that depends on them:

- GDD discussion, consolidation and scoped numerical design read the relevant questions and earlier answers before proposing more work. Authorized writing updates the affected entries.
- Product and Feature planning, synchronization and implementation check the questions that affect the selected scope or its dependencies. State what must wait and continue independent work; an unrelated open question does not block delivery.
- Design review checks whether remaining questions prevent the intended next use.
- Research and authorized experiments use the relevant question to identify the needed evidence, then return the result to the design task. An observation does not by itself adopt a rule.
- Status and continuation work use the relevant questions to explain the actual next decision.
- Discussion-only and review-only work report findings without editing this file.

When a question is resolved within the current authorization:

1. Put the adopted rule, its useful reason and its evidence limits in the GDD topic it belongs to.
2. Update the live references to point to that result.
3. Remove the resolved entry.

A deliberately deferred uncertainty stays open with its effect and a useful revisit condition. An adopted exclusion or version deferral belongs in the scope document. Keep only current questions; Git keeps the history. An empty file means no recorded open questions, not proof of complete, adopted or validated design.

## Candidate and unadopted ideas

Saving a proposal does not adopt it. Choose where to save it by what the current design needs, not by labels such as speculative, future or candidate:

| Content being saved | Fixed location |
| --- | --- |
| A current unresolved design choice, its compared alternatives and the evidence needed to choose | The corresponding question in `docs/gdd/open-questions.md`. A clearly marked working assumption used by the draft stays with its rule and links the question. |
| Alternative values or calculations for an already adopted rule or model | `systems/<system-key>.md` for ordinary rule values, or the fixed `balance/` file for models and derivations. Mark the alternatives as unadopted and keep the adopted value. A pending choice in open questions links these values instead of copying them. Numerical derivations that support a compared mechanic also stay in the balance file; the design choice stays in open questions. |
| An unadopted idea that no current design question depends on and that is not an alternative value of an adopted rule or model | `docs/unadopted-ideas.md`, with its useful reason, context and revisit condition when known. Do not create a system topic or an open question only to park it. |

For example, “possibly add prestige later; just keep the idea” belongs in `unadopted-ideas.md`. “Should this game's current loop include prestige?” belongs in open questions. A proposed reset-reward coefficient for an adopted prestige model stays beside that model's accepted values.

When an idea becomes part of a current comparison, move its proposal into the corresponding question and leave only a link in the ideas file. On adoption, move the settled content to its GDD or professional document and replace any remaining idea entry with that link. When closing a question, keep an unchosen idea only if it is still worth retaining, at the location the table selects; remove obsolete alternatives instead of keeping a second current body. Product candidates follow [Delivery decision ownership](#delivery-decision-ownership), and presentation alternatives follow [Game presentation documents](11-specialist-workflows.md#game-presentation-documents); this section does not move them into the ideas file.

Within the current writing authorization, `design-gdd` maintains these locations. `project-grill-me` returns conclusions to `design-gdd`, or saves an idea in `docs/unadopted-ideas.md` when the user explicitly asks to park it. Discussion alone writes nothing. These records do not authorize implementation or replace the GDD prerequisite.

## Design and delivery structure

```text
docs/
├── gdd/                    ← Maintained game design and its navigation
├── product.md              ← Delivery pre-decomposition and source navigation
└── product/
    ├── README.md           ← Directory purpose, not a Product
    └── 01-<delivery>.md    ← Written when this Product becomes current
```

GDD describes the game; Product describes how the selected design is delivered in verifiable units. A Product may cover one system, part of a system or a coherent outcome across systems, and it need not match one GDD chapter. For example, manual gathering can be one Product while automation stays a later candidate in the same gathering design.

`product.md` pre-decomposes the agreed delivery horizon into short candidates. A `product/NN-<delivery>.md` document is written only when its Product becomes current, and its Features are planned before the next Product is detailed. [Product-by-Product planning](02-feature-list-schema.md#product-by-product-planning) defines this order. A pre-decomposition is not a fixed commitment; adjust later candidates as delivery results change the intended sequence.

The initial `product.md` contains only a purpose and pending-state notice; it is neither design nor a delivery plan. Write delivery content from the [templates](templates/README.md). Find detailed Products through the links in `product.md` and the [Product filename](#product-filenames) pattern.

Product documents describe the current delivery scope only. They have no change-history section; Git keeps earlier versions. When the reason for a current boundary or order helps later decisions, state it beside that boundary.

### Delivery outcomes and prerequisites

Describe each Product by the observable capability it delivers, not only by a system, GDD chapter or code layer. Check that the boundary keeps a coherent result. For example, manual gathering may include collecting a resource, seeing the amount and handling the confirmed capacity limit. The precise rules still come from the GDD; this example adds no requirement to another Product.

For each prerequisite:

- Identify the result or decision it supplies, and which part of this delivery cannot proceed without it.
- Distinguish a required prerequisite from a preferred work order.
- Note when an already delivered capability satisfies it. A later Product's shared rule can be resolved without implementing that whole Product.

Keep these reasons in the dependency and integration sections of the Product documents, not in a new ledger or state field.

## When to create a Product

- **Create a Product** when a distinct, coherent outcome should be delivered and verified as the next unit. One system can span several Products, and one Product can integrate parts of several systems.
- **Extend the current Product** when the adopted change stays within its delivery goal. Reassess the current Feature coverage instead of creating a duplicate plan.
- **Revise a later candidate** in `product.md` when its boundary or order changes. Detail it only after the current Product's required Features are complete.

When the boundary is unclear, use `product-author`; it decides the route.

## Product filenames

- Name each detailed Product `docs/product/NN-<delivery>.md`: a two-digit number, a hyphen, then a lowercase kebab-case ASCII slug naming the delivered outcome, such as `01-manual-gathering.md`, `02-gathering-automation.md` or `03-ore-selling.md`.
- Allocate the filename when writing the current Product. The number is a stable identity, not the execution order; **Dependencies and suggested order** in `product.md` sets the order.
- Never renumber. A new Product takes the next unused number, even when it is a prerequisite of an earlier Product.
- Do not delete an obsolete Product document. Rename it in place in `docs/product/` by adding `_obsolete-` before the full filename, for example `_obsolete-03-ore-selling.md`. Its number stays allocated. Product discovery reads only filenames that start with the two-digit number, so renamed files are not current Products.

## Standard `product.md` sections

Write these sections in this order. A document rendered from the template keeps every template section; when a section does not apply, keep its heading and state that it does not apply. A project may add specialized sections, but the standard sections must stay easy to find.

| Section semantics | Required? | Content |
| --- | --- | --- |
| Design entry and delivery horizon | Yes | Link the actual GDD entry and the relevant game-version scope; identify which agreed scope this pre-decomposition covers. |
| Product pre-decomposition | Yes | Each candidate's delivery outcome, rough included and deferred boundary, and precise GDD references. Link a detailed Product document only after it exists. |
| Dependencies and suggested order | Yes | Prerequisite outcomes and the current recommended sequence, including cross-system decisions that affect the current Product. |
| Planning decisions to resolve | Yes | Unresolved delivery choices that span several Products or concern a candidate without a detailed document, under [Delivery decision ownership](#delivery-decision-ownership). Link questions owned by the GDD or a detailed Product. |

Do not repeat the GDD's positioning, target users, core-loop body, system inventory, game-version content or visual and audio direction; a short navigational summary is enough. The game-system inventory and the Product delivery list answer different questions and need not contain the same entries. Execution state stays in the Feature ledger and Progress, not in a Product status field.

## Standard `product/NN-<delivery>.md` sections

Write this document only when its Product becomes current. The filename number identifies it; it does not set execution order or show implementation progress.

A Product document makes the delivery boundary precise without copying game-design rules. A rendered template keeps its standard headings and marks sections that do not apply. Add delivery-specific sections when useful. Behavior, formulas, data definitions and state machines stay in their GDD source.

| Section semantics | Content |
| --- | --- |
| Delivery goal | The coherent, observable outcome this Product adds. |
| Design sources | Precise GDD sections and relevant professional-document links, stating how each applies. |
| Included and deferred scope | The adopted part of the design, its boundaries and the work intentionally left for later. An exclusion cannot silently change the design. |
| Prerequisites and integration | Delivered outcomes, interfaces and shared rules this Product depends on, with links to their sources. |
| Acceptance scenarios | End-to-end delivery scenarios and observable results derived from the sources. Feature planning owns task-sized AC and test mappings. |
| Open decisions | Unresolved delivery choices confined to this Product, under [Delivery decision ownership](#delivery-decision-ownership). Link questions owned by the GDD or by `product.md`, and identify this delivery's dependent work. |

### Delivery decision ownership

Store each unresolved delivery choice once, at the first matching row below. Other documents that depend on it state their own dependency without repeating the question.

| Decision scope | Fixed location |
| --- | --- |
| A game rule, intended experience or game-version design boundary is unresolved | `docs/gdd/open-questions.md`; Product only links it. |
| The choice changes the allocation, prerequisites or relative order of two or more identified Products | `docs/product.md` → Planning decisions to resolve, even when one affected Product already has a detailed document. |
| The choice is confined to one Product that has a detailed document | That `docs/product/NN-<delivery>.md` → Open decisions. |
| The choice is confined to a candidate whose detailed document has not been written | `docs/product.md` → Planning decisions to resolve, until that Product is detailed. |

For example, whether the current backpack delivery includes already-designed keyboard navigation belongs in that Product's Open decisions when no allocation to another Product is being decided. Assigning the same work between the backpack Product and an identified accessibility Product belongs in `product.md`. Leaving work for an unspecified future delivery does not make the first question cross-Product.

Moving and closing decisions:

- When detailing a candidate, move its still-open local delivery questions from `product.md` into the new document and replace them with links. Cross-Product questions stay in `product.md`.
- When a question's scope changes, move its body to the location that now matches and update live references in the same authorized edit.
- When a question is resolved, write the adopted boundary, prerequisite or order in the matching Product section, with a short reason when useful. Remove the open entry and update affected references. Do not keep a second question ledger.

## Anti-examples

- Do not put implementation choices, such as a vector type or a pathfinding algorithm, in GDD or Product documents. They belong in Project Rules, code or implementation notes.
- Do not copy GDD flows, states or numeric rules into Product. Link the precise source and explain how it applies to the delivery.
- Do not describe numeric behavior with subjective terms such as “high damage”; settle the formula or concrete value in the GDD.
- Do not use subjective acceptance language such as “renders smoothly”; state an observable threshold or outcome.
- Do not put parked ideas in active requirements. Use [Candidate and unadopted ideas](#candidate-and-unadopted-ideas) to distinguish a current design question, an alternative rule value and an idea saved for later. None of these records adopts a requirement or authorizes development.
