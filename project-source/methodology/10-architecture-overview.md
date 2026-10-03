# Architecture overview and decisions

The Architecture Overview records current project structure and provides reading entries. It is not a new approval Stage or a substitute for Product, Project Rules and approved decisions. New projects include a purpose/pending-state file in `docs/architecture.md`; fill it from actual structure within the authorized work, without inventing future modules. Use the same ownership and paths from initial development through expansion; there is no separate small-project arrangement.

`docs/architecture.md` owns the project-level map: modules and their roles, startup/composition entry points, cross-module collaborations and permitted dependency directions. A subsystem's internal state owners, interfaces, dependencies and runtime flows use `docs/architecture/<subsystem>.md`, regardless of length or complexity. Identify the subsystem by a stable lowercase hyphenated name in the overview and link its document there; reuse that name for the same actual subsystem. Keep project-level summaries in the overview and internal contracts in the subsystem file. Decision rationale follows the Feature design, ADR and [standalone-decision contract](#standalone-technical-decisions) below. Map templates are [architecture-overview.md.tmpl](templates/architecture-overview.md.tmpl) and [architecture-subsystem.md.tmpl](templates/architecture-subsystem.md.tmpl).

When a responsibility map is insufficient, the relevant subsystem document may trace key runtime flows: trigger, participating modules, state owner and result, with the Godot boundary, lifecycle and failure handling that matter. Link actual implementation or verification evidence and label proposed/unverified behavior. Keep this detail in the subsystem document; no fixed number of flows or diagrams is required.

Feature design in `docs/features/F0XX-design.md` explains one change. This map and its subsystem documents describe the current system across Features. Keep shared runtime structure here, a Feature's local implementation reasoning in its design and qualifying technical rationale in ADRs; standalone decisions use the specific contract below. Link the owners instead of copying them. Later changes update the current map without rewriting a completed Feature as though it had always used the new design.

## Game responsibilities and collaboration

Use the logic/presentation model in `docs/game-organization.md` to explain actual responsibilities within business modules. Link the relevant GDD rules and experience goals, UI and game-presentation specifications to implementation entries. The map owns current technical connections; it does not duplicate their requirements or require separate logic/presentation directories.

For a cross-layer flow whose boundary needs explanation, identify the request, authoritative state owner, accepted/rejected result and presentation consumer. Distinguish reading current state from reacting to a one-time event, and view-local state from business state. Explain who connects participants and cancels pending work when that lifetime affects correctness. For example, a shop UI requests a purchase, the purchase operation coordinates wallet and inventory owners, and the UI uses the result for feedback; reopening the UI reads current state without implying another purchase.

Gameplay orchestration, presentation sequencing and scene assembly have their actual owners; this does not mandate an additional control layer. Engine-dependent gameplay and animation timing may participate under an explicit validity/cancellation contract. Preserve implementation choices allowed by project rules. When documenting these relationships, use the project or subsystem location determined by their scope; notes only link the owning explanation.

## Navigation

When using a map, give each module its main location and useful reading entry points: key scenes, scripts or resources, and relevant verification entries when helpful. Link an existing module README when it already provides that navigation. Keep this selective; do not inventory every file, function or test.

At project level, point to the actual startup/composition boundary and persistent state owners when these help readers understand how modules fit together. Describe the structure that exists, without inventing a bootstrap or Autoload layer. In subsystem documents, keep basic navigation available even when runtime-flow detail is unnecessary.

Distinguish actual direct collaborators and the purpose of their interaction from permitted dependency directions. When using a diagram, identify what its arrows mean: code dependency, scene composition, inheritance or runtime messages, for example. Keep different relationships distinguishable; no fixed set of diagrams is required.

## Maintaining a map

Maps describe current boundaries, responsibility owners and allowed dependencies, linking decision rationale at its fixed owner. Update an existing map when its recorded responsibilities, ownership, collaborations, dependency constraints, paths or entry points change, including moves or renames that leave contracts intact. Implementation changes that do not affect mapped information need no map update or new diagram.

Within the changed scope, check that links and reading entries still resolve to the intended content, reconcile overview and subsystem summaries, and keep affected diagrams consistent with the text. Stage 0 reads the relevant map if present; review checks a changed boundary against it. A stale or missing optional map is a clarification/review concern, not a fabricated Gate failure.

