# Shader Language and Structure

Use exact target Godot 4.7 shader semantics and keep shader work visual, not authoritative gameplay logic.

## Target language

- **[MUST]** `shader_type` and render modes match the actual Node/material/render path and target Godot 4.7 API.
- **[MUST]** Do not copy Godot 3 or latest/master shader syntax/render modes without target-version verification.
- **[MUST]** Render-mode add/remove/change is rendering-pipeline behavior, not a cosmetic text edit.
- **[MUST]** Locals are initialized before read on every control-flow path; compile success does not make undefined values portable across GPU/drivers.

## Stage semantics

- **[MUST]** Define every custom shader function before any function that calls it. Helper functions called by `vertex()`, `fragment()`, or `light()` must appear above those processor functions.
- **[PREFER]** For readability, follow the Godot code order of `shader_type`, render modes, uniforms, constants, varyings, helper functions, then processor functions; not every formatting choice in this order is a compile requirement.
- **[MUST]** Cross-stage custom data uses `varying`; do not assume similarly named stage built-ins share custom state.
- **[MUST]** Use `flat` interpolation for discrete IDs/categories when interpolation would be semantically invalid.
- **[MUST]** Assign varyings only from processors/stages where Godot permits assignment.
- **[MUST]** Shader code never becomes authoritative gameplay state.

## Shader families

- **[MUST]** Particle shaders are stateful across frames and target GPU particles. Validate start/restart/keep-data/CUSTOM/USERDATA lifecycle when those semantics matter.
- **[REVIEW]** Sky shaders using TIME/dynamic uniforms/LIGHT/half/quarter passes may change radiance cubemap update cost and must be evaluated as sky-pipeline work, not ordinary fragment work.
- **[MUST]** Fog shaders require a renderer/volumetric-fog path that actually supports the intended behavior; evaluate FogVolume/froxel coverage cost.
- **[MUST]** `texture_blit` assumptions remain within its DrawableTexture contract; do not import CanvasItem assumptions blindly.
