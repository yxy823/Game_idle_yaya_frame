# Shader Uniform and Material Contracts

Uniforms are public APIs shared by the shader, materials and Resources, scenes, scripts, animations and project configuration.

## Uniform APIs

- **[MUST]** When a uniform's name, type or meaning changes, migrate every material, scene, script, AnimationPlayer and tooling consumer.
- **[MUST]** `set_shader_parameter()` calls match the Shader uniform's name and a compatible type exactly. A type mismatch may not produce a normal error and can lead to undefined behavior.
- **[MUST]** Provide safe defaults and meaningful hints. The `source_color` hint follows [Color space](color-alpha-and-blending.md#color-space).
- **[PREFER]** Use material uniforms for material-owned values, instance uniforms for true per-instance values where supported, and global uniforms for values truly shared across the project or environment.
- **[MUST]** Per-instance uniforms are supported only for `canvas_item` and `spatial` shaders, do not support textures or arrays, and have a practical maximum of 16 per shader.
- **[MUST]** With several materials on a 3D mesh, check that the corresponding per-instance uniforms use a consistent name, type and instance index across materials.
- **[REVIEW]** Compatibility-renderer paths that dynamically index sampler arrays with instance data require renderer-specific validation; support in another renderer is not evidence of support here.
- **[MUST]** Declare global uniforms in ProjectSettings under [Shader globals](../40-project-config/shader-globals.md); a default written in the shader declaration cannot be relied on.
- **[MUST]** Do not build gameplay architecture on high-frequency CPU readback of GPU or global-uniform state.

## Time and authoritative values

- **[MUST]** The built-in `TIME` is engine visual time with its own rollover and time-scale semantics. Do not use it for authoritative pause, replay or gameplay clocks.
- **[PREFER]** Use an explicit custom time uniform when deterministic or pause-specific visual time is part of the contract.
- **[MUST]** If both the CPU and the GPU need an authoritative value, keep ownership on the CPU or domain side and upload the value to the shader rather than reading shader state back as the authority.
