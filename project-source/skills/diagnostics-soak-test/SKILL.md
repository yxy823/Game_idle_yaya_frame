---
name: diagnostics-soak-test
description: "Run a bounded long-duration Godot scenario to investigate accumulation, lifecycle degradation or stability. Use for sustained execution, not general playtesting or code review."
---

# Soak testing

Follow `methodology/11-specialist-workflows.md` and the task's run authorization.
Before starting, establish scenario, intended duration, workload, sampling,
stop conditions and resource budget. Reuse existing decisions; resolve missing
duration/budget when a long run would otherwise be unbounded.

Exercise meaningful repeated lifecycle transitions and sustained behavior, such
as scene reopen/close, spawn/despawn, idle simulation, save/load or reconnect,
only where applicable. Use isolated user data and available representative inputs.
Define the baseline and useful observations: memory/object counts, errors,
latency, queue growth or drift. `diagnostics-instrumentation` supplies missing signals inside
its own authorized scope; a test must not add invisible production diagnostics.

Record exact version/dirty changes, environment, workload, elapsed runtime,
sampling gaps, peak/trend evidence, stop reason and observed failures. Preserve
raw logs with enough timing to reproduce the trigger. Do not invent hours from
simulation speed or equate simulated time with wall-clock coverage.

On early interruption, report the actual completed duration and untested
remainder. “No failure observed” applies only to executed scenarios and time.
A failure leads to diagnosis and authorized repair, then relevant reruns; do not
erase the first failure or certify a fix from a different diagnostic version.
Results supplement the task's verification plan and never masquerade as gdUnit
runs. Independent assessment of evidence follows the separate reviewer contract.
