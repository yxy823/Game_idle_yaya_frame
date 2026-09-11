# Shader Performance and Stability

Optimize based on measured workload and renderer semantics, not blanket folklore.

## Loops and sampling

- **[MUST]** Shader loops have provable termination. Dynamic/high-iteration fragment loops require review and bounded external uniform ranges.
- **[REVIEW]** Texture-sample cost is evaluated with screen coverage, instance count, texture behavior, and target hardware—not a universal sample-count maximum.
- **[REVIEW]** Procedural noise versus texture lookup is an ALU/bandwidth/memory trade-off; do not declare one universally faster.
- **[REVIEW]** Screen-texture effects include backbuffer/copy and full-screen coverage costs.
- **[REVIEW]** Multipass/`next_pass` is evaluated by total rendering cost and necessity; do not ban or prefer multipass mechanically.

## Variants and precision

- **[REVIEW]** Runtime branches and preprocessor variants have renderer/variant trade-offs. Do not mechanically rewrite everything branchless.
- **[MUST]** Do not use precision modifiers as a default mobile optimization without target evidence.
- **[MUST]** Do not compare computed floating control values for exact equality when numerical tolerance/representation makes that contract invalid.

## Reuse and stutter

- **[PREFER]** Algorithm-identical objects share shaders/material structure; use per-instance parameters instead of duplicating ShaderMaterial solely for per-object values.
- **[REVIEW]** Critical first-use Shader/Material/Particle paths should consider renderer-specific pipeline compilation/warmup stutter.
- **[MUST]** Resource preload does not prove first render pipeline is compiled; validate actual first draw where stutter is relevant.
- **[PREFER]** Use Tween for object-property interpolation, AnimationPlayer for authored/multi-property timelines, shaders for per-pixel/vertex visuals, and Particle Shaders for GPU particle state when each tool matches the effect.
