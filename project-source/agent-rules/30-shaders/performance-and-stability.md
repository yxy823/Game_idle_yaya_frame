# Shader Performance and Stability

Optimize based on the measured workload and renderer semantics, not on blanket folklore.

## Loops and sampling

- **[MUST]** Shader loops have provable termination. Dynamic or high-iteration fragment loops require review and bounded ranges for external uniforms.
- **[REVIEW]** Evaluate texture-sample cost with screen coverage, instance count, texture behavior and target hardware, not with a universal maximum sample count.
- **[REVIEW]** Procedural noise versus a texture lookup is a tradeoff between ALU, bandwidth and memory; do not declare either universally faster.
- **[REVIEW]** Screen-texture effects include backbuffer copy costs and full-screen coverage costs.
- **[REVIEW]** Evaluate multipass rendering (`next_pass`) by its total rendering cost and necessity; do not ban or prefer it mechanically.

## Variants and precision

- **[REVIEW]** Runtime branches and preprocessor variants have tradeoffs that depend on the renderer and the number of variants. Do not mechanically rewrite everything to be branchless.
- **[MUST]** Do not use precision modifiers as a default mobile optimization without evidence from the target.
- **[MUST]** Do not compare computed floating-point control values for exact equality when numerical tolerance or representation makes that contract invalid.

## Reuse and stutter

- **[PREFER]** Objects that use the same algorithm share shaders and material structure. Use per-instance parameters instead of duplicating a ShaderMaterial solely for per-object values.
- **[REVIEW]** For critical first-use Shader, Material and Particle paths, consider the renderer-specific stutter caused by pipeline compilation, and consider warming them up.
- **[MUST]** Preloading a Resource does not prove that its first render pipeline is compiled. Validate the actual first draw where stutter is relevant.
- **[PREFER]** Use a Tween for interpolating object properties, an AnimationPlayer for authored timelines across several properties, shaders for per-pixel or per-vertex visuals, and particle shaders for GPU particle state, when each tool matches the effect.
