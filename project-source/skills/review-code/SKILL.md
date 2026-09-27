---
name: review-code
description: "Independently review scoped code or changes against approved requirements, architecture and tests. Use when the user requests review; excludes implementation and refactor-candidate selection."
---

# Code review

Apply `methodology/12-independent-review.md` in a fresh reviewer instance. Fix the reviewed snapshot and scope, then select the inputs for the requested object:

- Change review: establish the comparison baseline and inspect the combined final diff, relevant Feature/AC when present, affected callers and original verification.
- Current-state audit: inspect the selected module, files or commit snapshot and direct callers. Use existing relevant requirements and evidence; do not require a diff or invent a Feature, AC or historical baseline. Follow the Audit route in `methodology/00-overview.md` without starting Feature delivery.

Apply the existing-GDD prerequisite before either scope. Read applicable GDD, Product delivery and professional sources, terminology and accepted ADRs/rules. Missing requirements or verification limit the corresponding conclusions; they do not prevent supported code-quality findings.

Answer two separate questions in one scoped pass:
- Requirements: does the result satisfy available approved requirements and AC, preserve required behavior and stay within authorization? Do available tests and human observations actually prove the claims on this snapshot? State what cannot be assessed when those sources are missing.
- Code quality: are responsibilities, state ownership, lifecycle and dependencies coherent? Inspect supported defects and material maintenance costs: duplicated domain rules, misplaced dispatch, magic values, oversized responsibilities, presentation/domain coupling and relevant Godot anti-patterns. Avoid stylistic rewrites without a concrete impact.

When reviewing state models, pattern choices or serialization, apply the current design defaults in Part 2 of `docs/project-rules.md`. Assess the confirmed need, lifecycle and caller obligations against the added structure and whether a simpler implementation can fulfill the same responsibilities. Ground proposed changes in concrete failure risks or maintenance costs; a pattern's presence or absence alone is not a defect.

For added or changed module boundaries, apply **Designing a module boundary** and, for a refactor, **Assessing a proposed refactor** in `methodology/10-architecture-overview.md`. Ground design findings in actual caller obligations, failure/lifetime risks or coordinated edits. A smell is an investigation clue, not a violation by itself; similar code shapes or necessary consumer updates do not alone justify a new abstraction or merged module.

For changed/removed contracts, inspect actual executable assertions, references, test discovery and retained coverage. Registry retirement alone cannot remove a stale test; unfinished required cleanup is `must_fix`. Check failure paths, repeated lifecycle use and the directly affected dependency boundary.

Use `must_fix`, `suggest` and `acceptable` where useful, linking each finding to its requirement/rule and file/evidence. Give a short conclusion for each of the two questions; one cannot stand in for the other. A suggestion is not an approved requirement or automatic TODO. Report evidence gaps and limits under the common contract. Do not fix or mark work accepted/completed.
