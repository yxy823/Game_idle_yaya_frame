# Optional architecture overview and decisions

An Architecture Overview is a lightweight navigation and ownership aid, not a
new approval Stage or a substitute for Product, Project Rules and approved
decisions. Use it when module boundaries are difficult to recover from code.
It is optional for small projects.

`docs/architecture.md` owns the project-level map: modules, responsibilities,
state owners, major allowed dependency directions and the reasons for those
boundaries. Use `docs/architecture/<subsystem>.md` for a complex subsystem;
link it from the overview instead of expanding the main file indefinitely.
Map templates are [architecture-overview.md.tmpl](templates/architecture-overview.md.tmpl)
and [architecture-subsystem.md.tmpl](templates/architecture-subsystem.md.tmpl).

When a responsibility map is insufficient, the relevant subsystem document may
trace key runtime flows: trigger, participating modules, state owner and result,
with the Godot boundary, lifecycle and failure handling that matter. Link actual
implementation or verification evidence and label proposed/unverified behavior.
Keep this detail in the subsystem document; no fixed number of flows or diagrams
is required.

Feature design in `docs/features/F0XX-design.md` explains one change. This map and its subsystem documents describe the current system across Features. Keep shared runtime structure here, local implementation reasoning in the Feature design and important choice rationale in ADRs; link the owners instead of copying them. Later changes update the current map without rewriting a completed Feature as though it had always used the new design.

Humans maintain why a boundary exists, who owns a responsibility, which
dependencies are allowed and why an exception is approved. Implementation
work updates a map only when those contracts change. Stage 0 reads the relevant
map if present; review checks a changed boundary against it. A stale or missing
optional map is a clarification/review concern, not a fabricated Gate failure.

## Assessing a proposed refactor

Start from an observed maintenance difficulty or the next agreed change. Read
what callers must know: required call order, validation, errors, state ownership
and lifetimes all contribute to interface complexity, even with few methods.

As a thought experiment, remove the layer and call its dependencies directly.
If behavior stays intact and coordination becomes simpler, the layer may be an
unnecessary forwarder. If its removal spreads validation, ordering, error handling
or lifecycle knowledge across callers, that responsibility still needs a coherent
home. Keep or relocate it instead of dissolving it into callers. Fewer files or
shorter signatures alone do not establish an improvement.

Preserve useful separation between independent game rules and Godot scene
orchestration. Check Node, Resource, Signal and SceneTree ownership and lifetimes
before merging boundaries. A short scene owner that cancels pending work or
manages signal subscriptions may carry a meaningful contract. Introduce a new
substitution point only for a concrete runtime or testing need; neither hypothetical
future platforms nor a fixed number of implementations determines its value.

Verify the behavior callers depend on using the existing
[testing strategy](08-testing-strategy.md): L1 for independent rules, L2 for real
collaboration and relevant engine behavior. Keep Godot semantics real when they
are the subject of the test. Merging modules or adding a boundary test does not
by itself justify deleting existing tests; retain needed scenarios and follow
the existing test and registry maintenance rules when retiring redundant cases.

## Architecture Decision Records

Consider an optional ADR for an important technical choice that affects multiple
Features/modules or constrains later work. First read related Feature notes,
architecture documents and existing ADRs. Reuse and link an explanation that
already answers the question instead of recording the same rationale again.

Create a separate ADR only when all three conditions hold:

- Reversing the choice would require meaningful migration or rework.
- A future maintainer could reasonably question the choice because its reasons
  cannot be recovered from the code alone.
- Real alternatives were considered, with concrete reasons for accepting some
  costs and rejecting others.

Repeated discussion is a signal to check whether the rationale is missing or
hard to find; it does not by itself justify another record. Local implementation
choices stay in Feature notes or its detailed design. Easily reversible changes and choices with no
real alternative need no ADR; keep any useful constraint in its existing owning
document. Do not invent alternatives or migrate historical notes to fill a record.

Use [architecture-decision-record.md.tmpl](templates/architecture-decision-record.md.tmpl)
at `docs/architecture/adr-NNNN-<slug>.md`. Choose the next unused number by reading
existing filenames. The template is available from project creation, but no
placeholder ADR or architecture map is required before a real decision exists.

During Feature work, Stage 1 assesses whether the current choices meet this threshold and whether an existing explanation suffices. Stage 2 records a confirmed pre-implementation decision; Stage 3 records decisions discovered during implementation before dependent work and final verification. Authorized standalone technical design/investigation may produce an ADR without creating a Feature. This is an Agent judgment at an existing planning point, not an automatic output for every Feature or Stage.

Likely candidates include a costly save-identity/migration model, cross-scene state ownership or a simulation strategy with real accuracy/performance tradeoffs. A local function, ordinary node layout or the already fixed Godot stack does not require a record by itself. Apply all three conditions rather than the topic name alone. Product keeps the required behavior; ADR keeps technical rationale. If feasibility changes Product intent or conflicts with a project rule, resolve that through its owning workflow instead of using ADR acceptance as an override.

Keep the problem and constraints, reasonable alternatives, decision, benefits
and accepted costs, evidence links and useful revisit conditions. Detailed
interfaces, protocols and test cases remain in their implementation, subsystem
documentation or existing Feature/test records. There is no ADR count, line
limit, periodic review date or additional completion Gate.

Use these states as ordinary Markdown, without a separate status registry:

- `Proposed`: a candidate choice; the record does not grant implementation approval.
- `Accepted`: the choice is confirmed within the task's existing authorization.
  Reuse an explicit decision already made; do not add another approval round.
  Acceptance records a decision, not proof that an API or runtime behavior was
  tested. Keep assumptions and any necessary verification visible.
- `Superseded by <ADR link>`: an accepted choice has been replaced. Preserve its
  rationale, link the replacement, and link back from the new ADR. Clarifying
  wording does not require a new record; changing the decision does.

The ADR owns the cross-Feature rationale. The architecture map owns the current
structure and links relevant ADRs without duplicating their rationale or status.
Feature notes keep local decisions and link applicable ADRs; Progress keeps only
current handoff links. Stage 0 reads relevant ADRs even when no map exists, and
the existing review checks consistency with applicable accepted decisions. A
missing optional ADR is not a failure; an actual conflicting or undecided choice
is resolved within the current task's scope and authorization.

## Extracted reference facts

Automation can extract only supported facts: a Resource dependency, an explicit
path reference, or a type reference actually recognized by its parser. Record
the extractor/version, source snapshot, scanned scope and known blind spots.
Dynamic loading, runtime signal connections and ownership generally cannot be
inferred from text alone. Keep generated facts in an owned artifact directory
such as `reports/maintenance/architecture-facts/<run>/`, under the
[report lifecycle](09-artifact-lifecycle.md#reports-and-cleanup).

Generated output is never the sole architectural authority. A diagram of
observed references cannot authorize dependencies or establish causal behavior.
Use a diagram only when it helps explain actual responsibilities or dependencies.
