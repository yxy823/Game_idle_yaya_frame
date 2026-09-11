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
| Status query with old PASS and changed source | Report stored evidence and unverified freshness separately; no fake current PASS. |
| Simple bounded next action | Short prompt; avoid copying the entire workflow. |
| Cross-module migration with uncertain inputs | Investigation/planning prompt with evidence gaps and validation obligations. |
| Emergency Bug | Shorter preparation is possible; required regression/affected checks, applicable human acceptance and traceable commit remain. |
| Stable lower ID depends on a newer pending ID | Use actual DAG eligibility, not numeric order or highest-ID selection. |
| Dirty tree contains another task | Report ownership conflict; do not stash, delete, overwrite or silently commit it. |

For every case, verify that advice reads current project facts, refers to the
existing destination workflow, gives one suitable prompt and performs no writes.
Record any observed misrouting as a focused regression case; do not claim these
expectations themselves are executed end-to-end tests.
