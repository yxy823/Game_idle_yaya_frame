# 30 Shader Rules

Applies to hand-written `.gdshader` and `.gdshaderinc` files for Godot 4.7.

There is no shader line-count limit. Split shaders by independent visual responsibility, reuse and validation needs.

| Document | Read when |
| --- | --- |
| `language-and-structure.md` | Writing or changing any shader: `shader_type`, render modes, processor functions, varyings, or particle, sky, fog and `texture_blit` shaders |
| `uniforms-and-material-contracts.md` | Adding or changing uniforms, material parameters, instance uniforms, `set_shader_parameter()` calls or shader time |
| `coordinates-and-sampling.md` | Working with UV, screen, pixel or texel coordinates, atlases and regions, filtering, mipmaps, vertex transforms or screen and backbuffer sampling |
| `color-alpha-and-blending.md` | Changing color-space handling, `source_color`, CanvasItem `COLOR`, alpha, blend modes or Spatial `ALPHA` |
| `performance-and-stability.md` | Changing loops, sampling cost, branches and variants, precision, material reuse or first-use compilation stutter |
| `includes-and-reuse.md` | Adding, changing, renaming or moving a `.gdshaderinc` |
| `validation.md` | Any shader change: determine its applicable validation |

Global shader uniforms declared in ProjectSettings follow [Shader globals](../40-project-config/shader-globals.md).

## Optional methods

The rules above define the engineering constraints. Use these technical references when their reasoning helps with the current question; the paths are relative to the project root.

| Current need | Reference |
| --- | --- |
| Choose a Shader approach, a coordinate or data flow, or a rendering tradeoff | `.agents/skills/implementation-guidance-godot/references/shader-implementation-methods.md` |
| Investigate Shader loading, material and parameter binding, visual data flow or rendering cost | `.agents/skills/bug-diagnosis-godot/references/shader-diagnostics.md` |

Each reference can be read on its own during authorized development, guidance, diagnosis or prototyping. Reading it supplies technical reasoning only; the current task keeps its own authorization and verification scope. Reading a reference does not start the workflow of the Skill that contains it. It also does not create a Feature, request the advisor, or permit running, editing or repairing anything.
