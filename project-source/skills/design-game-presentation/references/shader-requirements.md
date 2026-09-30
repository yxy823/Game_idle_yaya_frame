# Standardizing Shader presentation requirements

Describe the surface and visible change before implementation mathematics. Read only the topics relevant to the current component; this is not a required parameter form.

| Topic | Useful requirement questions |
| --- | --- |
| Carrier and scope | What is drawn: one sprite, UI region, material surface or a screen region? Which neighboring objects must remain unaffected? |
| Color and visibility | What becomes brighter, darker, tinted or transparent? Which original details and alpha edges remain visible? |
| Regions and masks | Where does the effect start, stop or exclude content? Is the boundary soft/sharp, moving/fixed, tied to the object's texture or to another coordinate space? |
| UV and texture behavior | Does the texture scroll, distort or repeat? How should seams, transparent padding and edges appear? Do source textures constrain the visible result? |
| Dissolve, outline and procedural patterns | Describe the visible direction, distribution, edge appearance and beginning/end states. Do not assume a noise algorithm or outline sampling method. |
| Time and external control | Is the effect autonomous, a one-shot event or driven by an external progress/value? What should pause, replay, cancellation and repeated triggering visibly do? |
| Space and composition | Should the pattern follow the object, remain anchored in the world or cover the screen? Is it layered with a separate transform, particle or frame animation? |

Example translation: “受伤时闪一下，但轮廓不要糊掉” can become “on the confirmed hit event, briefly brighten/tint the character's opaque region while preserving silhouette and transparent edges; then return to its original appearance.” The exact duration, color and retrigger behavior remain proposed or unresolved until the current design establishes them. Do not invent a fixed number simply to fill a specification.

Make rendering limits explicit where they affect the chosen approach. A Shader can make a surface appear displaced; collision, input areas, layout and game state require their own actual implementation when the requirement calls for them. A full-screen effect needs the real rendering context verified during implementation; do not silently treat it as a local sprite effect.

Record texture/mask dependencies and their relevant specs in this alternative's resource section. Preserve semantic control needs such as “progress from intact to invisible,” while leaving uniform names, equations, blending setup and source code to the implementation unless an existing integration contract requires them.
