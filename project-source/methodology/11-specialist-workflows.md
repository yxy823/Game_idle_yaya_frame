# 11 · Specialist work and sources

This specification owns professional document authority, source discovery and
handoffs. [Task routing](00-overview.md#canonical-task-routing) owns entry selection;
the existing planning and execution workflows own delivery. A specialist Skill
can be called alone or within an authorized task without creating another lifecycle.

## Ownership and decisions

| Concern | Owner / usual authoritative location |
| --- | --- |
| Player behavior, rules, triggers and Product scope | `product-author`: `docs/product.md`, `docs/product/*.md` |
| Shared visual direction, including choosing an art style | `design-art-direction`: `docs/art/art-bible.md` |
| Shared sound direction and feedback hierarchy | `design-audio-direction`: `docs/audio/sound-bible.md` |
| Interface layout, states and interaction presentation | `design-ui-spec`: `docs/ui/<interface>-design.md` |
| Visual asset specifications | `design-visual-asset-spec`: relevant entries in `docs/resource-requirements/<scope>.md` |
| SFX and music specifications | `design-audio-asset-spec`: relevant entries in the same resource list |
| Localization conventions and glossary | `content-localization`: `docs/localization/localization-spec.md`; runtime translations remain in project resources |

Reuse a suitable existing owning file; these paths are defaults, not a command
to create every document. Create only useful current-scope content, in
`document_language`. A complex asset specification may use a separately named
file linked by resource ID. Keep one authoritative body, with links from Product,
Feature design or AC; do not duplicate whole specifications in Product.

Each owner may write its own documents within existing concrete authorization.
File ownership does not authorize adopting an undecided requirement. Distinguish
confirmed requirements, proposals and measured observations in the relevant text.
An existing file or Git commit alone is not evidence of approval. Reuse the user's
decisions; ask only for missing material choices. A narrow specialist edit does not
authorize changing Product, another specialist's contract or the task's scope.

| Change | Route |
| --- | --- |
| Confirmed professional requirement changes | Owning Skill updates its source; assess current and planned work through `feature-sync`. Changed player behavior also goes through `product-author`. |
| Implementation violates a confirmed professional requirement | Repair within the unfinished owning Feature, or use `engineering-change-plan` for an independent bug. Cite the professional source even when Product does not repeat it. |
| A proposed improvement is not yet adopted | Return the proposal; do not use it as an AC, defect or implementation mandate. |
| Sources conflict or lack a material decision | Resolve with the appropriate owner/user before dependent work; report both sources instead of silently picking one. |

For standalone authorized specification work, validate affected links and commit
the complete task-owned source change under the project Git rules before a
Git-based synchronization. Within an existing Feature, use its documentation
checkpoint and commit; a Skill handoff does not create a new clean-worktree gate.
If a substantive source change needs synchronization, retain its committed-source
prerequisite. A no-commit instruction may leave that prerequisite unmet; report it.
When synchronization discovers stale links in its source inputs, the owning entry
repairs and commits them within the approved scope before any plan write, then
returns to the same synchronization for refreshed source analysis. Plan-record
references follow the synchronization Skill's own update and commit steps; a
Markdown filename alone does not determine which responsibility applies.

## Discover and map sources

The Feature `source` remains one precise primary source string: Product when it
owns the work, the professional source for independently owned professional work,
or `infrastructure` for technical work without a single documentary source.
Do not add a sources array or encode a list into this string. Record applicable
secondary requirements as links in AC or the existing optional Feature design.
Notes may provide navigation, but cannot be the only record of a binding constraint.

At planning or synchronization, follow the primary source's actual references to
UI, resource, art, audio and localization specifications. Each shared specification
states its applicability in ordinary prose, such as all inventory icons or all
interactive feedback; it need not list every Feature ID. Read the lightweight
Feature index and module dependencies to identify all already planned consumers,
then inspect their details. Shared scope can apply even where a link is missing;
repair missing references within scope instead of treating missing links as an
exemption. Check renames, removed sections and stale links. Do not load every
professional document for a task that cannot be affected.

Translate each applicable requirement into a concrete, task-sized AC or a linked
design constraint with a verification obligation. For example, name the icon states,
target display size and recognition check instead of only saying “fits Art Bible”.
Keep executable test mappings in Feature JSON/Registry; keep additional performance,
duration, display or listening checks in the existing verification plan/design.
No new schema field, dependency registry or duplicate acceptance ledger is needed.

Synchronization includes actual professional source paths and resource lists in
Git differences and current-source comparison. A previous `synced_at_commit` is
not proof that a newly admitted source category was previously considered, even
if its files predate that commit. Compare the historical sources and affected plan
at the anchor when needed. If coverage cannot be established, use the existing
current-document alignment route for already planned scope and report the unknown
historical coverage. Do not invent an old baseline, add per-source receipts, or
silently advance the anchor. Later Products remain unplanned until their turn;
completed Feature history remains intact and changed completed work gets follow-up.

## Design, production, integration and review

Design chooses the direction; specifications describe a concrete deliverable;
production supplies or processes assets; `content-asset-integration` imports and connects
available assets. Each can be requested independently. Reuse existing suitable
assets before requesting new ones; a reference image or audio example is not a
newly produced deliverable. Missing representative assets leave the corresponding
visual/listening checks unverified.

Visual-art production, music production and sound-effect production are reserved
capabilities only. Each will cover reuse and concrete generation/processing, but
their methods and tool choices are deferred. They have no discoverable production
Skill or agent in this version. Record a preparation gap and its specification;
do not invoke a nonexistent Skill or silently promise asset generation in a Bible.

`content-asset-integration`, `content-localization` and `diagnostics-instrumentation` may change resources, code or
configuration only inside an authorized Feature or scoped experiment. Return to
that task for verification, applicable human acceptance and completion. Standalone
specification or investigation work need not initialize Product or invent a Feature.
Diagnostic findings do not themselves authorize repairs or new requirements.

Formal reviews use separate review Skills and an independent instance under
[independent review](12-independent-review.md). No creation/measurement Skill
certifies its own output as independently reviewed. Human experience acceptance
remains the user's decision. Playtest analysis and release work are outside this scope.

## Finalization and evidence

For resource comparison or feedback timing, the project may use the optional
[asset workbench example](../examples/asset_workbench/README.md). It provides
single-asset inspection/audition and one icon-pulse event with A/B trials and an
explicit save target. Reuse an existing project's presentation/data/audio APIs
instead of forcing its objects into the example Cue. Example assets are not
approved production content. This is a development tool, not an asset-production
Skill, automatic analysis step, new Stage, or evidence of human acceptance.

Put binding professional requirements in ordinary, explicitly named source files.
Do not put their sole body in `README.md`, `docs/knowledge/`, `docs/research/` or `reports/`, which
can be excluded from the existing completion fingerprint. Finalize applicable
specifications and resource-list status/location updates at Stage 3's documentation
checkpoint, before final verification.

The existing fingerprint is global, not limited to a Feature's linked sources.
Even editorial changes to a professional Markdown file may invalidate current
completion evidence. Apply the existing revalidation rules; an editorial-only
synchronization decision does not exempt the fingerprint. Historical completed
Features are not automatically reopened. Keep transient findings in conversation,
or original evidence/review reports under [artifact lifecycle](09-artifact-lifecycle.md).
No fine-grained fingerprints or second evidence system are introduced.

Performance and long-run measurements identify the actual version/dirty changes,
environment, scenario, workload, method, duration, termination reason and gaps.
Separate temporary diagnostic instrumentation from the delivered version and
re-measure when the change affects the claim. An interrupted soak run proves only
its observed duration and scenarios; lack of a failure is not general proof.
The gdUnit evidence adapter remains for actual gdUnit results only. Supplemental
evidence satisfies its own planned obligations, not an invented gdUnit pass or an
excuse to skip required tests. The owning task and reviewer assess its sufficiency.
