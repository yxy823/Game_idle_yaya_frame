# Shader Uniform and Material Contracts

Uniforms are cross-file public APIs between shader, material/resource, scene, script, animation, and project configuration.

## Uniform APIs

- **[MUST]** Uniform rename/type/semantic changes migrate every material, scene, script, AnimationPlayer, and tooling consumer.
- **[MUST]** `set_shader_parameter()` calls must match the Shader uniform name and compatible type exactly; a type mismatch may not produce a normal error and can lead to undefined behavior.
- **[MUST]** Provide safe defaults and meaningful hints. Use `source_color` for actual color textures/uniforms, not data textures.
- **[PREFER]** Material-owned values use material uniforms; true per-instance values use instance uniforms where supported; true project/environment shared values use global uniforms.
- **[MUST]** Per-instance uniforms are supported only for `canvas_item` and `spatial` shaders, do not support textures or arrays, and have a practical maximum of 16 per shader.
- **[MUST]** With multiple materials on a 3D mesh, check that corresponding per-instance uniforms use consistent name, type, and instance index across materials.
- **[REVIEW]** Compatibility-renderer paths that dynamically index sampler arrays using instance data require renderer-specific validation; support in another renderer is not evidence of support here.
- **[MUST]** Global uniforms must be declared through Project Settings; Project Settings owns their authoritative declaration and default/value contract, so a default written in the shader declaration cannot be relied on.
- **[MUST]** Avoid high-frequency CPU readback of GPU/global-uniform state as a gameplay architecture.

## Time and global state

- **[MUST]** Built-in `TIME` is engine visual time with its own rollover/time-scale semantics. Do not use it for authoritative pause/replay/gameplay clocks.
- **[PREFER]** Use an explicit custom time uniform when deterministic/pause-specific visual time is part of the contract.
- **[MUST]** If both CPU and GPU require an authoritative value, keep CPU/domain ownership and upload to the shader rather than reading shader state back as authority.
