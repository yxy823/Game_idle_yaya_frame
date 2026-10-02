# GDD review concerns

Use this reference for a requested review of a GDD draft, selected topic or whole design. Review the supplied scope and its necessary dependencies; Product and Feature documents need not exist. A formal independent review follows `methodology/12-independent-review.md`, including read-only sources, evidence limits and return to the author for repairs.

## Establish what the document must support

Identify the intended next use: exploring a concept, selecting a design direction, handing off rules for implementation or checking an existing design. Start with the game goal, core loop, adopted scope and exclusions. Read layered designs from their actual entry and follow relevant links, including relevant entries in `docs/gdd/open-questions.md` under **Open design questions** in methodology 01. Use them to judge missing decisions and evidence, not to assume that every listed question blocks this review. A single-file GDD remains valid and needs no migration for review. Report the actual documents read and inaccessible references.

Judge coverage by content, not matching chapter names. A topic may span several files or share a chapter with another topic. Say “not found in the inspected material” when coverage is partial; do not infer that the whole project lacks the design.

## Examine relevant design concerns

| Concern | Questions that can expose a consequential gap |
| --- | --- |
| Concept and player | Are the player role, appeal, audience and play context clear enough for the current decision? Do platform, input, session duration and intended scale fit? |
| Experience and design pillars | Do intended experiences connect to concrete player moments and guide tradeoffs? Are experience claims distinguished from hypotheses needing play evidence? |
| Core loop | Do initial state, action, feedback, progress and continuation or ending form a coherent sequence? Can a representative play segment follow the stated rules, including relevant recovery, pause, exit and return behavior? |
| Mechanics and boundaries | Are triggers, inputs, states, outcomes, exceptions and cross-system dependencies sufficient for the intended next step? Could two reasonable readers implement materially different behavior? |
| Content and progression | Do content scale, teaching, challenge, unlocks and ending support the experience goals? Are target playtime and attention costs still visibly unverified where evidence is absent? |
| Interaction and presentation | Are controls, camera, UI, state feedback and applicable accessibility needs clear? Can the planned art and audio convey important actions and outcomes? Detailed professional specifications retain their own owners. |
| Scope and constraints | Are current version scope, necessary content, deferred work, exclusions and resource/platform constraints consistent? A GDD version boundary is distinct from a Product delivery unit. |
| Numeric description | Are units, formulas, bounds, parameter sources, assumptions and evidence status interpretable? Check obvious contradictions or calculation errors; use `review-balance` for formal balance diagnosis and `design-balance` for authoring or derivation. |
| Decisions and consistency | Do terminology, rules, values and decision status agree across the inspected sources? Do conflicting statements have an actual adoption basis? |
| Document organization | Can the entry reach the needed rules, and is the owning location clear? Are links valid, or have duplicated descriptions drifted? |
| Risk and verification | Are material unknowns and their consequences visible? Can important rules be checked, and are experience validation and implementation evidence distinguished? |

Inspect conditional systems only when adopted: economy needs sources, sinks and conversions; progression and automation need unlocks and changes in participation; narrative needs player action and consequences; levels need objectives, reachability and challenges; persistence needs retained state and recovery. Do not require offline gains, prestige or another genre convention merely because similar games use it.

## Match findings to the design stage

Distinguish not applicable, undesigned, proposed and awaiting evidence. A concept draft may leave parameters and experience hypotheses open. An implementation handoff must resolve rule gaps that would produce materially different behavior. Marking a needed rule “TBD” does not remove its blocking effect; conversely, an explicit candidate is not a defect merely because it is unvalidated. User adoption is not proof of fun, balance or implementation success.

Test suspicious rules with a concrete normal-use or boundary scenario, reading the general rule, exceptions and trigger together. If a claimed failure depends on another undecided rule, report that missing prerequisite rather than asserting a conflict that has not been established. When documents disagree, cite both locations and their decision status; recency, length or parent/child position alone does not establish authority.

## Return actionable findings

Use the parent Skill's finding contract and the formal review contract when applicable. Explain each issue's source, evidence, concrete effect, smallest useful correction and any decision still required. Rank by actual consequence: a core contradiction that prevents a coherent next step takes precedence over a local improvement or navigation issue. Keep suggestions separate from adopted design and do not impose a fixed finding count or a new score.

Conclude whether the inspected design supports its intended next use, the most consequential remaining gaps and which judgments require further source material, calculation or actual play. A document review cannot establish that the game runs, feels right or is balanced. Return repairs to `design-gdd`, scoped numeric authoring to `design-balance`, and delivery changes to `product-author`; the reviewer does not rewrite the GDD.
