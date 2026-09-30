# Selecting an implementation family

Choose by the required observable behavior and existing project capabilities. This table suggests a starting point, not a mandatory architecture or exhaustive comparison exercise.

| Need | Useful starting point | Decision that matters |
| --- | --- | --- |
| Existing project effect already communicates the intended feedback | Reuse or adapt its public controls | Check actual behavior and consumers before assuming it fits; preserve the project's integration conventions. |
| A few objects move, rotate, scale or change ordinary properties | Tween or existing property controls | Dynamic start/target values and interruption often favor Tween; distinguish actual transform changes from a visual illusion. |
| Authored timing coordinates several tracks or repeatable property changes | AnimationPlayer or existing animation resources | Identify which timing is fixed and which values remain driven by game state. Do not prescribe track structure during requirements planning. |
| A fixed authored sequence supplies shapes/details difficult to express procedurally | Sprite frames / an existing animation asset | Describe required timing, loop and orientation; note the external frames dependency and limitations on variation. Planning does not produce those images. |
| An existing surface changes per-pixel appearance | Shader, often animated by another controller | Color, UV distortion, masking or dissolve can fit; rendering alone does not update collision, layout, damage or entity state. |
| Many visual elements have independent birth, motion and lifetime | Particle system with suitable existing material/controls | Describe the population and lifecycle. Require custom processing only when ordinary capabilities cannot meet an actual requirement. |
| Several of these behaviors contribute to the same moment | A combination of component approaches | Coordinate trigger, ordering, space and cancellation; reuse each component's specification. |

For example, a character death can combine a surface dissolve, detached sparks and a short property animation. The game rule that the character is dead remains GDD/runtime logic; the presentation describes how that state becomes perceptible. UI involvement is optional.

Compare a candidate on perceptual fit, controllability, required files, reuse and meaningful runtime constraints. Do not claim measured performance from the technique's name or choose a universal winner. Use a scoped prototype only for a specific uncertainty such as acceptable density, interruption behavior or scale at the actual viewport.

Keep an exact engine property, renderer constraint or API as a requirement only when verified and material to the task. Otherwise leave it for implementation research. A useful planning result can say “sparks detach at the hit point and fade independently” without choosing a node tree or motion equation.
