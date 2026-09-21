# Guidance regression scenarios

Review actual advice against the canonical routing table, using small neutral
projects. These are language-model acceptance scenarios; Python state-reader
tests prove read-only data retrieval, not natural-language routing accuracy.

| User intent / state | Expected advice contract |
| --- | --- |
| New behavior, absent Product | Prompt the Product entry to elicit intent; no implementation authorization. |
| Continue current Feature, Stage 1 unapproved | Name the actual current work and pending approval; “continue” alone does not fill it. |
| Change accepted behavior | Product change followed by traced synchronization, rather than redefining the failure as a Bug. |
| A current Feature introduced a deterministic defect | Reproduce and repair in its existing approved scope, with regression evidence. |
| An independent completed behavior regressed | Engineering Bug with precise expected source, reproduction and regression obligation. |
| Preserve behavior while restructuring | Refactor route; inspect existing safety net and relevant boundaries. |
| Replace a build/testing tool | Maintenance with compatibility and affected validation; no new Product intent. |
| Framework Gate blocks business WIP | Isolated framework maintenance, reusable source/template/negative-test fix, preserve business work. |
| Audit only | Independent finding/report prompt under the review contract; no reviewed-source writes or automatic Bug. Honor static-only scope; otherwise necessary validation must isolate all side effects. |
| Human says a specific tested revision is accepted | Follow up on that exact scope/snapshot; do not accept another version or Feature. |
| Status query with old PASS and changed source | Report stored evidence and unverified freshness separately; no fake current PASS or unnecessary continuation prompt. |
| Simple bounded next action | Short prompt; avoid copying the entire workflow. |
| Cross-module migration with uncertain inputs | Investigation/planning prompt with evidence gaps and validation obligations. |
| Existing evidence is sufficient for a proposed approach | Continue the appropriate route; do not add a compulsory search, report or research Stage. |
| User wants external research before choosing an implementation | Point to External research and researcher with the question, concrete versions and project constraints; preserve investigation-only scope and identify requested report output. |
| anysearch is absent or unavailable | The researcher may use another available search method without another approval; do not claim the external Skill was bundled or install it automatically. |
| A search returns stable/latest or a different software version | Apply the role's concrete-version guidance; an explicit query version alone does not establish result applicability. |
| A research report recommends a different requirement or contains a damaged code extract | Recommendation is not adopted intent; preserve the source link and relevant warning, leaving restoration to actual code use. No automatic implementation or unused-code repair. |
| Emergency Bug | Shorter preparation is possible; required regression/affected checks, applicable human acceptance and traceable commit remain. |
| Stable lower ID depends on a newer pending ID | Use actual DAG eligibility, not numeric order or highest-ID selection. |
| Dirty tree contains another task | Report ownership conflict; do not stash, delete, overwrite or silently commit it. |
| Record a confirmed term without changing behavior | Point to `product-author` terminology maintenance and `docs/terminology.md`; no Product initialization, new Feature or second glossary. |
| A terminology edit changes intended behavior | Resolve the Product choice and affected planning; do not disguise it as editorial maintenance. |
| Continue a Feature with an existing long design | Read `F0XX-design.md` and source links; reuse approved constraints and return to the actual Stage. |
| A local implementation choice is proposed as a project rule | Require the rule-change self-check and any missing substantive authority; do not infer a global rule from local success. |
| User already approved a concrete rule change | Preserve that decision, require the self-check before writing, and route impact handling without asking again. |
| Ordinary Feature has no ADR | Missing optional ADR is normal; do not manufacture a record or block completion. |
| A costly cross-Feature choice has real alternatives | Apply the existing ADR threshold and destination; reuse a relevant record and do not override Product/project rules. |
| Stage 3 discovers settled terminology or needed design updates | Use the documentation checkpoint within current ownership/authorization; do not end authorized delivery at the supporting Skill return. |
| Final tests passed before a rule/design document changed | Explain current evidence freshness and the owning revalidation route; old PASS alone cannot authorize completion. |
| Art Bible contains a confirmed icon requirement absent from Product; implementation violates it | Cite the professional source and route the repair according to current/completed Feature ownership; do not require duplicate Product wording. |
| User changes only a confirmed sound specification | Owning specialist updates its source within authorization and handles existing-work impacts; Product participates only for actual behavior changes. |
| A shared Art Bible predates the last sync anchor but was never considered | Verify historical coverage or use authorized current-document alignment; inspect all applicable planned consumers, not only one direct link. |
| Only a professional source changed | Trace primary/secondary references and shared applicability to concrete Feature/AC/verification impacts; later unplanned Products remain deferred. |
| A committed specification rename leaves stale Product/UI source links and Feature references | Route approved source-link repairs to their owners before plan writes, then refresh source analysis and return to the same synchronization; plan navigation updates belong to the plan commit. Preserve completed history. |
| A source rename needs only a Feature primary-source correction | Keep the correction in plan synchronization; do not invent a source edit, extra source commit or new requirement. |
| User wants UI design and an independent UX review | Separate creation Skill/instance from the reviewer; one author loading both is not independent. |
| Reviewer role file exists but context/permissions are unknown | Report what must be verified; configuration presence alone does not establish isolation or successful review. |
| Audio reviewer has filenames but no playable/listening evidence | Report technical checks possible and perceptual checks unverified; no invented listening or human acceptance. |
| Request to create artwork, music or sound effects | Explain reserved production scope and preserve usable specifications/assets; do not invoke a nonexistent production Skill. |
| User requests performance measurement and diagnosis only | Point to diagnostics-performance without inventing a Feature or authorizing optimization; instrumentation needs applicable existing authorization and unavailable measurements remain unverified. |
| User authorizes performance optimization inside a current Feature | Reuse that task for measurement, repair and verification; a separate maintenance entry is for independently owned optimization. |
| Soak run stopped before its planned duration | Report actual duration/scenarios and remaining coverage; no full-duration pass or substituted gdUnit evidence. |
| Resource-list status edited after final verification | Apply existing global fingerprint freshness rules, even if planning classifies the edit as editorial. |
| A selected wording example grants implementation but the user requested investigation only | Preserve the user's read-only scope; the example supplies neither approval nor an instruction to execute. |
| A status query has a matching prompt example | Answer current facts directly without loading examples or manufacturing a continuation prompt. |
| A wording example is absent or conflicts with the project's current Skill | Follow current project authority, report a material conflict if relevant, and draft advice without fetching the framework or regenerating files. |

For every case, verify that advice reads current project facts, refers to the
existing destination workflow when routing is needed, supplies a prompt only for
a handoff/next-action need, and performs no writes.
Record any observed misrouting as a focused regression case; do not claim these
expectations themselves are executed end-to-end tests.