## Designing a module boundary

Apply the design defaults in `docs/project-rules.md` when adding a module, changing a public interface or moving responsibility. Assess the actual callers and confirmed behavior, whether or not an architecture map exists. An ordinary local function does not need a separate design exercise or artifact.

Read an interface as everything a caller must know: inputs and observable results, required configuration and call order, failure behavior, state ownership and lifetimes. For a Godot scene, this can include public signals, exported dependencies and when a pending operation becomes invalid. Identify which knowledge belongs to the caller and which repeated coordination the module could own. Hiding unrelated responsibilities behind one entry point does not make them cohesive.

Compare a direct implementation and existing responsibilities before adding an abstraction. Where materially different designs have real tradeoffs, compare their caller obligations, change locality and verification cost. Use only the alternatives needed to decide; this does not require a fixed number of designs, parallel reviewers or a new approval step.

| Illustrative Godot case | Design judgment |
| --- | --- |
| Several purchase buttons repeat price, balance and capacity checks, then coordinate payment and item delivery | Consider one purchase operation that coordinates the existing state owners through their APIs. Callers receive a defined result; failure effects and change notifications remain part of the contract. Price calculation, wallet and inventory can keep their separate responsibilities. |
| A short scene coordinator owns subscriptions and invalidates pending work when the scene exits | Keep or deliberately relocate that ownership. Removing the node is useful only if callers do not inherit scattered cleanup and lifetime obligations. |

These examples illustrate the judgment, not required game systems or patterns. Record the Feature's implementation choices and reasoning in its design file. A subsystem document describes current implemented structure and references that design; technical decisions meeting the ADR conditions below use the ADR as their rationale source.

## Assessing a proposed refactor

Start from an observed maintenance difficulty or the next agreed change and apply the caller assessment above to the existing and proposed boundaries.

As a thought experiment, remove the layer and call its dependencies directly. If behavior stays intact and coordination becomes simpler, the layer may be an unnecessary forwarder. If its removal spreads validation, ordering, error handling or lifecycle knowledge across callers, that responsibility still needs a coherent home. Keep or relocate it instead of dissolving it into callers. Fewer files or shorter signatures alone do not establish an improvement.

Preserve useful separation between independent game rules and Godot scene orchestration. Check Node, Resource, Signal and SceneTree ownership and lifetimes before merging boundaries. A short scene owner that cancels pending work or manages signal subscriptions may carry a meaningful contract. Introduce a new substitution point only for a concrete runtime or testing need; neither hypothetical future platforms nor a fixed number of implementations determines its value.

Verify the behavior callers depend on using the existing [testing strategy](08-test-traceability-and-evidence.md): L1 for independent rules, L2 for real collaboration and relevant engine behavior. Keep Godot semantics real when they are the subject of the test. Merging modules or adding a boundary test does not by itself justify deleting existing tests; retain needed scenarios and follow the existing test and registry maintenance rules when retiring redundant cases.

## Architecture Decision Records

An ADR is the fixed rationale source for a technical choice that affects multiple Features/modules or constrains project-wide later work and meets all three conditions below. Read the relevant Feature design, architecture and existing ADRs first. Reuse the existing ADR for the same decision; an explanation previously written elsewhere does not exempt a qualifying decision from this ownership contract.

Record the decision in an ADR when its scope qualifies above and all three conditions hold:

- Reversing the choice would require meaningful migration or rework.
- A future maintainer could reasonably question the choice because its reasons cannot be recovered from the code alone.
- Real alternatives were considered, with concrete reasons for accepting some costs and rejecting others.

