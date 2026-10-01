# Scene Structure and Ownership

Scene hierarchy expresses ownership, lifetime, transforms, dependencies, and propagation.

## Editing

- **[PREFER]** Use the Godot editor, structured scene tooling, or a generator for structural scene edits. Small deterministic text patches are acceptable when serialization semantics are known and validated.
- **[MUST]** Do not perform unrelated serialization normalization, section reordering, ID cleanup, or cosmetic rewrites during a focused scene change.
- **[MUST]** Do not impose hard node/tree-depth/line-count limits. A wrapper or subtree exists for semantic ownership/layout/lifecycle reasons, not metric compliance.

## Hierarchy and ownership

- **[MUST]** Parent-child structure should reflect ownership/lifetime/transform/dependency semantics.
- **[MUST]** Distinguish `parent` from `owner`; do not recursively set every Node owner to root as a shortcut.
- **[MUST]** A reusable scene should be self-contained around its intended public dependencies.
- **[PREFER]** The root script coordinates the scene's public API. Child scripts should represent an independent component/subtree responsibility.
- **[MUST]** Do not remove legitimate Timer/AnimationPlayer/component Nodes merely to reduce node count.
- **[REVIEW]** Multiple independent writers to the same visual/gameplay property require explicit coordination; avoid hidden last-writer-wins behavior.

Scene composition can contain both game logic and presentation. When a scene crosses that boundary, use `docs/game-organization.md` to identify state authority, feedback and their connection; do not classify a whole scene by its visual appearance. Animation callbacks may supply gameplay timing, while the game-rule owner decides validity, cancellation and resulting state changes. Keep the actual timing and lifetime contract explicit where it affects the feature.

## Propagation risks

- **[REVIEW]** Reparenting/wrapping Nodes must review transform, process/pause, visibility, modulation, theme, owner, and other inherited/propagated behavior.
- **[MUST]** Crossing an instance/ownership boundary during reparenting is a structural migration and requires consumer/reference review.
