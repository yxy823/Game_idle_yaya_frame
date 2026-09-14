---
name: execute-next-feature
description: >-
  Execute one approved Feature through test impact review, TDD/verification, applicable human acceptance, optional user-requested independent review and completion. Return to the calling workflow for any further authorized work. English triggers: execute next feature, implement F0XX, continue feature. 中文触发：执行下一个 Feature、实现 F0XX、继续当前 Feature。
---

# Execute next Feature

## Procedure

Use `methodology/03-execute-loop.md` as the sole Stage 0–8 procedure, including
its shared contracts, approval packet, evidence commands, exception handling
and authorized continuation. Read the shared contracts and current Stage,
then follow every applicable Stage in order. On resumption, use the actual
Feature/Progress state and current evidence to find the next required action;
do not restart completed work or repeat unchanged context.

| Decision or action | Supporting authority |
| --- | --- |
| Select the current Product/Feature | **Product-by-Product planning** in `methodology/02-feature-list-schema.md` |
| Read applicable implementation rules and knowledge | Project `AGENTS.md` and its task-specific routes |
| Resolve document language or environment setup | `methodology/05-document-language.md` and confirmed `docs/methodology-config.json` |
| Plan tests, stale-test cleanup or runtime selection | Relevant sections of `methodology/08-testing-strategy.md` |
| Write Feature, Registry or completion fields | Relevant artifact contract in `methodology/02-feature-list-schema.md` |
| Execute direct parsing/lint | `methodology/gdscript-lint.md` |
| Record Bug diagnosis/learning | `methodology/07-engineering-change.md` and execute Stage 5.5 |
| Archive execution or record architecture decisions | `methodology/09-artifact-lifecycle.md` and, when applicable, `methodology/10-architecture-overview.md` |

The execution specification owns optional Stage 6 review and all completion
conditions. This Skill supplies no alternative check sequence or evidence format.
Its `scripts/record-feature-completion.py` records and validates the evidence
described there; it does not perform implementation, tests or review.

At Stage 8, return the completed Feature and next action to the caller under
the specification's **Authorization and continuation** contract.
