# 01 · GDD and Product document structure

## GDD prerequisite and authority

Use `design-gdd` to develop a game idea into a GDD, or to deepen, revise or consolidate existing design. Initial design discussion, its supporting clarification and numerical modeling, and review of an actual draft can proceed before a complete GDD, Product or Feature exists. Use the known goals, constraints and available draft; preserve assumptions and unresolved choices. Discussion alone writes nothing, and a request to save a draft does not adopt all its proposals. Design work does not require a ready Godot environment.

Delivery planning, implementation, engineering repairs and runnable experiments require a substantive game design document under `docs/gdd/`. Read its entry and the sections relevant to the task. An empty directory, directory-navigation README, template or pending-state notice is not a GDD. If it is absent, explain the missing design and the `design-gdd` route; stop dependent development rather than inventing gameplay or starting an unrequested design interview. Other specialist work applies the same prerequisite unless it is the early GDD design support described above. A status query may explain the current state without starting work.

The GDD owns game positioning, intended player experience, core loops, system rules, states, numeric behavior, content progression and game-version design scope. A new GDD normally uses a short entry linking useful topic documents under `docs/gdd/`; do not create empty chapters to fill a template. Preserve an existing GDD's effective organization and section links, including a single-file design. A local edit does not require restructuring or a second copy, and no specific entry filename is mandatory. It need not settle every future detail, but the current delivery scope and design dependencies must be clear before dependent planning or implementation. Resolve an affecting design gap in its owning GDD topic; do not invent the missing rule in Product or Feature text.

The GDD is a normal maintained project source. Within the user's concrete authorization, `design-gdd` owns overall game design and cross-topic consistency; `design-balance` may directly maintain the scoped numerical model, formulas, parameters and calculation explanations at their owning GDD location. Ordinary specification values do not require numerical modeling. `product-author` owns delivery documents, not game-design authoring. The coordinating task handles affected Product/professional sources and existing Features through their owners without using a document author as a mandatory writing intermediary.

Proposals remain distinct from accepted design, and adoption remains distinct from calculation, runtime or experience verification. File presence or a saved edit alone does not confirm a choice. Saving a candidate must not silently replace an adopted value. Changing an experience goal, adding a mechanic or altering another system to make a model work returns to the overall design decision; numerical design does not authorize runtime code/resource edits. Preserve unrelated content and use the existing source-commit, synchronization and validation contracts when existing work is affected. An initial GDD draft need not create Products, Features or synchronization records. No separate GDD permission, tracking ledger or synchronization system is required.

Professional documents refine the GDD into UI, art, audio, resource and localization specifications under [Specialist work and sources](11-specialist-workflows.md). Reference a detail already defined in the GDD rather than maintaining another body. Changes to game rules or accepted overall direction update the GDD; technical implementation choices belong in Feature design, architecture or code.

