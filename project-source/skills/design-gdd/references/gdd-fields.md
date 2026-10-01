# GDD design coverage

Use this reference when drafting a full GDD, checking coverage or extending an existing design. These are design questions, not an interview checklist or a file-per-row template. The fixed **Design scope and boundaries** subdocument follows `methodology/01-product-doc-structure.md`; other topics may share a document, and a local revision needs only its affected topics and dependencies.

## Match depth to the requested result

- A concept draft should make the game, intended experience and current choices understandable. Preserve assumptions and explain gaps; do not invent players, rules, dates, content counts or test results to fill a section.
- A requested full GDD covers the applicable shared topics and the systems the game actually adopts. A populated directory does not establish completeness. An adopted system with missing rules is unfinished, not inapplicable.
- A local change preserves sufficient context and updates its consequences without recreating the whole GDD.
- Before dependent planning or implementation, clarify rules, states, feedback and observable results enough to avoid consequentially different implementations. Identify any remaining gap that blocks that use. Future unrelated design may remain open.

The entry briefly identifies the game, concept, covered scope and reading path. Include adoption or evidence limits where they affect how the document should be used. Follow an existing useful version convention; do not introduce a version scheme, ownership fields or duplicated execution status.

## Shared design topics

| Topic | Questions the design should answer |
| --- | --- |
| Concept and player context | What is the player doing and why might it appeal? What is the theme or player role, intended audience and play situation? Which platform, input and session expectations constrain the design? Unknown positioning remains a hypothesis. |
| Intended experience and design principles | Which specific moments, motivations or feelings matter? Which principles guide choices and exclusions? Explain their consequence for rules or scope rather than asserting that the game should be fun. |
| Core loop and representative play | What are the initial situation, player goal, visible information, recurring actions or waits, feedback and progress? How does play continue, finish, fail or recover where applicable? What happens when pausing, leaving or returning? Label a written play sequence as reasoning, not a playtest. |
| Mechanics and system relationships | What triggers a system, what inputs and state does it use, and what changes or outputs result? What limits and exceptions matter? How do systems affect each other? Record useful existing specifications with units, source and status. |
| Content, progression and pacing | What kinds and amount of content are in scope? What activities, teaching, challenge, unlocks or rewards shape each relevant stage? How do player time and attention change? Explain a session's progression even when no long-term growth exists; time targets are not measurements. |
| Interaction and understanding | What view, controls, information, navigation and state feedback support the actions? What must a first-time or returning player understand? Address relevant input, reading, color, sound and reaction constraints. Detailed interface specifications may link their professional owner. |
| Visual and audio intent | What mood and presentation make important objects, actions and states recognizable? What role does sound play? Name the useful properties of references. This is design intent; actual production and detailed professional specifications have separate owners. |
| Design scope and boundaries | What overall game scope and exclusions are adopted, and what is deferred only for a named version? Which actual resource, platform and design constraints apply? Keep this body in the fixed scope subdocument; local mechanism/presentation limits, delivery ordering and technical implementation detail remain with their own sources. |
| Risks, unknowns and validation | Which assumptions could change the design, what consequence would be wrong, and what work depends on resolving them? Rule checks identify initial conditions, action and expected result; experience checks identify observations that would support or challenge a hypothesis. Actual evidence states the tested conditions and limits. |
| Decisions and sources | Which consequential choices have been adopted, and on what basis? Where do conflicting claims or uncertain terms remain? Keep the necessary reason, source and uncertainty near the owning rule; reuse existing terminology and resumption records instead of duplicating them. |

## Conditional systems

Use a row only when the system is adopted, being compared or materially relevant to the requested design. Genre labels do not require mechanics.

| System | Relevant additional questions |
| --- | --- |
| Resources, economy, crafting or trade | What creates, consumes or converts each resource? What limits storage or access, and which investments compete? Distinguish balances, rates, cumulative gains and unlock progress. Formula derivation and related parameter sets use `design-balance`. |
| Growth, upgrades or builds | What grows, at what cost and benefit? What are the prerequisites, unlocks, exclusions and bottlenecks? How do upgrades change play and the role of earlier content? Model dependent curves only as deeply as the current decision requires. |
| Incremental play, automation or waiting | Which actions belong to the player and which to automation? How is automation obtained and configured, what work does it replace and what decisions remain? If offline progress is adopted, define continuing or suspended processes, time/capacity limits and return feedback. If reset/prestige is adopted, define its reward basis, cleared and retained state and the next run's change. Neither is a default requirement. |
| Combat, enemies or abilities | What are the combat objective, action timing, targeting, hit/defense relationship and state effects? How can players anticipate and respond? What happens after defeat? Clarify the roles of units, equipment or abilities before deriving their values. |
| Levels, puzzles, exploration or generation | What are the goal, reachability constraints, challenge, solutions, teaching sequence and recovery points? For generation, what boundaries and fairness must the player perceive, and how are unsolvable outcomes handled? |
| Narrative, characters or world | What are the world premise, motivations, relationships and conflict? How are story and player actions connected, and what consequences do choices have? Expand dialogue or branching only when relevant. |
| Multiplayer, cooperation or competition, when explicitly in the game scope | What are the player roles, shared or opposing goals, state ownership and information visibility? What happens when players join, leave or disconnect, and who receives a result? Describe player-facing rules; this does not introduce a development-team workflow or network architecture. |
| Persistent progress | What is retained, when, and what can be reversed? How do failure, reset, exit and return affect saved progress? State player-visible recovery behavior when relevant; technical storage design belongs elsewhere. |
| Monetization or ongoing content affecting play | What is acquired, how, and with which gameplay or fairness consequences? Define relevant reward triggers, content cycles and progress carry-over only when adopted. Do not invent revenue forecasts. |
| Language, device or platform constraints affecting experience | What text, voice, controls, readability or display constraints apply? Which interruptions or performance limits have visible consequences? Reference the appropriate professional requirements without prescribing an unrelated technical architecture. |

## Check the design as a player sequence

For the changed scope, follow why a player enters, what they see, what they can choose or do, how the rules respond, how progress occurs and how play ends or resumes. Then check that the adopted systems, presentation needs, scope and unresolved questions have an owning location. This catches missing relationships without requiring one document per topic or a repeated full-game audit.
