# Rule Precedence and Routing

Defines the semantics of rules inside this repository. It does not redefine the precedence of Codex, system, developer or user instructions.

## Normative levels

- **[MUST]** `[MUST]` is mandatory unless a higher-priority external instruction or an explicit repository rule exception applies.
- **[MUST]** `[REVIEW]` means that the operation may be valid but the named risk must be deliberately evaluated; it is not ignorable noise.
- **[PREFER]** `[PREFER]` is the default engineering direction when no stronger project-specific reason conflicts with it.
- **[MUST]** Do not introduce `MUST NOT`, `SHOULD`, `SHOULD NOT`, `MAY` or other normative levels. Express prohibitions as `[MUST] Do not ...`.
- **[MUST]** Machine severity such as Warning or Critical is independent of `[MUST]`, `[REVIEW]` and `[PREFER]`.

## Module interaction

- **[MUST]** Root and Core rules define global invariants. A specialized module may explicitly refine a general rule inside its delegated scope, but it may not silently weaken an applicable Core `[MUST]`.
- **[MUST]** Rule modules are additive by default. Cross-domain files and changes satisfy every applicable module.
- **[MUST]** A narrower specialized rule takes precedence over a general recommendation only within the scope it explicitly covers.
- **[MUST]** If two applicable `[MUST]` rules appear incompatible, inspect their scope, any explicit specialization, target Godot semantics and the designated project authority or configuration before treating them as a real conflict.
- **[MUST]** If two `[MUST]` rules remain genuinely incompatible, do not choose the more convenient rule. Treat it as a specification or rule conflict and report the unresolved blocker instead of weakening policy.

## Rule conflict protocol

When applicable `[MUST]` rules remain impossible to satisfy simultaneously after the analysis above:

1. **[MUST]** The Agent that detects the conflict stops implementation in the affected scope before making further writes there.
2. **[MUST]** Report every conflicting rule with its source path, and identify the affected files, behavior, and validation or completion Gates.
3. **[MUST]** Do not silently choose one rule, weaken either rule or implement a workaround that bypasses the conflict.
4. **[MUST]** Request explicit clarification or an approved update to the conflicting rule. Resume the affected implementation only after the conflict is resolved.

## Suspected rule errors

Repository rules can contain factual errors, outdated version assumptions or overly broad applicability, even when no two rules conflict.

- **[MUST]** When concrete evidence questions an applicable rule, check its scope and its factual and version assumptions. Then report the rule and its source, the limits of the evidence and the affected behavior to the user. Distinguish a rule defect from a justified departure that a `[PREFER]` permits; personal preference alone does not establish a defect.
- **[MUST]** Assess code compliance and rule correctness separately. Handle proposed corrections under [incremental rule maintenance](../../methodology/04-project-rules.md#incremental-rule-maintenance). Do not silently edit or waive a rule. Reuse specific approval, and pause only the implementation that depends on an unresolved required decision.

## Machine configuration and existing code

- **[MUST]** A designated machine-readable configuration is the single source of truth for exact values explicitly delegated to it, such as `gdlint.json` thresholds or an exact schema.
- **[MUST]** Machine configuration states the currently configured value; it does not prove that the value is correct under project rules or Godot semantics.
- **[MUST]** Existing implementation is evidence of current behavior and convention. It does not automatically override explicit current project rules or architecture.
- **[MUST]** Existing tests are executable evidence of previously encoded behavior, not immutable authority over an explicitly changed requirement.
- **[MUST]** Do not label a failing existing test "outdated" merely because it blocks implementation. Change it only when approved behavior changed or the test is demonstrated to be incorrect.
