---
name: diagnostics-instrumentation
description: "Design or add narrowly scoped runtime diagnostics for an authorized Godot investigation: logs, counters, timings or debug displays. Does not itself benchmark, certify performance or authorize repairs."
---

# Observability

Use `methodology/11-specialist-workflows.md`. Begin with the concrete question that existing evidence cannot answer: which transition occurred, what owns an object, why a request failed, where time is spent, or whether state accumulates. Read existing signals before adding more.

Choose the smallest signal that discriminates plausible causes. Define its unit, sampling/aggregation, context needed to interpret it and cost. Use existing logging/debug facilities; avoid a new diagnostics platform for one probe. Do not log secrets or unnecessary player data, flood per-frame logs, or introduce a reflection/property-mutation backdoor.

Persistent code/configuration changes require the current authorized task. Distinguish temporary instrumentation from retained support, specify activation and disable/cleanup behavior, and isolate diagnostic/test data. Verify the signal corresponds to the event it claims to measure and estimate measurement overhead.

Return original signal locations, the observed version, limitations and remaining hypotheses. `diagnostics-performance` or `diagnostics-soak-test` may consume the signals; a bottleneck or leak claim needs measurement. Repair requires its existing task authority and a new relevant verification. Formal review belongs to an independent instance, not this instrumentation Skill.
