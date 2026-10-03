---
name: review-code
description: "Independently inspect a module or code changes for defects and concrete maintenance problems. Use for a requested current-state audit or change review. Not for implementation or for selecting among recorded refactor candidates (engineering-refactor-select)."
---

# Code review

Apply `methodology/12-independent-review.md` in a fresh reviewer instance. Fix the reviewed snapshot and scope, then select the inputs for the requested object:

- Change review: establish the comparison baseline and inspect the combined final diff, relevant Feature/AC when present, affected callers and original verification.
- Current-state audit: inspect the selected module, files or commit snapshot and direct callers. Use existing relevant requirements and evidence; do not require a diff or invent a Feature, AC or historical baseline. Follow the Audit route in `methodology/00-overview.md` without starting Feature delivery.

A missing GDD does not stop either kind of review. A current-state audit can still give supported code-quality conclusions; requirement comparisons that need the GDD report that gap. When a GDD exists, apply **Design scope and boundaries** in `methodology/01-product-doc-structure.md` with the relevant GDD topics for game-behavior review. Read the applicable Product delivery and professional sources, terminology, accepted ADRs and engineering rules. Missing requirements or verification limit the corresponding conclusions; they do not prevent supported code-quality findings.

Answer two separate questions in one scoped pass:
- Requirements: does the result satisfy available approved requirements and AC, preserve required behavior and stay within authorization? Do available tests and human observations actually prove the claims on this snapshot? State what cannot be assessed when those sources are missing.
- Code quality: are responsibilities, state ownership, lifecycle and dependencies coherent? Inspect supported defects and material maintenance costs: duplicated domain rules, misplaced dispatch, magic values, oversized responsibilities, presentation/domain coupling and relevant Godot anti-patterns. Avoid stylistic rewrites without a concrete impact.

When reviewing state models, pattern choices or serialization, apply the current design defaults in Part 2 of `docs/project-rules.md`. Assess the confirmed need, lifecycle and caller obligations against the added structure and whether a simpler implementation can fulfill the same responsibilities. Ground proposed changes in concrete failure risks or maintenance costs; a pattern's presence or absence alone is not a defect.

For game logic/presentation boundaries, apply `docs/game-organization.md` to the actual behavior: who owns the business result, what local presentation state is needed, and what requests, state reads and events mean to consumers. Check relevant cancellation, restoration or repeated-use paths rather than enforcing a class count or communication pattern. Godot nodes and callbacks are not inherently presentation code; when animation supplies gameplay timing, assess how the code explicitly defines that timing and its result instead of treating that involvement alone as a defect.

For added or changed module boundaries, apply **Designing a module boundary** and, for a refactor, **Assessing a proposed refactor** in `methodology/10-architecture-overview.md`. Ground design findings in actual caller obligations, failure/lifetime risks or coordinated edits. A smell is an investigation clue, not a violation by itself; similar code shapes or necessary consumer updates do not alone justify a new abstraction or merged module.

In a current-state audit, follow a representative behavior through the selected scope and its direct callers.

- Investigate why an ordinary change requires coordinated edits or why a layer exists: what caller obligation or useful behavior would be lost if it were removed?
- Use change frequency or difficulty in following the code to choose where to inspect, not as proof of a defect.
- Tie each proposed simplification to a concrete risk or maintenance cost. Keeping the current structure is a valid conclusion.
- Do not turn a scoped request into an automatic repository-wide cleanup.

For changed or removed interfaces and behaviors, inspect actual executable assertions, references, test discovery and retained coverage. Registry retirement alone cannot remove a stale test; unfinished required cleanup is `must_fix`. Check failure paths, repeated lifecycle use and the directly affected dependency boundary.

Use `must_fix`, `suggest` and `acceptable` where useful, linking each finding to its requirement/rule and file/evidence. Give a short conclusion for each of the two questions; one cannot stand in for the other. A suggestion is not an approved requirement or automatic TODO.