Repeated discussion is a signal to check whether the rationale is missing or hard to find; it does not itself change ownership. Decisions outside these conditions use the owning Feature design, including brief local choices; work without a Feature uses [Standalone technical decisions](#standalone-technical-decisions). Investigation findings remain evidence until a decision is adopted; a standalone investigation does not need an artificial Feature. Do not invent alternatives to satisfy the ADR conditions. When a qualifying current decision's rationale already exists in a Feature design or architecture document, move the authorized current body into its ADR and replace it with a link. Preserve referenced anchors and historical records as history rather than creating another current rationale body.

Use [architecture-decision-record.md.tmpl](templates/architecture-decision-record.md.tmpl) at `docs/architecture/adr-NNNN-<slug>.md`. Choose the next unused number by reading existing filenames. The template is available from project creation, but no placeholder ADR or architecture map is required before a real decision exists.

During Feature work, Stage 1 checks the scope and three conditions to determine the fixed owner and locate any existing ADR. Stage 2 records a confirmed pre-implementation decision; Stage 3 records decisions discovered during implementation before dependent work and final verification. Authorized standalone technical design/investigation records a qualifying decision in an ADR without creating a Feature. Apply these same conditions regardless of game size or perceived complexity; do not create empty ADRs for decisions that have not arisen.

Likely candidates include a costly save-identity/migration model, cross-scene state ownership or a simulation strategy with real accuracy/performance tradeoffs. A local function, ordinary node layout or the already fixed Godot stack does not require a record by itself. Apply all three conditions rather than the topic name alone. GDD keeps game-design requirements, Product keeps delivery boundaries, and ADR keeps technical rationale. If feasibility changes game design or delivery scope, or conflicts with a project rule, resolve that through its owning workflow instead of using ADR acceptance as an override.

Keep the problem and constraints, reasonable alternatives, decision, benefits and accepted costs, evidence links and useful revisit conditions. Detailed interfaces, protocols and test cases remain in their implementation, subsystem documentation or existing Feature/test records. There is no ADR count, line limit, periodic review date or additional completion Gate.

Use these states as ordinary Markdown, without a separate status registry:

- `Proposed`: a candidate choice; the record does not grant implementation approval.
- `Accepted`: the choice is confirmed within the task's existing authorization. Reuse an explicit decision already made; do not add another approval round. Acceptance records a decision, not proof that an API or runtime behavior was tested. Keep assumptions and any necessary verification visible.
- `Superseded by <ADR link>`: an accepted choice has been replaced. Preserve its rationale, link the replacement, and link back from the new ADR. Clarifying wording does not require a new record; changing the decision does.

The ADR owns the rationale for decisions meeting the conditions above. The architecture map owns current structure and links relevant ADRs without duplicating their rationale or status. Feature design owns that Feature's local implementation decisions and links applicable ADRs; Feature notes provide navigation, and Progress keeps current handoff links. Standalone decisions follow the contract below. Stage 0 reads relevant ADRs even when no map exists, and review checks consistency with accepted decisions. No qualifying decision means no ADR is required; missing rationale for a qualifying decision is a documentation gap to resolve within the current task's scope and authorization.

## Standalone technical decisions

For work without a Feature, a technical decision meeting the ADR conditions still belongs in an ADR. When an adopted decision does not meet those conditions and saving it is authorized, use the **Standalone technical decisions** section in the architecture document determined below. This section records the decision and rationale, distinct from the map's current implemented facts; explain its scope, basis and unverified or unimplemented parts. Discussion-only work stays in the conversation.

| Decision scope | Fixed owning document |
| --- | --- |
| Exactly one identified subsystem | `docs/architecture/<subsystem>.md` |
| Cross-subsystem or project-level scope, including decisions before subsystem boundaries are established | `docs/architecture.md` |

Use the document's configured language for the section title and preserve its references. Do not invent a Feature, subsystem, separate guide or ADR to provide a filename. Once the decision becomes part of a Feature's approved implementation design, move the current rationale into its `F0XX-design.md` at the authorized design-persistence step and replace the architecture decision body with a link; establishing a pending Feature alone does not authorize that write. Current structure remains in the map, and referenced history remains historical. If the decision later meets the ADR conditions, migrate its current rationale to the ADR under the rule above.

## Extracted reference facts

Automation can extract only supported facts: a Resource dependency, an explicit path reference, or a type reference actually recognized by its parser. Record the extractor/version, source snapshot, scanned scope and known blind spots. Dynamic loading, runtime signal connections and ownership generally cannot be inferred from text alone. Keep generated facts in an owned artifact directory such as `reports/maintenance/architecture-facts/<run>/`, under the [report lifecycle](09-records-reports-and-handoff.md#reports-and-cleanup).

Generated output is never the sole architectural authority. A diagram of observed references cannot authorize dependencies or establish causal behavior. Use a diagram only when it helps explain actual responsibilities or dependencies.
