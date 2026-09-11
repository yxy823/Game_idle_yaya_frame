# Rule Precedence and Routing

Defines repository-internal rule semantics. It does not redefine Codex/system/developer/user instruction precedence.

## Normative levels

- **[MUST]** `[MUST]` is mandatory unless a higher-priority external instruction or an explicit repository rule exception applies.
- **[MUST]** `[REVIEW]` means the operation may be valid but the named risk must be deliberately evaluated; it is not ignorable noise.
- **[PREFER]** `[PREFER]` is the default engineering direction when no stronger project-specific reason conflicts.
- **[MUST]** Do not introduce `MUST NOT`, `SHOULD`, `SHOULD NOT`, `MAY`, or other normative levels. Express prohibitions as `[MUST] Do not ...`.
- **[MUST]** Machine severity such as Warning/Critical is independent of `[MUST]/[REVIEW]/[PREFER]`.

## Module interaction

- **[MUST]** Root/Core rules define global invariants. A specialized module may explicitly refine a general rule inside its delegated scope but may not silently weaken an applicable Core `[MUST]`.
- **[MUST]** Rule modules are additive by default. Cross-domain files and changes must satisfy every applicable module.
- **[MUST]** A narrower specialized rule takes precedence over a general recommendation only within the scope it explicitly owns.
- **[MUST]** If two applicable `[MUST]` rules appear incompatible, inspect scope, explicit specialization, target Godot semantics, and designated project authority/config before treating them as a real conflict.
- **[MUST]** If two `[MUST]` rules remain genuinely incompatible, do not choose the more convenient rule. Treat it as a specification/rule conflict and report the unresolved blocker instead of weakening policy.

## Rule conflict protocol

When applicable `[MUST]` rules remain impossible to satisfy simultaneously
after the analysis above:

1. **[MUST]** The Agent that detects the conflict must stop implementation in
   the affected scope before making further writes there.
2. **[MUST]** Report every conflicting rule with its source path and identify
   the affected files, behavior, and validation or completion Gates.
3. **[MUST]** Do not silently choose one rule, weaken either rule, or implement
   a workaround that bypasses the conflict.
4. **[MUST]** Request explicit clarification or an approved update to the
   governing rule, and resume the affected implementation only after the
   conflict is resolved.

## Machine configuration and existing code

- **[MUST]** A designated machine-readable configuration is the single source of truth for exact values explicitly delegated to it, such as `gdlint.json` thresholds or an exact schema.
- **[MUST]** Machine configuration states the current configured value; it does not automatically prove that value is correct under project rules or Godot semantics.
- **[MUST]** Existing implementation is evidence of current behavior/convention, not an automatic override of explicit current project rules or architecture.
- **[MUST]** Existing tests are executable evidence of previously encoded behavior, not immutable authority over an explicitly changed requirement.
- **[MUST]** Do not label a failing existing test 'outdated' merely because it blocks implementation. Change it only when approved behavior changed or the test is demonstrated incorrect.
