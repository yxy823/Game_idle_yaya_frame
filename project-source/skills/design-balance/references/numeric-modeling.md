# Numeric modeling and calculation checks

Use this reference to derive or diagnose the numeric relationships that matter to the current design. The listed systems are conditional lenses, not a checklist requiring every game to have an economy, combat or long-term growth.

## Establish the calculation contract

Identify the intended experience in observable or calculable terms, such as combat duration, resource scarcity, time to an unlock, attention demands or viability of a choice. State which aspects remain subjective and need observation.

Use the relevant player skill, equipment/build, difficulty, failure cost, session length and randomness assumptions. For each consequential variable, make its unit, source, domain, limit, rounding and update point clear. Distinguish a target from a measured value, an existing value from a candidate, and adoption from verification. Record enough source context to understand which rules the calculation uses without adding a separate provenance ledger.

When a rule is unresolved, a conditional model or comparison may still be useful. Say which result depends on that rule rather than silently resolving it. If the missing choice prevents a meaningful comparison, identify that specific gap and continue unaffected analysis.

## Keep resource and time quantities distinct

Balances, net production rates, cumulative acquisition and unlock progress are different quantities. State which the goal uses. Include relevant spending and capacity limits; a gross income target does not imply that the player can afford a purchase at the same time.

Separate active input, online waiting, paused time and offline time according to the adopted rules. Processes may overlap. Do not add two durations when they occur simultaneously, or charge time twice because both an action and an automatic process are described.

For an investment, distinguish:

- Time until the purchase is affordable, given current balance and eligible income.
- Time to recover the investment through its relevant incremental benefit.
- Time to reach the actual stage or unlock target, including prerequisite purchases and their effect on income.

These are not interchangeable pacing measures. If a purchase changes the rate, calculate the periods before and after it separately. When the goal concerns cumulative spending or acquisition, preserve that definition rather than substituting the current balance.

For example, suppose a purely illustrative model starts with 20 units, earns 2 units per second and allows a 100-unit upgrade that adds 1 unit per second. With no other spending or limits, affordability takes 40 seconds; simple incremental payback takes another 100 seconds. Neither number alone gives the time to a different unlock target. These assumptions and values are examples, not project defaults or industry benchmarks.

## Choose the relevant relationships

| System | Relationships and risks to examine |
| --- | --- |
| Combat | Effective output, incoming damage, survival and target turns/time. Include relevant hit rates, defenses, action loss, cooldowns, enemy count and phase changes. Average output alone may hide repeated failure or burst thresholds. |
| Economy | Sources, sinks, stored quantities, conversion and caps. Start from the intended accumulation or spending pattern; income equaling expenditure is not a universal balance target. Check profitable cycles or constraints that invalidate apparent gains. |
| Growth | Cost, benefit, prerequisites, unlocks, bottlenecks and time/attention investment. Check whether targets are reachable and what earlier investments do later. An upgrade's calculated benefit does not establish its subjective impact. |
| Automation and offline progress, when adopted | Investment, replaced actions, production and remaining player decisions. Use the actual processes, efficiency, time or capacity limits. Do not assume that every online rule also runs offline. |
| Reset or prestige, when adopted | Reward basis, cleared/retained state, recovery time and what changes in the next run. Compare the actual reset decision with continued play under the current scope. |
| Randomness and strategy | Expected value, variation, important tails and player-visible risk/reward. Compare plausible strategies and dependencies, including dominant combinations or choices made useless by thresholds. A single optimal trace does not cover likely play. |

Simple identities can expose inconsistent accounting:

```text
resource change = eligible inflows - outflows
ending balance = starting balance + accumulated changes
approximately constant conditions:
  total effective output ≈ effective output per turn × turns
```

Apply these only under their stated conditions. Use discrete updates, caps, floors, event order or phase changes when they affect the result. Continuous averages are insufficient if the actual rule can run out of a resource, miss an unlock or cross a sharp threshold.

## Compare scenarios and proposed changes

Select typical and consequential boundary situations from the actual question, such as a weak build, repeated poor luck, a capacity limit or a strategy that delays an investment. Check dimensions and arithmetic before interpreting the result. Compare alternative player choices where a tuning decision depends on them.

Explain which assumptions or parameters most affect the answer. A small sensitivity comparison often reveals whether a precise candidate value is justified. Prefer the simplest model that preserves the important relationship; do not create a general simulation framework for a calculation that a short computation can answer.

Report the inputs, method and actual output of any computation or simulation. When randomness matters, disclose its relevant distribution, sample conditions and limits. A deterministic mock only checks that modeled relationship; it cannot prove engine timing, integration or player experience.

For a proposed adjustment, show the original value, candidate value, expected direction of change and meaningful side effects. If reaching the goal requires a new mechanic or changed experience target, explain that dependency and return it to overall game design instead of hiding it in a formula.

## Separate evidence from the decision

A user can adopt a candidate before it has been observed in play. A calculation can be correct while its experience hypothesis remains untested. Keep those distinctions visible in the source rather than introducing another shared status table.

State the next useful observation, the evidence to collect and what would justify changing the parameter or model. Actual observations retain their conditions and scope; unrun validation remains a plan. Recalculate affected claims when rules or inputs change, and avoid presenting results for an earlier model as verification of its replacement.
