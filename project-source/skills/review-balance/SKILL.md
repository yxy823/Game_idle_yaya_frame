---
name: review-balance
description: "Independently examine game formulas and values against approved strategy, progression and pacing goals. Use for requested balance analysis; excludes tuning implementation and player playtest analysis."
---

# Balance review

Apply `methodology/12-independent-review.md`. Read the approved GDD mechanics, formulas and pacing/strategy goals, plus the actual numeric data. Missing goals within the existing GDD are an uncertainty, not permission to invent a desired balance.

Analyze meaningful decision paths and boundary cases: dominant or useless options, positive feedback, resource sources/sinks, breakpoints, compounding, progression walls and interaction between mechanics. Use transparent calculations or scoped simulations when authorized; state assumptions, units, initial conditions, randomness and parameter ranges.

Compare plausible player strategies rather than one optimal trace. Check whether the model matches implemented rules and whether results depend on unverified assumptions. Predicted pacing is not observed player enjoyment, comprehension or retention. General playtest analysis remains outside this framework scope.

Report supported exploits or contract failures separately from tuning suggestions. Keep raw calculations/results and confidence limits. Do not change values, rewrite GDD goals or use this review as human gameplay acceptance.
