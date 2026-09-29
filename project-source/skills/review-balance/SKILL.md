---
name: review-balance
description: "Independently review proposed or adopted game formulas and values against stated strategy, progression and pacing goals. Use for requested balance analysis; excludes numeric authoring, tuning implementation and player playtest analysis."
---

# Balance review

Apply `methodology/12-independent-review.md`. Read the supplied GDD mechanics, formulas and pacing/strategy goals, plus the actual numeric data. Distinguish approved rules from draft proposals; numeric review may precede Product, Features or runtime implementation. Missing goals or inputs limit the conclusion and do not authorize inventing a desired balance.

Analyze meaningful decision paths and boundary cases: dominant or useless options, positive feedback, resource sources/sinks, breakpoints, compounding, progression walls and interaction between mechanics. Use transparent calculations or scoped simulations when authorized; state assumptions, units, initial conditions, randomness and parameter ranges.

Compare plausible player strategies rather than one optimal trace. Check whether the model matches the reviewed rules and, when implementation is in scope, the actual runtime behavior; identify results that depend on unverified assumptions. Predicted pacing is not observed player enjoyment, comprehension or retention. General playtest analysis remains outside this framework scope.

Report supported exploits or contract failures separately from tuning suggestions. Keep raw calculations/results and confidence limits. Do not change values, rewrite GDD goals or use this review as human gameplay acceptance. Return scoped numeric authoring to `design-balance`, overall gameplay or experience changes to `design-gdd`, and code/resource repairs to the authorized implementation owner.
