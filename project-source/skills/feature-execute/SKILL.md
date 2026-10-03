---
name: feature-execute
description: >-
  Execute one approved Feature through test impact review, TDD/verification, applicable human acceptance, optional user-requested independent review and completion. Return to the calling workflow for any further authorized work. English triggers: execute next feature, implement F0XX, continue feature. 中文触发：执行下一个 Feature、实现 F0XX、继续当前 Feature。
---

# Execute next Feature

## Procedure

Inspect relevant source changes and resolve their impacts before dependent execution. Use `methodology/03-execute-loop.md` as the sole Stage 0–8 procedure, including its shared contracts, approval packet, evidence commands, exception handling and authorized continuation. Read the shared contracts and current Stage, then follow every applicable Stage in order. On resumption, use the actual Feature/Progress state and current evidence to find the next required action; do not restart completed work or repeat unchanged context.

| Decision or action | Supporting authority |
| --- | --- |
| Select the current Product/Feature | **Stage 0 · select and load context** in `methodology/03-execute-loop.md`, with Product order from **Product-by-Product planning** in methodology 02 |
| Read applicable implementation rules and knowledge | Project `AGENTS.md` and its task-specific routes |
| Prepare needed implementation guidance for an existing Feature | [implementation-guidance-godot](../implementation-guidance-godot/SKILL.md); its explicit-request contract controls advisor delegation, while methodology 03 Stages 1C, 2 and 3 cover the design lifecycle |
| Resolve document language or environment setup | `methodology/05-document-language.md` or `methodology/06-project-environment.md`, and current `docs/methodology-config.json` |
| Plan tests, stale-test cleanup or runtime selection | Relevant sections of `methodology/08-test-traceability-and-evidence.md` |
| Write Feature, Registry or completion fields | Relevant artifact contract in `methodology/02-feature-list-schema.md` |
| Execute direct parsing/lint | `methodology/contracts/gdscript-lint.md` |
| Record Bug diagnosis/learning | `methodology/07-engineering-change.md` and execute Stage 5.5 |
| Archive execution or record architecture decisions | `methodology/09-records-reports-and-handoff.md` and, when applicable, `methodology/10-architecture-overview.md` |
| Use professional sources, supporting specialist work or supplemental evidence | `methodology/11-specialist-workflows.md` |
| Perform user-requested independent review | Stage 6 and `methodology/12-independent-review.md`; review methods live in separate Skills |

The execution specification owns optional Stage 6 review and all completion conditions. This Skill supplies no alternative check sequence or evidence format. The project command `tools/features/record-feature-completion.py` records and validates the evidence described there; it does not perform implementation, tests or review.

At Stage 8, report the completed Feature and the next action. Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
