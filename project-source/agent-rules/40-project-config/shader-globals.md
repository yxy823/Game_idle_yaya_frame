# Shader Globals

Global shader uniforms are project-level GPU APIs. This document owns their ProjectSettings declaration; shader-side uniform rules are in [Shader uniform and material contracts](../30-shaders/uniforms-and-material-contracts.md).

## Globals

- **[MUST]** The name, type and default of a persistent global uniform are project-defined configuration. A fallback or default on the shader side does not replace the project declaration.
- **[MUST]** Renaming, removing or retyping a global uniform migrates every shader, script, scene and material consumer.
- **[MUST]** Do not casually treat Color and vec4 as semantically interchangeable in project or global APIs.
- **[MUST]** Use global uniforms only for data truly shared across the project or environment, not for per-object convenience state.
- **[MUST]** When the CPU and the GPU both need a value, keep the authority on the CPU side, as described in [Time and authoritative values](../30-shaders/uniforms-and-material-contracts.md#time-and-authoritative-values).
- **[PREFER]** Declare static global uniforms in project configuration rather than adding them dynamically during normal startup.
- **[PREFER]** Use `ShaderGlobalsOverride` for temporary or scene-local override semantics where appropriate.
- **[MUST]** Only the first `ShaderGlobalsOverride` in SceneTree order takes effect; independent systems must not silently compete through several overrides.
- **[MUST]** When several scenes or systems need temporary overrides, use a single coordinating owner, and validate that removing it restores the project-wide global value.
