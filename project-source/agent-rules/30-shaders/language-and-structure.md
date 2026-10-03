# Shader Language and Structure

Use the exact shader semantics of the target Godot 4.7, and keep shader work visual rather than authoritative gameplay logic.

## Target language

- **[MUST]** `shader_type` and render modes match the actual Node, material and render path and the target Godot 4.7 API.
- **[MUST]** Do not copy shader syntax or render modes from Godot 3, `latest` or `master` without verifying them against the target version.
- **[MUST]** Adding, removing or changing a render mode is rendering-pipeline behavior, not a cosmetic text edit.
- **[MUST]** Initialize locals before they are read on every control-flow path. A successful compile does not make undefined values portable across GPUs and drivers.

## Stage semantics

- **[MUST]** Define every custom shader function before any function that calls it. Helper functions called by `vertex()`, `fragment()` or `light()` appear above those processor functions.
- **[PREFER]** For readability, follow the Godot code order: `shader_type`, render modes, uniforms, constants, varyings, helper functions, then processor functions. Not every formatting choice in this order is a compile requirement.
- **[MUST]** Pass custom data between stages through `varying`. Do not assume that similarly named built-ins in different stages share custom state.
- **[MUST]** Use `flat` interpolation for discrete IDs or categories when interpolation would be semantically invalid.
- **[MUST]** Assign varyings only in the processor functions where Godot permits assignment.
- **[MUST]** Shader code never becomes authoritative gameplay state.

## Shader families

- **[MUST]** Particle shaders keep state across frames and target GPU particles. When the start, restart, keep-data, `CUSTOM` or `USERDATA` lifecycle matters, validate it across frames.
- **[REVIEW]** Sky shaders that use `TIME`, dynamic uniforms, `LIGHT`, or half- and quarter-resolution passes may change the update cost of the radiance cubemap. Evaluate them as sky-pipeline work, not ordinary fragment work.
- **[MUST]** Fog shaders require a renderer and volumetric-fog path that actually supports the intended behavior. Evaluate the FogVolume and froxel coverage cost.
- **[MUST]** Keep `texture_blit` assumptions within its DrawableTexture contract; do not carry CanvasItem assumptions over blindly.
