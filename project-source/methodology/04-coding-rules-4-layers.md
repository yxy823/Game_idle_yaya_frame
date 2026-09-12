# 04 - Coding Rules architecture

This document keeps its historical filename for workflow compatibility. The
current architecture is responsibility-based; it is not an independent
four-layer override system.

## Responsibilities

The repository uses these rule boundaries:

```text
docs/coding_rules.md
  collaboration, workflow, and stack-independent architecture

AGENTS.md
  root project router and repository execution instructions

agent-rules/00-core/
  global engineering invariants and rule precedence

agent-rules/<specialized module>/
  concrete Godot, GDScript, and domain semantics for that module
```

`methodology/` defines Product and Feature workflow, Test Impact Review,
traceability, human acceptance, and completion gates. It does not become a
second source for concrete engine or language behavior.

## `docs/coding_rules.md`

The generated Coding Rules document is the stable home for:

- collaboration expectations and human-control boundaries;
- stack-independent workflow constraints;
- general architecture, dependency, state, data, error-handling, and
  performance principles;
- a short orientation to the repository rule sources.

It must not copy the current Environment Bootstrap status, executable paths,
tool versions, or concrete Godot/GDScript rules. Those facts belong to the
authoritative configuration or routed rule documents.

## Rule loading

An agent loads the applicable rules in this order:

1. Read the root `AGENTS.md` and identify the affected domains.
2. Read `agent-rules/00-core/README.md` and its routed concrete documents.
3. Read each affected specialized module README and every concrete document it
   routes for the change. A module's `validation.md` is applied whenever that
   module is affected.
4. Apply the core precedence protocol. A specialized rule may refine behavior
   inside its delegated scope, but may not silently weaken a core invariant.
5. Report a real contradiction instead of selecting one source silently.

The README files are the routing authority for concrete documents. File names
alone are not a substitute for an explicit Read list.

## Stack-independent architecture

The following principles belong in `docs/coding_rules.md` because they do not
depend on a particular engine or programming language:

- separate data and presentation, with explicit events or read-only state;
- use an explicit state machine for meaningful multi-state transitions;
- keep data/rules, orchestration/control, and presentation/input boundaries
  understandable;
- prefer composition and explicit dependency passing over hidden global access;
- drive adjustable behavior from data or focused configuration;
- keep core rules as independent and testable as the project allows;
- keep important runtime state representable as plain serializable data;
- distinguish expected failure from exceptional failure and do not silently
  swallow errors;
- measure before introducing performance complexity.

Use a Command or another focused abstraction when it removes real complexity
from a non-trivial action. Do not impose a pattern where a small pure function,
an existing project convention, or a direct implementation is clearer.

Organize code around cohesive responsibilities and domain boundaries. File
length, complexity, and other numeric limits belong to the project's
machine-readable validation configuration. They are evidence for review, not a
universal line-count rule or an automatic split authorization.

## Contextual project knowledge

`docs/knowledge/` stores reusable approaches, debugging methods and failure
lessons from actual project tasks. Its README routes to topic
indexes and separate entries. Consult relevant notes before choosing an approach,
then check their conditions against current intent, code and target-version facts.
Knowledge is evidence, not another source of mandatory engineering rules.

An experience may be useful only in this project's particular conditions and
still deserve a note. Feature notes keep the original incident and local task
history; knowledge holds the extracted explanation and links that record. Stable
prescriptive guidance follows the existing rule-promotion path below.

## Evolution and rule promotion

Keep concrete framework and language learnings in the appropriate
`agent-rules/<module>/` source after explicit approval. Keep incident-specific
learning in the relevant Feature notes. Promote only reusable, prescriptive
guidance; do not turn Coding Rules into an incident log.

When a change would move a rule between these boundaries, inspect ownership and
report the boundary change before editing. Do not create a parallel concrete
rule authority to avoid the existing router.
