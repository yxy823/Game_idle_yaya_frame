# 01 · GDD and Product document structure

## GDD prerequisite and authority

Use `design-gdd` to develop a game idea into a GDD, or to deepen, revise or consolidate existing design. Initial design discussion, its supporting clarification, numerical modeling and presentation exploration, and review of an actual draft can proceed before a complete GDD, Product or Feature exists. Use the known goals, constraints and available draft; preserve assumptions and unresolved choices. Discussion alone writes nothing, and a request to save a draft does not adopt all its proposals. During the same authorized GDD authoring or consolidation, supporting specialist work may place already confirmed specifications at their fixed owners under methodology 11, within that writing scope. This does not permit unrelated specialist design or implementation without its GDD prerequisite. Design work does not require a ready Godot environment.

Delivery planning, implementation, engineering repairs and runnable experiments require a substantive game design document under `docs/gdd/`. Read its entry and the sections relevant to the task. An empty directory, directory-navigation README, template or pending-state notice is not a GDD. If it is absent, explain the missing design and the `design-gdd` route; stop dependent development rather than inventing gameplay or starting an unrequested design interview. Other specialist work applies the same prerequisite unless it is the early GDD design support described above. A status query may explain the current state without starting work.

The GDD owns game positioning, intended player experience, core loops, system rules, states, numeric behavior, content progression and game-version design scope. Use the [standard document names](#gdd-document-names) under `docs/gdd/`, including [Design scope and boundaries](#design-scope-and-boundaries) and [Open questions](#open-design-questions). The entry links the actual owning sources. Preserve existing organization outside an authorized restructuring scope; do not create empty chapters or duplicate bodies. The GDD need not settle every future detail, but the current delivery scope and design dependencies must be clear before dependent planning or implementation. Resolve an affecting design gap in its owning GDD topic and update its open question; do not invent the missing rule in Product or Feature text.

The GDD is a normal maintained project source. Within the user's concrete authorization, `design-gdd` owns overall game design and cross-topic consistency; `design-balance` may directly maintain the scoped numerical model, formulas, parameters and calculation explanations at their owning GDD location. Ordinary specification values do not require numerical modeling. `product-author` owns delivery documents, not game-design authoring. The coordinating task handles affected Product/professional sources and existing Features through their owners without using a document author as a mandatory writing intermediary.

Proposals remain distinct from accepted design, and adoption remains distinct from calculation, runtime or experience verification. File presence or a saved edit alone does not confirm a choice. Saving a candidate must not silently replace an adopted value. Changing an experience goal, adding a mechanic or altering another system to make a model work returns to the overall design decision; numerical design does not authorize runtime code/resource edits. Preserve unrelated content and use the existing source-commit, synchronization and validation contracts when existing work is affected. An initial GDD draft need not create Products, Features or synchronization records. No separate GDD permission, tracking ledger or synchronization system is required.

Professional documents own presentation, UI, art, audio, resource and localization specifications under [Specialist work and sources](11-specialist-workflows.md). GDD owns game rules and overall experience goals and links those specifications. During authorized creation or consolidation, move confirmed professional details to their fixed owner and replace the GDD body with a reference; the place where a detail was first written does not change its responsibility. Changes to game rules or accepted overall direction update GDD; implementation design belongs in the Feature design, current implemented structure in architecture, and executable behavior in code.

The [logic/presentation responsibility model](00-overview.md#game-logic-presentation-and-delivery) does not turn the GDD into a logic-only document. For a shop purchase, the GDD owns purchase conditions, state effects and intended feedback; the shop UI and item-acquisition presentation refine how the player operates and perceives it. Product selects a coherent delivery across those sources. Keep detailed collaboration and state-owner implementation in architecture or the relevant Feature design, linking their actual paths when available.

Before revising design or delivery scope, check the applicable GDD design boundaries below, engineering constraints in `docs/project-rules.md` and relevant accepted architecture decisions. A design request does not silently amend an engineering rule. Resolve such conflicts through [project rule maintenance](04-coding-rules-4-layers.md#incremental-rule-maintenance).

## GDD document names

New GDDs and authorized standardization use these fixed filenames for the matching responsibilities. They are reference targets, not interchangeable examples. Keep filenames unchanged across document languages; titles and prose follow `document_language`.

| Filename under `docs/gdd/` | Owning responsibility |
| --- | --- |
| `README.md` | GDD entry: brief game introduction, covered scope and links to the actual design sources. |
| `concept-and-experience.md` | Game concept, player context, intended experience, design principles, world premise, character identities/relationships and authored story outline. Narrative mechanics belong to their system file. |
| `gameplay.md` | Core loop, representative play, cross-system relationships and navigation to the game's systems. |
| `systems/<system-key>.md` | One game system's mechanics, inputs, states, transitions, limits, rule scenarios and content-definition catalog, including branching/stateful narrative rules. Reference numerical models rather than copying them. |
| `balance/<system-key>.md` | That system's numerical models: variables, formulas, parameter values, curves, calculation assumptions and derivations. |
| `balance/cross-system.md` | Numerical models whose relationships span multiple systems; system-specific models remain at their own keys and are referenced. |
| `progression.md` | Content placement, teaching and challenge sequencing, progression goals and intended pacing; reference content definitions and unlock rules in system files and curves in balance files. |
| `presentation.md` | Game-level interaction, understanding, intended player feelings, recognition needs and feedback goals. Link UI/presentation specifications and the Art/Sound Bibles for visual style and sound-language standards. |
| `design-scope-and-boundaries.md` | Overall design scope, confirmed exclusions and version boundaries, under the contract below. |
| `open-questions.md` | Current unresolved design choices and missing evidence, under the contract below. |

Use this structure from initial design through later expansion, regardless of game size, document length or perceived complexity. Create a body when its content is written; do not prebuild empty topics. Keep the initial purpose notices and the scope document's first-write conditions. A system's rules always use its system file, including the first system introduced into a draft; `gameplay.md` keeps the cross-system view and links. Numerical-model content always uses the balance path selected by its system scope. An ordinary dimension or item count that is a rule specification stays with that rule; named model variables, derived values and calculation explanations stay together in the balance file, and rules reference them.

Use one stable lowercase hyphenated `system-key` for each distinct game system, recorded with its actual system link in `gameplay.md`; reuse the same key for its balance file. The key identifies the system, not its size, implementation module or writing session. Reserve `cross-system` for the cross-system balance file. Related models within one system share its balance file using headings; do not invent additional file choices or split them by complexity. When a new system identity is confirmed, add its link within the existing gameplay navigation rather than creating a separate registry. The GDD entry links the standard topics and the actual system/balance sources.

Content definitions follow the system that establishes their gameplay identity, even when another system consumes them. For example, ore types defined by mining stay in `systems/mining.md`; a shop references those definitions and owns its sale rules. Modeled prices/yields belong in the matching balance source, while their stage distribution belongs in `progression.md`. Static world and character descriptions do not require inventing a narrative system; choices, branches and story-state transitions do.

Read the existing GDD entry before naming an output or drafting a consumer prompt. Reference the actual owning file and relevant heading; do not infer that a standard topic already has content. In an imported or differently organized GDD, edit an existing topic at its current owner unless its migration is authorized. New topics and new systems always use the standard paths above, with links from the existing entry and, for systems, `gameplay.md`; extending an existing rule is not a new topic. This permits a local addition without relocating unrelated legacy content or creating a second body. When standardization or restructuring is authorized, move affected content to its owning location and update all affected references, including Product/Feature sources and professional documents. Preserve filenames and referenced headings while their meaning is unchanged. A necessary rename or move must carry its affected paths and anchors with it.

## Design scope and boundaries

`docs/gdd/design-scope-and-boundaries.md` is the fixed GDD subdocument for **Design scope and boundaries** (`设计范围与边界` in Chinese). Keep this path stable, use the equivalent title and prose in `document_language`, and link it directly from the GDD entry. It owns overall game-design scope, confirmed exclusions and version boundaries across game logic and presentation. Project Rules owns development constraints, collaboration and engineering principles; a game's long-lived or cross-system design boundary still belongs in GDD.

Keep the applicable conditions, exceptions and useful reason with each boundary. Distinguish an adopted exclusion, a deferral limited to a named game version, and an unresolved choice or candidate. Missing design does not imply an exclusion. Reference the existing version definitions rather than inventing a new release sequence.

Local mechanism limits remain in their owning GDD topics; local presentation or Shader constraints remain in the corresponding design or professional specification. Link them from this scope topic only when useful for navigation. Do not collect every local rule here or repeat its full body in Project Rules, Product, Feature or professional sources. When moving a boundary, update affected references and replace the old body with a link within the authorized scope.

For game-design discussion, delivery planning, implementation or review, read the relevant sections of this scope topic and the owning topics before proposing work or questions. Apply confirmed boundaries when filtering out-of-scope cases; read Project Rules when engineering constraints affect the task. Reuse unchanged context and explicit user decisions, including decisions not yet saved. Pure engineering or status work need not load unrelated game-design material. If the scope topic has not yet been written, use the available design and confirmed constraints; a missing file alone does not invalidate substantive existing design or block discussion.

When authorized GDD drafting first saves the game's design, `design-gdd` creates this subdocument from the actual known scope and links it from the entry. Authorized scope revisions maintain it and the necessary references as decisions settle; for an existing GDD, move the affected scope content without reorganizing unrelated topics. Do not prefill an empty project with invented exclusions or create a placeholder as evidence of completed design. Reuse existing writing authority for settled decisions; changing an adopted boundary still needs the corresponding design decision. Discussion-only work does not write files and identifies useful confirmed conclusions that remain unsaved when wrapping up. Supporting Skills return those conclusions to the owning task rather than starting a separate rule-maintenance workflow.

## Open design questions

`docs/gdd/open-questions.md` is the fixed GDD document for **Open questions** (`开放问题` in Chinese). It owns the current unresolved game-design choices and missing facts or evidence that could change the design. Link it directly from the GDD entry, use descriptive question headings that consumers can reference, and write in `document_language`. New projects include a purpose/pending-content notice; it is not substantive design or proof that all questions have been settled. When authorized drafting starts from an existing GDD without this file, establish it from the actual known questions without reorganizing unrelated topics.

Keep each question's actual uncertainty, relevant topic/source links, effect on design or dependent work, and the decision or evidence needed to resolve it together. Include the alternatives being compared for that question or a working assumption when known, following [Candidate and unadopted ideas](#candidate-and-unadopted-ideas); do not invent questions or fixed IDs, scores, owners or workflow states to fill a template. Distinguish a user choice from a fact requiring investigation, calculation or play evidence. A question about a topic not yet written may describe that scope without linking a nonexistent file.

Game-design questions have one body here. Their GDD topics retain the rule context, clearly qualified working assumptions and a short link to the relevant question. Product, Feature, professional sources and Progress reference the question and explain their own dependency rather than copying it. Local delivery choices, implementation tradeoffs, execution blockers and unadopted ideas remain with their existing owners; this document is not a second task backlog.

Use the questions in the work that depends on them:

- GDD discussion, consolidation and scoped numerical design read relevant questions and existing answers before proposing more work; authorized source writing maintains the affected entries.
- Product/Feature planning, synchronization and implementation check questions affecting the selected scope or its dependencies. State what must wait and continue independent work; an unrelated open question does not block delivery.
- Design review checks whether remaining questions prevent the intended next use. Research and authorized experiments use the relevant question to identify needed evidence, then return their result to the owning design task; an observation does not itself adopt a rule.
- Status and continuation work use relevant questions to explain the actual next decision. Discussion-only and review-only work report findings without editing this file.

As a question is resolved within existing authorization, put the adopted rule, useful reason and evidence limits in the owning design topic, update affected live references to that result, and remove the resolved entry. A deliberately deferred uncertainty remains open with its effect and useful revisit condition; an adopted exclusion or version deferral belongs in the scope document. Keep only current questions, using Git for history. No entries means no recorded open questions, not proof of complete, adopted or validated design.

## Candidate and unadopted ideas

Saving a proposal does not adopt it. Route its content by what the current design needs, not by labels such as speculative, future or candidate:

| Content being saved | Fixed owner |
| --- | --- |
| A current unresolved design choice, its compared alternatives and the evidence needed to choose | The corresponding question in `docs/gdd/open-questions.md`. A qualified working assumption used by the draft stays with its owning rule and links this question. |
| Alternative values or calculations attached to an already adopted rule/model | The owning `systems/<system-key>.md` for ordinary rule values, or the fixed `balance/` source for models and derivations. Mark alternatives unadopted and preserve the adopted value. A pending choice in open questions links these values rather than copying them. Numerical derivations supporting a compared mechanic likewise stay in the fixed balance source; the design choice stays in open questions. |
| An unadopted idea with no current unresolved design question depending on it and no role as an alternative value of an adopted rule/model | `docs/unadopted-ideas.md`, with its useful reason, context and revisit condition when known. Do not create a system topic or an open question merely to park it. |

For example, “possibly add prestige later; just keep the idea” belongs in `unadopted-ideas.md`. “Should this game's current loop include prestige?” belongs in open questions. A proposed reset reward coefficient for an adopted prestige model stays beside that model's accepted values.

When an idea becomes part of a current comparison, move its proposal body into the corresponding question and leave only a useful destination link in the idea file. On adoption, move the settled content to its GDD or professional owner and replace any retained idea entry with that link. When closing a question, keep an unchosen idea only if it is still worth retaining, at the owner selected above; remove obsolete alternatives instead of maintaining a second current body. Existing delivery candidates and professional technique alternatives retain their own contracts; this section does not move them into an ideas backlog.

Within existing writing authority, `design-gdd` maintains these destinations and `project-grill-me` returns conclusions to that owner or saves an explicitly requested parked idea in `docs/unadopted-ideas.md`. Discussion alone writes nothing. These records neither authorize implementation nor replace the GDD prerequisite.

## Design and delivery structure

```text
docs/
├── gdd/                    ← Maintained game design and its navigation
├── product.md              ← Delivery pre-decomposition and source navigation
└── product/
    ├── README.md           ← Directory purpose, not a Product
    └── 01-<delivery>.md    ← Written when this Product becomes current
```

GDD describes the game; Product describes how the selected design is delivered in verifiable units. A Product may cover one system, a part of a system or a coherent outcome across systems. It need not match one GDD chapter. For example, manual gathering can be one Product while automation remains a later candidate in the same gathering design.

Pre-decompose the currently agreed delivery horizon in `product.md` to check coverage, boundaries, dependencies and suggested order. Keep future Products as concise candidates there; do not create their detailed documents, Feature IDs, AC or test registrations in advance. When a Product becomes current, revisit its sources using earlier delivery results and write its `product/NN-name.md` document, then decompose its complete necessary scope into multiple Features. Finish those required Features before detailing the next Product, under [Product-by-Product planning](02-feature-list-schema.md#product-by-product-planning).

An affecting cross-system rule must be resolved before current implementation, even if the other Product is later. Clarify that shared rule in the GDD without writing the future Product's full delivery document. Adjust future candidates as learning changes the intended delivery sequence; a pre-decomposition is not a fixed implementation commitment.

The initial `product.md` contains only a purpose and pending-state notice. It establishes neither design nor a delivery plan. Use the canonical templates when writing actual delivery content; discover detailed Products through the overview and the `NN-name.md` convention.

Generated headings and prose must follow the project's configured `document_language`; the section semantics below must remain intact in every language. See [05-document-language.md](./05-document-language.md).

### Delivery outcomes and prerequisites

Describe each Product by the observable capability it delivers, rather than only naming a system, GDD chapter or code layer. Check that the boundary preserves a coherent result: for example, manual gathering may include collecting a resource, seeing the amount and handling the confirmed capacity limit. Its precise rules still come from the GDD; this example does not add requirements to another Product.

For each prerequisite, identify the result or decision it supplies and what part of this delivery cannot proceed without it. Distinguish required prerequisites from a preferred work order. Existing capabilities may already satisfy a dependency; a later Product's shared rule can be resolved without implementing that whole Product. Keep these reasons in the existing dependency/integration sections, not a new ledger or state field.

## Standard `product.md` sections

Write these sections in this order. A document rendered from the canonical template must preserve every template section; when a section does not apply, retain its heading and state that it is not applicable. A project may add specialized sections, but the standard semantics must remain easy to locate.

| Section semantics | Required? | Content |
| --- | --- | --- |
| Design entry and delivery horizon | Yes | Link the actual GDD entry and relevant game-version scope; identify which agreed scope this pre-decomposition covers. |
| Product pre-decomposition | Yes | Each candidate's delivery outcome, rough included/deferred boundary and precise GDD references. Link a detailed Product document only after it exists. |
| Dependencies and suggested order | Yes | Explain prerequisite outcomes and the current recommended sequence, including cross-system decisions affecting the current Product. |
| Planning decisions to resolve | Yes | Unresolved delivery choices spanning multiple Products or concerning a candidate without a detailed Product document, under [Delivery decision ownership](#delivery-decision-ownership). Link questions owned by GDD or a detailed Product. |
| Change history | Yes | Reverse-chronological delivery-scope/order changes and reasons. Game-design history stays with its source. |

Do not repeat the GDD's positioning, target users, core-loop body, system inventory, game-version content or visual/audio direction. A short navigational summary is sufficient. The game-system inventory and Product delivery list answer different questions and need not contain the same entries. Actual execution state remains in the Feature ledger and Progress, not an additional Product status field.

## Standard `product/NN-name.md` sections

Write this document only when the Product becomes current. Its filename number identifies it; it does not establish execution order or implementation completion.

A Product document makes its delivery boundary precise without copying game-design rules. A rendered template retains its standard headings and explicitly marks inapplicable sections. Add useful delivery-specific sections when needed; keep behavior, formulas, data definitions and state-machine bodies in their GDD source.

| Section semantics | Content |
| --- | --- |
| Delivery goal | The coherent, observable outcome this Product adds. |
| Design sources | Precise GDD sections and applicable professional-source links, stating how they apply. |
| Included and deferred scope | The adopted part of the design, its boundaries and intentionally later work; exclusions cannot silently change the design. |
| Prerequisites and integration | Existing delivered outcomes, interfaces and shared rules this Product depends on, with links to their sources. |
| Acceptance scenarios | End-to-end delivery scenarios and observable results derived from the sources; Feature planning owns task-sized AC and test mappings. |
| Open decisions | Unresolved delivery choices confined to this detailed Product, under [Delivery decision ownership](#delivery-decision-ownership). Link questions owned by GDD or the overview and identify this delivery's dependent work. |
| Change history | Reverse-chronological delivery-boundary changes and reasons. |

### Delivery decision ownership

Store each unresolved delivery choice once, using the first applicable condition below. References at other locations identify their own dependency without repeating the question's body.

| Decision scope | Fixed owner |
| --- | --- |
| A game rule, intended experience or game-version design boundary is unresolved | `docs/gdd/open-questions.md`; Product only references it. |
| The choice changes the allocation, prerequisites or relative order of two or more identified Products | `docs/product.md` → Planning decisions to resolve, even when one affected Product already has a detailed document. |
| The choice is confined to one Product with an existing detailed document | That `docs/product/NN-name.md` → Open decisions. |
| The choice is confined to a candidate whose detailed document has not been written | `docs/product.md` → Planning decisions to resolve until that Product is detailed. |

For example, whether the current backpack delivery includes already-designed keyboard navigation belongs in that Product's Open decisions when no other Product allocation is being decided. Assigning the same work between the backpack Product and an identified accessibility Product belongs in the overview. Merely leaving work for an unspecified future delivery does not make the first question cross-Product.

When detailing a candidate, move its still-open local delivery questions from the overview into the new detail and replace the old body with a link; keep cross-Product questions in the overview. When a question's scope changes, move its body to the newly determined owner and update live references in the same authorized edit. Once resolved, put the adopted boundary, prerequisite or order in its owning Product section, remove the open entry and update affected references. Preserve useful change reasons in the existing history, without a second question ledger.

## Visual prototype before dependent implementation

Professional documents are maintained directly by their owning Skills under [Specialist work and sources](11-specialist-workflows.md). GDD owns game-design requirements; Product selects the delivery scope and links the applicable sources.

For a new interface or a substantial layout/resource change, establish its visual foundation before implementing logic that depends on that interface. Reuse an already validated layout when it covers the current scope; copy/value changes, non-visual logic and unaffected modules do not require another prototype. Work on the current interface/module, including its surrounding screen context, rather than waiting for all game art or all future screens to be ready.

The sequence is: interface purpose and main states → representative resources and initial specifications → independent Godot visual prototype → layout/scale validation and adjustment → dependent production logic → visual refinement. Resource specifications and layout may iterate together.

The Agent identifies this need during planning and resource preflight, or the user may request a prototype directly. This is task reasoning, not a background trigger. Discussion-only work proposes the next step without writing or building; existing implementation authorization covers in-scope preparation and execution, but never supplies the user's actual visual acceptance.

### Scope and resources

Before building, identify the questions to settle, the target viewport/window and relevant scaling conditions, core elements/states, available resources and remaining gaps. The relevant specialist Skills specify these inputs; a written sketch or HTML exploration does not verify the Godot result. When resources need a preparation handoff, use the owning [resource sections](#resource-requirements-and-handoff) below.

Use representative real images, fonts, video, music and sound effects where the interface calls for them. Select samples that expose actual aspect ratios, detail, text lengths and content density; do not require every media type or the complete asset library. Distinguish source pixel dimensions, on-screen size and visible subject size after transparent padding. For audio, identify duration, looping and feedback timing relevant to the experience. Follow existing asset provenance and import rules. A missing sample leaves that check unverified; identify the gap and seek a suitable sample or an explicitly accepted substitute, rather than claiming that text, silence or a placeholder filename proves it.

Create a clearly named, independently runnable `.tscn` in the project's existing scene organization, separate from production functionality. Include the actual content regions, representative items, buttons and text in their surrounding layout. Use local sample state and only interactions needed for evaluation, such as hover/pressed/selected/disabled feedback, opening a panel, scrolling or preview playback. Do not connect production business/game rules, persistence or live data flows. If project Autoloads would run those flows, isolate the prototype entry from their side effects. A small local script is sufficient when native controls cannot express the required feedback.

Final backgrounds, decoration and palette are optional at this point; readable contrast and distinguishable interaction states are necessary for evaluation. Avoid a fixed number of design variants: compare alternatives only when a real layout decision needs them.

### Validation and adoption

Run the scene in the target project's confirmed Godot environment. Check spatial relationships, resource scale/cropping, text readability, button usability and relevant empty/dense/long-text states at the agreed display conditions. Exercise interactions and listen to relevant samples. Static checks and screenshots are supporting evidence, not substitutes for actual operation and human judgment. Missing execution or human feedback remains explicitly unverified.

Keep the entry scene, questions, observations, links to the applicable presentation/resource sections and file disposition in current Feature notes, or Progress for a standalone experiment. Keep resource details in their owning design sections. Confirmed game-design changes belong in the GDD via `design-gdd`, or `design-balance` for scoped numerical design; delivery-boundary changes belong in Product, while professional layout, presentation, size, readability or sound specifications belong in their owning specialist source. Adoption uses the applicable authorization and source-impact route. Node properties and tuning values remain in the scene, resources or implementation notes. Do not maintain a second specification or prototype status ledger.

During planned delivery, use an ordinary Feature for an independently reviewable visual foundation and make dependent implementation wait for its applicable manual acceptance. A narrow check may stay inside the current Feature, with the visual decision settled before dependent logic. An explicitly requested standalone exploration follows the scoped-experiment route in [task routing](00-overview.md#canonical-task-routing). Prototype acceptance covers only its visual/interaction scope, never the later business behavior.

After validation, reuse suitable layout nodes, themes and resources deliberately; remove sample-state wiring when adopting them into production. Retain a separate prototype only while it answers an ongoing question; otherwise archive or remove it within the authorized scope. Record unresolved limits and keep the accepted decisions, without maintaining competing production and prototype interfaces.

## Scoped logic prototypes

Use `prototype-godot` when an authorized experiment can settle a specific interaction, state-transition or technical-feasibility question. Identify the question, relevant confirmed GDD rules, observed result needed to answer it and the bounded experiment before building. Preserve unsettled design choices as proposals; an experiment does not approve a new rule. Reuse an existing experiment when it still answers the question, and follow the scoped-experiment route in [task routing](00-overview.md#canonical-task-routing).

Prefer a small, independently runnable Godot scene with only the state and interactions needed for the question. Make relevant state visible, support reset to a known starting point, and combine free operation with repeatable situations that expose the uncertainty. For a crafting queue, useful situations might include insufficient materials, pausing or cancellation and refund; include only those relevant to the confirmed question. Do not require a fixed number of cases or visual variants.

Local sample state is suitable for exploring a proposed interaction. If the question concerns actual signals, input, lifecycle, persistence or another engine integration, exercise the relevant real path under the task's permissions and protect live data. A simulated transition cannot prove that integration works. Use the visual-prototype requirements above when judging layout, representative assets or perceptual quality. HTML is optional only for an explicitly requested engine-independent concept demonstration; it is not a required precursor or evidence of Godot behavior.

Report what the experiment answered, the actual observations and remaining limits. Reuse the recording and adoption rules under [Validation and adoption](#validation-and-adoption): retain the entry and useful evidence in existing notes or Progress, return accepted decisions to their source owners, and resolve sample code disposition within authorization. A successful experiment does not establish production readiness, required regression coverage or human acceptance. Do not make experimentation a prerequisite for work with no relevant uncertainty.

## Resource requirements and handoff

Maintain resource specifications and preparation information inside the design that owns their use. Determine the owner from the actual or explicitly considered uses, including the UI/presentation component boundaries in methodology 11:

| Resource use | Fixed owner |
| --- | --- |
| Confined to one presentation or one extracted presentation component | Its `docs/presentation/<scope>.md` or `docs/presentation/components/<component-key>.md`: keep an alternative-only dependency in that alternative, and requirements shared by its alternatives in the common resource section. |
| Confined to one interface or one extracted UI component, with no separate presentation owning the use | Its `docs/ui/<interface>-design.md` or `docs/ui/components/<component-key>-design.md` resource section. |
| Shared across independent owners above, outside a single component contract | Visual resources: **Shared resource specifications** in `docs/art/art-bible.md`; audio resources: the same section in `docs/audio/sound-bible.md` (`共享资源规格` in Chinese). |

A shared component's own resources stay with that component; many callers do not by themselves make those resources global. An item icon used by inventory, shop and reward feedback belongs in the Art Bible's shared-resource section, while a texture used only by a shared icon-flight alternative stays in that component. A general click sound used by independent interfaces belongs in the Sound Bible's shared-resource section.

When additional uses change the owner, move the affected specifications and preparation state together, update consumers and replace old bodies with references within the authorized scope. Style/direction Skills own the Bibles' shared standards; `design-visual-asset-spec` and `design-audio-asset-spec` maintain concrete file entries in their shared-resource sections. Localized headings retain these section semantics. Link uses to that body; do not create a separate default resource-list directory, a list per Feature or a second receiving ledger. No Product-writing intermediary is needed.

Read the current task, applicable GDD and professional requirements, selected or candidate alternative, relevant existing assets and supplied source locations. Include only files needed by the current scope or explicitly discussed alternative. Do not add future decoration or separate files for states that existing themes or procedural presentation can express. Record unknown inputs rather than inventing resources, styles, dimensions or technical requirements. A candidate alternative's dependencies are not automatically resources the project must prepare.

Use `document_language`, state the covered uses and link source requirements. A compact table can collect short entries; longer specifications stay in the same owning section. If local resource IDs help references, keep them stable and unique in that document/section, including the owning path and anchor in cross-document links. No global ID counter or resource registry is needed.

Record the information needed to prepare and inspect each actual resource:

| Field | Meaning |
| --- | --- |
| Purpose and identity | Needed kind, covered uses, real or proposed filename, and applicable shared style/source links. Preserve reusable filenames. |
| Resource constraints | Required format and applicable dimensions, transparency, aspect ratio, padding/cropping, frame timing, audio duration/looping or other meaningful constraints. Distinguish source pixels from expected display/visible-subject size or relative scale. Do not impose pixel fields on audio or unrelated media. |
| Preparation and file mapping | Factual preparation status, supplied source/actual location, proposed or actual project target path and relation to runtime consumers. Mark missing files and sample/final status explicitly. |
| Decisions and observations | Separate confirmed requirements, proposed values, measured values, pending confirmation and not applicable. Keep unresolved choices with the alternative they affect. |

Reuse the project's file organization. Runtime assets stay outside ignored documentation folders. Link existing provenance records where relevant rather than duplicating them. Settings that merely implement the requirement stay in actual scenes/resources/code or engineering guidance.

A non-final sample can suffice for a scoped prototype; state what it represents and what remains to be replaced. Missing textures do not prevent planning a spark's motion, density, duration and trigger. If the particle alternative needs a texture, describe its applicable specifications there and leave the unavailable file explicit. Only dependent implementation or final experience checks may be blocked; do not turn optional parameters or missing files into a barrier to useful planning.

Link applicable resource sections from Feature AC/design, with notes or Progress providing navigation. Do not hide binding requirements solely in process-only notes or copy entire rows. A resource analysis alone does not change intent, authorize production or create Features. Material changes follow the owning source's route in `11-specialist-workflows.md`.

Hand off links to the owning sections, missing specifications/files and intended destinations so the user can prepare or supply them externally. Image/audio production and local asset-library retrieval are outside this capability. If resources suffice, continue authorized work without a ceremonial wait. When files arrive, inspect their actual content and applicable format, dimensions or duration; filenames and user-reported copying alone do not establish fit. Update those same sections and retain unresolved gaps. Copy/import only within the authorized scope, preserving source files and unrelated content. Finalize preparation status and actual file/consumer relationships before final task verification. Specification completion, file presence, successful import and human visual/audio acceptance are separate facts.

## Project terminology

Clarify vocabulary when competing names or meanings would change a Product decision. Read existing definitions first. If one word describes different concepts, distinguish them using familiar names; if several words mean the same thing, propose one consistent name. Reuse an already clear definition instead of starting a glossary for every task.

Test the distinction with a concrete scenario. For example, when discussing inventory, distinguish an item definition, an owned item and a stack only if their identity or behavior differs. Whether two items with different modifiers can stack exposes a real decision; listing every possible item attribute does not. Record an accepted behavior decision in its owning GDD section and derive delivery scope and AC from it.

When implementation exists, compare the relevant code with the stated meaning. Surface conflicts with both sources: code describes what happens today and cannot silently redefine approved intent. A new meaning remains a proposal until the user resolves the material Product choice.

`docs/terminology.md` is the single authoritative file for confirmed project term definitions, canonical names, aliases and conceptual distinctions. This location is fixed whether a term is used in one topic or across systems, Products, Features or conversations. GDD, Product, Feature and professional documents use these terms and link their definitions; they do not maintain separate domain glossaries or authoritative local definitions. Target-locale wording belongs to the localization specification's **Term translations** section under [Localization term translations](11-specialist-workflows.md#localization-term-translations); a translated name is not a competing domain definition. Ordinary explanatory prose and examples remain with the topic they explain.

The terminology file explains what a project concept means and how its name differs from related names. GDD owns its detailed gameplay rules, conditions, flows, values, state transitions and intended experience. Professional documents own their specifications and architecture/code own implementation choices. A short definition may identify a concept by its role, but links to the owning design for its full behavior. Do not create a second `UBIQUITOUS_LANGUAGE.md` or parallel glossary, or turn terminology into a general project-context document or dictionary of ordinary words and engine APIs.

Authorized GDD creation, revision and consolidation include recording the current scope's confirmed terms in `docs/terminology.md` through `project-terminology`, together with the affected references. Collect definitions already present in the supplied design; do not wait for another system, Product or Feature to use them. Reuse the task's writing authority unless the user explicitly limits the writable files; discussion-only work writes nothing. New projects include a short purpose/pending-state file. If it is missing, create it when saving confirmed definitions. When no terms have been confirmed, retain the pending state without inventing entries or blocking unrelated design work. Apply the GDD creation/development boundary above; recording a term does not establish a game design or authorize development.

Use a compact structure, expanding only where a distinction needs explanation:

- Begin with a short description of the domain covered when it helps orient the reader, then give each term a canonical name and definition, normally one or two sentences. Include domain actions as well as nouns when their meanings matter. Necessary distinctions may take more space; there is no word or term quota.
- Explain necessary conceptual relationships, aliases or commonly confused neighbors only when they prevent a real misunderstanding.
- Link to the owning GDD section for detailed rules, flows, values and state transitions, and to Product/Feature records for delivery scope and AC. Keep implementation state ownership, Godot classes, storage formats and technical choices in architecture records or code.
- Keep pending ideas, chat logs, current progress and task-local notes out of terminology. Move existing definitions from the authorized GDD or professional scope into this file and replace their old bodies with links. Preserve section anchors used by existing Feature sources, leaving a link at the old location. Original input materials that the task requires preserving remain identified as source material; current definitions are maintained only in the terminology file.

`project-grill-me` returns clarified answers to the owning task; `product-spec-elicitor` focuses on delivery choices. `design-gdd` owns overall game design, `design-balance` its scoped numerical design, and `product-author` Product delivery documents. `project-terminology` owns meaning-preserving definitions in `docs/terminology.md` and their references. Using it during GDD writing does not start Product planning. Pure terminology maintenance may clarify a name, record an already agreed distinction or move/link a definition; it does not require a new Product, Feature or Feature synchronization. If a definition changes actual intent or exposes a material unresolved behavior, resolve that decision through the design owner and synchronize affected work before updating dependent terminology.

Read relevant terminology definitions during clarification, planning, implementation and review when the file exists. Follow `document_language`, preserve stable IDs, and do not rename code or migrate saved data merely to align terminology.

### Incremental terminology maintenance

Check new terms, renames, retirements and clarified meanings during GDD and Product writing and at the Stage 3 documentation checkpoint before final verification. Save confirmed additions or changes in `docs/terminology.md`; if none changed, do not write or produce an empty report. Reuse existing documentation authorization for settled, meaning-preserving changes; discovering a new material Product choice does not approve it.

Add confirmed definitions, merge duplicates and repair references. For a rename, retain an old name only while it helps readers find the canonical term. For retirement, retain a replacement link when historical references need it; otherwise remove obsolete wording within scope. Resolve semantic changes in the owning Product/design workflow first and synchronize affected work. Keep the current definitions here and the change rationale in Product history, Feature design, ADR or Git as appropriate, not a growing glossary change log. A known code identifier may be recorded as an alias without authorizing code or save-data migration.

## Module filename rules

- Use a two-digit prefix and a kebab-case ASCII slug, such as `01-pawn-core.md`, `02-map.md`, or `13-mining.md`.
- Allocate a filename when writing the current Product. Numbers are stable identities, not execution order; planning and execution follow the overview's current dependencies and intended order.
- Once assigned, module numbers must not be reordered. New modules use the next available number, including a new prerequisite of an existing module.
- An obsolete module must be renamed with the `_obsolete-` prefix rather than deleted, preserving traceability.

## Version convention

Use the game-version names and scope already defined in the GDD. Product links the version scope it delivers; it does not maintain a separate release sequence or change a game version merely because a delivery unit is split or reordered.

## When to create a module

- **Create a Product** when a distinct, coherent outcome should be delivered and verified as the next unit. One system can span several Products, and one Product can integrate parts of several systems.
- **Extend the current Product** when the adopted change remains within its coherent delivery goal. Reassess existing Feature coverage rather than creating a duplicate plan.
- **Revise a later candidate** in `product.md` when its boundary or order changes. Detail it only after the current Product's required Features are complete.

When the boundary is unclear, use `product-author`; it owns the routing decision.

## Anti-examples

- Do not put implementation choices such as a vector type or pathfinding algorithm in GDD or Product documents. Those choices belong in Project Rules, code, or implementation notes.
- Do not copy GDD flows, states or numeric rules into Product. Link the precise source and explain its delivery applicability.
- Do not describe numeric behavior with subjective terms such as “high damage”; resolve the applicable formula or concrete value in the GDD.
- Do not use subjective acceptance language such as “renders smoothly”; state an observable threshold or outcome.
- Do not put parked ideas in active requirements. Use [Candidate and unadopted ideas](#candidate-and-unadopted-ideas) to distinguish a current design question, an alternative rule value and an idea saved for later; none of these records alone adopts a requirement or authorizes development.
