---
name: bug-diagnosis-godot
description: Investigate a specific Godot project defect through reproduction, discriminating hypotheses and causal evidence. Use when the cause is unknown or a repair needs a reliable diagnosis; feedback with uncertain expectations first needs triage.
---

# Diagnose a project defect

Establish how the reported trigger produces the incorrect result. Use **Causal diagnosis** in `methodology/07-engineering-change.md` for the investigation method; that specification also owns Bug routing, records and repair verification. Apply its existing GDD prerequisite and reuse an already established contract and ownership instead of restarting triage.

## Choose the necessary evidence

Start from the confirmed expected behavior, actual symptom, relevant implementation and current evidence. If it is not yet clear whether the observation contradicts approved intent, use [feedback-triage-godot](../feedback-triage-godot/SKILL.md) before selecting a repair. Read affected engineering domains through project `AGENTS.md`; do not load every domain or diagnostic method for one failure.

Apply the canonical diagnosis method to obtain a useful reproduction, distinguish plausible causes and explain the causal chain. Investigation can use existing logs and source reasoning before a runnable reproduction is available. Runtime evidence, diagnostic edits and test runs must fit the current task's authorized scope and project verification rules; a read-only request does not authorize them.

Use the relevant method only when its evidence answers the current question:

| Evidence needed | Method |
| --- | --- |
| Missing signals about a transition, object owner or repeated operation | [diagnostics-instrumentation](../diagnostics-instrumentation/SKILL.md) |
| Comparable timing, memory or workload measurements | [diagnostics-performance](../diagnostics-performance/SKILL.md) |
| Accumulation or stability during sustained/repeated execution | [diagnostics-soak-test](../diagnostics-soak-test/SKILL.md) |
| Evidence points to Shader loading, material/parameter binding, visual data flow or rendering cost | [Shader diagnostics](references/shader-diagnostics.md), a directly readable technical reference rather than another Skill workflow |

The same diagnosis can trace rule results, state, feedback and their connections under the canonical method. Neither a visual symptom nor reading a Shader reference requires the user to classify the defect's layer, split its record or grant further execution authority.

## Return the diagnosis to the owning task

Report the symptom and expected source, useful trigger, causal conclusion with supporting evidence, rejected alternatives when informative, and remaining uncertainty. State the actual investigation coverage and any required next check. Propose the smallest repair justified by the evidence; do not label a hypothesis as the root cause because its workaround made the symptom disappear.

Follow methodology 07 for durable Bug evidence and `methodology/09-records-reports-and-handoff.md` for retained results and temporary probes. Record only what the task needs in existing Feature/Progress locations. Preserve original failure evidence and make the state of temporary diagnostics explicit.

A diagnosis-only request ends with the supported conclusion or a clear blocker; an unresolved cause remains unresolved. When repair is already authorized, return to its current Feature or [engineering-change-plan](../engineering-change-plan/SKILL.md) as the ownership contract requires, then continue the authorized work. Diagnosis neither creates a separate approval gate nor replaces regression verification, applicable human acceptance or the existing completion contract.