Before revising design or delivery scope, check applicable hard constraints in `docs/project-rules.md` and relevant accepted architecture decisions. A design request does not silently amend a project rule. Resolve conflicts through [project rule maintenance](04-coding-rules-4-layers.md#incremental-rule-maintenance).

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
| Planning decisions to resolve | Yes | Questions that affect delivery boundaries or order, linking design questions to their GDD location. |
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
| Open decisions | Only unresolved choices affecting this delivery; identify which dependent work must wait and where the design decision belongs. |
| Change history | Reverse-chronological delivery-boundary changes and reasons. |

## Visual prototype before dependent implementation

Professional documents are maintained directly by their owning Skills under [Specialist work and sources](11-specialist-workflows.md). GDD owns game-design requirements; Product selects the delivery scope and links the applicable sources.

For a new interface or a substantial layout/resource change, establish its visual foundation before implementing logic that depends on that interface. Reuse an already validated layout when it covers the current scope; copy/value changes, non-visual logic and unaffected modules do not require another prototype. Work on the current interface/module, including its surrounding screen context, rather than waiting for all game art or all future screens to be ready.

The sequence is: interface purpose and main states → representative resources and initial specifications → independent Godot visual prototype → layout/scale validation and adjustment → dependent production logic → visual refinement. Resource specifications and layout may iterate together.

The Agent identifies this need during planning and resource preflight, or the user may request a prototype directly. This is task reasoning, not a background trigger. Discussion-only work proposes the next step without writing or building; existing implementation authorization covers in-scope preparation and execution, but never supplies the user's actual visual acceptance.

### Scope and resources

Before building, identify the questions to settle, the target viewport/window and relevant scaling conditions, core elements/states, available resources and remaining gaps. The relevant specialist Skills specify these inputs; a written sketch or HTML exploration does not verify the Godot result. When resources need a preparation handoff, use the [resource preparation list](#resource-preparation-list-and-handoff) below.

Use representative real images, fonts, video, music and sound effects where the interface calls for them. Select samples that expose actual aspect ratios, detail, text lengths and content density; do not require every media type or the complete asset library. Distinguish source pixel dimensions, on-screen size and visible subject size after transparent padding. For audio, identify duration, looping and feedback timing relevant to the experience. Follow existing asset provenance and import rules. A missing sample leaves that check unverified; identify the gap and seek a suitable sample or an explicitly accepted substitute, rather than claiming that text, silence or a placeholder filename proves it.

Create a clearly named, independently runnable `.tscn` in the project's existing scene organization, separate from production functionality. Include the actual content regions, representative items, buttons and text in their surrounding layout. Use local sample state and only interactions needed for evaluation, such as hover/pressed/selected/disabled feedback, opening a panel, scrolling or preview playback. Do not connect production business/game rules, persistence or live data flows. If project Autoloads would run those flows, isolate the prototype entry from their side effects. A small local script is sufficient when native controls cannot express the required feedback.

Final backgrounds, decoration and palette are optional at this point; readable contrast and distinguishable interaction states are necessary for evaluation. Avoid a fixed number of design variants: compare alternatives only when a real layout decision needs them.

### Validation and adoption

Run the scene in the target project's confirmed Godot environment. Check spatial relationships, resource scale/cropping, text readability, button usability and relevant empty/dense/long-text states at the agreed display conditions. Exercise interactions and listen to relevant samples. Static checks and screenshots are supporting evidence, not substitutes for actual operation and human judgment. Missing execution or human feedback remains explicitly unverified.

Keep the entry scene, questions, observations, a link to any resource preparation list and file disposition in current Feature notes, or Progress for a standalone experiment. Keep resource details in that list when present. Confirmed game-design changes belong in the GDD via `design-gdd`, or `design-balance` for scoped numerical design; delivery-boundary changes belong in Product, while professional layout, size, readability or sound specifications belong in their owning specialist source. Adoption uses the applicable authorization and source-impact route. Node properties and tuning values remain in the scene, resources or implementation notes. Do not maintain a second specification or prototype status ledger.

During planned delivery, use an ordinary Feature for an independently reviewable visual foundation and make dependent implementation wait for its applicable manual acceptance. A narrow check may stay inside the current Feature, with the visual decision settled before dependent logic. An explicitly requested standalone exploration follows the scoped-experiment route in [task routing](00-overview.md#canonical-task-routing). Prototype acceptance covers only its visual/interaction scope, never the later business behavior.

After validation, reuse suitable layout nodes, themes and resources deliberately; remove sample-state wiring when adopting them into production. Retain a separate prototype only while it answers an ongoing question; otherwise archive or remove it within the authorized scope. Record unresolved limits and keep the accepted decisions, without maintaining competing production and prototype interfaces.

## Scoped logic prototypes

Use `prototype-godot` when an authorized experiment can settle a specific interaction, state-transition or technical-feasibility question. Identify the question, relevant confirmed GDD rules, observed result needed to answer it and the bounded experiment before building. Preserve unsettled design choices as proposals; an experiment does not approve a new rule. Reuse an existing experiment when it still answers the question, and follow the scoped-experiment route in [task routing](00-overview.md#canonical-task-routing).

Prefer a small, independently runnable Godot scene with only the state and interactions needed for the question. Make relevant state visible, support reset to a known starting point, and combine free operation with repeatable situations that expose the uncertainty. For a crafting queue, useful situations might include insufficient materials, pausing or cancellation and refund; include only those relevant to the confirmed question. Do not require a fixed number of cases or visual variants.

Local sample state is suitable for exploring a proposed interaction. If the question concerns actual signals, input, lifecycle, persistence or another engine integration, exercise the relevant real path under the task's permissions and protect live data. A simulated transition cannot prove that integration works. Use the visual-prototype requirements above when judging layout, representative assets or perceptual quality. HTML is optional only for an explicitly requested engine-independent concept demonstration; it is not a required precursor or evidence of Godot behavior.

Report what the experiment answered, the actual observations and remaining limits. Reuse the recording and adoption rules under [Validation and adoption](#validation-and-adoption): retain the entry and useful evidence in existing notes or Progress, return accepted decisions to their source owners, and resolve sample code disposition within authorization. A successful experiment does not establish production readiness, required regression coverage or human acceptance. Do not make experimentation a prerequisite for work with no relevant uncertainty.

## Resource preparation list and handoff

Create or update a project-local Markdown list when the user requests one or the authorized task needs the user to prepare/reuse resources before a prototype or implementation. Prefer an existing list covering the same scope; otherwise use `docs/resource-requirements/<scope>.md`, such as `inventory-panel.md`. Blank projects provide `docs/resource-requirements/README.md` for discovery, without empty resource lists or one list per Feature by default. Several Features may reference the same list. Name lists for a stable business scope and resource purpose using lowercase English and hyphens, such as `shared-item-icons.md` or `combat-feedback.md`; do not bind shared lists to a single Feature ID or preparation batch. Add module subdirectories only when actual volume warrants them, preserving references when moving files. The responsible specialist maintains its entries; the current task coordinates shared uses without a separate registry or a Product-writing intermediary.

Read the current task, confirmed GDD design, Product delivery scope and professional requirements, relevant existing assets and any supplied source locations. `design-visual-asset-spec` and `design-audio-asset-spec` maintain their domain entries in the same list. Include only the minimum files needed for this scope, merging repeated uses of one resource. Do not add future decoration or separate files for states that existing themes or procedural presentation can already express. Record unknown inputs rather than inventing resources, styles, dimensions or other technical requirements.

The document follows `document_language` and contains a brief scope/source overview, a resource file table and unresolved questions. State the covered uses and boundaries and link the applicable Product, UI and shared professional sources. Maintain the directory README's list links, purposes/boundaries and source navigation when lists are added, renamed, merged or removed; specifications and preparation status stay in the lists rather than the index.

Keep these nine core fields in the table; longer specifications may live in details keyed by resource ID:

| Field | Meaning |
| --- | --- |
| Resource ID | Unique within the list, e.g. `RES-001`; preserve IDs when revising it, and include the list path for cross-list references. No global counter. |
| Resource filename | Semantic name with full extension when the format is known. Preserve reusable filenames; mark suggested names as proposals. If format is unresolved, mark the extension pending or show labeled alternatives. |
| Resource type | The actual needed kind: image, icon, character/UI art, texture, animation, audio, video, font, model or another task-specific resource. |
| Purpose | The task use and any shared uses that avoid duplicate preparation. |
| Pixel dimensions | Width × height where applicable; distinguish required dimensions from measurements of an existing file. |
| Style | Confirmed visual/audio direction, or pending; do not invent a final palette. |
| File format | Confirmed requirement or observed existing format, consistent with the filename; unresolved choices remain pending. |
| Preparation status | Plain factual wording such as pending decision, to prepare, supplied/uninspected or inspected for reuse; never a substitute for Feature completion or human acceptance. |
| Notes | Only applicable constraints, e.g. transparency, aspect ratio, animation frames/duration, audio sample rate/looping or model requirements. |

For each entry, include **source/actual location**, **project target path** and **expected display size or relative scale** in Notes or its ID-linked details. Identify missing sources and proposed target paths explicitly; reuse the project's organization. Runtime assets stay outside ignored documentation folders. Link existing provenance records where relevant rather than duplicating them.

Use distinct labels for **pending confirmation** (applicable but unknown), **not applicable**, **proposed value** and **measured value**. A non-final sample can be sufficient for the current prototype; state what it represents and what remains to be replaced. Do not turn every optional technical parameter into a blocking question. Missing information does not prevent drafting the useful list.

GDD owns game design; Product owns delivery scope; professional sources own their confirmed detailed specifications; the list owns local specifications, preparation details and file mapping; scenes/resources own implementation settings. Link the applicable list entries from Feature AC/design, with notes or Progress providing navigation. Do not hide binding requirements solely in process-only notes or copy entire rows. A resource analysis alone does not change intent or create Features. Material changes follow the owning source's route in `11-specialist-workflows.md`.

Hand off the list with the missing files/specifications and their destination paths so the user can create, reuse or supply them. Pause only work that needs unavailable resources, subject to the current task's continuation boundaries. If resources already suffice, continue authorized work without a ceremonial wait. When files arrive, inspect their actual content and applicable format, dimensions or duration; filenames and user-reported copying alone do not establish fit. Update the same list and retain unresolved gaps. Copy/import only within the authorized scope, preserving source files and unrelated project content, then continue the prototype and its actual operation/listening checks. List completion, file presence, successful import and visual/audio acceptance are separate facts.

## Project terminology (optional)

Clarify vocabulary when competing names or meanings would change a Product decision. Read existing definitions first. If one word describes different concepts, distinguish them using familiar names; if several words mean the same thing, propose one consistent name. Reuse an already clear definition instead of starting a glossary for every task.

Test the distinction with a concrete scenario. For example, when discussing inventory, distinguish an item definition, an owned item and a stack only if their identity or behavior differs. Whether two items with different modifiers can stack exposes a real decision; listing every possible item attribute does not. Record an accepted behavior decision in its owning GDD section and derive delivery scope and AC from it.

When implementation exists, compare the relevant code with the stated meaning. Surface conflicts with both sources: code describes what happens today and cannot silently redefine approved intent. A new meaning remains a proposal until the user resolves the material Product choice.

Keep a definition in its GDD section when that context already explains it sufficiently. Use `docs/terminology.md` for confirmed project vocabulary needed across systems, Products, Features or conversations. New projects include a short purpose/pending-state placeholder; add definitions only when useful confirmed content exists. A placeholder or missing glossary is not a blocker. Apply the GDD creation/development boundary above to the owning task; recording a term does not establish a game design or authorize development.

`docs/terminology.md` owns confirmed domain vocabulary and a shared language across requirements, design, code and discussion. It is not a general project-context document. Do not create a second `UBIQUITOUS_LANGUAGE.md` or parallel glossary. Retain definitions that will be reused beyond this discussion and prevent a real ambiguity; stable means currently agreed, not immutable.

Use a compact structure, expanding only where a distinction needs explanation:

- Begin with a short description of the domain covered when it helps orient the reader, then give each term a canonical name and definition, normally one or two sentences. Include domain actions as well as nouns when their meanings matter. Necessary distinctions may take more space; there is no word or term quota.
- Explain necessary conceptual relationships, aliases or commonly confused neighbors only when they prevent a real misunderstanding.
- Link to the owning GDD section for detailed rules, flows, values and state transitions, and to Product/Feature records for delivery scope and AC. Keep implementation state ownership, Godot classes, storage formats and technical choices in architecture records or code.
- Keep pending ideas, chat logs, current progress and task-local notes out of terminology. Reuse existing definitions; when moving one here, replace authorized duplicates with links rather than keeping competing copies. Preserve section anchors used by existing Feature sources, leaving a link at the old location.

`project-grill-me` returns clarified answers to the owning task; `product-spec-elicitor` focuses on delivery choices. `design-gdd` owns overall game design, `design-balance` its scoped numerical design, and `product-author` Product delivery documents. `project-terminology` owns meaning-preserving definitions and links, whether local to the GDD or shared in `docs/terminology.md`. An authorized design task may use it for useful settled terms while creating the GDD; this does not start Product planning. Pure terminology maintenance may clarify a name, record an already agreed distinction or move/link a definition; it does not require a new Product, Feature or Feature synchronization. If a definition changes actual intent or exposes a material unresolved behavior, resolve that decision through the design owner and synchronize affected work before updating dependent terminology.

Read relevant terminology definitions during clarification, planning, implementation and review when the file exists. Follow `document_language`, preserve stable IDs, and do not rename code or migrate saved data merely to align terminology.

### Incremental terminology maintenance

Check new terms, renames, retirements and clarified meanings during Product work and at the Stage 3 documentation checkpoint before final verification. If there is no useful change, do not write or produce an empty report. Reuse existing documentation authorization for settled, meaning-preserving changes; discovering a new material Product choice does not approve it.

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
- Do not put speculative future ideas in active requirements. Keep them in `docs/unadopted-ideas.md` until adopted into the existing GDD; that file is not a route for starting development without a GDD.
