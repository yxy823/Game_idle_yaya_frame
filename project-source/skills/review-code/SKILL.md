---
name: review-code
description: "Independently review scoped code or changes against approved requirements, architecture and tests. Use when the user requests review; excludes implementation and refactor-candidate selection."
---

# Code review

Apply `methodology/12-independent-review.md` in a fresh reviewer instance. Read
the selected Feature/AC, relevant Product and professional sources, terminology,
accepted ADRs/rules, final diff, affected callers and original verification.

Answer two separate questions in one scoped pass:
- Requirements: does the result satisfy concrete AC, preserve required behavior
  and stay within authorization? Do tests and human observations actually prove
  the claims on this snapshot?
- Code quality: are responsibilities, state ownership, lifecycle and dependencies
  coherent? Inspect supported defects and material maintenance costs: duplicated
  domain rules, misplaced dispatch, magic values, oversized responsibilities,
  presentation/domain coupling and relevant Godot anti-patterns. Avoid stylistic
  rewrites without a concrete impact.

For added or changed module boundaries, apply **Designing a module boundary**
and, for a refactor, **Assessing a proposed refactor** in
`methodology/10-architecture-overview.md`. Ground design findings in actual
caller obligations, failure/lifetime risks or coordinated edits. A smell is an
investigation clue, not a violation by itself; similar code shapes or necessary
consumer updates do not alone justify a new abstraction or merged module.

For changed/removed contracts, inspect actual executable assertions, references,
test discovery and retained coverage. Registry retirement alone cannot remove a
stale test; unfinished required cleanup is `must_fix`. Check failure paths,
repeated lifecycle use and the directly affected dependency boundary.

Use `must_fix`, `suggest` and `acceptable` where useful, linking each finding
to its requirement/rule and file/evidence. Give a short conclusion for each of
the two questions; one cannot stand in for the other. A suggestion is not an
approved requirement or automatic TODO. Report evidence gaps and limits under
the common contract. Do not fix or mark work accepted/completed.
