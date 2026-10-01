# Shader implementation methods

Use this reference when a Shader approach, data flow or rendering tradeoff needs reasoning. A parameter-only adjustment may need only its existing parameter contract. Read the relevant sections for the current question rather than producing a complete algorithm plan for every change.

This is a technical reference, independently usable by authorized implementation, guidance and prototype tasks. Reading it does not start the containing Skill's Feature workflow, create a Feature, request an advisor or authorize edits and runtime experiments. Keep the current task's scope and verification rules. Paths in code spans are relative to the target project root.

## Start from the intended effect and its actual surface

Use the confirmed presentation requirements and current implementation to establish what the player should perceive, which parts must remain unchanged and what is still uncertain. When the presentation itself is undecided, use the existing presentation-planning entry; do not treat an algorithm choice as approval to change the experience.

Identify the actual receiving object, shader type, material and relevant renderer, viewport and texture context. A sprite effect, mesh material, full-screen effect and particle simulation do not have interchangeable inputs or output responsibilities. Keep an existing non-Shader approach when it satisfies the requirement more directly; mixed Shader, animation and script control can be appropriate.

For a hit flash, for example, distinguish the confirmed hit result from the visual flash progress. The gameplay owner determines whether the hit occurred; the presentation controller can shape its progress and retrigger behavior, while the Shader turns those inputs into pixels. This does not prescribe a particular signal, controller object or clock implementation.

## Trace the data that produces the result

Explain only the uncertain or consequential parts of the path:

- **Inputs and owners:** Which values come from textures, geometry, material parameters, scene configuration or runtime control? Who updates a progress value, and what happens on a repeated trigger or interruption?
- **Spaces and units:** Where are coordinates, widths, offsets and distances defined? Where does a conversion happen? A texture-space outline and a constant screen-width outline can require different reasoning.
- **Processing and transfer:** What is sampled or calculated, in which shader stage, and what must reach the next stage? Vertex outputs carried by varyings are interpolated for fragment use; choose this transfer only when that interpolation preserves the intended result. Object-space inputs alone do not justify moving a nonlinear or detailed calculation to the vertex stage. See the [Godot 4.7 shading language reference](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html#varyings).
- **Outputs and composition:** What changes RGB, coverage or alpha? Which source details and modulation should survive? Check the actual blending and render context rather than judging the output expression alone.

The existing rules own the engineering contracts: use `agent-rules/30-shaders/coordinates-and-sampling.md` for spaces, regions and sampling; `uniforms-and-material-contracts.md` in that directory for parameter and clock ownership; and `color-alpha-and-blending.md` for composition. This reference supplies ways to reason about choices, not a second rule checklist.

## Compare approaches for the requested effect

These are useful decision points, not mandatory algorithms or deliverables.

| Effect | Questions that distinguish approaches | Consequences to consider |
| --- | --- | --- |
| Tint or hit flash | Blend with source detail or replace its color? Which alpha or mask defines the affected area? Is progress externally controlled? | Preserving a silhouette and tinting the entire quad are different outcomes. Repeated hits may change the controller behavior without requiring another Shader. |
| Outline | Inside or outside the silhouette? What defines width: texels, object units or screen pixels? Which neighborhood samples are needed? | Sampling radius and sample count affect cost and quality. Atlas boundaries, transparent padding and drawable geometry can constrain an outside outline. |
| Dissolve | Which field is compared with progress? Which direction disappears? What must happen at both endpoints? Is there an edge band? | Threshold, edge color and coverage are separate choices. Texture-driven and procedural fields trade authoring control against calculation and sampling cost. |
| Distortion or scrolling | Which texture or screen image is sampled? In which space is its offset defined? What happens outside the valid range? | Offset magnitude, repeat/filter behavior and available source pixels determine the result; screen sampling also depends on the actual capture path. |
| Procedural pattern, noise or distance field | What scale is visible, and what should stay stable as the object, camera or time changes? | Detail can alias under movement or minification. Compare the simplest adequate field with texture lookup or additional calculation, based on the required appearance. |
| 3D rim or view-dependent highlight | Are the normal and view direction meaningful in this stage and expressed in the same space? Does the effect change surface color, emission or transparency? | Normalize transformed/interpolated directions where the calculation requires it. A rim's brightness does not by itself imply transparent coverage. |

Check built-in availability and stage semantics against the target version's [CanvasItem](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/canvas_item_shader.html) or [Spatial](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html) reference as appropriate. Do not carry a built-in or rendering assumption from a different shader type into the implementation.

## Fit the material and control path

Reuse existing material, animation and script consumers where they fit. Work out whether a changed value belongs to a shared material or to one displayed instance before changing its control path. `ShaderMaterial.set_shader_parameter()` uses the exact, case-sensitive uniform name; changing a shared material affects its users. The [Godot 4.7 ShaderMaterial API](https://docs.godotengine.org/en/4.7/classes/class_shadermaterial.html#class-shadermaterial-method-set-shader-parameter) documents that behavior. Let the existing uniform rules determine suitable per-instance or resource arrangements rather than universally duplicating materials.

Describe an additional texture's purpose, channel meaning, dimensions or density needs, transparency and sampling assumptions only as far as the chosen approach requires them. Put scheme-specific resource requirements in that scheme's presentation-document section, following the existing document ownership; this does not authorize image production or require a separate asset list.

Consider expected texture reads, calculation, coverage, overdraw and simultaneous instances when they could distinguish candidates. A smaller expression is not proof of a faster effect. Use `agent-rules/30-shaders/performance-and-stability.md` and obtain measurements when the task actually needs performance evidence; do not introduce profiling as a prerequisite to an ordinary parameter change.

## Return the choice to the current task

When the change affects a documented presentation scheme, update its selected approach and actual implementation/consumer paths under the existing presentation-document contract. Keep necessary engineering reasoning in the owning Feature design or implementation location when one is needed; a small change need not create an additional design file. Candidates can remain unimplemented.

Plan validation against the actual target compiler, material and render path under `agent-rules/30-shaders/validation.md`, within the task's authorized scope. Compilation alone cannot establish the intended appearance. For an observed failure, use [Shader diagnostics](../../bug-diagnosis-godot/references/shader-diagnostics.md) to choose evidence that tests the current hypothesis; that reference does not change the task's authority or completion criteria.
