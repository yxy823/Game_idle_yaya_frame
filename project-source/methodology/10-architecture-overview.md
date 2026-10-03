# 10 · Architecture overview

The architecture documents record the current project structure and give reading entry points. They are not an approval Stage and do not replace Product, Project Rules or approved decisions.

## Where architecture and decisions are recorded

This table is the single statement of where structure and decisions live; other documents link here.

| Content | Location |
| --- | --- |
| Project-level map: modules and their roles, startup and composition entry points, cross-module collaborations, permitted dependency directions | `docs/architecture.md` |
| A subsystem's internal state owners, interfaces, dependencies and runtime flows, regardless of length | `docs/architecture/<subsystem>.md` |
| One Feature's implementation design and local decisions with their rationale | `docs/features/F0XX-design.md` |
| Rationale of a technical choice meeting the [ADR conditions](#architecture-decision-records) | `docs/architecture/adr-NNNN-<slug>.md` |
| An adopted technical decision without a Feature that does not meet the ADR conditions | The **Standalone technical decisions** section of an architecture document, under [Standalone technical decisions](#standalone-technical-decisions) |
| Navigation to these records | Feature notes and current Progress links |

- New projects start with a purpose and pending-state notice in `docs/architecture.md`. Fill it from the actual structure within authorized work; do not invent future modules.
- The same locations apply from initial development through expansion. There is no separate arrangement for small projects.
- Name each subsystem with a stable lowercase hyphenated name in the overview, link its document there, and reuse that name for the same subsystem.
- Keep project-level summaries in the overview and internal contracts in the subsystem file.
- Link the owning record instead of copying it. Later changes update the current map without rewriting a completed Feature as though it had always used the new design.

Map templates are [architecture-overview.md.tmpl](templates/architecture-overview.md.tmpl) and [architecture-subsystem.md.tmpl](templates/architecture-subsystem.md.tmpl).

When a responsibility map is not enough, the subsystem document may trace key runtime flows: the trigger, participating modules, state owner and result, with the Godot boundary, lifecycle and failure handling that matter. Link actual implementation or verification evidence, and label proposed or unverified behavior. No fixed number of flows or diagrams is required.

## Game responsibilities and collaboration

Use the logic and presentation model in `docs/game-organization.md` to explain actual responsibilities within business modules. Link the relevant GDD rules and experience goals, UI and game-presentation specifications to implementation entry points. The map describes the current technical connections; it does not copy their requirements or require separate logic and presentation directories.

For a cross-layer flow whose boundary needs explanation, identify the request, authoritative state owner, accepted/rejected result and presentation consumer. Distinguish reading current state from reacting to a one-time event, and view-local state from business state. Explain who connects participants and cancels pending work when that lifetime affects correctness. For example, a shop UI requests a purchase, the purchase operation coordinates wallet and inventory owners, and the UI uses the result for feedback; reopening the UI reads current state without implying another purchase.

Gameplay orchestration, presentation sequencing and scene assembly each have their actual owner; no additional control layer is required. Engine-dependent gameplay and animation timing may take part under an explicit validity and cancellation contract. Keep implementation choices that project rules allow. Document these relationships in the project or subsystem document that matches their scope; notes only link that explanation.

## Navigation

When using a map, give each module its main location and useful reading entry points: key scenes, scripts or resources, and relevant verification entries when helpful. Link an existing module README when it already provides that navigation. Keep this selective; do not inventory every file, function or test.

At project level, point to the actual startup/composition boundary and persistent state owners when these help readers understand how modules fit together. Describe the structure that exists, without inventing a bootstrap or Autoload layer. In subsystem documents, keep basic navigation available even when runtime-flow detail is unnecessary.

Distinguish actual direct collaborators and the purpose of their interaction from permitted dependency directions. When using a diagram, identify what its arrows mean: code dependency, scene composition, inheritance or runtime messages, for example. Keep different relationships distinguishable; no fixed set of diagrams is required.

## Maintaining a map

Maps describe current boundaries, responsibility owners and allowed dependencies, and link decision rationale where it is recorded. Update a map when its recorded responsibilities, ownership, collaborations, dependency constraints, paths or entry points change, including moves or renames that leave contracts intact. Implementation changes that do not affect mapped information need no map update or new diagram.

Within the changed scope, check that links and reading entries still lead to the intended content, reconcile the overview and subsystem summaries, and keep affected diagrams consistent with the text. Stage 0 reads the relevant map if there is one, and review checks a changed boundary against it. A stale or missing optional map is a question for clarification or review, not a Gate failure.

## Designing a module boundary

Apply the design defaults in `docs/project-rules.md` when adding a module, changing a public interface or moving responsibility. Assess the actual callers and confirmed behavior, whether or not an architecture map exists. An ordinary local function does not need a separate design exercise or artifact.

Read an interface as everything a caller must know: inputs and observable results, required configuration and call order, failure behavior, state ownership and lifetimes. For a Godot scene, this can include public signals, exported dependencies and when a pending operation becomes invalid. Identify which knowledge belongs to the caller and which repeated coordination the module could own. Hiding unrelated responsibilities behind one entry point does not make them cohesive.

Compare a direct implementation and existing responsibilities before adding an abstraction. Where materially different designs have real tradeoffs, compare their caller obligations, change locality and verification cost. Use only the alternatives needed to decide; this does not require a fixed number of designs, parallel reviewers or a new approval step.

| Illustrative Godot case | Design judgment |
| --- | --- |
| Several purchase buttons repeat price, balance and capacity checks, then coordinate payment and item delivery | Consider one purchase operation that coordinates the existing state owners through their APIs. Callers receive a defined result; failure effects and change notifications remain part of the contract. Price calculation, wallet and inventory can keep their separate responsibilities. |
| A short scene coordinator owns subscriptions and invalidates pending work when the scene exits | Keep or deliberately relocate that ownership. Removing the node is useful only if callers do not inherit scattered cleanup and lifetime obligations. |

These examples illustrate the judgment; they are not required game systems or patterns. Record the resulting choices where the [table above](#where-architecture-and-decisions-are-recorded) assigns them.

## Assessing a proposed refactor

Start from an observed maintenance difficulty or the next agreed change and apply the caller assessment above to the existing and proposed boundaries.

As a thought experiment, remove the layer and call its dependencies directly. If behavior stays intact and coordination becomes simpler, the layer may be an unnecessary forwarder. If its removal spreads validation, ordering, error handling or lifecycle knowledge across callers, that responsibility still needs a coherent home. Keep or relocate it instead of dissolving it into callers. Fewer files or shorter signatures alone do not establish an improvement.

Preserve useful separation between independent game rules and Godot scene orchestration. Check Node, Resource, Signal and SceneTree ownership and lifetimes before merging boundaries. A short scene owner that cancels pending work or manages signal subscriptions may carry a meaningful contract. Introduce a new substitution point only for a concrete runtime or testing need; neither hypothetical future platforms nor a fixed number of implementations determines its value.

Verify the behavior callers depend on under [08 · Test traceability and evidence](08-test-traceability-and-evidence.md): L1 for independent rules, L2 for real collaboration and relevant engine behavior. Keep Godot semantics real when they are what the test checks. Merging modules or adding a boundary test does not by itself justify deleting tests; keep needed scenarios and follow the Registry rules when retiring redundant cases.

## Architecture Decision Records

Record a technical choice in an ADR when it affects several Features or modules, or constrains later project-wide work, and all three conditions hold:

- Reversing the choice would require meaningful migration or rework.
- A future maintainer could reasonably question the choice because its reasons cannot be recovered from the code alone.
- Real alternatives were considered, with concrete reasons for accepting some costs and rejecting others.

Read the relevant Feature design, architecture and current ADRs first, and reuse the ADR that already covers the same decision. A qualifying decision belongs in an ADR even when an explanation was written elsewhere earlier.

- Decisions outside these conditions, including brief local choices, go in the Feature design. Work without a Feature uses [Standalone technical decisions](#standalone-technical-decisions).
- Repeated discussion is a signal to check whether the rationale is missing or hard to find; it does not change where the rationale belongs.
- Investigation findings stay evidence until a decision is adopted. A standalone investigation does not need an artificial Feature.
- Do not invent alternatives to satisfy the conditions.
- When a qualifying decision's current rationale sits in a Feature design or architecture document, move it into the ADR within authorization and replace it with a link. Keep referenced anchors and earlier records as history instead of creating a second current rationale.

Use [architecture-decision-record.md.tmpl](templates/architecture-decision-record.md.tmpl) at `docs/architecture/adr-NNNN-<slug>.md`. Choose the next unused number from the current filenames. The template is available from project creation, but no placeholder ADR or architecture map is required before a real decision exists.

During Feature work:

- Stage 1 checks the scope and the three conditions to decide where the decision goes, and finds any current ADR.
- Stage 2 records a decision confirmed before implementation.
- Stage 3 records decisions discovered during implementation, before dependent work and final verification.

Authorized standalone technical design or investigation records a qualifying decision in an ADR without creating a Feature. Apply these same conditions regardless of game size or perceived complexity; do not create empty ADRs for decisions that have not arisen.

Likely candidates include a costly save-identity/migration model, cross-scene state ownership or a simulation strategy with real accuracy/performance tradeoffs. A local function, ordinary node layout or the already fixed Godot stack does not require a record by itself. Apply all three conditions rather than the topic name alone. GDD keeps game-design requirements, Product keeps delivery boundaries, and ADR keeps technical rationale. If feasibility changes game design or delivery scope, or conflicts with a project rule, resolve that through its owning workflow instead of using ADR acceptance as an override.

Keep the problem and constraints, reasonable alternatives, decision, benefits and accepted costs, evidence links and useful revisit conditions. Detailed interfaces, protocols and test cases stay in the implementation, the subsystem documentation or the Feature and test records. There is no ADR count, line limit, periodic review date or additional completion Gate.

Use these states as ordinary Markdown, without a separate status registry:

- `Proposed`: a candidate choice; the record does not grant implementation approval.
- `Accepted`: the choice is confirmed within the task's authorization. Reuse an explicit decision already made; do not add another approval round. Acceptance records a decision, not proof that an API or runtime behavior was tested. Keep assumptions and any necessary verification visible.
- `Superseded by <ADR link>`: an accepted choice has been replaced. Preserve its rationale, link the replacement, and link back from the new ADR. Clarifying wording does not require a new record; changing the decision does.

The architecture map links relevant ADRs without copying their rationale or status, and the Feature design links the ADRs that apply to it. Stage 0 reads relevant ADRs even when no map exists, and review checks consistency with accepted decisions. Without a qualifying decision, no ADR is needed; missing rationale for a qualifying decision is a documentation gap to resolve within the current task's scope and authorization.

## Standalone technical decisions

For work without a Feature, a technical decision meeting the ADR conditions still belongs in an ADR. When an adopted decision does not meet those conditions and saving it is authorized, use the **Standalone technical decisions** section in the architecture document determined below. This section records the decision and rationale, distinct from the map's current implemented facts; explain its scope, basis and unverified or unimplemented parts. Discussion-only work stays in the conversation.

| Decision scope | Document |
| --- | --- |
| Exactly one identified subsystem | `docs/architecture/<subsystem>.md` |
| Cross-subsystem or project-level scope, including decisions before subsystem boundaries are established | `docs/architecture.md` |

Write the section title in the configured document language and keep its references working. Do not invent a Feature, subsystem, separate guide or ADR just to have a file.

- Once the decision becomes part of a Feature's approved implementation design, move the current rationale into its `F0XX-design.md` at the authorized design-saving step and replace the architecture text with a link. Creating a pending Feature alone does not authorize that write.
- Current structure stays in the map, and referenced history stays as it is.
- If the decision later meets the ADR conditions, move its current rationale to an ADR under the rule above.

## Extracted reference facts

Automation can extract only supported facts: a Resource dependency, an explicit path reference, or a type reference actually recognized by its parser. Record the extractor/version, source snapshot, scanned scope and known blind spots. Dynamic loading, runtime signal connections and ownership generally cannot be inferred from text alone. Keep generated facts in a report directory such as `reports/maintenance/architecture-facts/<run>/`, under the [report lifecycle](09-records-reports-and-handoff.md#reports-and-cleanup).

Generated output is never the sole architectural authority. A diagram of observed references cannot authorize dependencies or establish causal behavior. Use a diagram only when it helps explain actual responsibilities or dependencies.
