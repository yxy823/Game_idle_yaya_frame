# 11 · Specialist work and sources

This specification defines where professional documents live, how planning and synchronization find their sources, and how resource requirements are handed off. [Task routing](00-overview.md#canonical-task-routing) selects the entry; [Feature planning](02-feature-list-schema.md) and the [execution loop](03-execute-loop.md) handle delivery. A specialist Skill can run alone or inside an authorized task; it does not start another lifecycle.

## Ownership and decisions

Game logic owns rules, business state and valid results. Presentation makes them perceptible and may own local interaction or playback state. `docs/game-organization.md` explains this responsibility model, and [architecture](10-architecture-overview.md) describes the actual implementation relationships.

- The model describes responsibilities inside game modules. It does not prescribe directories or communication mechanisms, and it adds no task routes, Feature types, fields or Stages.
- Presentation-only, logic-only and cross-layer describe a function's scope. Delivery boundaries and order still follow the [decomposition rules](02-feature-list-schema.md#decomposition-rules), including a visual prototype before logic that depends on its decisions.
- Environment, tests, build tools and the delivery workflow are shared engineering support, not additional game layers.
- Logic and presentation do not have separate document sets. The GDD holds the overall rules and experience goals, and one Feature may deliver both.
- Ordinary UI and other feedback are part of presentation but need no separate game-presentation document. A presentation document describes one game moment, not the whole presentation layer.

Use this table to find the authoritative document for each concern:

| Concern | Skill and fixed location |
| --- | --- |
| Game positioning, experience, loops, behavior, rules, states and game-version scope | `design-gdd`: the design files under `docs/gdd/`, including initial design from an idea |
| Numerical models, formulas, parameters, curves and calculation explanations | `design-balance`: the fixed balance files under [GDD document names](01-product-doc-structure.md#gdd-document-names), without a duplicate specification |
| Delivery pre-decomposition, boundaries, dependencies and source mapping | `product-author`: `docs/product.md`, plus only the current `docs/product/NN-<delivery>.md` |
| Shared visual specification refining the GDD's direction | `design-art-direction`: `docs/art/art-bible.md` |
| Shared sound specification and feedback hierarchy refining the GDD | `design-audio-direction`: `docs/audio/sound-bible.md` |
| Interface layout, states and interaction presentation | `design-ui-spec`: `docs/ui/<interface>-design.md`; shared controls use `docs/ui/components/<component-key>-design.md` under [UI document boundaries](#ui-document-boundaries) |
| A game presentation's observable process, component requirements and approach selection | `design-game-presentation`: `docs/presentation/<scope>.md`; shared components use the fixed location under [Game presentation documents](#game-presentation-documents); UI or GDD documents link each use |
| Visual asset specifications | `design-visual-asset-spec`: the resource section of the presentation or UI document that uses the asset, or **Shared resource specifications** in `docs/art/art-bible.md`, selected by [Resource requirements and handoff](#resource-requirements-and-handoff) |
| SFX and music specifications | `design-audio-asset-spec`: the resource section of the presentation or UI document that uses the sound, or **Shared resource specifications** in `docs/audio/sound-bible.md`, selected the same way |
| Localization coverage, locale conventions and approved term translations | `design-localization-spec`: `docs/localization/localization-spec.md`, including [Term translations](#localization-term-translations). Domain definitions link to `docs/terminology.md`, and detailed game rules link to the GDD |
| Translation resources and runtime locale support | `content-localization`: approved translations, keys and locale-sensitive implementation inside the authorized Feature or experiment |

### GDD prerequisite and fixed locations

Standalone and embedded specialist work follow [GDD prerequisite and authority](01-product-doc-structure.md#gdd-prerequisite-and-authority), including its exception for early design support. Presentation exploration and saving settled professional specifications may support initial GDD design; runnable work still needs the relevant substantive design.

- The locations above follow content responsibility, regardless of game size or where the content was first drafted.
- Not every document has to be filled.
- New projects include purpose and pending-state files for the Art Bible, Sound Bible and localization specification, and navigation READMEs for UI and presentations. Their presence does not establish an adopted requirement or a produced asset.

### What stays in the GDD

The GDD keeps game rules, intended player feelings and what players must recognize. Professional standards go to their documents:

- visual style, palette, typography and material treatment: the Art Bible;
- sonic identity, timbre, rhythm and feedback hierarchy: the Sound Bible;
- locale coverage and language conventions: the localization specification;
- interface specifications and complete presentation sequences: their UI and presentation paths.

For example, the GDD may require a calm experience and recognizable rewards. Low-saturation hand-drawn art and restrained acoustic textures are Bible standards linked from that goal.

When saving or consolidating:

- Save confirmed content in `document_language` at its professional document, including during authorized GDD creation or consolidation.
- Move in-scope current specifications that are embedded in the GDD to their professional document and replace the GDD bodies with links. Keep referenced anchors and any original inputs the task must preserve.
- Product, Feature design and AC reference the same professional documents.
- When the user limits the write scope, report the specific content left unsaved or unmoved. Do not silently keep two current versions.

### Writing and adoption

- Each Skill writes its own documents within the user's concrete authorization. Owning a file does not authorize adopting an undecided requirement.
- Distinguish confirmed requirements, proposals and measured observations in the text. A file or a Git commit alone is not evidence of approval.
- Reuse the user's decisions; ask only for missing material choices.
- A narrow specialist edit does not authorize changing GDD rules, Product scope, another specialist's specification or the task's scope.
- `design-balance` maintains its numerical GDD content directly, without routing the writes through `design-gdd`. Changes to experience goals, mechanics or other systems return to `design-gdd`.
- When another professional decision changes game behavior or the accepted overall direction, update the GDD through `design-gdd` in the same task.

| Change | Route |
| --- | --- |
| A confirmed professional requirement changes | The Skill that owns the document updates it; `feature-sync` assesses current and planned work. A change to overall game design updates the GDD through `design-gdd`, scoped numerical design through `design-balance`, and delivery boundaries through `product-author`. |
| Implementation violates a confirmed professional requirement | Repair it inside the unfinished Feature that delivers it, or use `engineering-change-plan` for an independent bug. Cite the professional document even when Product does not repeat it. |
| A proposed improvement is not yet adopted | Return the proposal. Do not use it as an AC, a defect or an implementation mandate. |
| Sources conflict or lack a material decision | Resolve it with the responsible Skill or the user before dependent work. Report both sources instead of silently picking one. |

### Committing source changes before synchronization

- For standalone authorized specification work, validate the affected links and commit the complete source change under the project Git rules before `feature-sync` compares Git history.
- Inside a Feature, use its Stage 3 documentation checkpoint and commit. A Skill handoff does not start a new task or require a clean working directory.
- A substantive source change that needs synchronization must be committed first. If a no-commit instruction leaves it uncommitted, report the unmet prerequisite.
- When synchronization finds stale links in its source documents, the Skill that maintains those documents repairs and commits them within the approved scope before any plan write. Synchronization then restarts its source analysis on the refreshed documents.
- Links inside plan records follow `feature-sync`'s own update and commit steps. A Markdown filename alone does not decide which Skill maintains a file.

## Discover and map sources

The Feature `source` stays one precise primary source string:

- the current Product's delivery section, for Product-derived work;
- a GDD or professional section, when it directly defines the scoped change;
- `infrastructure`, for technical work without a single documentary source.

Do not add a sources array or encode a list into this string. Record observable requirements as concrete AC with source links. Record implementation constraints and their source links in the Feature design file. Notes provide navigation, not the body of a binding constraint.

At planning or synchronization:

1. Read the relevant GDD entry, [Design scope and boundaries](01-product-doc-structure.md#design-scope-and-boundaries) and [Open design questions](01-product-doc-structure.md#open-design-questions). Check whether an open question prevents a current requirement or AC; do not turn a working assumption into adopted design.
2. Follow the primary source's actual links to GDD sections, UI and presentation documents, resource sections, and art, audio and localization specifications.
3. Read the Feature index and Product dependencies to find every planned consumer of a shared source, then read their details. Each shared source states in plain prose where it applies, such as "all inventory icons" or "all interactive feedback"; it need not list Feature IDs.
4. Apply a shared source even where a link to it is missing. Repair missing links within scope instead of treating them as an exemption.
5. Check for renames, removed sections and stale links.

Use the same reading when creating or reviewing professional requirements. Do not load design or professional documents that cannot affect the task.

Translate each requirement that applies into a concrete, task-sized AC, or into a linked design constraint with a verification obligation. For example, name the icon states, target display size and recognition check instead of only saying “fits the Art Bible”. Keep executable test mappings in the Feature JSON and the Registry. Keep additional performance, duration, display or listening checks in the Feature's verification plan or design. No new schema field, dependency registry or duplicate acceptance ledger is needed.

Synchronization covers the actual GDD, Product and professional source paths, including presentation documents and their resource sections, in both the Git differences and the comparison with current sources.

- A previous `synced_at_commit` proves only that the sources read at that synchronization were considered. A source category that synchronization did not read, such as presentation documents, may still be unsynchronized even when its files predate that commit.
- When needed, compare the sources and the affected plan as they were at the anchor.
- If coverage cannot be established, use `feature-sync`'s current-document alignment for the planned scope and report the unknown history.
- Do not invent a baseline, add per-source receipts or silently advance the anchor.
- Later Products stay short pre-decomposition candidates until their turn. Completed Feature history stays intact; a change to completed work gets a follow-up.

## Localization term translations

Maintain the approved glossary in the **Term translations** section of `docs/localization/localization-spec.md` (`术语译名` in Chinese). `design-localization-spec` maintains this section.

- Each entry links the canonical concept in `docs/terminology.md` and gives the target locale, the chosen wording and any context-dependent distinction.
- Keep pending candidates marked as pending until the wording is adopted.
- Keep forbidden variants or inflection guidance only when they prevent an actual ambiguity.
- Do not copy domain definitions or create a second registry of term identities.

The documents divide the work as follows:

- `docs/terminology.md` owns conceptual meaning, canonical project names and lookup aliases, including code names. It does not decide target-locale wording.
- The localization glossary owns those wording requirements.
- Runtime translation resources hold the complete translated strings and implement the glossary. Ordinary sentences and dialogue are not copied into a Markdown translation catalog.
- The documentation language does not choose the game's source or target locale.

`content-localization` applies the approved entries to actual strings, and `review-localization` checks consistent use against the same section. A proposed term translation or a conflict returns to `design-localization-spec` within the task's authorization. A change to the underlying concept or gameplay returns to `design-gdd` and [Project terminology](14-project-terminology.md). During authorized consolidation, move in-scope target-language glossary bodies from the GDD or the terminology file into this section and update references. Runtime strings remain implementation content, not another authoritative glossary.

## UI document boundaries

Use one `docs/ui/<interface>-design.md` for each screen or overlay that the player enters and leaves on its own and that has its own interaction flow. Give the interface a stable lowercase English hyphenated key, independent of its scene filename, Product or writing session.

- A panel, tab, HUD part or local expansion that works only inside its host flow stays in the host's document. Hiding or showing a widget does not by itself make a separate interface.
- A shop's confirmation dialog with its own confirm and cancel flow has its own document; the shop's item list stays in the shop document.

When a second distinct interface adopts or explicitly considers the same control or dialog behavior:

1. Check `docs/ui/README.md`, then choose a stable lowercase English hyphenated behavior key, such as `confirmation-dialog`.
2. Move the common states, interaction rules and component-only resource specifications to `docs/ui/components/<component-key>-design.md`. If the dialog already had an interface document, move that body instead of keeping both.
3. Leave each consumer only its invocation context, supplied content, local differences and links.

Shared appearance alone belongs in the Art Bible and does not need a behavior component document. Keep a component inside its only interface until such reuse exists; do not create hypothetical shared controls. Once extracted, the component keeps its path while any consumer remains.

`docs/ui/README.md` lists interface and component links, their purpose, associated Products when any, and component consumers; do not create another component index. Moves update affected links and remove duplicate current bodies within the task's authorization and the [artifact lifecycle](09-records-reports-and-handoff.md). Complete game moments use the presentation rules below.

## Game presentation documents

Plan around an observable game moment, such as an item arriving in the inventory or a character dying. Start from the experience goal and describe the trigger, the visible and audible sequence and the end condition before selecting techniques. A presentation can combine sprite frames, Shader, particles, Tween, AnimationPlayer or project implementations that already exist. Choosing a technique does not authorize implementing it or producing image or audio files.

When feedback represents a game-state change, identify the business fact or accepted result it communicates and link its GDD section instead of redefining the rule. Distinguish a request or an immediate interaction response from a confirmed success result. Current-state display and one-time event feedback may need different behavior: reopening a health panel shows current HP without replaying a past hit. `docs/game-organization.md` describes this collaboration model; actual APIs, signal wiring and lifecycle ownership belong in architecture or the implementation design.

A presentation's identity is its trigger moment and the result the player perceives.

- Different sources of the same moment and result share one `docs/presentation/<scope>.md`. Name the stable lowercase English hyphenated scope after that result, not after a screen, Feature or technique. Record source-specific triggers, targets and selected combinations inside that document.
- For example, item arrival after either a reward claim or a shop purchase uses `item-added.md` when both communicate the same confirmed arrival. Different origin screens alone do not justify separate `reward-collection.md` and `shop-purchase.md` copies.
- A separately meaningful process with a different trigger or result, such as revealing an unknown reward before it is accepted, has its own scope. If that process ends with the item-arrival moment, link `item-added.md` at that point instead of copying it or creating a component for the whole moment.
- Reuse of part of two distinct processes follows the component rules below.

Check `docs/presentation/README.md` before assigning a scope. Use sections for the following information, and expand only the detail that is useful for the current scope:

- **Goal and process:** the source requirement, applicable scenarios, observable sequence, confirmed constraints and unresolved choices.
- **Components and standard requirements:** what each part must communicate, and when relevant its timing, spatial relationship, triggers, retrigger and cancel behavior, and externally controlled values. Distinguish shared requirements from one alternative's own constraints. Do not prescribe algorithms or node organization without a real requirement.
- **Alternatives:** candidates for the whole presentation or for individual components, with their suitability, tradeoffs, dependencies and resource specifications. A candidate can remain a description; not every alternative must be built. Component bodies follow the placement rules below.
- **Current adoption and implementation:** the selected combination for each relevant use, plus the actual implementation and consumer paths when they exist. For example, in `item-added.md` the reward overlay may adopt icon flight B plus destination feedback A; link those sections instead of repeating a full specification for every combination. Distinguish proposed paths from actual files, and unimplemented decisions from integrated behavior.
- **Acceptance entry:** link the Feature or experiment that verifies the presentation, the acceptance conditions, the runnable entry and the report or completion record. Identify which alternative or combination and which scenario the evidence covers. Results stay in those records under the [artifact lifecycle](09-records-reports-and-handoff.md), not in a second acceptance ledger in this document.

### Shared presentation components

Keep a component's requirements, alternatives and alternative-specific resources in its parent presentation while only that presentation uses it. Several UI consumers of the same presentation do not change this.

When a second distinct presentation adopts or explicitly considers the same component behavior:

1. Check the presentation navigation, then choose one stable lowercase English hyphenated key that names the behavior, such as `icon-flight`.
2. Move the component body to `docs/presentation/components/<component-key>.md`.
3. Replace every parent copy with a link. Different techniques for that behavior stay as alternatives inside the component document.

The shared component owns its common requirements, alternatives, resource specifications and links to the shared implementation. Each parent presentation owns its own sequence, trigger and target context, selected combination and acceptance entry, and links the component's sections. Record the component link and its consuming presentations in `docs/presentation/README.md`; do not create another component index.

A shared component keeps its fixed path while any presentation uses it, even after another consumer is removed. Removing the last use follows the [artifact lifecycle](09-records-reports-and-handoff.md). Do not create a shared component file for hypothetical reuse, or keep a second current body in the original parent.

### Links, Features and implementation updates

UI specifications link presentations at their actual use sites and end with a “Related game presentations” navigation section, written in `document_language`. Ordinary control states can stay in the UI specification. Several interfaces can link one shared presentation and keep their own trigger and consumer information. Presentations without a UI use are linked from the relevant GDD topic. `docs/presentation/README.md` is navigation to the actual documents and upstream sources; do not keep binding requirements only in that index.

Presentation documents and Features do not correspond one to one. Map only adopted requirements and currently authorized alternatives into the Feature source, AC, design and verification obligations. Detailed engineering guidance stays in the Feature design or the implementation; link its actual path from the relevant alternative instead of copying code or algorithms here. Use `prototype-godot` to answer a concrete uncertainty, not as a compulsory step for every presentation.

The implementation task updates the presentation document with the effective technique, files, resources and consumers before final verification.

- It may change the implementation means while keeping the confirmed presentation requirements, within its authorization. Changed goals or constraints use the change routes in [Writing and adoption](#writing-and-adoption).
- Distinguish planning complete, implementation available and actual human acceptance.
- Replacing one component updates the adopted combination and the current verification scope. Earlier acceptance evidence stays as history for the version and coverage it recorded.

## Resource requirements and handoff

Keep resource specifications and preparation information inside the design document that uses the resource. Choose the document from the actual or explicitly considered uses, including the component boundaries in [UI document boundaries](#ui-document-boundaries) and [Shared presentation components](#shared-presentation-components):

| Resource use | Fixed location |
| --- | --- |
| Used by one presentation or one extracted presentation component only | Its `docs/presentation/<scope>.md` or `docs/presentation/components/<component-key>.md`. A dependency of one alternative stays in that alternative; requirements shared by its alternatives go in the common resource section. |
| Used by one interface or one extracted UI component only, and no separate presentation covers the use | The resource section of its `docs/ui/<interface>-design.md` or `docs/ui/components/<component-key>-design.md`. |
| Shared across several of the documents above, outside a single component | Visual resources: **Shared resource specifications** in `docs/art/art-bible.md`. Audio resources: the same section in `docs/audio/sound-bible.md` (`共享资源规格` in Chinese). |

A shared component's own resources stay with that component; many callers do not by themselves make those resources global. An item icon used by the inventory, the shop and reward feedback belongs in the Art Bible's shared-resource section. A texture used only by a shared icon-flight alternative stays in that component. A general click sound used by independent interfaces belongs in the Sound Bible's shared-resource section.

When added uses change where a resource belongs:

- Move the affected specifications and preparation state together, update consumers and replace old bodies with links within the authorized scope.
- `design-art-direction` and `design-audio-direction` own the Bibles' shared standards. `design-visual-asset-spec` and `design-audio-asset-spec` maintain the concrete file entries in the shared-resource sections.
- Localized headings keep these section semantics.
- Link each use to that body. Do not create a separate default resource-list directory, a list per Feature or a second receiving ledger. Product does not need to relay these writes.

### Writing resource entries

Read the current task, the relevant GDD and professional requirements, the selected or candidate alternative, the relevant project assets and any supplied source locations.

- Include only files needed by the current scope or an explicitly discussed alternative.
- Do not add future decoration, or separate files for states that themes or procedural presentation can already express.
- Record unknown inputs instead of inventing resources, styles, dimensions or technical requirements.
- A candidate alternative's dependencies are not automatically resources the project must prepare.

Write in `document_language`, state the covered uses and link the source requirements. A compact table can hold short entries; longer specifications stay in the same section. If local resource IDs help references, keep them stable and unique in that document or section, and include the document path and anchor in cross-document links. No global ID counter or resource registry is needed.

Record what is needed to prepare and inspect each actual resource:

| Field | Meaning |
| --- | --- |
| Purpose and identity | Needed kind, covered uses, real or proposed filename, and links to the applicable shared style or source. Keep reusable filenames. |
| Resource constraints | Required format and, where relevant, dimensions, transparency, aspect ratio, padding or cropping, frame timing, audio duration or looping, or other meaningful constraints. Distinguish source pixels from the expected display size, visible subject size or relative scale. Do not impose pixel fields on audio or unrelated media. |
| Preparation and file mapping | Factual preparation status, the supplied source or actual location, the proposed or actual project target path, and the relation to runtime consumers. Mark missing files and sample or final status explicitly. |
| Decisions and observations | Separate confirmed requirements, proposed values, measured values, values pending confirmation and fields that do not apply. Keep unresolved choices with the alternative they affect. |

Reuse the project's file organization. Runtime assets stay outside ignored documentation folders. Link provenance records where relevant instead of copying them. Settings that only implement a requirement stay in the actual scenes, resources, code or engineering guidance.

A non-final sample can be enough for a scoped prototype; state what it represents and what remains to be replaced. Missing textures do not prevent planning a spark's motion, density, duration and trigger. If the particle alternative needs a texture, describe its specifications in that alternative and mark the unavailable file. Only dependent implementation or final experience checks may be blocked; do not turn optional parameters or missing files into a barrier to useful planning.

Link the relevant resource sections from Feature AC or design; notes or Progress provide navigation. Do not hide binding requirements only in process notes, and do not copy entire rows. A resource analysis alone does not change intent, authorize production or create Features. A material change follows the routes in [Writing and adoption](#writing-and-adoption).

### Handing off and receiving files

1. Hand off links to the resource sections, the missing specifications and files, and their intended destinations, so the user can prepare or supply them outside the project. Image and audio production and searching a local asset library are outside this capability.
2. If the available resources are enough, continue authorized work without waiting.
3. When files arrive, inspect their actual content and the relevant format, dimensions or duration. A filename or the user's report that a file was copied does not establish fit.
4. Update the same sections and keep unresolved gaps visible.
5. Copy or import only within the authorized scope, keeping source files and unrelated content.
6. Finalize the preparation status and the actual file and consumer relationships before final task verification.

Specification completion, file presence, successful import and human visual or audio acceptance are separate facts.

## Design, production, integration and review

Design chooses the direction; specifications describe a concrete deliverable; production supplies or processes assets; `content-asset-integration` imports and connects available assets. Each can be requested independently. Reuse suitable project assets before requesting new ones; a reference image or audio example is not a produced deliverable. Missing representative assets leave the corresponding visual or listening checks unverified.

Visual-art, music and sound-effect production are reserved capabilities. No production Skill or agent exists, and their methods and tools are undefined. Record the preparation gap and its specification; do not invoke a nonexistent Skill or promise asset generation in a Bible.

`content-asset-integration`, `content-localization` and `diagnostics-instrumentation` may change resources, code or configuration only inside an authorized Feature or scoped experiment.

- Adopting numerical values into runtime resources or code also uses that implementation route; authorization for the numerical document alone does not cover it.
- These Skills return to the calling task for verification, any required human acceptance and completion.
- Standalone specification or investigation work need not invent a detailed Product or Feature. The GDD prerequisite and its early-design exception still apply.
- Diagnostic findings do not authorize repairs or new requirements.

For comparing resources or tuning feedback timing, the project may use the optional [asset workbench example](../asset_workbench/examples/README.md), which lists its entries, controls and supported parameters. It is a development tool, not an asset-production Skill, an automatic analysis step, a Stage or evidence of human acceptance, and its example assets are not approved production content. Reuse the project's own presentation, data and audio APIs instead of forcing project objects into the example Cue.

Formal reviews use separate review Skills and an independent instance under [independent review](12-independent-review.md). No creation or measurement Skill certifies its own output as independently reviewed. Human experience acceptance remains the user's decision. Playtest analysis and release work are outside this scope.

## Finalization and evidence

Put binding requirements in their source documents under `docs/gdd/` or the relevant professional directory. Do not put the only body of a requirement in a general-purpose `README.md`, `docs/knowledge/`, `docs/research/` or `reports/`; a substantive GDD `README.md` entry is a source document. [Artifact-backed completion and semantic freshness](08-test-traceability-and-evidence.md#artifact-backed-completion-and-semantic-freshness) defines which of these files the completion fingerprint covers and when an edit invalidates evidence.

- Finalize the GDD, specifications, presentation adoption and implementation links, and resource status and location updates at the Stage 3 documentation checkpoint, before final verification.
- Record later human acceptance in the report or completion record that the presentation links. Do not append the result to the source documents after verification while still treating the earlier evidence as current.
- Keep transient findings in the conversation, and original evidence or review reports under the [artifact lifecycle](09-records-reports-and-handoff.md).

Performance and long-run measurements record:

- the actual version and uncommitted changes;
- the environment, scenario and workload;
- the method, duration and termination reason;
- the remaining gaps.

Keep temporary diagnostic instrumentation separate from the delivered version, and measure again when the change affects the claim. An interrupted soak run proves only its observed duration and scenarios; the absence of a failure is not general proof. The gdUnit evidence adapter accepts actual gdUnit results only. Supplemental evidence satisfies its own planned obligations; it does not stand in for a gdUnit pass or excuse skipping required tests. The task that planned the measurement and the reviewer judge whether the evidence is sufficient.
