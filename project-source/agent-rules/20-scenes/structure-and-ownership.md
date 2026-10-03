# Scene Structure and Ownership

The scene hierarchy expresses ownership, lifetime, transforms, dependencies and propagation.

## Editing

- **[PREFER]** Use the Godot editor, structured scene tooling or a generator for structural scene edits. Small deterministic text patches are acceptable when the serialization semantics are known and validated.
- **[MUST]** Do not perform unrelated serialization normalization, section reordering, ID cleanup or cosmetic rewrites during a focused scene change.
- **[MUST]** Do not impose hard limits on node count, tree depth or line count. A wrapper or subtree exists for ownership, layout or lifecycle reasons, not for metric compliance.

## Hierarchy and ownership

- **[MUST]** Make the parent-child structure reflect ownership, lifetime, transform and dependency semantics.
- **[MUST]** Distinguish `parent` from `owner`. Do not recursively set every Node's owner to the root as a shortcut.
- **[MUST]** Keep a reusable scene self-contained around its intended public dependencies.
- **[PREFER]** The root script coordinates the scene's public API. Child scripts represent an independent component or subtree responsibility.
- **[MUST]** Do not remove legitimate Timer, AnimationPlayer or component Nodes merely to reduce the node count.
- **[REVIEW]** Several independent writers to the same visual or gameplay property require explicit coordination; avoid hidden last-writer-wins behavior.

Scene composition can contain both game logic and presentation. When a scene crosses that boundary, use `docs/game-organization.md` to identify the state authority, the feedback and their connection; do not classify a whole scene by its visual appearance. Animation callbacks may supply gameplay timing, while the game-rule owner decides validity, cancellation and the resulting state changes. Keep the actual timing and lifetime contract explicit where it affects the feature.

## Propagation risks

- **[REVIEW]** When reparenting or wrapping Nodes, review transform, process and pause, visibility, modulation, theme, owner and other inherited or propagated behavior.
- **[MUST]** Crossing an instance or ownership boundary during reparenting is a structural migration and requires a review of consumers and references.
