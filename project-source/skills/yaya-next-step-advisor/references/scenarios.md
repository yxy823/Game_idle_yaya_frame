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
| Audit only | Read-only finding/report prompt; no source writes or automatically created Bug. |
| Human says a specific tested revision is accepted | Follow up on that exact scope/snapshot; do not accept another version or Feature. |
| Status query with old PASS and changed source | Report stored evidence and unverified freshness separately; no fake current PASS or unnecessary continuation prompt. |
| Simple bounded next action | Short prompt; avoid copying the entire workflow. |
| Cross-module migration with uncertain inputs | Investigation/planning prompt with evidence gaps and validation obligations. |
| Emergency Bug | Shorter preparation is possible; required regression/affected checks, applicable human acceptance and traceable commit remain. |
| Stable lower ID depends on a newer pending ID | Use actual DAG eligibility, not numeric order or highest-ID selection. |
| Dirty tree contains another task | Report ownership conflict; do not stash, delete, overwrite or silently commit it. |
| Record a confirmed term without changing behavior | Point to `product-standardizer` terminology maintenance and `docs/terminology.md`; no Product initialization, new Feature or second glossary. |
| A terminology edit changes intended behavior | Resolve the Product choice and affected planning; do not disguise it as editorial maintenance. |
| Continue a Feature with an existing long design | Read `F0XX-design.md` and source links; reuse approved constraints and return to the actual Stage. |
| A local implementation choice is proposed as a project rule | Require the rule-change self-check and any missing substantive authority; do not infer a global rule from local success. |
| User already approved a concrete rule change | Preserve that decision, require the self-check before writing, and route impact handling without asking again. |
| Ordinary Feature has no ADR | Missing optional ADR is normal; do not manufacture a record or block completion. |
| A costly cross-Feature choice has real alternatives | Apply the existing ADR threshold and destination; reuse a relevant record and do not override Product/project rules. |
| Stage 3 discovers settled terminology or needed design updates | Use the documentation checkpoint within current ownership/authorization; do not end authorized delivery at the supporting Skill return. |
| Final tests passed before a rule/design document changed | Explain current evidence freshness and the owning revalidation route; old PASS alone cannot authorize completion. |

For every case, verify that advice reads current project facts, refers to the
existing destination workflow when routing is needed, supplies a prompt only for
a handoff/next-action need, and performs no writes.
Record any observed misrouting as a focused regression case; do not claim these
expectations themselves are executed end-to-end tests.
