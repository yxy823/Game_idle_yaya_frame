# Optional architecture overview

An Architecture Overview is a lightweight navigation and ownership aid, not a
new approval Stage or a substitute for Product, Coding Rules and approved
decisions. Use it when module boundaries are difficult to recover from code.
It is optional for small projects.

`docs/architecture.md` owns the project-level map: modules, responsibilities,
state owners, major allowed dependency directions and the reasons for those
boundaries. Use `docs/architecture/<subsystem>.md` for a complex subsystem;
link it from the overview instead of expanding the main file indefinitely.
Templates live in `methodology/templates/architecture-*.md.tmpl`.

Humans maintain why a boundary exists, who owns a responsibility, which
dependencies are allowed and why an exception is approved. Implementation
work updates a map only when those contracts change. Stage 0 reads the relevant
map if present; review checks a changed boundary against it. A stale or missing
optional map is a clarification/review concern, not a fabricated Gate failure.

Automation can extract only supported facts: a Resource dependency, an explicit
path reference, or a type reference actually recognized by its parser. Record
the extractor/version, source snapshot, scanned scope and known blind spots.
Dynamic loading, runtime signal connections and ownership generally cannot be
inferred from text alone. Keep generated facts in an owned artifact directory
such as `reports/architecture-facts/<run>/`, with lifecycle records.

Generated output is never the sole architectural authority. A diagram of
observed references cannot authorize dependencies or establish causal behavior.
Use a diagram only when it helps explain actual responsibilities or dependencies.
