# Shader diagnostics

Use this reference when evidence points to Shader compilation, material/parameter binding, visual data flow or rendering cost. Start with the actual symptom and confirmed expectation; a missing effect can originate in gameplay, event delivery or presentation control before the Shader is involved. The user need not identify that boundary in advance.

This is a technical reference, independently usable by the current authorized diagnosis, implementation or prototype task. Reading it does not invoke the containing Skill's full workflow, create a Feature or authorize diagnostic edits, running Godot or repairing the defect. **Causal diagnosis** in `methodology/07-engineering-change.md` owns the investigation and Bug records; `methodology/09-artifact-lifecycle.md` owns temporary probes and retained evidence. Paths in code spans are relative to the target project root.

## Select a branch from the evidence

Read current source, relevant consumers and existing evidence before choosing a probe. Establish the actual Godot version and the material/node/render context relevant to the symptom. Ask for missing logs, an image or runtime conditions only when that evidence can distinguish causes; none is a universal submission requirement.

| Observed problem | Useful checks or discriminating evidence |
| --- | --- |
| Compilation or loading fails | Relate the actual engine error to the loaded Shader and include files. Verify resource paths and consumers before modifying an expression merely near the reported line. |
| Edits seem to have no effect | Confirm which scene, node, material and source the running instance actually uses. Check whether another assignment, material override or runtime update replaces the intended value. When hot reload is uncertain, obtain evidence of the loaded revision or deliberately reload within the task's authority. |
| A parameter affects nothing, the wrong value or several objects | Trace its exact uniform name, type, material instance and runtime writer. Distinguish a shared-material update from per-instance control before changing ownership. |
| The Shader runs but color, edges or transparency are wrong | Isolate the relevant sample, coordinate conversion, alpha, mask or blend relationship. The hypothesis determines which intermediate value to inspect. |
| Timing or repeated triggers behave incorrectly | Trace the trigger, controller state and value delivered to the Shader, then its time/progress calculation. Do not infer a Shader defect solely from a visual symptom. |
| The effect is expensive | Establish a comparable workload and use existing performance diagnosis when measurements are needed. Compare relevant coverage, overdraw, sampling or simultaneous instances; do not infer cost from source length. |

Use the existing `agent-rules/30-shaders/README.md` route for applicable engineering constraints. For example, `ShaderMaterial.set_shader_parameter()` is case-sensitive and updates a shared material for all its users; see the [Godot 4.7 ShaderMaterial API](https://docs.godotengine.org/en/4.7/classes/class_shadermaterial.html#class-shadermaterial-method-set-shader-parameter). The source path in an editor or an unchanged log alone does not prove that the running object consumed the latest edit.

## Make one suspected relationship visible

A temporary output can test whether an input or intermediate value matches the hypothesis. Choose the smallest useful probe and preserve unrelated work. Reading all channels or adding permanent debug uniforms is not a prerequisite.

| Question | Possible temporary view | Interpretation limits |
| --- | --- | --- |
| Are the coordinates in the intended space and range? | Map the relevant coordinate components into visible colors or a simple grid. | Out-of-range values need a meaningful display mapping. Discontinuities may be expected at seams or repeated regions. |
| Is the correct source sampled? | Show raw sampled RGB, or sampled alpha as grayscale. | Separate source content from modulation, later masks and blending. A grayscale alpha probe must be visible without accidentally hiding its own zero values. |
| Does a threshold or mask select the intended area? | Show the scalar field, mask or edge band separately. | Check expected endpoints and polarity; a uniform black or white result is not automatically wrong. |
| Is a direction or auxiliary buffer meaningful? | Inspect appropriately mapped normals, directions, depth or screen samples when the actual shader type and stage provide them. | Signed or non-color data needs interpretation. Do not invent unavailable built-ins or assume that a screen/depth source includes every object. |

In CanvasItem fragment processing, incoming `COLOR` combines vertex color/modulation and the default texture; comparing it with a raw texture sample can separate those factors. See the [Godot 4.7 CanvasItem reference](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/canvas_item_shader.html#color-and-texture). When constructing a probe, keep its compositing changes explicit: a Spatial Shader that reads or writes `ALPHA` enters the transparent pipeline, so adding that output can change the behavior under investigation. See the [Godot 4.7 Spatial reference](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html#fragment-built-ins).

For example, if a hit flash colors the sprite's transparent rectangle red, first confirm which alpha should preserve the silhouette. Compare sampled alpha with the effect mask only as needed to distinguish an input problem from output composition. Do not rewrite the hit calculation just because the symptom followed a hit, or claim an alpha fix from a diagnostic image that bypasses the formal blend path.

## Stabilize a comparison when time obscures it

If successive observations cannot be compared because animation advances, hold the relevant progress or diagnostic time input constant and align the scene, camera, viewport, trigger and initialization conditions that affect the result. This is a targeted comparison, not proof that the entire runtime is deterministic.

Pausing the scene does not freeze the built-in Shader `TIME`; the [Godot 4.7 CanvasItem time contract](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/canvas_item_shader.html#global-built-ins) documents that distinction. Use a controlled input when the comparison needs one, within the existing clock contract. Reset other relevant state where necessary rather than assuming a fixed time also resets particle simulation or gameplay.

An image can preserve useful evidence, but every defect does not need screenshots or a golden-image system. Match the evidence to the claim: compiler output for compilation, actual parameter/control evidence for binding, and a comparable rendered observation for an appearance hypothesis.

## Restore and verify the formal path

Once the probe has answered its question, restore temporary outputs, assignments, diagnostic constants and resources introduced for the investigation. Retain useful failure evidence under the existing artifact policy. Confirm that the intended Shader revision and real material/control path are in use, then check the original trigger and relevant regression cases under `agent-rules/30-shaders/validation.md` and the current task's verification boundary.

A read-only investigation may finish without running or changing anything; record that coverage honestly. A successful probe is not proof that the restored implementation works. If loading freshness, the real render path or the cause remains unverified, report that precise gap. Keep objective mismatches, aesthetic judgments and untested hypotheses distinct, and return findings to the owning task without a second Bug record solely for the Shader portion.
