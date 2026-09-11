# Shader Globals

Global shader uniforms are project-level GPU APIs.

## Globals

- **[MUST]** Persistent global uniform name/type/default is project-defined configuration. Shader-side fallback/default does not replace project declaration.
- **[MUST]** Rename/remove/type change migrates every shader/script/scene/material consumer.
- **[MUST]** Do not casually treat Color and vec4 as semantically interchangeable in project/global APIs.
- **[MUST]** Use global uniforms only for truly project/environment shared data, not per-object convenience state.
- **[MUST]** If CPU and GPU both need value, maintain CPU/domain authority and upload it rather than making GPU state authoritative.
- **[PREFER]** Declare static global uniforms in project configuration rather than adding them dynamically at normal startup.
- **[PREFER]** Use ShaderGlobalsOverride for temporary/scene-local override semantics where appropriate.
- **[MUST]** Only the first `ShaderGlobalsOverride` in SceneTree order is effective; independent systems must not silently compete with multiple overrides.
- **[MUST]** When multiple scenes or systems need temporary overrides, use a single coordinating owner and validate that removing it restores the project-wide global value.
