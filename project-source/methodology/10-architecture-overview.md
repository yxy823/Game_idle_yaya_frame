# Optional architecture overview and decisions

An Architecture Overview is a lightweight navigation and ownership aid, not a
new approval Stage or a substitute for Product, Coding Rules and approved
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
the existing test and catalog maintenance rules when retiring redundant cases.

## Architecture Decision Records

Use an optional ADR for one important technical choice whose tradeoffs affect
multiple Features/modules, constrain the project over time, or are costly to
reverse. Check related decisions first. Local implementation choices stay in
Feature notes; ordinary changes and experiments need no ADR by default.

Use [architecture-decision-record.md.tmpl](templates/architecture-decision-record.md.tmpl)
at `docs/architecture/adr-NNNN-<slug>.md`. Choose the next unused number by reading
existing filenames. The template is available from project creation, but no
placeholder ADR or architecture map is required before a real decision exists.

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
such as `reports/architecture-facts/<run>/`, with lifecycle records.

Generated output is never the sole architectural authority. A diagram of
observed references cannot authorize dependencies or establish causal behavior.
Use a diagram only when it helps explain actual responsibilities or dependencies.
