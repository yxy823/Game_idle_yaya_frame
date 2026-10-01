# 30 Shader Rules

Applies to hand-written `.gdshader` and `.gdshaderinc` for Godot 4.7.

There is no shader line-count limit. Split by independent visual responsibility, reuse, and validation needs.

Read all concrete documents relevant to the shader: `language-and-structure.md`, `uniforms-and-material-contracts.md`, `coordinates-and-sampling.md`, `color-alpha-and-blending.md`, `performance-and-stability.md`, `includes-and-reuse.md`, and `validation.md`.

## Optional methods

The rules above own engineering constraints. Use these technical references when their reasoning helps the current question; paths below are relative to the target project root.

| Current need | Reference |
| --- | --- |
| Choose a Shader approach, coordinate/data flow or rendering tradeoff | `.agents/skills/implementation-guidance-godot/references/shader-implementation-methods.md` |
| Investigate Shader loading, material/parameter binding, visual data flow or rendering cost | `.agents/skills/bug-diagnosis-godot/references/shader-diagnostics.md` |

Both references are independently readable during authorized development, guidance, diagnosis or prototyping. Reading one does not start its containing Skill's workflow, create a Feature, request an advisor or grant permission to run, edit or repair anything. Keep the current task's authority and verification scope.
