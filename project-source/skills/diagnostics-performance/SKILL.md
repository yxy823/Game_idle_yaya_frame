---
name: diagnostics-performance
description: "Measure and diagnose a scoped Godot performance problem with reproducible workloads and comparable evidence. Use for profiling; instrumentation and fixes are separate authorized work."
---

# Performance profiling

Follow `methodology/11-specialist-workflows.md`, especially evidence limits. Clarify the actual symptom and workload from the task: frame-time spikes, startup/loading, simulation throughput, memory or another measured concern. Use approved budgets where present; do not invent a pass threshold.

Record the actual version/dirty state, Godot version, machine, execution mode, display conditions, workload and measurement tool. Select representative stable and transition scenarios; distinguish warm-up, import/editor work and steady runtime. Collect suitable distributions, spikes and trends rather than relying on average FPS alone. Retain raw captures and the comparison conditions.

Separate observation from causal explanation. Test one supported hypothesis within the authorized experiment scope; request [diagnostics-instrumentation](../diagnostics-instrumentation/SKILL.md) only if missing signals block discrimination. Temporary instrumentation changes the measured version and may perturb it. Do not generalize editor/debug measurements to a delivery configuration without evidence.

Return bottleneck evidence, confidence limits and prioritized repair proposals. An authorized fix follows the owning execution route and is remeasured against a comparable baseline with correctness checks. Profiling does not self-certify the fix or replace gdUnit results.
